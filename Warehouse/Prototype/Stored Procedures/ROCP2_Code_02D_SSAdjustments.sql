
/***************************************************************************
Author:	Main Code written by Jenny Hurley - SP Created by Suraj Chahal
Date: 25-01-2016
Purpose: ROC Phase 2 forecasting tool - SS adjustment codes
***************************************************************************/
CREATE PROCEDURE [Prototype].[ROCP2_Code_02D_SSAdjustments]
	(
	@IndividualBrand BIT
	)
AS
BEGIN

--DECLARE @IndividualBrand BIT
--SET @IndividualBrand = 1

IF OBJECT_ID ('tempdb..#Output_SSResults') IS NOT NULL DROP TABLE #Output_SSResults
CREATE TABLE #Output_SSResults 
	(
	BrandID SMALLINT null
        ,Trans_p_00 REAL NULL
        ,Trans_p_05 REAL NULL
        ,Trans_p_10 REAL NULL
        ,Trans_p_15 REAL NULL
        ,Trans_p_20 REAL NULL
        ,Trans_p_25 REAL NULL
        ,Trans_p_30 REAL NULL
        ,Trans_p_35 REAL NULL
        ,Trans_p_40 REAL NULL
        ,Trans_p_45 REAL NULL
        ,Trans_p_50 REAL NULL
        ,Trans_p_55 REAL NULL
        ,Trans_p_60 REAL NULL
        ,Trans_p_65 REAL NULL
        ,Trans_p_70 REAL NULL
        ,Trans_p_75 REAL NULL
        ,Trans_p_80 REAL NULL
        ,Trans_p_85 REAL NULL
        ,Trans_p_90 REAL NULL
        ,Trans_p_95 REAL NULL
        ,Trans_p_100 REAL NULL
        ,Sales_p_00 REAL NULL
        ,Sales_p_05 REAL NULL
        ,Sales_p_10 REAL NULL
        ,Sales_p_15 REAL NULL
        ,Sales_p_20 REAL NULL
        ,Sales_p_25 REAL NULL
        ,Sales_p_30 REAL NULL
        ,Sales_p_35 REAL NULL
        ,Sales_p_40 REAL NULL
        ,Sales_p_45 REAL NULL
        ,Sales_p_50 REAL NULL
        ,Sales_p_55 REAL NULL
        ,Sales_p_60 REAL NULL
        ,Sales_p_65 REAL NULL
        ,Sales_p_70 REAL NULL
        ,Sales_p_75 REAL NULL
        ,Sales_p_80 REAL NULL
        ,Sales_p_85 REAL NULL
        ,Sales_p_90 REAL NULL
        ,Sales_p_95 REAL NULL
        ,Sales_p_100 REAL NULL
	)

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

DELETE FROM Prototype.ROCP2_SSByBrand
WHERE BrandID IN (SELECT BrandID FROM #Brand)

END
ELSE
BEGIN

INSERT INTO #Brand
SELECT *
FROM Prototype.ROCP2_Brandlist

TRUNCATE TABLE Prototype.ROCP2_SSByBrand

END
/*****************************************************************/

CREATE NONCLUSTERED INDEX IDX_AcqL ON #Brand (AcquireL)
CREATE NONCLUSTERED INDEX IDX_LapL ON #Brand (LapserL)
CREATE NONCLUSTERED INDEX IDX_RowNo ON #Brand (RowNo)





/*********************************************
*****Starting the Loop round for Brands*******
*********************************************/
DECLARE @brandid int, @rowno int
set @rowno = 1

WHILE @rowno <= (select max(rowno) from #Brand)        ---Limit to just 50 for test run

BEGIN
set @brandid = (select brandid from #Brand where rowno=@rowno)
--print @rowno
--print @brandid

----Consumer Combinations for brands 

IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT  DISTINCT
	ConsumerCombinationID,
	cc.BrandID,
	b.BrandName,
	b.SectorID
INTO #CCIDs 
FROM Relational.ConsumerCombination cc (NOLOCK)
INNER JOIN Relational.Brand b 
	ON b.BrandID = cc.BrandID
INNER JOIN #Brand bi
	ON bi.BrandID = b.BrandID
	AND cc.BrandID = @BrandID
WHERE	IsUKSpend = 1

CREATE CLUSTERED INDEX IDX_CCID ON #CCIDs (ConsumerCombinationID)
CREATE NONCLUSTERED INDEX IDX_BID ON #CCIDs (BrandID)


IF OBJECT_ID('tempdb..#TransLast12m') IS NOT NULL DROP TABLE #TransLast12m
SELECT	BrandID,
	ct.CINID,
	Amount,
	ROW_NUMBER() OVER(ORDER BY Amount) as TransNumber,
	TranDate
INTO #TransLast12m
FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
INNER JOIN Prototype.ROCP2_SegFore_FixedBase c
	ON c.CINID = ct.CINID  
INNER JOIN #CCIDs cc
	ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE	TranDate BETWEEN DATEADD(MONTH,-12,DATEADD(DAY,-14,GETDATE())) AND DATEADD(DAY,-14,GETDATE())
	AND ISRefund = 0 --- exclude refunds

CREATE CLUSTERED INDEX IDX_CD ON #TransLast12m (CINID)
CREATE NONCLUSTERED INDEX IDX_BD ON #TransLast12m (BrandID)


/**************************************************
*****Approach 1: Building a Spend Distribution*****
**************************************************/
IF OBJECT_ID('tempdb..#ATVTrans0') IS NOT NULL DROP TABLE #ATVTrans0
SELECT 
floor (1.0*amount) ATV
, SUM(amount) Value
, count(1) as Trans
INTO #ATVTrans0
FROM #TransLast12m tr
GROUP BY floor (1.0*amount) 
order by  floor (1.0*amount) 

--select top 100 * from #ATVTrans0 order by brandid,  ATV  -- rounded


/* Add Total Spedners and Sales for the segment*/
IF OBJECT_ID('tempdb..#ATVTrans1') IS NOT NULL DROP TABLE #ATVTrans1
SELECT b.*
, SUM(Trans) OVER () Total_Trans
,SUM(Value) OVER () Total_Value
INTO #ATVTrans1 
FROM #ATVTrans0 b

CREATE INDEX IND_ATVTrans1_ATV on #ATVTrans1(ATV);

/*Cumulative Sales and Spenders */

IF OBJECT_ID('tempdb..#ATVTrans2') IS NOT NULL DROP TABLE #ATVTrans2
SELECT  
t1.ATV, 
1.0*SUM(t2.Trans)/t1.Total_Trans as Perc_Trans,
1.0*SUM(t2.Value)/t1.Total_Value as Perc_Value,
t1.Total_Trans
INTO #ATVTrans2
FROM #ATVTrans1 t1
INNER JOIN  #ATVTrans1 t2
ON t1.ATV <= t2.ATV 
GROUP BY t1.ATV, t1.Total_Trans, t1.Total_Value, t1.Total_Trans

-- 0s
--select top 100 * from #ATVTrans2

-- % customers and sales above certain transaction value
IF OBJECT_ID('tempdb..#TempSpendStretch') IS NOT NULL DROP TABLE #TempSpendStretch
SELECT 
COALESCE(MIN(CASE WHEN Perc_Trans <=0.00 THEN ATV END),MAX(ATV),0) Trans_p_00,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.05 THEN ATV END),MAX(ATV),0) Trans_p_05,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.10 THEN ATV END),MAX(ATV),0) Trans_p_10,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.15 THEN ATV END),MAX(ATV),0) Trans_p_15,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.20 THEN ATV END),MAX(ATV),0) Trans_p_20,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.25 THEN ATV END),MAX(ATV),0) Trans_p_25,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.30 THEN ATV END),MAX(ATV),0) Trans_p_30,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.35 THEN ATV END),MAX(ATV),0) Trans_p_35,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.40 THEN ATV END),MAX(ATV),0) Trans_p_40,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.45 THEN ATV END),MAX(ATV),0) Trans_p_45,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.50 THEN ATV END),MAX(ATV),0) Trans_p_50,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.55 THEN ATV END),MAX(ATV),0) Trans_p_55,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.60 THEN ATV END),MAX(ATV),0) Trans_p_60,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.65 THEN ATV END),MAX(ATV),0) Trans_p_65,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.70 THEN ATV END),MAX(ATV),0) Trans_p_70,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.75 THEN ATV END),MAX(ATV),0) Trans_p_75,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.80 THEN ATV END),MAX(ATV),0) Trans_p_80,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.85 THEN ATV END),MAX(ATV),0) Trans_p_85,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.90 THEN ATV END),MAX(ATV),0) Trans_p_90,
COALESCE(MIN(CASE WHEN Perc_Trans <=0.95 THEN ATV END),MAX(ATV),0) Trans_p_95,
COALESCE(MIN(CASE WHEN Perc_Trans <=1.00 THEN ATV END),MAX(ATV),0) Trans_p_100,
COALESCE(MIN(CASE WHEN Perc_Value <=0.00 THEN ATV END),MAX(ATV),0) Sales_p_00,
COALESCE(MIN(CASE WHEN Perc_Value <=0.05 THEN ATV END),MAX(ATV),0) Sales_p_05,
COALESCE(MIN(CASE WHEN Perc_Value <=0.10 THEN ATV END),MAX(ATV),0) Sales_p_10,
COALESCE(MIN(CASE WHEN Perc_Value <=0.15 THEN ATV END),MAX(ATV),0) Sales_p_15,
COALESCE(MIN(CASE WHEN Perc_Value <=0.20 THEN ATV END),MAX(ATV),0) Sales_p_20,
COALESCE(MIN(CASE WHEN Perc_Value <=0.25 THEN ATV END),MAX(ATV),0) Sales_p_25,
COALESCE(MIN(CASE WHEN Perc_Value <=0.30 THEN ATV END),MAX(ATV),0) Sales_p_30,
COALESCE(MIN(CASE WHEN Perc_Value <=0.35 THEN ATV END),MAX(ATV),0) Sales_p_35,
COALESCE(MIN(CASE WHEN Perc_Value <=0.40 THEN ATV END),MAX(ATV),0) Sales_p_40,
COALESCE(MIN(CASE WHEN Perc_Value <=0.45 THEN ATV END),MAX(ATV),0) Sales_p_45,
COALESCE(MIN(CASE WHEN Perc_Value <=0.50 THEN ATV END),MAX(ATV),0) Sales_p_50,
COALESCE(MIN(CASE WHEN Perc_Value <=0.55 THEN ATV END),MAX(ATV),0) Sales_p_55,
COALESCE(MIN(CASE WHEN Perc_Value <=0.60 THEN ATV END),MAX(ATV),0) Sales_p_60,
COALESCE(MIN(CASE WHEN Perc_Value <=0.65 THEN ATV END),MAX(ATV),0) Sales_p_65,
COALESCE(MIN(CASE WHEN Perc_Value <=0.70 THEN ATV END),MAX(ATV),0) Sales_p_70,
COALESCE(MIN(CASE WHEN Perc_Value <=0.75 THEN ATV END),MAX(ATV),0) Sales_p_75,
COALESCE(MIN(CASE WHEN Perc_Value <=0.80 THEN ATV END),MAX(ATV),0) Sales_p_80,
COALESCE(MIN(CASE WHEN Perc_Value <=0.85 THEN ATV END),MAX(ATV),0) Sales_p_85,
COALESCE(MIN(CASE WHEN Perc_Value <=0.90 THEN ATV END),MAX(ATV),0) Sales_p_90,
COALESCE(MIN(CASE WHEN Perc_Value <=0.95 THEN ATV END),MAX(ATV),0) Sales_p_95,
COALESCE(MIN(CASE WHEN Perc_Value <=1.00 THEN ATV END),MAX(ATV),0) Sales_p_100
--MAX(COALESCE(Total_Spenders,0)) Total_Spenders
INTO #TempSpendStretch
FROM #ATVTrans2 c

-- 0s
insert into #Output_SSResults
select 
@brandID as brandID
,* 
from #TempSpendStretch

--print @rowno
set @rowno = @rowno+1
--print @rowno

END
--- Comments in line with campaign forecasting tool
-- Not sure about the spenders here, being calculated as 

--select * from #Output_SSResults

INSERT INTO Prototype.ROCP2_SSByBrand
SELECT *
FROM #Output_SSResults


----------------------------------------------------------------------------------------------------
------   OUTPUT 
-----------------------------------------------------------------------------------------------------
/*

SELECT 'Copy below results to columns A13 on DataSS' Instructions
select * 
from Staging.ROCP2_SSByBrand
*/

END

