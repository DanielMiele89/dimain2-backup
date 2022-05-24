
/******************************************************************************
CAMPAIGN PLANNING TOOL - SCRIPT 3
---------------------------------
-- Author: Suraj Chahal
-- Create date: 10/11/2015
-- Description: Build the following tables used for Campaign Planning

BUILDS THE TABLE CampaignPlanning_Seasonality
*******************************************************************************/

CREATE PROCEDURE [Staging].[CampaignPlanning_3_SeasonalityData]
									
AS
BEGIN
	SET NOCOUNT ON;


/************************************************************
***************Seasonality Transactional Data****************
************************************************************/
IF OBJECT_ID('tempdb..#Cal') IS NOT NULL DROP TABLE #Cal
SELECT  Stratification.leastdate(CAST(CAST(DATEDIFF(WEEK, 0, GETDATE())*7-7*4-7 AS DATETIME) AS DATE),
						CAST(CAST(DATEDIFF(WEEK, 0, MaxDate)*7-7*4 AS DATETIME) AS DATE)) StartDate, 
	Stratification.leastdate(CAST(CAST(DATEDIFF(WEEK, 0, GETDATE())*7-1-7 AS DATETIME) AS DATE),
						CAST(CAST(DATEDIFF(WEEK, 0, MAXDATE)*7-1 AS DATETIME) AS DATE))  EndDate
INTO #Cal
FROM Staging.CampaignPlanning_MaxTrandate


--**Calendar with 56 past weeks
IF OBJECT_ID ('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar 
DECLARE	@DateFrom DATE,
	@DateTo DATE;

SET @DateTo = (SELECT MAX(EndDate) FROM #Cal)
SET @DateFrom = DATEADD(WEEK,-52,(SELECT MAX(StartDate) FROM #Cal));
-------------------------------
WITH T (StartDate, EndDate)
AS
	( 
	SELECT	@DateFrom as StartDate,
		DATEADD(DAY,6,@DateFrom) as EndDate
UNION ALL
	SELECT	DATEADD(DAY,7,T.StartDate),
		DATEADD(DAY,7+6,T.StartDate)
	FROM T 
	WHERE T.StartDate < DATEADD(DAY,-7,@DateTo)
	)
SELECT	StartDate,
	EndDate
INTO #Calendar
FROM T OPTION (MaxRecursion 32767)
--


ALTER TABLE #Calendar
ALTER COLUMN StartDate DATE NOT NULL

ALTER TABLE #Calendar
ALTER COLUMN EndDate DATE NOT NULL

ALTER TABLE #Calendar
ADD PRIMARY KEY (StartDate, EndDate)
--


/***********************************************************
***************Past 56 past weeks transactions************** 
***********************************************************/
/*
CREATE TABLE Staging.CampaignPlanning_SeasonalTrans
	(
	PartnerID INT NOT NULL,
	TransactionWeek DATE NOT NULL,
	Value FLOAT NULL--,
--	Spenders INT NULL,
--	TransCount INT NULL
	)

CREATE CLUSTERED INDEX IDX_PT ON Staging.CampaignPlanning_SeasonalTrans (PartnerID,TransactionWeek)
*/

TRUNCATE TABLE Staging.CampaignPlanning_SeasonalTrans


DECLARE @StartRow INT,
	@PartnerID INT

SET @StartRow = 1
SET @PartnerID = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow)

WHILE @StartRow <= (SELECT MAX(RowNo) FROM Staging.CampaignPlanning_Brand)
BEGIN

--***********************************************************************************************

INSERT INTO Staging.CampaignPlanning_SeasonalTrans
SELECT	br.PartnerID,
	StartDate as TransactionWeek, 
	SUM(Amount) as Value
FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
INNER JOIN Staging.CampaignPlanning_AllCustomers t
	ON t.CINID = ct.CINID
INNER JOIN Staging.CampaignPlanning_Brand_CCID br --**Staging.CampaignPlanning_Brand_CCID
	ON br.ConsumerCombinationID = ct.ConsumerCombinationID
	AND br.PartnerID = @PartnerID
INNER JOIN #Calendar cw
	ON ct.TranDate BETWEEN cw.StartDate AND cw.EndDate
WHERE	Amount > 0
GROUP BY br.PartnerID, StartDate

--***********************************************************************************************
	SET @StartRow = @StartRow+1
	SET @PartnerID = (SELECT PartnerID FROM Staging.CampaignPlanning_Brand WHERE RowNo = @StartRow)

END

/* Customers crossed join with Partners*/
IF OBJECT_ID('tempdb..#SeasonalCount') IS NOT NULL DROP TABLE #SeasonalCount
SELECT	DISTINCT
	b.PartnerID,
	PartnerName,
	AllCustomers,
	c.StartDate as TransactionWeek, 
	(DENSE_RANK() OVER (PARTITION BY b.PartnerID ORDER BY c.StartDate)-1)/4 as PeriodID,
	COALESCE(h.HolidayID,'0') HolidayID
INTO #SeasonalCount
FROM Staging.CampaignPlanning_Brand b
INNER JOIN Relational.Partner p
	ON b.PartnerID = p.PartnerID
CROSS JOIN
	(
	SELECT COUNT(DISTINCT FanID) as AllCustomers
	FROM Staging.CampaignPlanning_AllCustomers
	)a
CROSS JOIN #Calendar c
LEFT OUTER JOIN MI.Holiday_Week h
	ON h.StartDate = c.StartDate


ALTER TABLE #SeasonalCount
ALTER COLUMN PartnerID INT NOT NULL

ALTER TABLE #SeasonalCount
ALTER COLUMN TransactionWeek DATE NOT NULL


ALTER TABLE #SeasonalCount
ADD PRIMARY KEY (PartnerID,TransactionWeek)


/***********************************************
************Seasonality Adjustments*************
***********************************************/
IF OBJECT_ID('tempdb..#SeasonalSummary') IS NOT NULL DROP TABLE #SeasonalSummary
SELECT	sc.PartnerID,
	sc.TransactionWeek,
	HolidayID,
	PeriodID,
	AllCustomers,
	COALESCE(Value,0) as Sales 
INTO #SeasonalSummary
FROM #SeasonalCount sc
LEFT OUTER JOIN Staging.CampaignPlanning_SeasonalTrans st
	ON sc.PartnerID = st.PartnerID
	AND sc.TransactionWeek = st.TransactionWeek

CREATE CLUSTERED INDEX IND ON #SeasonalSummary (PartnerID)


/***********************************************
*******************Base Summary*****************
***********************************************/
IF OBJECT_ID ('tempdb..#BaseSummary') IS NOT NULL DROP TABLE #BaseSummary
SELECT	a.*,
	CASE
		WHEN a.BaseCustomers > 0 THEN 1.0*BaseSales/BaseCustomers 
	END BaseSPC
INTO #BaseSummary
FROM	(
	SELECT	PartnerID,
		SUM(AllCustomers) as BaseCustomers,
		SUM(Sales) as BaseSales
	FROM #SeasonalSummary 
	WHERE PeriodID = 0 
	GROUP BY PartnerID
	)a

CREATE CLUSTERED INDEX B_IND ON #BaseSummary (PartnerID)


/***********************************************
*******************Base Summary*****************
***********************************************/
IF OBJECT_ID('tempdb..#SeasonalDev') IS NOT NULL DROP TABLE #SeasonalDev
SELECT	PartnerID, 
	STDEVP(1.0*Sales/AllCustomers) SPC_Dev 
INTO #SeasonalDev
FROM #SeasonalSummary
GROUP BY PartnerID
--(68 row(s) affected)



/***********************************************
***************Add Seasonal Capping*************
***********************************************/
--**1/5, 5 and 2, 0.5 are arbitrary capped values, decided to cap values at te level of +/- 4 sigma
IF OBJECT_ID('tempdb..#SeasonalCapping') IS NOT NULL DROP TABLE #SeasonalCapping
SELECT	d.*, 
	CASE	
		WHEN BaseSPC > 0 THEN Stratification.least(1.0*(BaseSPC+4*SPC_Dev)/BaseSPC,5)
		ELSE 2
	END MaxSPC,
	CASE	
		WHEN BaseSPC > 0 THEN Stratification.greatest(1.0*(BaseSPC-4*SPC_Dev)/BaseSPC,1.0/5)
		ELSE 0.5
	END MinSPC
INTO #SeasonalCapping
FROM #SeasonalDev d
INNER JOIN #BaseSummary b 
	ON b.PartnerID = d.PartnerID


/****************************************************
***********Build a future 104 weeks calendar - 2y**********
****************************************************/
IF OBJECT_ID('tempdb..#FutureCalendar') IS NOT NULL DROP TABLE #FutureCalendar
DECLARE	@DateFrom2 SMALLDATETIME,
	@DateTo2 SMALLDATETIME;
SET @DateFrom2 = DATEADD(DAY,1,(SELECT MAX(EndDate) FROM #Cal));
SET @DateTo2 = DATEADD(WEEK,51+52,(SELECT MAX(EndDate) FROM #Cal));
-------------------------------
WITH T(DATE)
AS
	( 
	SELECT @DateFrom2 
UNION ALL
	SELECT DATEADD(DAY,7,T.DATE)
	FROM T 
	WHERE T.DATE < @DateTo2
	)
SELECT	Date,
	CASE 
		WHEN DATEDIFF(WEEK, @DateFrom2, DATE)+1<=52 THEN DATEADD(DAY,-52*7,DATE) ELSE DATEADD(DAY,-52*2*7,Date)
	END  LookupDate
INTO #FutureCalendar
FROM T OPTION (MaxRecursion 32767)
--

CREATE CLUSTERED INDEX IND ON #FutureCalendar (LookupDate)



/****************************************
***********Build forecast table**********
****************************************/
IF OBJECT_ID('tempdb..#Forecast') IS NOT NULL DROP TABLE #Forecast
SELECT	c.PartnerID,
	c.PartnerName,
	f.Date,
	c.HolidayID,
	b.BaseCustomers,
	b.BaseSales,
	CASE 
		WHEN c.HolidayID <> '0' THEN SUM(h.AllCustomers)
		ELSE SUM(p.AllCustomers)
	END as Customers,
	CASE
		WHEN c.HolidayID <> '0' THEN SUM(h.Sales)
		ELSE SUM(p.Sales)
	END as Sales
INTO #Forecast
FROM #FutureCalendar f
INNER JOIN #SeasonalCount c
	ON c.TransactionWeek = f.LookupDate
INNER JOIN #BaseSummary b
	ON b.PartnerID = c.PartnerID
LEFT OUTER JOIN #SeasonalSummary h 
	ON h.HolidayID = c.HolidayID 
	AND h.HolidayID <> '0' 
	AND c.HolidayID <> '0'
	AND h.PartnerID = c.PartnerID 
LEFT OUTER JOIN #SeasonalSummary p 
	ON p.PeriodID = c.PeriodID
	AND p.HolidayID = '0'
	AND c.HolidayID = '0'
	AND p.PartnerID = c.PartnerID 
GROUP BY c.PartnerID, f.Date, c.HolidayID, b.BaseCustomers, b.BaseSales, c.PartnerName



/**********************************************
***********Build Final Forecast table**********
**********************************************/
IF OBJECT_ID('Staging.CampaignPlanning_Seasonality') IS NOT NULL DROP TABLE Staging.CampaignPlanning_Seasonality
SELECT	f.PartnerID,
	f.Date,
	f.HolidayID,
	Stratification.greatest(Stratification.least(
			COALESCE(CASE WHEN Sales>0 and BaseSales>0 THEN  1.0*Sales*BaseCustomers/(1.0*Customers*BaseSales) END,1)
			,MaxSPC),MinSPC) AS SPCAdj
INTO Staging.CampaignPlanning_Seasonality
FROM #Forecast f
INNER JOIN #SeasonalCapping c
	ON c.PartnerID = f.PartnerID
--(7072 row(s) affected)


END