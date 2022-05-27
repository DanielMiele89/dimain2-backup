
/***************************************************************************
Author:	Main Code written by Jenny Hurley - SP Created by Suraj Chahal
Date: 25-01-2016
Purpose: ROC Phase 2 forecasting tool - Spender Adjustments
Version: V2 - V1 adapted from V2 to incorporate adjustments ratios at segment level (agg)
-- Dones as per STO sales model code : Jenny Hurley
-- Currently this is done as full data segmentation with RBS base.  
-- could perhaps improve accuracy by building more relevant data history


***************************************************************************/
CREATE PROCEDURE [Prototype].[ROCP2_Code_02E_SpenderAdjustmentsv3]
	(
	@IndividualBrand BIT
	)
AS
BEGIN


--DECLARE @IndividualBrand BIT
--SET @IndividualBrand = 1

/***************************************
*******Dates : (Define the dates)*******
***************************************/
IF OBJECT_ID('tempdb..#WeekBuild') IS NOT NULL DROP TABLE #WeekBuild
SELECT	*,
	ROW_NUMBER() OVER(ORDER BY StartDate) as Weekno
INTO #WeekBuild
FROM	(
	SELECT	WeekNum,
		MIN(StartDate) as StartDate,
		MAX(EndDate) as EndDate
	FROM Prototype.ROCP2_SegFore_Rundaylk 
	WHERE BuildWeek = 1
	GROUP by WeekNum
	)a


CREATE CLUSTERED INDEX IDX_SDED ON #WeekBuild (StartDate,EndDate)
CREATE NONCLUSTERED INDEX IDX_WeekNum ON #WeekBuild (WeekNum)
CREATE NONCLUSTERED INDEX IDX_WeekNo ON #WeekBuild (WeekNo)

/******************************************
****Brands : Again make a genric tables****
******************************************/

/*****************************************************************/
IF OBJECT_ID ('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
CREATE TABLE #Brand
	(
	BrandID SMALLINT NOT NULL,
	BrandName VARCHAR(75) NULL,
	Sector SMALLINT,
	AcquireL0 SMALLINT,
	LapserL0 SMALLINT,
	Acquire_Pct0 INT,
	RowNo SMALLINT,
	AcquireL SMALLINT,
	LapserL SMALLINT,
	Acquire_Pct INT
	PRIMARY KEY (BrandID)
	)

IF @IndividualBrand <> 0
BEGIN

INSERT INTO #Brand
SELECT *
FROM Prototype.ROCP2_Brandlist_Individual
--

DELETE FROM Prototype.ROCP2_SpendersAdj
WHERE BrandID IN (SELECT BrandID FROM #Brand)

END
ELSE
BEGIN

INSERT INTO #Brand
SELECT *
FROM Prototype.ROCP2_Brandlist

TRUNCATE TABLE Prototype.ROCP2_SpendersAdj

END
/*****************************************************************/

CREATE NONCLUSTERED INDEX IDX_AcqL ON #Brand (AcquireL)
CREATE NONCLUSTERED INDEX IDX_LapL ON #Brand (LapserL)
CREATE NONCLUSTERED INDEX IDX_RowNo ON #Brand (RowNo)



/*************************************
***CREATE Staging.ROCP2_SpendersAdj***
*************************************/
--IF OBJECT_ID ('Prototype.ROCP2_SpendersAdj') IS NOT NULL DROP TABLE Prototype.ROCP2_SpendersAdj
--CREATE TABLE Prototype.ROCP2_SpendersAdj 
--	(
--	BrandID SMALLINT NULL,
--	Segment VARCHAR(50) NULL,
--	WeekLength SMALLINT NULL,
--	Spenders INT NULL,
--	Trans INT NULL,
--	ATF REAL NULL,
--	Base_Spenders INT NULL,
--	Base_Trans INT NULL,
--	BASE_ATF REAL NULL,
--	ATFRatio REAL NULL
--	)
--CREATE CLUSTERED INDEX IDX_BID ON Prototype.ROCP2_SpendersAdj (BrandID)

/*****************************************
*********Creating Brand Loop code*********
*****************************************/
DECLARE @BrandID SMALLINT,
	@RowNo INT

SET @RowNo = 1

WHILE @RowNo <= (SELECT MAX(RowNo) FROM #Brand)

BEGIN
SET @BrandID = (SELECT BrandID FROM #Brand WHERE RowNo = @RowNo)


IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT  ConsumerCombinationID,
	cc.BrandID
INTO #CCIDs 
FROM Relational.ConsumerCombination cc WITH (NOLOCK)
WHERE	cc.BrandID = @BrandID
	and IsUKSpend = 1
--
CREATE CLUSTERED INDEX IND_CC on #CCIDs (ConsumerCombinationID)
CREATE NONCLUSTERED INDEX IND_BD on #CCIDs (BrandID)


/********************************
*******Transactional pull********
********************************/
DECLARE @EndDate DATE, @firstdate date, @lengthA int, @lengthL int,  @LdateS date

SET @EndDate = (SELECT MAX(EndDate) FROM #WeekBuild)
SET @FirstDate = DATEADD(WEEK,-52,@EndDate)
SET @lengthA = (select AcquireL from #Brand where brandid=@brandid)
SET @lengthL = (select LapserL from #brand where brandid=@brandid)


 declare @fdateS date, @edateS date
 set @edateS = dateadd(day,-1,@firstdate)
 set @fdateS = dateadd(month,-@lengthA,@edateS) -- Could be bespoke per brand but for simplication of code at the 
 set @LdateS  =  dateadd(month,-@lengthL,@edateS) -- Could be bespoke per brand but for simplication of code at the 


IF OBJECT_ID('tempdb..#Last12mSpd') IS NOT NULL DROP TABLE #Last12mSpd
SELECT	ct.CINID,
	TranDate,
	COUNT(1) as Trans
INTO #Last12mSpd
FROM #CCIDs b 
INNER JOIN Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
	ON b.ConsumerCombinationID = ct.ConsumerCombinationID
INNER JOIN Prototype.ROCP2_SegFore_FixedBase c
	ON c.CINID = ct.CINID
WHERE TranDate BETWEEN @FirstDate AND @EndDate
	AND isRefund = 0
GROUP BY ct.TranDate, ct.CINID
--
CREATE CLUSTERED INDEX IND_CD ON #Last12mSpd (CINID)
CREATE NONCLUSTERED INDEX IND_TD ON #Last12mSpd (TranDate)

/***************************************************
***************************************************/
---- Defining segments
--select * from prototype.ROCp2_Brandlist
 ---- Segmentation Spend 

 IF OBJECT_ID('tempdb..#SegmentPlan') IS NOT NULL DROP TABLE #SegmentPlan

select ct.CINID
,1 as PreSpder
,max(case when trandate >= @LdateS then 1 else NULL end) as LastXSpder
into #SegmentPlan
from #ccids b 
inner join Warehouse.Relational.ConsumerTransaction ct  with (nolock) on b.ConsumerCombinationID=ct.ConsumerCombinationID
inner join Prototype.ROCP2_SegFore_FixedBase   c on c.cinid=ct.cinid    ----------ROCP2_SegFore_FixedBase
where TranDate between @fdateS and @edateS
AND ISRefund = 0 --- exclude refunds
group by ct.CINID

-- Create Universe

 IF OBJECT_ID('tempdb..#UniverseATF') IS NOT NULL DROP TABLE #UniverseATF

 select b.cinid
  , case when s.PreSpder is NULL then 'Acquire'
         when s.LastXSpder is NULL then 'Lapser'
		 when s.LastXSpder is not null then 'Existing' else 'Error' end as SegmentAgg
 -- , s.PreSpder 
--  , s.LastXSpder
--   ,ls.trans 
into #UniverseATF
 from Prototype.ROCP2_SegFore_FixedBase b
 left join #SegmentPlan s on b.cinid=s.cinid

--select count(distinct cinid),SegmentAgg from #UniverseATF group by SegmentAgg

 IF OBJECT_ID('tempdb..#Universe_Acquire') IS NOT NULL DROP TABLE #Universe_Acquire
 select cinid
 into #Universe_Acquire
 from #UniverseATF
 where SegmentAgg in ('Acquire')


 IF OBJECT_ID('tempdb..#Universe_Lapser') IS NOT NULL DROP TABLE #Universe_Lapser
 select cinid
 into #Universe_Lapser
 from #UniverseATF
 where SegmentAgg in ('Lapser')

 
 IF OBJECT_ID('tempdb..#Universe_Existing') IS NOT NULL DROP TABLE #Universe_Existing
 select cinid
 into #Universe_Existing
 from #UniverseATF
 where SegmentAgg in ('Existing')


----  Spliting the last 12month transactions by date into Segment
--- Was very slow when I cut by this... 
-- Might need to loop 
 IF OBJECT_ID('tempdb..#last12m_Seg_Ac') IS NOT NULL DROP TABLE #last12m_Seg_Ac
 select lt.*
into #last12m_Seg_Ac
 from #Last12mSpd lt
 where cinid in (select distinct cinid from #Universe_Acquire)

 IF OBJECT_ID('tempdb..#last12m_Seg_LP') IS NOT NULL DROP TABLE #last12m_Seg_LP
 select lt.*
into #last12m_Seg_LP
 from #Last12mSpd lt
 where cinid in (select distinct cinid from #Universe_Lapser)

 IF OBJECT_ID('tempdb..#last12m_Seg_Ex') IS NOT NULL DROP TABLE #last12m_Seg_Ex
 select lt.*
into #last12m_Seg_Ex
 from #Last12mSpd lt
 where cinid in (select distinct cinid from #Universe_Existing)



/****************************************************
****************************************************/
DECLARE @EndDate1 DATE
SET @EndDate1 = (SELECT MAX(EndDate) FROM #WeekBuild)

IF OBJECT_ID('tempdb..#summary1') IS NOT NULL DROP TABLE #summary1
select 'All' as Segment 
,*
,case when spenders>0 then Trans/cast (spenders as real) else NULL end as ATF
into #summary1
from (
	select 4 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #Last12mSpd t
	where TranDate between dateadd(week,-4,@enddate1)  and @enddate1
	union all
	select 8 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #Last12mSpd t
	where TranDate between dateadd(week,-8,@enddate1)  and @enddate1
	union all
	select 12 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #Last12mSpd t
	where TranDate between dateadd(week,-12,@enddate1)  and @enddate1
	union all
	select 16 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #Last12mSpd t
	where TranDate between dateadd(week,-16,@enddate1)  and @enddate1
	union all
	select 20 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #Last12mSpd t
	where TranDate between dateadd(week,-20,@enddate1)  and @enddate1
	union all
	select 24 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #Last12mSpd t
	where TranDate between dateadd(week,-24,@enddate1)  and @enddate1
	union all
	select 48 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #Last12mSpd t
	where TranDate between dateadd(week,-48,@enddate1)  and @enddate1
	union all
	select 52 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #Last12mSpd t
	where TranDate between dateadd(week,-52,@enddate1)  and @enddate1
) a



IF OBJECT_ID('tempdb..#summary2') IS NOT NULL DROP TABLE #summary2
select 'Acquire' as Segment 
,*
,case when spenders>0 then Trans/cast (spenders as real) else NULL end as ATF
into #summary2
from (
	select 4 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ac t
	where TranDate between dateadd(week,-4,@enddate1)  and @enddate1
	union all
	select 8 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ac t
	where TranDate between dateadd(week,-8,@enddate1)  and @enddate1
	union all
	select 12 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ac t
	where TranDate between dateadd(week,-12,@enddate1)  and @enddate1
	union all
	select 16 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ac t
	where TranDate between dateadd(week,-16,@enddate1)  and @enddate1
	union all
	select 20 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ac t
	where TranDate between dateadd(week,-20,@enddate1)  and @enddate1
	union all
	select 24 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ac t
	where TranDate between dateadd(week,-24,@enddate1)  and @enddate1
	union all
	select 48 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ac t
	where TranDate between dateadd(week,-48,@enddate1)  and @enddate1
	union all
	select 52 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ac t
	where TranDate between dateadd(week,-52,@enddate1)  and @enddate1
) a


IF OBJECT_ID('tempdb..#summary3') IS NOT NULL DROP TABLE #summary3
select 'Existing' as Segment 
,*
,case when spenders>0 then Trans/cast (spenders as real) else NULL end as ATF
into #summary3
from (
	select 4 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ex t
	where TranDate between dateadd(week,-4,@enddate1)  and @enddate1
	union all
	select 8 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ex t
	where TranDate between dateadd(week,-8,@enddate1)  and @enddate1
	union all
	select 12 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ex t
	where TranDate between dateadd(week,-12,@enddate1)  and @enddate1
	union all
	select 16 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ex t
	where TranDate between dateadd(week,-16,@enddate1)  and @enddate1
	union all
	select 20 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ex t
	where TranDate between dateadd(week,-20,@enddate1)  and @enddate1
	union all
	select 24 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ex t
	where TranDate between dateadd(week,-24,@enddate1)  and @enddate1
	union all
	select 48 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ex t
	where TranDate between dateadd(week,-48,@enddate1)  and @enddate1
	union all
	select 52 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_Ex t
	where TranDate between dateadd(week,-52,@enddate1)  and @enddate1
) a


IF OBJECT_ID('tempdb..#summary4') IS NOT NULL DROP TABLE #summary4
select 'Lapser' as Segment 
,*
,case when spenders>0 then Trans/cast (spenders as real) else NULL end as ATF
into #summary4
from (
	select 4 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_LP t
	where TranDate between dateadd(week,-4,@enddate1)  and @enddate1
	union all
	select 8 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_LP t
	where TranDate between dateadd(week,-8,@enddate1)  and @enddate1
	union all
	select 12 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_LP t
	where TranDate between dateadd(week,-12,@enddate1)  and @enddate1
	union all
	select 16 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_LP t
	where TranDate between dateadd(week,-16,@enddate1)  and @enddate1
	union all
	select 20 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_LP t
	where TranDate between dateadd(week,-20,@enddate1)  and @enddate1
	union all
	select 24 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_LP t
	where TranDate between dateadd(week,-24,@enddate1)  and @enddate1
	union all
	select 48 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_LP t
	where TranDate between dateadd(week,-48,@enddate1)  and @enddate1
	union all
	select 52 as weeklength
		  ,count(distinct cinid) as spenders
		  ,sum(trans) as Trans
	from #last12m_Seg_LP t
	where TranDate between dateadd(week,-52,@enddate1)  and @enddate1
) a




IF OBJECT_ID('tempdb..#summary') IS NOT NULL DROP TABLE #summary
select *
into #summary
from 
(
select * from #summary1
union all
select * from #summary2
union all
select * from #summary3
union all
select * from #summary4
) a


-- Yes Suraj I know this is horrible but I really needed to get the results out!!  Was already behind as this was changed to fix a last min bug.
--select * from #summary


--------------------------  THe one week build length
--- Since there might be low data volumes and week data is more volitile build an average solution
-- could look to do this for the various other low time points

--declare @noweeks real
--set @noweeks = (select max(weekno) from #weekbuild)

-- Don't need to code in week divide as reduces to same thing

IF OBJECT_ID('tempdb..#Base1') IS NOT NULL DROP TABLE #Base1

select  'All' Segment
      ,sum(spenders) as BASESpenders
      ,sum(trans) as BASETrans  -- how woudl null work here! 
	  ,case when sum(spenders) >0 then sum(trans)/cast (sum(spenders) AS real) else 0 end as BASEATF
into #Base1
from (
				select weekno
				,coalesce(count(distinct cinid),0) as spenders
				,coalesce(sum(trans),0) as trans
				from #Last12mSpd s
				cross join #weekbuild w
				where s.trandate between w.startdate and w.enddate
				group by weekno 
		) a

--select * from #Base1

IF OBJECT_ID('tempdb..#Base2') IS NOT NULL DROP TABLE #Base2

select 'Acquire' as Segment
	  ,sum(spenders) as BASESpenders
      ,sum(trans) as BASETrans  -- how woudl null work here! 
	  ,case when sum(spenders) >0 then sum(trans)/cast (sum(spenders) AS real) else 0 end as BASEATF
into #Base2
from (
				select weekno
				,coalesce(count(distinct cinid),0) as spenders
				,coalesce(sum(trans),0) as trans
				from #last12m_Seg_Ac s
				cross join #weekbuild w
				where s.trandate between w.startdate and w.enddate
				group by weekno 
		) a


IF OBJECT_ID('tempdb..#Base3') IS NOT NULL DROP TABLE #Base3

select 'Existing' as Segment
	  ,sum(spenders) as BASESpenders
      ,sum(trans) as BASETrans  -- how woudl null work here! 
	  ,case when sum(spenders) >0 then sum(trans)/cast (sum(spenders) AS real) else 0 end as BASEATF
into #Base3
from (
				select weekno
				,coalesce(count(distinct cinid),0) as spenders
				,coalesce(sum(trans),0) as trans
				from #last12m_Seg_Ex s
				cross join #weekbuild w
				where s.trandate between w.startdate and w.enddate
				group by weekno 
		) a

IF OBJECT_ID('tempdb..#Base4') IS NOT NULL DROP TABLE #Base4

select 'Lapser' as Segment
	  ,sum(spenders) as BASESpenders
      ,sum(trans) as BASETrans  -- how woudl null work here! 
	  ,case when sum(spenders) >0 then sum(trans)/cast (sum(spenders) AS real) else 0 end as BASEATF
into #Base4
from (
				select weekno
				,coalesce(count(distinct cinid),0) as spenders
				,coalesce(sum(trans),0) as trans
				from #last12m_Seg_LP s
				cross join #weekbuild w
				where s.trandate between w.startdate and w.enddate
				group by weekno 
		) a

IF OBJECT_ID('tempdb..#Base') IS NOT NULL DROP TABLE #Base
select *
into #Base
from 
(
select * from #Base1
union all
select * from #Base2
union all
select * from #Base3
union all
select * from #Base4
) a



--- WHAT DO I DO IF NO SPENDERS IN A WEEK!!!  

IF OBJECT_ID('tempdb..#Combined') IS NOT NULL DROP TABLE #Combined
Select a.*
,case when BASEATF>0 then ATF /CAST( BASEATF AS real) else NULL end as ATFRatio
into #Combined
from (
select s.*
      ,b.BASEATF 
from #summary s
cross join #Base b where s.segment=b.segment  ) a



INSERT INTO Prototype.ROCP2_SpendersAdj
SELECT  @BrandID as BrandID,
	*  
FROM #Combined

SET @RowNo = @RowNo+1 

END

END