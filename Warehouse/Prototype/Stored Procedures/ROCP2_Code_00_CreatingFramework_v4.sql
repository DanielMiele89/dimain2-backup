/***************************************************************************
Author:	Main Code written by Jenny Hurley - SP Created by Suraj Chahal
Date: 20-01-2016
Purpose: Create framework for building Forecasting and Segmentation 
	 Sector default time frame definitions and Lapser and Acquire times
***************************************************************************/
CREATE PROCEDURE [Prototype].[ROCP2_Code_00_CreatingFramework_v4]
AS
BEGIN

/***************************************************************
ROC Phase 2:

--**Definitions: Acquire are not shopped in time frame
--**Lapser: not shopped in l but shopped some point in a (i.e. shopped a-l months ago)
***************************************************************/
IF OBJECT_ID('tempdb..#SectorDefaults_TransLength') IS NOT NULL DROP TABLE #SectorDefaults_TransLength
CREATE TABLE #SectorDefaults_TransLength (
	SectorName varchar(50) NULL,
	SectorID SMALLINT NOT NULL,
	AcquireL SMALLINT NULL,
	LapserL SMALLINT NULL,
	Acquire_Pct INT NULL
	)

INSERT INTO #SectorDefaults_TransLength (SectorName, SectorID)
SELECT	SectorName,
	SectorID
FROM relational.brandsector 
WHERE SectorID IN	(
		SELECT	DISTINCT
			SectorID
		FROM relational.BrandSector 
		WHERE	SectorGroupID IN (1,2)
			AND SectorName NOT IN ('Gambling','Sports And Clubs')
			)

/******************************************************
***********Update Acquire and Lapser Fields************
******************************************************/
UPDATE #SectorDefaults_TransLength
SET acquireL = 6
WHERE sectorname IN ('Grocery','Petrol','Transport')
--------------------------------------------------------
UPDATE #SectorDefaults_TransLength
SET LapserL = 3
WHERE sectorname IN ('Grocery','Petrol','Transport')


UPDATE #SectorDefaults_TransLength
SET acquireL = 18
WHERE sectorname IN ('Consumer Electronics','Communication')
--------------------------------------------------------
UPDATE #SectorDefaults_TransLength
SET LapserL = 12
WHERE sectorname IN ('Consumer Electronics','Communication')


UPDATE #SectorDefaults_TransLength
SET acquireL = 24
WHERE sectorname IN ('Travel','Household','Repair And Maintenance','Accommodation')
--------------------------------------------------------
UPDATE #SectorDefaults_TransLength
SET LapserL = 12
WHERE sectorname IN ('Travel','Household','Repair And Maintenance','Accommodation')


UPDATE #SectorDefaults_TransLength
SET acquireL = 60
WHERE sectorname IN ('Utilities')
--------------------------------------------------------
UPDATE #SectorDefaults_TransLength
SET LapserL = 12
WHERE sectorname IN ('Utilities')


UPDATE #SectorDefaults_TransLength
SET acquireL = 12
WHERE acquireL IS NULL
--------------------------------------------------------
UPDATE #SectorDefaults_TransLength
SET LapserL = 6
WHERE LapserL IS NULL

--------------------------------------
UPDATE #SectorDefaults_TransLength
SET Acquire_Pct = 50
WHERE Acquire_Pct IS NULL


---- Time periods are set to be 3 points this is to cope with the data history changing thorough the forecasting year


IF OBJECT_ID('Prototype.ROCP2_SegFore_SectorTimeFrame_LK') IS NOT NULL DROP TABLE Prototype.ROCP2_SegFore_SectorTimeFrame_LK
SELECT *
INTO Prototype.ROCP2_SegFore_SectorTimeFrame_LK
FROM #SectorDefaults_TransLength

ALTER TABLE Prototype.ROCP2_SegFore_SectorTimeFrame_LK
ADD CONSTRAINT pk_SectorID PRIMARY KEY (SectorID)


/*******************************************************
*******Retailer - based Acquire and Lapser lengths******
*******************************************************/
--IF OBJECT_ID('Prototype.ROCP2_SegFore_BrandTimeFrame_LK') IS NOT NULL DROP TABLE Prototype.ROCP2_SegFore_BrandTimeFrame_LK
--CREATE TABLE Prototype.ROCP2_SegFore_BrandTimeFrame_LK
--	(
--	BrandID SMALLINT NULL,
--	AcquireL SMALLINT NULL,
--	LapserL SMALLINT NULL
--	)

--************************************************************************
--INSERT INTO Staging.ROCP2_SegFore_BrandTimeFrame_LK 
--VALUES (190,48,12)
--************************************************************************

/***************************************************************************************************/

/**************************************************
0b Dates - Creating a dates AND week lookup range
**************************************************/
IF OBJECT_ID('tempdb..#DateList') IS NOT NULL DROP TABLE #DateList
CREATE TABLE #DateList
	(
	DateID INT PRIMARY KEY CLUSTERED IDENTITY (1,1),
	LineDate DATE
	)

DECLARE @RunDate DATE
SET @RunDate = '2014-01-01'
WHILE @RunDate <= '2018-12-31'
BEGIN

      INSERT INTO #DateList(LineDate)
      SELECT @RunDate   
      SET @RunDate = DATEADD(DAY, 1, @RunDate)
END


IF OBJECT_ID ('tempdb..#WeekRef') IS NOT NULL DROP TABLE #WeekRef
SELECT	*,
	DATENAME(dw, LineDate) as WeekDay,
	LineDate as StartDate,
	DATEADD(day,6,LineDate) as Enddate,
	ROW_NUMBER() over(order by LineDate) as weeknum
INTO #WeekRef
FROM #DateList 
WHERE DATENAME(DW, LineDate) IN ('Monday')
ORDER BY LineDate


----- Now need to create reference unique by transactional date with weekno
IF OBJECT_ID ('tempdb..#WeekRef2') IS NOT NULL DROP TABLE #WeekRef2
SELECT	d.*,
	WeekNum,
	wr.StartDate,
	wr.Enddate,
	DAY(D.LineDate) as Day,
	MONTH(d.LineDate) as dmonth,
	YEAR(d.LineDate) as Year
INTO #WeekRef2
FROM #DateList d
CROSS JOIN #WeekRef wr
WHERE (
	CASE 
		WHEN d.LineDate BETWEEN Startdate AND Enddate 
		THEN WeekNum ELSE 
	NULL END) IS NOT NULL
ORDER BY LineDate


/****************************************
*******Adding the special date flags*****
****************************************/
IF OBJECT_ID ('tempdb..#WeekRef3') IS NOT NULL DROP TABLE #WeekRef3
SELECT	*,
	CASE
		WHEN day=22 AND dmonth=12 AND year=2014 THEN 'X1-2014'
		WHEN day=29 AND dmonth=12 AND year=2014 THEN 'X2-2014'
		WHEN day=28 AND dmonth=11 AND year=2014 THEN 'X3-2014' -- Black Friday
		WHEN day=18 AND dmonth=4  AND year=2014 THEN 'X4-2014' -- GF - Easter tends to have drop on Easter Sunday AND slight higher on GF AND EM

		WHEN day=22 AND dmonth=12 AND year=2015 THEN 'X1-2015' -- First week of Xmas (secular not litergical)
		WHEN day=29 AND dmonth=12 AND year=2015 THEN 'X2-2015' -- Second week of Xmas (secular not litergical)
		WHEN day=27 AND dmonth=11 AND year=2015 THEN 'X3-2015' -- Black Friday
		WHEN day=3  AND dmonth=4  AND year=2015 THEN 'X4-2015'

		WHEN day=22 AND dmonth=12 AND year=2016 THEN 'X1-2016' -- First week of Xmas (secular not litergical)
		WHEN day=29 AND dmonth=12 AND year=2016 THEN 'X2-2016' -- Second week of Xmas (secular not litergical)
		WHEN day=25 AND dmonth=11 AND year=2016 THEN 'X3-2016' -- Black Friday
		WHEN day=25 AND dmonth=3  AND year=2016 THEN 'X4-2016'

		WHEN day=22 AND dmonth=12 AND year=2017 THEN 'X1-2017' -- First week of Xmas (secular not litergical)
		WHEN day=29 AND dmonth=12 AND year=2017 THEN 'X2-2017' -- Second week of Xmas (secular not litergical)
		WHEN day=24 AND dmonth=11 AND year=2017 THEN 'X3-2017' -- Black Friday
		WHEN day=14 AND dmonth=4  AND year=2017 THEN 'X4-2017'

		WHEN day=22 AND dmonth=12 AND year=2018 THEN 'X1-2018' -- First week of Xmas (secular not litergical)
		WHEN day=29 AND dmonth=12 AND year=2018 THEN 'X2-2018' -- Second week of Xmas (secular not litergical)
		WHEN day=30 AND dmonth=11 AND year=2018 THEN 'X3-2018' -- Black Friday CHECK!!
		WHEN day=30 AND dmonth=3  AND year=2018 THEN 'X4-2018'
		ELSE NULL END as RefDate   
INTO #WeekRef3
FROM #WeekRef2 
--- select top 100 * from #WeekRef3


IF OBJECT_ID ('Prototype.ROCP2_SegFore_WeekRef') IS NOT NULL DROP TABLE Prototype.ROCP2_SegFore_WeekRef
SELECT	*,
	COALESCE(Xweek,MonthID1) as MonthID2
INTO Prototype.ROCP2_SegFore_WeekRef
FROM	(
	SELECT *,
	CAST(MONTH(DATEADD(DAY,3,startdate))AS VARCHAR(2)) + '-' + CAST(YEAR(DATEADD(DAY,3,StartDate)) AS VARCHAR(4)) as MonthID1
	FROM	(
		SELECT	WeekNum, 
			MIN(startdate) as StartDate,
			MAX(enddate) as EndDate,
			MAX(CASE WHEN refdate IS NOT NULL THEN RefDate ELSE NULL END) as Xweek
		-- Assigning a month for each week (do based on mid day)
		FROM #WeekRef3 
		GROUP BY weeknum
		) a
	)b
ORDER BY WeekNum


---- Need to build back to by day tables
IF OBJECT_ID ('Prototype.ROCP2_SegFore_DayRef') IS NOT NULL DROP TABLE Prototype.ROCP2_SegFore_DayRef
SELECT	d.*,
	w.MonthID1,
	w.MonthID2
INTO Prototype.ROCP2_SegFore_DayRef
FROM #weekref2 d
CROSS join Prototype.ROCP2_SegFore_weekRef w 
WHERE LineDate between w.startdate AND w.enddate
ORDER by LineDate


/*****************************************************************************************************/
--0c

/*********************
Create Publisher Lists
*********************/

if object_id('Prototype.ROCP2_PublisherList') is not null drop table Prototype.ROCP2_PublisherList
create table Prototype.ROCP2_PublisherList
	(
	Publisher varchar(50) null
	,PubNo tinyint Null
	,ClubID smallint null
	,Type1 varchar(50) NULL   -- This is used to determine which algorithm to use
	)

--select * from SLC_Report.dbo.Club where ID in (12,143,144,145)
-- Get correct names
-- Not sure whether to go from  code here as SMS is not yet included
-- A1_NFi1 : Algorithm for Nfi.  Basic assumes no history and no further data information
-- A2_Fi1 : RBS used for .  Assumes long data history present and heatmap scores available

insert into Prototype.ROCP2_PublisherList
values ('Quidco',1,12,'A1_NFi1')
,      ('Next Jump',2,145,'A1_NFi1')
,      ('Easy Fundraising',3,143,'A1_NFi1')
,      ('Student Money Saver',4,NULL,'A1_NFi1')
,      ('Airtime Rewards',5,144,'A1_NFi1')
,      ('R4G',6,12,'A1_NFi1')     
,      ('RBS',7,NULL,'A2_Fi1') -- Note no clubID is given for RBS as it is not used (or required)  These Numbers get used in pub scaling      ---- Name, PublisherNo, CLUBID
,      ('Collinson - Virgin',8,NULL,'A1_NFi1')   
,      ('Collinson - Avios',9,NULL,'A1_NFi1')   
,      ('Vouchercodes',10,NULL,'A1_NFi1')  
,      ('AMEX',11,NULL,'A1_NFi1')  
,      ('Collinson - BAA',12,NULL,'A1_NFi1') 
,      ('Smartspend',13,NULL,'A1_NFi1') 
,      ('Vouchercloud',14,NULL,'A1_NFi1') 
,      ('Affinion',15,NULL,'A1_NFi1') 
,      ('Top CashBack',16,NULL,'A1_NFi1')
,	   ('Gobsmack',17,NULL,'A1_NFi1')
,	   ('Bink',18,NULL,'A1_NFi1')
,	   ('Collinson - MBNA',19,NULL,'A1_NFi1')

--- R4G is an exception as not a publisher in the system as should.  It is clubID 12 (Quidco) with a separate ID list to differentiate customers

--select * from Prototype.ROCP2_PublisherList
-------- THESE ARE THE STANDARD NFI BASE SEGMENTS
-- HOWEVER RBS NOW HAS TRIGGER SEGMENTS

if object_id('tempdb..#SegmentOutputs') is not null drop table #SegmentOutputs
create table #SegmentOutputs (Segment varchar(25) null
							,RowNo smallint null
							)


insert into #SegmentOutputs  -- These are the Segments shown in the calculation sheets...  
values ('Acquire',1)
,      ('Winback',2)
,      ('WinbackPrime',3)
,      ('Retain',4)
,      ('Grow',5)
,      ('Welcome',6)       ---- NOte that in the forecast build this is AllBase for outputs this is 
,      ('LowInterest',7)
,      ('Homemover',8)
,      ('Birthday',9)
    

--select * from #SegmentList
-- select distinct segment from Prototype.ROCP2_SegFore_Fi_NaturalSales

---- The forecasting tool is split by week in the background calculations
-- 
--- Want to code up weeks
if object_id ('tempdb..#WeekNo') is not null drop table #WeekNo
create table #WeekNo (WeekID smallInt NULL )

declare @WeekID Int
set @WeekID = 1
while @WeekID <= 52
begin
 --print @weekID
      insert into #WeekNo (WeekID)
      values (@WeekID )
	
      set @WeekID = @WeekID + 1
end

IF OBJECT_ID ('Prototype.ROCP2_PublisherCombinations') IS NOT NULL DROP TABLE Prototype.ROCP2_PublisherCombinations
CREATE TABLE Prototype.ROCP2_PublisherCombinations
	(
	WeekID SMALLINT NOT NULL,
	Publisher VARCHAR(100) NULL,
	Segment VARCHAR(100) NULL,
	CycleID SMALLINT NULL,
	PeriodID SMALLINT NULL
	)

INSERT INTO Prototype.ROCP2_PublisherCombinations

select	w.WeekID
       ,p.Publisher
       ,s.Segment    -- SHOULD I CONVERT ALL BASE TO WELCOME>!
	   ,ceiling((WeekID/cast (2 as real))) as CycleID
	   ,ceiling((WeekID/cast (4 as real))) as PeriodID
from Prototype.ROCP2_PublisherList p
CROSS JOIN #SegmentOutputs s
CROSS JOIN #WeekNo w
where p.Type1 in ('A1_NFi1') 
and s.rowno between 1 and 6 --- Only doing the segments that natural sales are calculated for.  This is not the best way to do this but works from now... should probably just build from the natural sales but this is earlier in the process
union all
select	w.WeekID
       ,p.Publisher
       ,s.Segment    -- SHOULD I CONVERT ALL BASE TO WELCOME>!
	   ,ceiling((WeekID/cast (2 as real))) as CycleID
	   ,ceiling((WeekID/cast (4 as real))) as PeriodID
from Prototype.ROCP2_PublisherList p
CROSS JOIN #SegmentOutputs s
CROSS JOIN #WeekNo w
where p.Type1 in ('A2_Fi1') 


--select * from Prototype.ROCP2_PublisherCombinations

CREATE CLUSTERED INDEX IDX_WID ON Prototype.ROCP2_PublisherCombinations (WeekID)
CREATE NONCLUSTERED INDEX IDX_PID ON Prototype.ROCP2_PublisherCombinations (Publisher)
CREATE NONCLUSTERED INDEX IDX_S ON Prototype.ROCP2_PublisherCombinations (Segment)
CREATE NONCLUSTERED INDEX IDX_CID ON Prototype.ROCP2_PublisherCombinations (CycleID)
CREATE NONCLUSTERED INDEX IDX_Per ON Prototype.ROCP2_PublisherCombinations (PeriodID)


TRUNCATE TABLE Prototype.ROCP2_ActivationVolumes

INSERT INTO Prototype.ROCP2_ActivationVolumes
SELECT	*
FROM	(
	SELECT	ToDate,
		Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_EFR
UNION ALL
	SELECT	ToDate,
		Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_NJ
UNION ALL 
	SELECT	ToDate,
		Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_AirtimeRewards
UNION ALL 
	SELECT	ToDate,
		'Student Money Saver' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_SMS
UNION ALL 
	SELECT	ToDate,
		'Quidco' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_PureQuidco
UNION ALL 
	SELECT	ToDate,
		'R4G' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_R4G
UNION ALL 
	SELECT	ToDate,
		'Collinson - Virgin' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_CollinsonVirgin
UNION ALL 
	SELECT	ToDate,
		'Collinson - Avios' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_CollinsonAvios
UNION ALL 
	SELECT	ToDate,
		'Vouchercodes' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_Vouchercodes
UNION ALL 
	SELECT	ToDate,
		'AMEX' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_AMEX
UNION ALL 
	SELECT	ToDate,
		'Collinson - BAA' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_collinsonBAA
UNION ALL 
	SELECT	ToDate,
		'Smartspend' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_smartspend
UNION ALL 
	SELECT	ToDate,
		'Vouchercloud' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_vouchercloud
UNION ALL 
	SELECT	ToDate,
		'Affinion' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_affinion
UNION ALL 
	SELECT	ToDate,
		'Top CashBack' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_TopCashback
UNION ALL
	SELECT  ToDate,
		'Gobsmack' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_Gobsmack
UNION ALL
	SELECT  ToDate,
		'Bink' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_Bink
UNION ALL
	SELECT  ToDate,
		'Collinson - MBNA' as Publisher,
		Cumulative_Cardholders,
		Added_Cardholders
	FROM Prototype.ActivationsProjections_Weekly_CollinsonMBNA

--- Adding for RBS base... NOTE the Marketable by Email are in the 
	)a

--select  * from Prototype.ROCP2_ActivationVolumes
--select * from Warehouse.Prototype.ActivationsProjections_Weekly_affinion

--- RBS volumes :  Note that Not making account of Engaged or Marketbale base.
-- Assumes all weeks are full -- which is currently the case (and the ROC cycles could be linked to this)
-- The segmentation has put all the non-marketable into low interest... So needs to be from marketable base.  It assumes marketable base is same as sample.


IF OBJECT_ID ('tempdb..#RBSVolumes') IS NOT NULL DROP TABLE #RBSVolumes
select a.ToDate
,a.Publisher
,a.Cumulative_Cardholders
--,b.NewWeek
,Cumulative_Cardholders-NewWeek as Added_Cardholders
into #RBSVolumes
from
(select Weekstartdate as Todate
    ,'RBS' as Publisher
	,ActivationForecast as Cumulative_Cardholders
	,ROW_NUMBER () over (order by weekstartdate) as Rowno
from Warehouse.MI.CBPActivationsProjections_Weekly ) a
left join
(select Weekstartdate as Todate
    ,'RBS' as Publisher
	,ActivationForecast as NewWeek
	,(ROW_NUMBER () over (order by weekstartdate))+1 as Rowno
from Warehouse.MI.CBPActivationsProjections_Weekly ) b
on a.Rowno=b.Rowno


------------------------------ Adding at end
insert into Prototype.ROCP2_ActivationVolumes
select * from #RBSVolumes



END

-- select * from Warehouse.MI.CBPActivationsProjections_Weekly 