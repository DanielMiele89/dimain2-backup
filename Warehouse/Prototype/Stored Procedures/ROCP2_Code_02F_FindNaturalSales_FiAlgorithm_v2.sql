
/***************************************************************************
Author:	Main Code written by Jenny Hurley - SP Created by Suraj Chahal
Date: 20-01-2016
Purpose: Building Natural Sales
***************************************************************************/
CREATE PROCEDURE [Prototype].[ROCP2_Code_02F_FindNaturalSales_FiAlgorithm_v2]  -- THIS SIMPLE FI ALGORITHM
	(
	@IndividualBrand BIT
	)
AS
BEGIN

--DECLARE	@IndividualBrand BIT
--SET @IndividualBrand = 1


IF OBJECT_ID ('tempdb..#WeekBuild') IS NOT NULL DROP TABLE #WeekBuild
SELECT	*,
	ROW_NUMBER() OVER (ORDER BY StartDate) as WeekNo
INTO #WeekBuild
FROM	(
	SELECT	WeekNum,
		MIN(StartDate) as StartDate,
		MAX(Enddate) as EndDate
	FROM Prototype.ROCP2_SegFore_Rundaylk 
	WHERE BuildWeek = 1
	GROUP BY WeekNum 
	) a


IF OBJECT_ID ('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
select	DATEADD(DAY,-1,MIN(Startdate)) as EndDate,   -- the segmentation enddate
	MIN(Startdate) as fStartDate,
	MAX(Enddate) as fEnddate
into #Dates
from #WeekBuild

--select * from #dates
--select * from #weekbuild


IF OBJECT_ID ('tempdb..#SegmentList') IS NOT NULL DROP TABLE #SegmentList
CREATE TABLE #SegmentList
	(
	Segment VARCHAR(25) NULL,
	RowNo SMALLINT NULL
	)

INSERT INTO #SegmentList
VALUES	('Acquire',1),
	('Winback',2),
	('WinbackPrime',3),
	('Retain',4),
	('Grow',5),
	('AllBase',6),
	('LowInterest',7),  --- Adding for FI pub were heatmaps can split the acquire
	('Homemover',8), 
	('Birthday',9), 
	('Welcome',10)

CREATE CLUSTERED INDEX IDX_Seg ON #SegmentList (Segment)
CREATE NONCLUSTERED INDEX IDX_RowNo ON #SegmentList (RowNo)


IF OBJECT_ID ('tempdb..#SegmentSummary0') IS NOT NULL DROP TABLE #SegmentSummary0
CREATE TABLE #SegmentSummary0
	(
        Segment VARCHAR(25) NULL,
	Counts INT NULL,
	Avgw_sales MONEY NULL,
	Avgw_spder FLOAT NULL,
	Avgw_Sales_InStore MONEY NULL,
    Avgw_spder_InStore REAL NULL
	)			
CREATE CLUSTERED INDEX IDX_Seg ON #SegmentSummary0 (Segment)


--IF OBJECT_ID ('Prototype.ROCP2_SegFore_Fi_NaturalSales') IS NOT NULL DROP TABLE Prototype.ROCP2_SegFore_Fi_NaturalSales
--CREATE TABLE Prototype.ROCP2_SegFore_Fi_NaturalSales
--	(
--        BrandID SMALLINT NULL,
--        Segment VARCHAR(25) NULL,
--        Timepoint SMALLINT NULL,
--	Counts INT NULL,
--	AVGw_Sales MONEY NULL,
--	AVGw_Spder REAL NULL,
--	AVGw_Sales_InStore MONEY NULL,
--        AVGw_Spder_InStore REAL NULL							
--	)

--CREATE CLUSTERED INDEX IDX_BrandID ON Prototype.ROCP2_SegFore_Fi_NaturalSales (BrandID)	
--CREATE NONCLUSTERED INDEX IDX_Seg ON Prototype.ROCP2_SegFore_Fi_NaturalSales (Segment)


------------  
IF OBJECT_ID('tempdb..#Activated_HM') IS NOT NULL DROP TABLE #Activated_HM
select a.*
,lk2.comboID as ComboID_2 -- Gender / Age group and Cameo grp
into #Activated_HM
from Prototype.ROCP2_RBS_MyRewardsBase a  --- Created in V2
left join InsightArchive.HM_Combo_SalesSTO_Tool lk2 on a.gender=lk2.gender and a.CAMEO_CODE_GRP=lk2.CAMEO_grp and a.Age_Group=lk2.Age_Group

CREATE INDEX IND_Cins on #Activated_HM(CINID);



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
DELETE FROM Prototype.ROCP2_SegFore_Fi_NaturalSales
WHERE BrandID IN (SELECT BrandID FROM #Brand)

END
ELSE
BEGIN

INSERT INTO #Brand
SELECT *
FROM warehouse.Prototype.ROCP2_Brandlist

TRUNCATE TABLE Prototype.ROCP2_SegFore_Fi_NaturalSales

END
/*****************************************************************/

CREATE NONCLUSTERED INDEX IDX_AcqL ON #Brand (AcquireL)
CREATE NONCLUSTERED INDEX IDX_LapL ON #Brand (LapserL)
CREATE NONCLUSTERED INDEX IDX_RowNo ON #Brand (RowNo)

--select * from #brand

/***************************************
****Find CCIDs for Assessment Brands****
***************************************/
DECLARE @BrandID SMALLINT,
	@RowNo SMALLINT

SET @RowNo = 1

WHILE @RowNo<= (SELECT MAX(RowNo) from #Brand)       

BEGIN

SET @BrandID = (SELECT BrandID FROM #Brand where rowno=@rowno)

IF OBJECT_ID ('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT  ConsumerCombinationID,
	cc.BrandID
INTO #CCIDs 
FROM Relational.ConsumerCombination cc (NOLOCK)
WHERE	cc.BrandID = @BrandID
	AND IsUKSpend = 1

CREATE CLUSTERED INDEX IND_CC on #CCIDs(ConsumerCombinationID)
CREATE NONCLUSTERED INDEX IDX_BID ON #CCIDs (BrandID)

-- select * from #brand

/********************************************************************************
Build Natural Counts data - Forecast data is the latest 4 weeks (of a full month)
********************************************************************************/
DECLARE	@BuildEnd DATE,
	@TimeBuild DATE,
	@TValue INT,
	@Lapser DATE,
	@LasperL INT

--SET @TValue = 1 --- starting at point.  The hard code lapsers values here will hit at months when lapsers should first appear. 
-- Note that the structure is SET up so that having a brand centric timepoint value is possible.  however at this stage I don't have time to refine this for a flexiable lasper time etc..

SET @TValue = (SELECT AcquireL FROM #brand WHERE BrandID = @BrandID)  -- once retail length is full then loop ends.  will mean not limit to top end... Need to make sure Acquire materation is reached. 

--BEGIN

SET @LasperL = (SELECT LapserL FROM #Brand where BrandID = @BrandID)
SET @BuildEnd = (SELECT EndDate FROM #Dates)

SET @TimeBuild = DATEADD(MONTH,-@TValue,@BuildEnd)
SET @Lapser = DATEADD(MONTH,-@LasperL,@BuildEnd)


---------- Extracting the date base date frame
IF OBJECT_ID('tempdb..#SpendHistory_t1') IS NOT NULL DROP TABLE #SpendHistory_t1
SELECT	ct.CINID,
	BrandID,
	c.MarketableByEmail, ---- LG add
	SUM(Amount) as Sales,
--	COUNT(1) as Trans,
	MAX(CASE
		WHEN TranDate BETWEEN @Lapser AND @BuildEnd THEN 1
		ELSE NULL
	END) as SpderLastx
--	DATEDIFF(DAY,MAX(tranDate),@BuildEnd) as DaysSince
   ,1 as SpderA
INTO #SpendHistory_t1
FROM Relational.ConsumerTransaction ct (NOLOCK) 
INNER JOIN #Activated_HM c (NOLOCK)  --- NEED THIS TO BE THE RBS BASE BUT JUST USE ACTIVATED_HM NOW
	ON c.CINID = ct.CINID
INNER JOIN #CCIDs cc
	ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE	TranDate BETWEEN @TimeBuild AND @BuildEnd --- CHANGE THIS AND BUILD TO RETAILER MAX
	AND isRefund = 0 --- exclude refunds
	AND cc.BrandID = @BrandID 
GROUP BY ct.CINID, BrandID, MarketableByEmail


--Spenders only NTile bands
IF OBJECT_ID ('tempdb..#Spder_Bands') IS NOT NULL DROP TABLE #Spder_Bands
SELECT	NTILE(3) OVER(ORDER BY Sales DESC) as SalesP3,
--	NTILE(3) OVER(ORDER BY Trans DESC) as FreqP3,
--	NTILE(3) OVER(ORDER BY Dayssince) as RecentP3,
	*
INTO #Spder_Bands
FROM #SpendHistory_t1
where SpderLastx is not NULL
and MarketableByEmail = 1 --- LG Add


---- Lapser cutpoints
IF OBJECT_ID ('tempdb..#Spder_BandsL') IS NOT NULL DROP TABLE #Spder_BandsL
SELECT	NTILE(3) OVER(ORDER BY Sales DESC) as SalesP3,
--	NTILE(3) OVER(ORDER BY Trans DESC) as FreqP3,
--	NTILE(3) OVER(ORDER BY Dayssince) as RecentP3,
	*
INTO #Spder_BandsL
FROM #spendHistory_t1
WHERE SpderLastx is NULL
and  MarketableByEmail = 1 --- LG Add


IF OBJECT_ID ('tempdb..#CUTOFFS') IS NOT NULL DROP TABLE #CUTOFFS
SELECT	MIN(CASE WHEN SalesP3 = 1 THEN Sales ELSE NULL END) as TopSalesCut
--	AVG(Trans) as ATF
INTO #CUTOFFS
FROM #Spder_Bands
--


-- When no lapsers this is null so need to make sure it will still work in the process
IF OBJECT_ID ('tempdb..#CUTOFFSL') IS NOT NULL DROP TABLE #CUTOFFSL
SELECT	MIN(CASE WHEN SalesP3 = 1 THEN Sales ELSE NULL END) as TopSalesCut
--	AVG(Trans) as ATF
INTO #CUTOFFSL
FROM #Spder_BandsL
--

/**********************************
******Getting Forecast Spend*******
**********************************/
DECLARE	@fStartDate DATE,
	@fEndDate DATE

SET @fStartDate = (SELECT fStartDate FROM #dates)
SET @fEndDate = (select fEndDate from #dates)

IF OBJECT_ID('tempdb..#ForecastSpend') IS NOT NULL DROP TABLE #ForecastSpend
SELECT	ct.CINID,
	TranDate,
	SUM(Amount) as Fsales,
	SUM(CASE WHEN isOnline = 0 THEN Amount ELSE NULL END) as Fsales_InStore
INTO #ForecastSpend
FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
INNER JOIN #Activated_HM c
	on c.cinid = ct.cinid
INNER JOIN #CCIDs cc
	on cc.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE	TranDate BETWEEN @fStartDate AND @fEndDate
	AND cc.BrandID =@BrandID -- building with single brand  
	AND isRefund = 0 --- exclude refunds
GROUP BY ct.CINID, TranDate


IF OBJECT_ID('tempdb..#ForecastSpend2') IS NOT NULL DROP TABLE #ForecastSpend2
SELECT	t.*,
	w.Weekno
INTO #ForecastSpend2
FROM #ForecastSpend t 
CROSS JOIN #WeekBuild w
WHERE t.TranDate BETWEEN w.StartDate AND w.EndDate


/**********************************************************************
Building the customer universe - Reduce down as don't need all of this
**********************************************************************/
/*
Acquire	1
AllBase	6
Grow	5
Retain	4
Winback	2
WinbackPrime	3
*/

-----  Need to do here in process as linked to @brandid

IF OBJECT_ID('tempdb..#Activated_HM2') IS NOT NULL DROP TABLE #Activated_HM2
select b.*
,hm.Index_RR
,lk.UnknownGroup
,case when lk.UnknownGroup = 1 then 100 else Index_RR end as Response_Index
into #Activated_HM2
from #Activated_HM b
left join Warehouse.InsightArchive.SalesSTO_HeatmapBrandCombo_Index hm on b.ComboID_2=hm.ComboID_2 and hm.brandid=@brandid
left join Warehouse.InsightArchive.HM_Combo_SalesSTO_Tool lk on lk.comboID=hm.ComboID_2

/****************************************************************************************************/
/**  Coding the Triggers                                                                        *****/
/****************************************************************************************************/


--select * from #weekbuild
/***********************************************************************/
-- HOMEMOVERS 
/**************************/
-- Classified as homemovers 28 days before.
-- No lag build into here although could not see any in campiagn planning... might need to consider a build.. but assuming that selections will not be 
-- to the lastest date but to the latest populated date. 
Declare @TriggerStart28 date, @TriggerEnd date
Set @TriggerEnd = (dateadd(day,-1,(select min(startdate) from #WeekBuild))) -- ADD in some lag!
set @TriggerStart28 = (dateadd(day,-28,@TriggerEnd)) 


IF OBJECT_ID ('tempdb..#Homemovers_4wks') IS NOT NULL DROP TABLE #Homemovers_4wks

SELECT DISTINCT 
a.CINID
INTO #Homemovers_4wks
FROM Relational.Homemover_Details h
inner join #Activated_HM a on h.FanID=a.FanID  --- FROM THE SAMPLE BASE.  % FROM SAMPLE
where h.loaddate between @TriggerStart28 and @TriggerEnd

/***********************************************************************/
-- New Joiners
-- Joined in the last 28 days
-- But again not sure about whether to build in lag....
/**************************/
IF OBJECT_ID ('tempdb..#NewJoiners_4wks') IS NOT NULL DROP TABLE #NewJoiners_4wks

SELECT DISTINCT 
b.CINID
--,a.ActivationStart
--,a.ActivationEnd
INTO #NewJoiners_4wks
From #Activated_HM b 
inner join MI.CustomerActivationPeriod a on b.fanid=a.fanid  -- Think there is a better activated data tables
where a.Activationstart  between @TriggerStart28 and @TriggerEnd

/***********************************************************************/
-- Birthday
-- Doing as Birthday in the next 28 days -- technically there is seasonality.. I am not coding here
-- The counts could be correct to be evened out... or weighted for seasonality 
-- doubt volumes are big enough to look into this now
/**************************/

IF OBJECT_ID ('tempdb..#Birthday_dayMonth') IS NOT NULL DROP TABLE #Birthday_dayMonth
select datefromparts(2016,month(min(startdate)),Day(min(startdate))) as Start1
 ,datefromparts(2016,month(max(enddate)),Day(max(enddate))) as End1
 into #Birthday_dayMonth
from #WeekBuild

IF OBJECT_ID ('tempdb..#Birthday_next28') IS NOT NULL DROP TABLE #Birthday_next28

select distinct cinid
into #Birthday_next28
from (
SELECT b.FanID
,b.CINID
,DOB
,datefromparts(2016,month(DOB),Day(DOB)) as DOBjoin  -- Setting to Dummy Year
From #Activated_HM b 
inner join relational.customer a on b.fanid=a.fanid  -- Think there is a better activated data tables
) a
where a.DOBjoin between (select Start1 from #Birthday_dayMonth) and (select End1 from #Birthday_dayMonth)

---select top 100 * from #Birthday_next28


---------------------------------------------
---Code for New Cut Off for Acquisition------
---------------------------------------------

--Select * from #Activated_HM2 --- 1m base
--select * from #Brand --- cut offs for brand


IF OBJECT_ID ('tempdb..#AllAcq_HeatMap') IS NOT NULL 
														DROP TABLE #AllAcq_HeatMap
Select a.*,
		0 as Prime,
		1 as Segment
Into #AllAcq_HeatMap
from #Activated_HM2 as a
Left Outer join #SpendHistory_t1 as s
	on	a.CINID = s.CINID
Where	s.CINID is null
		and a.MarketableByEmail = 1


--------------------------------------------------------------------------------------
----------------------------------Find score split point------------------------------
--------------------------------------------------------------------------------------
Declare @Acquiresplitpoint int
		,@Index_RR_Score real
		,@AcquirePct int
		
		 
set @AcquirePct = (select Acquire_Pct from #Brand)

Set @Acquiresplitpoint = (	Select (Count(*)/100)*@AcquirePct 
							from #AllAcq_HeatMap where MarketableByEmail = 1)

Set @Index_RR_Score = 
		(	Select Min(Index_RR) From 
			(
				Select Top (@Acquiresplitpoint) Index_RR
				From #AllAcq_HeatMap
				where MarketableByEmail = 1
				Order by Index_RR Desc
			) as a
		)

--select	@AcquirePct
--select	@Acquiresplitpoint
--select	@Index_RR_Score


IF OBJECT_ID ('tempdb..#AllAcq_HeatMap_Prime') IS NOT NULL 
														DROP TABLE #AllAcq_HeatMap_Prime
select *
into	#AllAcq_HeatMap_Prime
from	#AllAcq_HeatMap
Where	MarketableByEmail =1 and
		Index_RR >= @Index_RR_Score



IF OBJECT_ID ('tempdb..#Universe1') IS NOT NULL DROP TABLE #Universe1
SELECT	a.*,
	CASE WHEN Segment = 'Acquire' THEN 1 ELSE 0 END as Acquire,
	CASE WHEN Segment = 'WinbackPrime' THEN 1 ELSE 0 END as WinbackPrime,
	CASE WHEN Segment = 'Winback' THEN 1 ELSE 0 END as Winback,
	CASE WHEN Segment = 'Retain' THEN 1 ELSE 0 END as Retain,
	CASE WHEN Segment = 'Grow' THEN 1 ELSE 0 END as Grow,
    CASE WHEN Segment = 'LowInterest' then 1 else 0 end as LowInterest,

	1 as AllBase

INTO #Universe1
FROM	(
	SELECT	b.CINID
		--CASE 
		--	WHEN s.Sales IS NULL THEN 'Acquire'
		--	WHEN s.SpderLastx IS NULL AND s.trans IS NOT NULL AND (Sales >= COALESCE(cl.Topsalescut,0) OR Trans >= COALESCE(cl.ATF,0)*3) THEN 'WinbackPrime'
		--	WHEN s.SpderLastx IS NULL AND s.trans IS NOT NULL THEN 'Winback'
		--	WHEN s.trans IS NOT NULL AND (s.sales>=c.Topsalescut OR Trans>=c.ATF*3) THEN 'Retain'
		--	WHEN s.trans IS NOT NULL THEN 'Grow'
		--	ELSE 'ERROR'
		--END as Segment_Ag1
     ,case when s.SpderA is NULL and ap.CINID is not null and b.marketablebyemail=1 then 'Acquire' 
           when s.SpderA is NULL OR b.marketablebyemail=0  then 'LowInterest'  -- Need to expliciting CODE the NON-Marketable: SB is taking them out to start with and then doing cuts
		                                                                    -- might be better but don't have time to recode.  Not urgent
		   
           when s.SpderLastx is NULL and s.SpderA=1 and sales>=coalesce(cl.Topsalescut,0)and b.marketablebyemail=1 then 'WinbackPrime'
		   when s.SpderLastx is NULL and s.SpderA=1 and b.marketablebyemail=1 then 'Winback'
		   when  s.SpderLastx is not null   and (s.sales>=coalesce(c.Topsalescut,0)) and b.marketablebyemail=1 then 'Retain'
           when s.SpderLastx is not null and b.marketablebyemail=1  then 'Grow'
		   else 'Error' end as Segment
    ,case when home.cinid is NULL then 0 else 1 end as Homemover
	,case when birth.cinid is NULL then 0 else 1 end as Birthday
	,case when NJ.cinid is NULL then 0 else 1 end as Welcome  -- Now I am adding New Joiners... should probably take both the %base and metrics from segments excluding but don't have time to code/execute this into full

	FROM #Activated_HM2 b
	LEFT JOIN #SpendHistory_t1 s
		ON b.CINID = s.CINID
	LEFT JOIN #Homemovers_4wks home on home.CINID=b.CINID
	LEFT JOIN #Birthday_next28 Birth on Birth.CINID=b.CINID
	LEFT JOIN #NewJoiners_4wks NJ on NJ.CINID=b.CINID
	LEFT JOIN #AllAcq_HeatMap_Prime AP on AP.CINID = b.CINID
	CROSS JOIN #CutOffs c 
	CROSS JOIN #CutOffsl cl
	)a


--select segment,count(1) from #Universe1 group by segment

/********************************
*****Summarise to get counts*****
********************************/
DECLARE @seq TINYINT,
	@SQL VARCHAR(8000),
	@VarName VARCHAR(50)
SET @seq = 1
WHILE @seq IS NOT NULL
BEGIN
	SELECT @VarName = Segment FROM #SegmentList WHERE RowNo = @seq

	DECLARE @NoWeeks real
	SET @NoWeeks = (select max(WeekNo) from #WeekBuild)
	SET @SQL = '

SELECT	''' +@VarName+ ''' as CustomerType,
	SUM(Sales) / '+cast(@noweeks as varchar)+' as AVGw_Sales,
	SUM(Spender)/ '+cast(@noweeks as varchar)+' as AVGw_spder,
	SUM(Sales_Instore) / '+cast(@noweeks as varchar)+' as AVGw_Sales_InStore,
	SUM(Spender_Instore)/ '+cast(@noweeks as varchar)+' as AVGw_spder_InStore
INTO #ForecastOut
FROM	(
	SELECT	WeekNo,
		SUM(t.Fsales) as sales,
		COUNT(distinct t.cinid) as spender,
		SUM(t.Fsales_InStore) as sales_Instore,
		COUNT(DISTINCT case when Fsales_InStore>0 then t.cinid end) as spender_Instore
	FROM #Universe1 b
	INNER JOIN #ForecastSpend2 t
		on b.CINID = t.CINID
	WHERE '+@Varname+'=1    
	GROUP BY Weekno
	)a

SELECT	'''+@varname+''' as Customertype,
	COUNT(DISTINCT CINID) as Cardholders
INTO #CountsOut
FROM #Universe1
WHERE '+@varname+' = 1    

--Joining the table to get outputs
SELECT	c.*,
	f.avgw_Sales,
	f.avgw_spder,
	f.avgw_Sales_InStore,
	f.avgw_spder_InStore
INTO #Outall
FROM #CountsOut c
LEFT JOIN #forecastout f
	on c.CustomerType = f.CustomerType

INSERT INTO #segmentsummary0
SELECT	*
FROM #OutAll
'

exec(@sql)
	SELECT @seq = MIN(RowNo) FROM #SegmentList WHERE RowNo > @seq

END


--- Add into a perm table
DECLARE @Base INT
SET @Base = (SELECT COUNT(DISTINCT CINID) FROM #Activated_HM)


INSERT INTO Prototype.ROCP2_SegFore_Fi_NaturalSales
SELECT @BrandID,
	Segment,
	@TValue,
	COUNTS,
	AVGw_sales,
	AVGw_spder,
	AVGw_Sales_InStore,
	AVGw_spder_InStore
FROM #SegmentSummary0

--select * from #SegmentSummary0

--SET @TValue = @TValue + 3

TRUNCATE TABLE #Segmentsummary0

--END  -- This ends the time loop

SET @rowno = @rowno +1
END  -- This ends the brand loop



END