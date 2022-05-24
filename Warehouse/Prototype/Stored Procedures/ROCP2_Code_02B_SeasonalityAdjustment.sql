
/***************************************************************************
Author:	Main Code written by Jenny Hurley - SP Created by Suraj Chahal
Date: 25-01-2016
Purpose: Seasonality Adjustment
***************************************************************************/
CREATE PROCEDURE [Prototype].[ROCP2_Code_02B_SeasonalityAdjustment]
			(
			@IndividualBrand BIT
			)
AS
BEGIN


--DECLARE	@IndividualBrand BIT
--SET @IndividualBrand = 1


/*****************************************
***ROC Phase 2 - Seasonality Adjustment***
*****************************************/
--Defining the DATE ranges
--Defining the seasonal data values (could explore going back further than a year and using averages)
IF OBJECT_ID ('Prototype.ROCP2_SeasonBuild') IS NOT NULL DROP TABLE Prototype.ROCP2_SeasonBuild
SELECT	DISTINCT
	MonthID1,
	SUBSTRING(MonthID1,1,CHARINDEX('-',MonthID1)-1 ) as Month_Season,
	SUBSTRING(MonthID1,CHARINDEX('-',MonthID1)+1,4)-1 as Year_Season,
	CAST(SUBSTRING(MonthID1,1,CHARINDEX('-',MonthID1)-1) AS VARCHAR(2)) +'-'+ CAST(SUBSTRING(MonthID1,CHARINDEX('-',MonthID1)+1,4)-1 AS VARCHAR(4)) as Season_ID
INTO Prototype.ROCP2_SeasonBuild
FROM Prototype.ROCP2_SegFore_Rundaylk
WHERE	BuildWeek = 1



--SELECT TOP 10 * FROM Staging.ROCP2_SeasonBuild

--select * from Staging.ROCP2_SegFore_Rundaylk where buildweek=1 order by linedate
-------------------------------------------------------------------------------
--Generating base build period dates.  
--Note that it is taken to be the build month for last year.  (rather than the current build month).
--This is as it is assumed the forecast start dates will be nearer to the build month and therefore comparing to ly will allow for less trending

--Same time last year
IF OBJECT_ID('tempdb..#WeekBuild') IS NOT NULL DROP TABLE #WeekBuild
SELECT	*,
	ROW_NUMBER () OVER(ORDER BY StartDate) as WeekNo
INTO #WeekBuild
FROM	(
	SELECT	WeekNum,
		MIN(StartDate) as Startdate,
		MAX(EndDate) as EndDate
	FROM Prototype.ROCP2_SegFore_Rundaylk 
	WHERE MonthID1 IN (SELECT Season_ID FROM Prototype.ROCP2_SeasonBuild)
	GROUP BY WeekNum
	) a

--select * from #weekbuild

IF OBJECT_ID ('tempdb..#BuildWeek1') IS NOT NULL DROP TABLE #BuildWeek1
SELECT COUNT(DISTINCT WeekNum) as No_ofWeeks
INTO #BuildWeek1
FROM #weekbuild

-- Defining the historical data period
-- The months to be considered
-- The number of weeks in each month.  Note they can be only 1 week if a special period (i.e. Black Friday week)
IF OBJECT_ID ('tempdb..#MonthID2_Dates') IS NOT NULL DROP TABLE #MonthID2_Dates
SELECT	*,
	(DATEDIFF(DAY, Startdate, Enddate)+1)/7 AS Weeks
INTO #MonthID2_Dates
FROM	(
	SELECT	MonthID2,
		MIN(startdate) AS Startdate,
		MAX(enddate) AS EndDate
	FROM Prototype.ROCP2_SegFore_Rundaylk
	GROUP BY MonthID2
	)a
	WHERE	Startdate >=	(
				SELECT
				MIN(linedate)
				FROM Prototype.ROCP2_SegFore_Rundaylk
				WHERE monthID2 = (SELECT Season_ID FROM Prototype.ROCP2_SeasonBuild)
				)
		AND EndDate <=	(
				SELECT	LastAvailable
				FROM Prototype.ROCP2_SegFore_Rundates
				)
ORDER BY Startdate



-- select * from #MonthID2_dates
IF OBJECT_ID ('tempdb..#WeekBuild_S') IS NOT NULL DROP TABLE #WeekBuild_S
SELECT	WeekNum,
	MonthID2,
	MIN(StartDate) AS StartDate,
	MAX(EndDate) AS EndDate
INTO #WeekBuild_S
FROM Prototype.ROCP2_SegFore_Rundaylk
WHERE MonthID2 IN 
	(
	SELECT	DISTINCT
		MonthID2
	FROM #MonthID2_dates
	)
GROUP BY WeekNum, MonthID2

--select * from #weekbuild_s order by weeknum

--  Brands : again make a  genric tables
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

DELETE FROM Prototype.ROCP2_SegFore_OutputSeasonal
WHERE BrandID IN (SELECT BrandID FROM #Brand)

DELETE FROM Prototype.ROCP2_SegFore_OutputSeasonalYoYTrend
WHERE BrandID IN (SELECT BrandID FROM #Brand)

END
ELSE
BEGIN

INSERT INTO #Brand
SELECT *
FROM Prototype.ROCP2_Brandlist

TRUNCATE TABLE Prototype.ROCP2_SegFore_OutputSeasonal
TRUNCATE TABLE Prototype.ROCP2_SegFore_OutputSeasonalYoYTrend

END
/*****************************************************************/

CREATE NONCLUSTERED INDEX IDX_AcqL ON #Brand (AcquireL)
CREATE NONCLUSTERED INDEX IDX_LapL ON #Brand (LapserL)
CREATE NONCLUSTERED INDEX IDX_RowNo ON #Brand (RowNo)



/***************************************************
*********3 . Building the seasonality code**********
***************************************************/
--IF OBJECT_ID('Prototype.ROCP2_SegFore_OutputSeasonal') IS NOT NULL DROP TABLE Prototype.ROCP2_SegFore_OutputSeasonal
--CREATE TABLE Prototype.ROCP2_SegFore_OutputSeasonal
--	(
--	BrandID int NULL,
--	MonthID2 varchar(10) NULL,
--	Sales_adj real NULL,
--	Spender_adj real NULL,
--	Avgw_Sales real NULL,
--	Avgw_Spder int NULL,
--	Avgw_Sales_BASE real NULL,
--	Avgw_Spender_BASE int NULL,
--	Cardholders real NULL
--	)
--CREATE CLUSTERED INDEX IDX_BID ON Prototype.ROCP2_SegFore_OutputSeasonal (BrandID)


--IF OBJECT_ID('Prototype.ROCP2_SegFore_OutputSeasonalYoYTrend') IS NOT NULL DROP TABLE Prototype.ROCP2_SegFore_OutputSeasonalYoYTrend
--CREATE TABLE Prototype.ROCP2_SegFore_OutputSeasonalYoYTrend
--	(
--	BrandID INT NULL,
--	YoY_SalesAdj REAL NULL,
--	YoY_SpenderAdj REAL NULL
--	)
--Would it be better to 

--select * from #OUTPUT_Seasonal_ALL


/*****************************************
*********Creating Brand Loop code*********
*****************************************/
DECLARE @BrandID INT,
        @RowNo INT
SET @RowNo = 1

WHILE @RowNo <= (SELECT	MAX(RowNo) FROM #Brand)   ---Limit to just 50 for test run

BEGIN
  
SET @BrandID =	(
		SELECT	BrandID
		FROM #Brand
		WHERE RowNo = @RowNo
		)
  --PRINT @RowNo
  --PRINT @BrandID

DECLARE @SeasonStart AS DATE
SET @SeasonStart =	(
			SELECT	DATEADD(WEEK, -12, MIN(linedate))
			FROM Prototype.ROCP2_SegFore_Rundaylk
			WHERE monthID2 = (
					SELECT	Season_ID
					FROM Prototype.ROCP2_SeasonBuild
					)
			)  -- Going back 12 weeks further than linebuild so I can build trend data

IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT	DISTINCT
	ConsumerCombinationID,
	cc.BrandID
INTO #CCIDs
FROM Relational.ConsumerCombination cc WITH (NOLOCK)
WHERE	cc.BrandID = @BrandID
	AND IsUKSpend = 1
--and bi.RowNo between 225 and 250 -- limiting to 25 for testing code process
CREATE CLUSTERED INDEX IND_CC ON #CCIDs (ConsumerCombinationID)
CREATE NONCLUSTERED INDEX IND_BI ON #CCIDs (BrandID)

/***********************************************
**********Finding last 12 months spend**********
***********************************************/
IF OBJECT_ID('tempdb..#Last12mSpd') IS NOT NULL DROP TABLE #Last12mSpd
SELECT	ct.CINID,
	TranDate,
	SUM(amount) AS Sales
--issue is that this start list could be dynamic! Limit to 14 currently. 
INTO #Last12mSpd
FROM #CCIDs b
INNER JOIN Relational.ConsumerTransaction ct WITH (NOLOCK)
	ON b.ConsumerCombinationID = ct.ConsumerCombinationID
INNER JOIN Prototype.ROCP2_SegFore_FixedBase c
	ON c.CINID = ct.CINID
WHERE	TranDate BETWEEN @SeasonStart AND 
	(
	SELECT	BuildEnd
	FROM Prototype.ROCP2_SegFore_Rundates
	)
	AND IsRefund = 0 --- exclude refunds
	AND b.BrandID = @BrandID -- building with single brand  -- Prezzo 
GROUP BY ct.TranDate, ct.CINID
--
CREATE CLUSTERED INDEX IDX_CD ON #Last12mSpd (CINID)
CREATE NONCLUSTERED INDEX IDX_TD ON #Last12mSpd (TranDate)

/***************************************************
*******Creating RR and SPC for the Base Data********
***************************************************/
IF OBJECT_ID('tempdb..#Last12mSpdByWeek') IS NOT NULL DROP TABLE #Last12mSpdByWeek
SELECT	t.*,
	w.WeekNum
INTO #Last12mSpdByWeek
FROM #Last12mSpd t
CROSS JOIN #WeekBuild w
WHERE TranDate BETWEEN w.Startdate AND w.EndDate
--
CREATE CLUSTERED INDEX IDX_CD ON #Last12mSpdByWeek (CINID)
CREATE NONCLUSTERED INDEX IDX_TD ON #Last12mSpdByWeek (TranDate)
CREATE NONCLUSTERED INDEX IDX_WN ON #Last12mSpdByWeek (WeekNum)


IF OBJECT_ID('tempdb..#Base_Values') IS NOT NULL DROP TABLE #Base_Values
DECLARE @Cardholders INT
SET @Cardholders =
	(
	SELECT	COUNT(DISTINCT CINID)
	FROM Prototype.ROCP2_SegFore_FixedBase
	)

-- note the approach takes the average sales and spenders over the weeks at this stage (If I did the weekly calculations of SPC and RR and took the average if for that week there happened
-- to be zero spenders then the average would be higher than should be. 
SELECT	@Cardholders AS Cardholders,
	SUM(CASE WHEN Sales = 0 THEN NULL ELSE Sales END)/MAX(No_OfWeeks) AS AVGw_Sales_BASE,
	SUM(CASE WHEN Spenders = 0 THEN NULL ELSE Spenders END)/MAX(No_OfWeeks) AS AVGw_Spender_BASE,
	AVG(SPS) AS AverageSPS -- doing a check
INTO #Base_values
FROM	(
	SELECT	WeekNum,
		SUM(sales) AS Sales,
		COUNT(DISTINCT cinid) AS Spenders,
		SUM(CASE WHEN Sales = 0 THEN NULL ELSE Sales END)/COUNT(DISTINCT CINID) AS SPS,
		MAX(No_OfWeeks) AS No_OfWeeks
	FROM #Last12mSpdByWeek
	CROSS JOIN #BuildWeek1
	GROUP BY WeekNum
	) a

--SELECT
--  *
--FROM #Base_values

IF OBJECT_ID ('tempdb..#SeasonalTrans') IS NOT NULL DROP TABLE #SeasonalTrans
SELECT	a.MonthID2,
	MAX(wn.weeks) AS No_OfWeeks,
	SUM(CASE WHEN Sales = 0 THEN NULL ELSE Sales END)/MAX(wn.weeks) AS AVGw_Sales,
	SUM(CASE WHEN Spenders = 0 THEN NULL ELSE Spenders END)/MAX(wn.weeks) AS AVGw_spder
INTO #SeasonalTrans
FROM	(
	SELECT	WeekNum,
		MonthID2,
		SUM(sales) AS Sales,
		COUNT(DISTINCT CINID) AS Spenders
	FROM #Last12mSpd t
	CROSS JOIN #WeekBuild_s w
	WHERE t.Trandate BETWEEN w.StartDate AND w.EndDate
	GROUP BY WeekNum, MonthID2
	)a
LEFT JOIN #MonthID2_dates wn
	ON wn.MonthID2 = a.MonthID2
GROUP BY a.MonthID2

--select * from Staging.STOSalesForecast_weekRef order by startdate 
-- max(end week) 
/*
SELECT
  *
FROM #SeasonalTrans
SELECT
  SUM(sales),
  COUNT(DISTINCT cinid)
FROM #Last12mSpd
WHERE TranDate BETWEEN '2015-08-31' AND '2015-09-27'

SELECT
  *
FROM #weekbuild_s
SELECT TOP 100
  *
FROM #MonthID2_dates
*/

/**********************************************
********Aggregating together the data**********
**********************************************/




IF OBJECT_ID('tempdb..#Output_Seasonal') IS NOT NULL DROP TABLE #Output_Seasonal
SELECT	@BrandID AS BrandID,
	MonthID2,
	(CASE WHEN AVGw_Sales = 0 THEN NULL ELSE AVGw_Sales END)/  nullif(AVGw_Sales_BASE, 0) AS Sales_adj,
	CAST((CASE WHEN AVGw_Spder = 0 THEN NULL ELSE AVGw_Spder END) AS REAL)/CAST(nullif(AVGw_Spender_BASE,0) AS REAL) AS Spender_adj,
	s.AVGw_Sales,
	s.AVGw_Spder,
	b.AVGw_Sales_BASE,
	b.AVGw_Spender_BASE,
	b.Cardholders
INTO #Output_Seasonal
FROM #SeasonalTrans s
CROSS JOIN #Base_values b
--
CREATE CLUSTERED INDEX IDX_BID ON #Output_Seasonal (BrandID)


INSERT INTO Prototype.ROCP2_SegFore_OutputSeasonal
SELECT	BrandID,
	MonthID2,
	Sales_adj,
	Spender_adj,
	AVGw_Sales,
	AVGw_Spder,
	AVGw_Sales_BASE,
	AVGw_Spender_BASE,
	Cardholders 
FROM #Output_Seasonal
--



/********************************************************
******4. TrendData (base on the last 12 weeks YoY)*******
********************************************************/
IF OBJECT_ID('tempdb..#Trenddates') IS NOT NULL DROP TABLE #Trenddates
SELECT	DATEADD(WEEK,-12,MIN(StartDate)) AS StartTrendTY,
	MAX(EndDate) AS EndTrendTY,
	DATEADD(WEEK,-52,DATEADD(WEEK,-12,MIN(StartDate))) AS StartTrendLY,
	DATEADD(WEEK,-52,MAX(EndDate)) AS EndTrendLY
INTO #TrendDates
FROM Prototype.ROCP2_SegFore_Rundaylk
WHERE BuildWeek = 1


INSERT INTO Prototype.ROCP2_SegFore_OutputSeasonalYoYTrend
SELECT	@BrandID,
	(CASE WHEN TY_Sales = 0 THEN NULL ELSE TY_Sales END)/CAST(LY_Sales AS real) YoY_SalesAdj,
	(CASE WHEN TY_Spenders = 0 THEN NULL ELSE TY_Spenders END)/CAST(LY_spenders AS real) AS YoY_SpenderAdj
FROM	(
	SELECT	SUM(sales) AS LY_Sales,
		COUNT(DISTINCT cinid) AS LY_spenders
	FROM #Last12mSpd
	WHERE TranDate BETWEEN
		(
		SELECT	DISTINCT
			StartTrendLY
		FROM #TrendDates
		)
	AND	(
		SELECT	DISTINCT
			EndTrendLY
		FROM #TrendDates
		)
	)LY
CROSS JOIN
	(
	SELECT	SUM(sales) AS TY_Sales,
		COUNT(DISTINCT CINID) AS TY_spenders
	FROM #Last12mSpd
	WHERE	TranDate BETWEEN 
		(
		SELECT	DISTINCT
			StartTrendTY
		FROM #TrendDates
		)
		AND 
		(
		SELECT	DISTINCT
			EndTrendTY
		FROM #Trenddates
		)
	)TY


--PRINT @RowNo
SET @RowNo = @RowNo + 1
--PRINT @RowNo
END


----------------------------------------------------------------------
----------  5. OUTPUTs
----------------------------------------------------------------------
-- Base Month
/*
SELECT
  'Copy below results to columns J2 in sheet Seasonality' Instructions
SELECT
  monthid2,
  brandid,
  Sales_adj,
  Spender_adj,
  avgw_sales,
  avgw_spder,
  avgw_Sales_BASE,
  avgw_Spender_BASE,
  Cardholders
FROM Staging.ROCP2_SegFore_OutputSeasonal
WHERE monthid2 NOT IN (SELECT DISTINCT
  season_ID
FROM Staging.ROCP2_SeasonBuild)
ORDER BY brandid, monthid2
---- 
SELECT
  'Copy below results to columns A5 in sheet Seasonality' Instructions
SELECT
  monthID1,
  season_ID
FROM Staging.ROCP2_SeasonBuild


SELECT
  'Copy below results to columns B11 in sheet Seasonality' Instructions
SELECT DISTINCT
  monthid2
FROM Staging.ROCP2_SegFore_OutputSeasonal
WHERE monthid2 NOT IN (SELECT DISTINCT
  season_ID
FROM Staging.ROCP2_SeasonBuild)
ORDER BY monthid2


SELECT
  'Copy below results to columns U2 in sheet Seasonality' Instructions
SELECT
  LineDate,
  MonthID2
FROM Staging.ROCP2_SegFore_DayRef
ORDER BY linedate

SELECT
  'Copy below results to columns Y3 in sheet Seasonality' Instructions
SELECT
  *
FROM Staging.ROCP2_SegFore_OutputSeasonalYoYTrend


*/
/*
IF OBJECT_ID('tempdb..#ccids') IS NOT NULL
  DROP TABLE #ccids
SELECT DISTINCT
  ConsumerCombinationID,
  cc.BrandID INTO #ccids
FROM Warehouse.Relational.ConsumerCombination cc WITH (NOLOCK)
WHERE cc.BrandID = 75
AND IsUKSpend = 1
--and bi.RowNo between 225 and 250 -- limiting to 25 for testing code process

CREATE INDEX IND_CC ON #ccids (ConsumerCombinationID);

IF OBJECT_ID('tempdb..#DailySales') IS NOT NULL
  DROP TABLE #DailySales

(SELECT
  ct.CINID,
  TranDate,
  SUM(amount) AS sales
--- issue is that this start list could be dynamic! Limit to 14 currently. 
INTO #DailySales
FROM #ccids b
INNER JOIN Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
  ON b.ConsumerCombinationID = ct.ConsumerCombinationID
INNER JOIN #customerbase c
  ON c.cinid = ct.cinid
WHERE TranDate BETWEEN '2015-08-01' AND '2016-01-31'
AND ISRefund = 0 --- exclude refunds
AND b.brandID = 75 -- building with single brand  -- Prezzo 
GROUP BY ct.TranDate,
         ct.CINID
)


SELECT
  trandate,
  SUM(sales) AS sales
FROM #DailySales
GROUP BY tranDate
ORDER BY trandate
---------------

--- Sept to Sept Linear Growth!!
*/

END