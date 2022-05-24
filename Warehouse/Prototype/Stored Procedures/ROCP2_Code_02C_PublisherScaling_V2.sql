
/***************************************************************************
Author:	Main Code written by Jenny Hurley - SP Created by Suraj Chahal
Date: 25-01-2016
Purpose: Publisher Scaling Factor
***************************************************************************/
CREATE PROCEDURE [Prototype].[ROCP2_Code_02C_PublisherScaling_V2]
AS
BEGIN


--Understanding publisher scaling correction 

/**************************************************
***Setting Length of Time for quick Segmentation***
**************************************************/
if object_id('tempdb..#Timepoint') is not null drop table #Timepoint
create table #Timepoint
	(
	tValue SMALLINT NULL
	)

insert into #Timepoint
values (3)       -- The number is months which the segmentation of Acquire and existing will be split
   


/*****************************************************************************/
/*  Setting Dates                                                          ***/
/*****************************************************************************/
IF OBJECT_ID('tempdb..#WeekBuild') IS NOT NULL DROP TABLE #WeekBuild
select	*,
	ROW_NUMBER () OVER (ORDER BY StartDate) as Weekno
into #WeekBuild
from (
select weeknum
,min(StartDate) as StartDate
,max(EndDate) as EndDate
from Prototype.ROCP2_SegFore_Rundaylk 
where buildweek=1
group by weeknum ) a


IF OBJECT_ID('tempdb..#Dates0') IS NOT NULL DROP TABLE #Dates0
select 
dateadd(day,-1,min(StartDate)) as EndDate   -- the segmentation EndDate
,min(StartDate) as fStartDate
,max(EndDate) as fEndDate
into #Dates0
from #WeekBuild

--select * from #Dates0
--select * from #WeekBuild


/***********************************
*******Customer base for nFI********
***********************************/
--LIMIT TO ACTIVATED DATES PRIOR TO 
IF OBJECT_ID('tempdb..#CustBase_Pub0') IS NOT NULL DROP TABLE #CustBase_Pub0
SELECT	c.name as ClubName,
	clubID as ClubID,
	f.ID as ID,
	f.CompositeID,
	p.ID as PanID
	,r4g.CompositeID as R4G_Flag -- When populated then R4G : JH v2 EDIT
INTO #CustBase_Pub0  -- Changed to 0 as JH v2 EDIT
FROM SLC_Report.dbo.Fan f WITH (NOLOCK)
INNER JOIN SLC_Report.dbo.Pan p WITH (NOLOCK)
	ON F.CompositeID = P.CompositeID
INNER JOIN SLC_Report.dbo.Club c WITH (NOLOCK)
	ON c.ID = f.clubid
LEFT  JOIN Warehouse.InsightArchive.QuidcoR4GCustomers r4g WITH(NOLOCK)
	ON f.CompositeID = r4g.CompositeID
where	f.clubID IN 
		(
		SELECT	DISTINCT 
			ClubID 
		FROM Prototype.ROCP2_PublisherList 
		WHERE ClubID IS NOT NULL
		) ---12 Quidco, 143 Easyfundraising, 144 Karrot, 145 NextJump -- SMS!  
		and p.AdditionDate <= (select fEndDate from #Dates0 )---(select dateadd(week,-12,fStartDate) from #Dates0) -- changing to fEndDate to match the dashboard
--	and r4g.CompositeID is NULL -- Excluding R4G cardholders : JH EDIT V2  -- taken out
GROUP BY  c.name, clubID, f.ID, f.CompositeID, p.ID , r4g.CompositeID

-- Allowed for R4G to be included, and a flag to reclassify
--select top 100 * from #CustBase_Pub0

IF OBJECT_ID('tempdb..#CustBase_Pub') IS NOT NULL DROP TABLE #CustBase_Pub
select ClubID  --- Wonder if should lose this as join is misleading with no club ID
,case when R4G_Flag is not NULL then 'R4G' else ClubName end as Clubname
,ID
,CompositeID
,PanID
into #CustBase_Pub
from #CustBase_Pub0


CREATE CLUSTERED INDEX IND_ID on #CustBase_Pub (PanID) 
CREATE NONCLUSTERED INDEX IND_CID on #CustBase_Pub (CompositeID)
CREATE NONCLUSTERED INDEX IND_CLID on #CustBase_Pub (ClubID)
CREATE NONCLUSTERED INDEX IND_CLN on #CustBase_Pub (Clubname)

--select count(distinct CompositeID), count(distinct panid) ,Clubname, clubID  from #CustBase_Pub group by Clubname, clubID


/*************************************************
****Generating Live Retailer List by Publisher****
*************************************************/
----- First and Last Dates of Incentived transactions
-- taking incentivesed as the Mids are being managed BUT DOES HAVE THE ISSUE OF HAVING EXISTING UPLIFT IN IT! 
--- INCLUDES UPLIFT
DECLARE @tValue1 SMALLINT
set @tValue1 = (select tvalue from #Timepoint)*4   -- to get weeks
--print @tValue1

IF OBJECT_ID('tempdb..#dates_incentivised0') IS NOT NULL DROP TABLE #dates_incentivised0
SELECT	CAST(MIN(TransactionDate) as date) as FirstTrandate,
	CAST(MAX(TransactionDate) as date) as LastTrandate,
	c.Name as ClubName,
--	clubID as ClubID,  : JH EDIT V2
	part.Name as PartnerName,
	part.ID as PartnerID
INTO #Dates_Incentivised0 -- JH EDIT V2
FROM SLC_Report.dbo.Fan f with (nolock)   -- link to my customer base table!
INNER JOIN  SLC_Report.dbo.PAN AS P with (nolock)
	ON F.CompositeID = P.CompositeID
INNER JOIN  SLC_Report.dbo.Club c  with (nolock)
	ON c.ID = f.clubid
inner join  SLC_Report.dbo.Match m  with (nolock)
	on P.ID = m.PanID
INNER JOIN  SLC_Report.dbo.RetailOutlet ro with (nolock)
	ON m.RetailOutletID = ro.ID
INNER JOIN  SLC_Report.dbo.Partner part  with (nolock)
	ON ro.PartnerID = part.ID
WHERE	f.clubID in 
		(
		SELECT	DISTINCT
			ClubID 
		FROM Prototype.ROCP2_PublisherList 
		WHERE ClubID IS NOT NULL
		) ---12 Quidco, 143 Easyfundraising, 144 Karrot, 145 NextJump 
        AND m.Status IN (1)-- Valid transaction status
        AND m.RewardStatus IN (0,1) -- Valid transaction status
        --AND m.TransactionDate (select fEndDate from #Dates0)
GROUP BY c.name,  part.Name, part.ID --,clubID
HAVING	CAST(MIN(TransactionDate) AS DATE) <= (SELECT DATEADD(WEEK,-@tValue1,fStartDate) from #Dates0) 
	AND CAST(MAX(TransactionDate) as date) >= (select fEndDate from #Dates0)  -- this is quite strict as limits to time elapse after month build 
ORDER BY clubname, part.Name, part.ID

---- R4G is currently in the Quidco umbrella 
-- This means I need to mirror data for the Quidco club for the R4G group
--select * from #dates_incentivised0




IF OBJECT_ID('tempdb..#dates_incentivised') IS NOT NULL DROP TABLE #dates_incentivised
select *
into #dates_incentivised
from (
select *
from #dates_incentivised0
union all
select FirstTrandate
,LastTrandate
,'R4G' as ClubName
,PartnerName
,PartnerID
from #dates_incentivised0
where clubname in ('Quidco')  ) a


IF OBJECT_ID('prototype.ROCP2_NFiPubdates') IS NOT NULL DROP TABLE prototype.ROCP2_NFiPubdates
select * 
into prototype.ROCP2_NFiPubdates
from #dates_incentivised

--------------------------------------------------------------------------
------ Generate Retailer list tables to use Like for like with RBS base
--------------------------------------------------------------------------
--- Originally I linked this to incentived in the forecase period but think that this is a double selection

IF OBJECT_ID('tempdb..#RetailerBuildList') IS NOT NULL DROP TABLE #RetailerBuildList
select b.ClubName,  b.Partnername, b.PartnerID --b.clubID
,row_number() over (order by clubname) as RowNo   --- used in the loop code for NFI
,dense_rank() over (order by clubname)  as PublisherNo
into #RetailerBuildList
from #Dates_Incentivised b
where PartnerID not in (4523,4450,4266) -- Exlcuding O2 and Caffe Nero (e) and Vodaphone
--and PartnerID in (4319) -- ONly doing cafe nero for test
group by  b.clubname, b.Partnername, b.partnerID -- b.clubID,
order by clubname, partnername

--select * from #RetailerBuildList

--select top 10 * from SLC_Report.dbo.Fan where ID
--select top 10 CompositeID  from SLC_Report.dbo.PAN
--select  * from SLC_Report.dbo.Club



--------------------------------------------------------------------------
------ RBS base data pull
--------------------------------------------------------------------------



---- Think I can clean out this step
IF OBJECT_ID('tempdb..#RBSBASE') IS NOT NULL DROP TABLE #RBSBASE
select a.*
into #RBSBASE
from Prototype.ROCP2_SegFore_FixedBase a  -- fixed base


CREATE INDEX IND_Cins on #RBSBASE(CINID);

----  The main code  (campaign heatmap) set index to 100 for all those unknown
----  In main code (campaign heatmap) I think missing is just set to 0 (so excluded).  

-------------------------------


------------------------------------------------------------------------------
-- All segments list table : Did we say 5!  Did Tom want to lose Winback prime?
---- Note that newly activated is not included here.  volumes dependent on pub activations
-- Recode to perm scheme table
if object_id('tempdb..#SegmentList') is not null drop table #SegmentList
create table #SegmentList (Segment varchar(25) null
							,rowno int null
							)

insert into #SegmentList
values ('Acquire',1)
,      ('Existing',2)
,      ('AllBase',3)                                            ---- Code this segment as think will use in the Welcome and can act as base point


--select * from #SegmentList


------------------------------------------------------------------------
---------- Creating Brand Loop code
------------------------------------------------------------------------


IF OBJECT_ID('tempdb..#PartnerBrand_Lookup') IS NOT NULL DROP TABLE #PartnerBrand_Lookup
select distinct  partnerID, brandid , partnerName
into #PartnerBrand_Lookup
from [Warehouse].[InsightArchive].[nFIpartnerdeals]  -- Lloyd's lookup table  THIS HAS DUPS
where brandname is not NULL

--select * from #PartnerBrand_Lookup order by brandid

--There are doubles on brand for example 
--4319	75	Caffe Nero
--4523	75	Caffe Nero (e)

---- For now I think this might need to be manually assessed
/*
select * 
from #PartnerBrand_Lookup
where brandid in (
select distinct brandid from #PartnerBrand_Lookup
group by brandid
having count(brandID)>1) 
*/
-- Get rid of Cafe Nero (e)



-- distinct list (as might be dups per publisher

IF OBJECT_ID('tempdb..#brand') IS NOT NULL DROP TABLE #brand
select distinct 
	  p.BrandID
	  ,row_number () over (order by p.brandid) as retailerno
into #brand
from #RetailerBuildList r
inner join #PartnerBrand_Lookup p on r.partnerID=p.partnerID    --- Speak to team data about why these are not here am I to join on Name!!!
where p.PartnerID not in (4523)
group by p.BrandID


--select * from #brand

----------------------------------------------------------------------------------------------
--------------  RBS : Loop code to get spenders results per brand
----------------------------------------------------------------------------------------------



if object_id('tempdb..#SegmentSummary0') is not null drop table #SegmentSummary0
create table #SegmentSummary0 (
                           Segment varchar(25) null
						   ,counts int NULL
						   ,avgw_sales money null
						   ,avgw_spder real null 
						   )


if object_id('tempdb..#AlloutputsRBS') is not null drop table #AlloutputsRBS
create table #AlloutputsRBS (
                            BrandID int null
				        --     ,BrandName varchar(50) NULL
                            ,Segment varchar(25) null
							,counts int NULL
							,avgw_sales money null
							,avgw_spder real null					
							 )
							



DECLARE @BrandID int, @rowno int
set @rowno = 1

WHILE @rowno <=(select max(retailerno) from #brand)       ---Limit to just 7 for trial

BEGIN
set @BrandID = (select brandid from #brand where retailerno=@rowno)
--print @rowno
--print @BrandID

IF OBJECT_ID('tempdb..#ccids') IS NOT NULL DROP TABLE #ccids
select  distinct ConsumerCombinationID
       ,cc.BrandID
into #ccids 
from Warehouse.Relational.ConsumerCombination cc with(nolock)
where cc.BrandID=@BrandID
and IsUKSpend = 1

CREATE CLUSTERED INDEX IND_CC on #CCIDs(ConsumerCombinationID)
CREATE NONCLUSTERED INDEX IND_BD on #CCIDs(BrandID)
-- select * from #OutputSummary


---- Approach is now to take the latest full month


------------------------------------------------------------
---------- Build Natural Counts data
-- Forecast data is the latest 4 weeks (of a full month)
------------------------------------------------------------
declare @buildend date, @timebuild date ,@tvalue int, @lapser date, @LasperL int
set @tvalue = (select tvalue from #Timepoint) --- starting at point.  The hard code lapsers values here will hit at months when lapsers should first appear. 
-- Note that the structure is set up so that having a brand centric timepoint value is possible.  however at this stage I don't have time to refine this for a flexiable lasper time etc..

---WHILE @tvalue <=   --- once retail length is full then loop ends.  will mean not limit to top end... Need to make sure Acquire materation is reached. 

set @buildend = (select dateadd(day,-1,fStartDate) from #Dates0)
set @timebuild = dateadd(month,-@tvalue,@buildend)

---------- Extracting the date base date frame
IF OBJECT_ID('tempdb..#SpendHistory_t1') IS NOT NULL DROP TABLE #SpendHistory_t1
(select ct.CINID
      ,BrandID
  ,1 as spender
into #SpendHistory_t1
from #ccids b 
INNER JOIN Warehouse.Relational.ConsumerTransaction ct with(nolock)
	ON b.ConsumerCombinationID=ct.ConsumerCombinationID
INNER JOIN #RBSBASE c with(nolock)
	ON c.cinid=ct.cinid
where	TranDate between @timebuild and @buildend --- CHANGE THIS AND BUILD TO RETAILER MAX
	AND ISRefund = 0 --- exclude refunds
	and b.brandID =@BrandID 
	AND IsOnline = 0
group by ct.cinid, BrandID
)

CREATE CLUSTERED INDEX IND_CIN ON #SpendHistory_t1 (CINID)
CREATE NONCLUSTERED INDEX IDX_BID ON #SpendHistory_t1 (BrandID)



/*******************************
*****Getting forecast spend*****
*******************************/
DECLARE @fStartDate DATE,
	@fEndDate DATE

SET @fStartDate = (select fStartDate from #Dates0)
SET @fEndDate = (select fEndDate from #Dates0)


IF OBJECT_ID('tempdb..#ForecastSpend') IS NOT NULL DROP TABLE #ForecastSpend
SELECT	ct.CINID,
	TranDate,
	SUM(Amount) as FSales
INTO #ForecastSpend
FROM #ccids b 
INNER JOIN Warehouse.Relational.ConsumerTransaction ct with (nolock)
	on b.ConsumerCombinationID = ct.ConsumerCombinationID
INNER JOIN #RBSBASE c
	on c.cinid=ct.cinid
WHERE	TranDate BETWEEN @fStartDate AND @fEndDate
	AND b.brandID = @BrandID -- building with single brand  
	AND ISRefund = 0 --- exclude refunds
GROUP BY ct.CINID, TranDate

CREATE CLUSTERED INDEX IND_CIN ON #ForecastSpend (CINID)
CREATE NONCLUSTERED INDEX IDX_TD ON #ForecastSpend (TranDate)


IF OBJECT_ID ('tempdb..#ForecastSpend2') IS NOT NULL DROP TABLE #ForecastSpend2
SELECT	t.*,
	w.Weekno
INTO #ForecastSpend2
FROM #ForecastSpend t 
CROSS JOIN #WeekBuild w
WHERE t.trandate BETWEEN w.StartDate AND w.EndDate


/***********************************************************************
Building the customer universe -- reduce down as don't need all of this
***********************************************************************/
IF OBJECT_ID ('tempdb..#Universe1') IS NOT NULL DROP TABLE #Universe1
SELECT	a.*,
	CASE WHEN Segment = 'Acquire' THEN 1 ELSE 0 END AS Acquire,
	CASE WHEN Segment = 'Existing' THEN 1 ELSE 0 END AS Existing,
	1 as AllBase
INTO #Universe1
FROM	(
	SELECT	b.CINID,
		CASE WHEN s.Spender = 1 THEN 'Existing' ELSE 'Acquire' END as Segment
	FROM #RBSBASE b
	LEFT JOIN #SpendHistory_t1 s
		ON b.CINID = s.CINID
	) a

/***************************************
********Summarise to get counts*********
***************************************/
DECLARE	@seq TINYINT,
	@SQL VARCHAR(8000),
	@varname VARCHAR(50)
SET @seq = 1
WHILE @seq IS NOT NULL
BEGIN

	SELECT @varname = Segment FROM #SegmentList WHERE rowno = @seq
--	set @base = cast((select count(distinct cinid) from #universe1 ) as real)
	DECLARE @noweeks REAL
	set @noweeks = (SELECT MAX(weekno) FROM #WeekBuild)
	SET @SQL = '

select 
''' +@varname+ ''' as customertype
,sum(sales) / '+cast(@noweeks as varchar)+' as avgw_Sales
,sum(spender)/ '+cast(@noweeks as varchar)+' as avgw_spder
into #forecastout
from (
select weekno
,sum(t.Fsales) as sales
,count(distinct t.cinid) as spender

from #universe1 b
inner join #ForecastSpend2 t on b.cinid=t.CINID
where '+@varname+'=1    
group by weekno ) a

select 
'''+@varname+''' as Customertype
,count(distinct cinid) as cardholders
into #countsout
from #universe1
where '+@varname+'=1    

--- Joining the table to get outputs
select c.*
,f.avgw_Sales
,f.avgw_spder

into #outall
from #countsout c
left join #forecastout f on c.Customertype=f.Customertype

insert into #segmentsummary0
select * from #outall'

EXEC(@sql)
	SELECT @seq = MIN(rowno) FROM #SegmentList WHERE rowno >@seq

END

--- Add into a perm table
declare @base int
set @base = (select count(distinct CINID) from #RBSBASE)

--declare @brandname varchar(50)
--set @brandname = (select min(Brandname) from #PartnerBrand_Lookup where brandid=@BrandID)


--select top 10 * from #SegmentSummary

INSERT INTO #AlloutputsRBS
SELECT	@BrandID
	--,@brandname 
	,Segment
	--,@tvalue
	,Counts
	,Avgw_sales
	,Avgw_spder
FROM #segmentsummary0

truncate table #segmentsummary0


set @rowno = @rowno +1
END  

CREATE CLUSTERED INDEX IDX_BID ON #AlloutputsRBS (BrandID)

--select top 100 * from #AlloutputsRBS
--select * from Staging.ROCP2_SegFore_RBSSeg_NatralSales where brandID=75
/**********************************************************************************/
/*  Run and repeat process for nFI
***********************************************************************************/
if object_id('tempdb..#segmentsummary0p') is not null drop table #segmentsummary0p
create table #segmentsummary0p
	(
	Segment varchar(25) null,
	counts int NULL,
	avgw_sales money null,
	avgw_spder real null 
	)
							


if object_id ('tempdb..#AlloutputsPub') is not null drop table #AlloutputsPub
create table #AlloutputsPub
	(
--	ClubID int NULL
	Clubname varchar(50) NULL
	,Partnerid int null
	,PartnerName varchar(50) NULL
	,Cardholders int null
	,Segment varchar(25) null
	,counts int NULL
	,avgw_sales money null
	,avgw_spder real null					
	)
							

---select count(distinct ID), count(distinct CompositeID), club from #CustBase_Pub group by club

DECLARE @rownop int
set @rownop = 1

WHILE @rownop <=(select max(rowno) from #RetailerBuildList)       ---Limit to just 7 for trial

BEGIN
--print @rownop


declare @tvaluenFi1 int
set @tvaluenFi1 = (select tvalue from #Timepoint) * 4   -- to get weeks
--print @tvaluenFi1

--#CustBase_Pub
----- No longer only incentived but 
IF OBJECT_ID('tempdb..#Spendhist_Pub') IS NOT NULL DROP TABLE #Spendhist_Pub
SELECT	b.clubname as Club,
--	clubID as ClubID,  -- JH EDT v2
	part.Name as PartnerName,
	part.ID as PartnerID,
	b.ID as ID,
	1 as Spender
INTO #Spendhist_Pub
FROM #CustBase_Pub b 
INNER JOIN SLC_Report.dbo.Match m
	on b.PANID = m.PanID
INNER JOIN SLC_Report.dbo.RetailOutlet ro
	ON m.RetailOutletID = ro.ID
INNER JOIN SLC_Report.dbo.Partner part
	ON ro.PartnerID = part.ID
--INNER JOIN  SLC_Report.dbo.Trans t ON b.ID = t.FanID
--INNER JOIN  SLC_Report.dbo.TransactionType tt ON tt.ID = t.TypeID
WHERE   b.Clubname in (select Clubname from #RetailerBuildList where rowno=@rownop)  ---- (12,143,144,145) ---12 Quidco, 143 Easyfundraising, 144 Karrot, 145 NextJump -- SMS! JH Edit V2
        AND m.Status IN (1)-- Valid transaction status  (Incentivised)
        AND m.RewardStatus IN (0,1) -- Valid transaction status (Incentivised)
        AND m.TransactionDate BETWEEN (select dateadd(week,-@tvaluenFi1,fStartDate) from #Dates0) and (select dateadd(day,-1,fStartDate) from #Dates0)  -- CHANGE THIS
	AND part.ID in (select partnerID from #RetailerBuildList where rowno=@rownop)
GROUP BY  b.clubname,part.Name,part.ID,b.ID 
--END

--- Changing pub base changed the figures slightly as registration. Double check and QA
--select top 100 * from #CustBase_Pub
/******************************************
**********Getting forecast spend***********
******************************************/
IF OBJECT_ID('tempdb..#ForecastSpendPub') IS NOT NULL DROP TABLE #ForecastSpendPub
SELECT	b.ID as ID
	,CAST(TransactionDate as date) as TranDate
	,SUM(amount) as FSales
INTO #ForecastSpendPub
FROM #CustBase_Pub b 
INNER JOIN SLC_Report.dbo.Match m
	ON b.PanID = m.PanID
INNER JOIN SLC_Report.dbo.RetailOutlet ro
	ON m.RetailOutletID = ro.ID
INNER JOIN SLC_Report.dbo.Partner part
	ON ro.PartnerID = part.ID
	AND AMount > 0
WHERE   b.Clubname IN
		(
		SELECT ClubName
		FROM #RetailerBuildList
		WHERE RowNo = @RowNop
		)
        AND m.Status IN (1)-- Valid Transaction Status
        AND m.RewardStatus IN (0,1) -- Valid Transaction Status
        AND m.TransactionDate BETWEEN @fStartDate and @fEndDate
	AND part.ID in (select PartnerID from #RetailerBuildList where rowno=@rownop)
GROUP BY  b.ID , CAST(TransactionDate AS DATE)


--select top 100 * from #ForecastSpendPub


IF OBJECT_ID('tempdb..#ForecastSpendPub2') IS NOT NULL DROP TABLE #ForecastSpendPub2
SELECT	t.*,
	w.Weekno
INTO #ForecastSpendPub2
FROM #ForecastSpendPub t 
CROSS JOIN #WeekBuild w
WHERE t.trandate BETWEEN w.StartDate AND w.EndDate


/***********************************************************************
Building the customer universe -- reduce down as don't need all of this
***********************************************************************/
IF OBJECT_ID('tempdb..#CustPub_UniqueID') IS NOT NULL DROP TABLE #CustPub_UniqueID
select ID, Clubname
into #CustPub_UniqueID
from #CustBase_Pub
where clubname in (select distinct Clubname from #RetailerBuildList where rowno=@rownop)
group by ID, Clubname

IF OBJECT_ID('tempdb..#universe1Pub') IS NOT NULL DROP TABLE #universe1Pub
select a.*
,case when Segment = 'Acquire' then 1 else 0 end as Acquire
,case when Segment = 'Existing' then 1 else 0 end as Existing
,1 as AllBase
into #universe1Pub
from (
select b.ID
,case when s.spender=1 then 'Existing' else 'Acquire' end as Segment
from #CustPub_UniqueID b
left join #spendhist_Pub s on b.ID=s.ID
) a

--select * from #SegmentList
------------------------------------------
----   Summarise to get counts
-------------------------------------------

DECLARE @seqp tinyint, @SQLp varchar(8000), @varnamep varchar(50)
set @seqp = 1
WHILE @seqp IS NOT NULL
BEGIN


	SELECT @varnamep = Segment FROM #SegmentList WHERE rowno = @seqp

	declare @noweeksp real
    set @noweeksp = (select max(weekno) from #WeekBuild)
	SET @SQLp = '

select 
''' +@varnamep+ ''' as customertype
,sum(sales) / '+cast(@noweeksp as varchar)+' as avgw_Sales
,sum(spender)/ '+cast(@noweeksp as varchar)+' as avgw_spder
into #forecastoutp
from (
select weekno
,sum(t.Fsales) as sales
,count(distinct t.id) as spender
from #universe1Pub b
inner join #ForecastSpendPub2 t on b.Id=t.ID
where '+@varnamep+'=1    
group by weekno ) a

select 
'''+@varnamep+''' as Customertype
,count(distinct id) as cardholders
into #countsoutp
from #universe1Pub
where '+@varnamep+'=1    

--- Joining the table to get outputs
select c.*
,f.avgw_Sales
,f.avgw_spder
into #outallp
from #countsoutp c
left join #forecastoutp f on c.Customertype=f.Customertype

insert into #segmentsummary0p
select * from #outallp'

exec(@sqlp)
	SELECT @seqp = MIN(rowno) FROM #SegmentList WHERE rowno >@seqp

END



declare @PartnerID int ,  @basep int --@clubID int
set @PartnerID = (select distinct partnerID from #RetailerBuildList where rowno=@rownop)
--set @clubID = (select distinct clubID from #RetailerBuildList where rowno=@rownop)
declare @PartnerName varchar(50) , @clubname varchar(50)
set @PartnerName = (select distinct PartnerName from #RetailerBuildList where rowno=@rownop)
set @clubname = (select distinct clubname from #RetailerBuildList where rowno=@rownop)
set @basep = (select count(distinct id) from #CustPub_UniqueID) 



--select top 10 * from #segmentsummary0p

insert into #AlloutputsPub
select @Clubname 
,@Partnerid
,@PartnerName as partnername
,@basep
,segment

--,@tvalue
,counts
,avgw_sales
,avgw_spder
from #segmentsummary0p

truncate table #segmentsummary0p

set @rownop = @rownop +1
END  

--select top 100 * from #AlloutputsRBS
--select * from Staging.ROCP2_SegFore_RBSSeg_NatralSales where brandID=75


--select * from #AlloutputsPub
--select * from #AlloutputsRBS where brandid = 75


------------------------------------------------------------------------------------------
------  Joining table together to build scaling factors

--select top 100 * from #PartnerBrand_Lookup

--- Add into a perm table
declare @base2 int 
set @base2  = (select count(distinct cinid) from #RBSBase) 

IF OBJECT_ID('Prototype.ROCP2_PubScaling_CoreData') IS NOT NULL DROP TABLE Prototype.ROCP2_PubScaling_CoreData
select	pub.*,
	p.BrandID,
	--,p.brandname,
	-- RR, SPS and %Base,
	case when pub.avgw_spder>0 then pub.avgw_spder / cast (pub.counts as real) else NULL end as RR,
	case when pub.counts>0 then pub.counts / cast (pub.Cardholders as real) else NULL end as Segment_Percent,
	@base2 as Base_Cardholder,
	r.avgw_sales as BASE_avgw_sales,
	r.avgw_spder as BASE_avgw_spder,
	r.counts as BASE_Counts,
	case when r.avgw_spder>0 then r.avgw_spder / cast (r.counts as real) else NULL end as BASE_RR,
	case when r.counts>0 then r.counts / cast (@base2 as real) else NULL end as BASE_Percent,
	case when (r.avgw_spder>=5 OR pub.avgw_spder>=5) then 0 else 1 end as LowFlag
into Prototype.ROCP2_PubScaling_CoreData
from #AlloutputsPub pub
INNER JOIN #PartnerBrand_Lookup p
	ON pub.partnerID=p.partnerID
INNER JOIN #AlloutputsRBS r
	ON r.brandID = p.brandid
	AND r.segment=pub.Segment

--select top 100 * from Prototype.ROCP2_PubScaling_CoreData
--select top 100 * from #AlloutputsPub
--- Get a generic scaling factor (use only brands with 25 spenders in all base)

IF OBJECT_ID('tempdb..#ToUseSclaing') IS NOT NULL DROP TABLE #ToUseSclaing
select partnerID, ClubName
into #ToUseSclaing
from Prototype.ROCP2_PubScaling_CoreData
group by  partnerID, ClubName 
having sum(LowFlag) =0



------  Excluding any brand / Club combination where the scaling RR factors would be based on low observations



IF OBJECT_ID('Prototype.ROCP2_PubScaling_BrandPubLevel') IS NOT NULL DROP TABLE Prototype.ROCP2_PubScaling_BrandPubLevel
select	--s.ClubID
	s.ClubName
	,s.PartnerID
	,s.PartnerName
	,s.BrandID
	--,s.BrandName
	,s.Segment as SegmentAgg
	,s.RR
	,s.BASE_RR
	,s.RR / s.BASE_RR as ScalingRR
	,Segment_Percent
	,BASE_Percent
into Prototype.ROCP2_PubScaling_BrandPubLevel
from Prototype.ROCP2_PubScaling_CoreData s
inner join #ToUseSclaing u
	on s.partnerID=u.partnerID
	and s.ClubName=u.ClubName


--select * from #ScalingSummary

IF OBJECT_ID('Prototype.ROCP2_PubScaling_GenericPub') IS NOT NULL DROP TABLE Prototype.ROCP2_PubScaling_GenericPub
select	--ClubID,
	ClubName,
	SegmentAgg,
	avg(ScalingRR) as ScalingRR
into Prototype.ROCP2_PubScaling_GenericPub
from Prototype.ROCP2_PubScaling_BrandPubLevel
group by  Clubname , SegmentAgg 


--select top 100 * from Prototype.ROCP2_PubScaling_GenericPub

END

--select * from Prototype.ROCP2_PubScaling_BrandPubLevel

--select * from Prototype.ROCP2_PubScaling_CoreData