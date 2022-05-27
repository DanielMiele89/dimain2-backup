
/***************************************************************************
Author:	Main Code written by Jenny Hurley - SP Created by Suraj Chahal
Date: 25-01-2016
Purpose: ROC Phase 2 forecasting tool - Spender Adjustments
***************************************************************************/
CREATE PROCEDURE Prototype.[ROCP2_Code_02E_SpenderAdjustments]
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
	RowNo SMALLINT,
	AcquireL SMALLINT,
	LapserL SMALLINT
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
--IF OBJECT_ID ('Prototype.ROCP2_SpendersAdj') IS NOT NULL DROP TABLE Staging.ROCP2_SpendersAdj
--CREATE TABLE Prototype.ROCP2_SpendersAdj 
--	(
--	BrandID SMALLINT NULL,
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
DECLARE @EndDate DATE,
	@FirstDate DATE

SET @EndDate = (SELECT MAX(EndDate) FROM #WeekBuild)
SET @FirstDate = DATEADD(WEEK,-52,@EndDate)

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


/****************************************************
****************************************************/
DECLARE @EndDate1 DATE
SET @EndDate1 = (SELECT MAX(EndDate) FROM #WeekBuild)

IF OBJECT_ID ('tempdb..#Summary1') IS NOT NULL DROP TABLE #Summary1
SELECT	*,
	CASE WHEN Spenders > 0 THEN Trans/CAST(Spenders AS REAL) ELSE NULL END as ATF
INTO #Summary1
FROM	(
	SELECT	4 as WeekLength,
		COUNT(DISTINCT CINID) as Spenders,
		SUM(Trans) as Trans
	FROM #Last12mSpd t
	WHERE TranDate BETWEEN DATEADD(WEEK,-4,@EndDate1)  and @EndDate1
UNION ALL
	SELECT	8 as WeekLength,
		COUNT(DISTINCT CINID) as Spenders,
		SUM(Trans) as Trans
	FROM #Last12mSpd t
	WHERE TranDate between dateadd(week,-8,@EndDate1)  and @EndDate1
UNION ALL
	SELECT 12 as WeekLength
		  ,COUNT(DISTINCT CINID) as Spenders
		  ,sum(Trans) as Trans
	FROM #Last12mSpd t
	WHERE TranDate between dateadd(week,-12,@EndDate1)  and @EndDate1
UNION ALL
	SELECT 24 as WeekLength
		  ,COUNT(DISTINCT CINID) as Spenders
		  ,sum(Trans) as Trans
	FROM #Last12mSpd t
	WHERE TranDate between dateadd(week,-24,@EndDate1)  and @EndDate1
UNION ALL
	SELECT 48 as WeekLength
		  ,COUNT(DISTINCT CINID) as Spenders
		  ,sum(Trans) as Trans
	FROM #Last12mSpd t
	WHERE TranDate between dateadd(week,-48,@EndDate1)  and @EndDate1
UNION ALL
	SELECT 52 as WeekLength
		  ,COUNT(DISTINCT CINID) as Spenders
		  ,sum(Trans) as Trans
	FROM #Last12mSpd t
	WHERE TranDate between dateadd(week,-52,@EndDate1)  and @EndDate1
	) a


IF OBJECT_ID('tempdb..#Base1') IS NOT NULL DROP TABLE #Base1
SELECT	SUM(Spenders) as BASESpenders,
	SUM(Trans) as BASETrans,
	CASE 
		WHEN SUM(Spenders) >0 THEN SUM(Trans)/CAST(SUM(Spenders) AS REAL) 
		ELSE 0 
	END AS BASEATF
INTO #Base1
FROM	(
	SELECT	WeekNo,
		COALESCE(COUNT(DISTINCT CINID),0) as Spenders,
		COALESCE(SUM(Trans),0) as Trans
	FROM #Last12mSpd s
	CROSS JOIN #WeekBuild w
	WHERE s.TranDate BETWEEN w.StartDate AND w.EndDate
	GROUP BY WeekNo 
	)a


IF OBJECT_ID('tempdb..#Combined') IS NOT NULL DROP TABLE #Combined
SELECT a.*
,case when BASEATF>0 then ATF /CAST( BASEATF AS real) else NULL end as ATFRatio
INTo #Combined
FROM (
SELECT * 
FROM #summary1 
cross join #Base1 ) a



INSERT INTO Prototype.ROCP2_SpendersAdj
SELECT  @BrandID as BrandID,
	*  
FROM #Combined

SET @RowNo = @RowNo+1 

END





------------------------------------------------------------------------
------------  5. OUTPUTs
------------------------------------------------------------------------
---- Base Month

--SELECT 'Copy below results to columns i4 in DataSpendersAdj sheet ' Instructions

--SELECT BrandID
--,WeekLength
--,ATFRatio
--FROM Staging.ROCP2_SpendersAdj

END

