

-- *****************************************************************************************************
-- Author: Ijaz Amjad
-- Create date: 30/03/2016
-- Description: IN-PROGRESS
-- *****************************************************************************************************
CREATE PROCEDURE [Prototype].[SSRS_R0080_Test_Unbranded_BrandSuggestions_SingleBrand](
			@BrandIDs INT)
									
AS
BEGIN
	SET NOCOUNT ON;

/***********************************************
******Create Brands to Be Assessed Table********
***********************************************/
--CREATE TABLE #Brands (BrandID VARCHAR(20))

--WHILE @BrandIDs LIKE '%,%'
--BEGIN
--	INSERT INTO #Brands
--	SELECT  SUBSTRING(@BrandIDs,1,CHARINDEX(',',@BrandIDs)-1)
--	SET @BrandIDs = (SELECT  SUBSTRING(@BrandIDs,CHARINDEX(',',@BrandIDs)+1,LEN(@BrandIDs)))
--END
--	INSERT INTO #Brands
--	SELECT @BrandIDs

DECLARE @BrandID INT
SET @BrandID = @BrandIDs


IF OBJECT_ID ('tempdb..#BrandsToBeAssessed') IS NOT NULL DROP TABLE #BrandsToBeAssessed
SELECT	bm.BrandID,
	cc.BrandID as CC_BrandID,
	cc.ConsumerCombinationID,
	cc.Narrative,
	mcc.MCCDesc
INTO #BrandsToBeAssessed
FROM Warehouse.Staging.BrandMatch bm
INNER JOIN Warehouse.Relational.ConsumerCombination cc
      ON cc.Narrative like bm.Narrative
--INNER JOIN #Brands b
	--ON bm.BrandID = b.BrandID
INNER JOIN Warehouse.Relational.MCCList MCC
      ON cc.MCCID = mcc.MCCID
WHERE	cc.BrandID = 944 
	AND LocationCountry = 'GB' 
	AND bm.BrandID = @BrandID
ORDER BY bm.BrandID

CREATE CLUSTERED INDEX IDX_CCID ON #BrandsToBeAssessed (ConsumerCombinationID)



IF OBJECT_ID ('tempdb..#BrandTransAll') IS NOT NULL DROP TABLE #BrandTransAll
SELECT	BrandID,
	CC_BrandID,
	bt.ConsumerCombinationID,
	Narrative,
	MCCDesc as MCCDescription,
	MAX(TranDate) as LastTransaction,
	SUM(Amount) as TransactionAmount_All,
	COUNT(1) as Transactions_All,
	SUM(Amount)/COUNT(1) as ATV_All,
	CAST(COUNT(1) AS NUMERIC(32,2))/CAST(COUNT(DISTINCT CINID) AS NUMERIC(32,2)) as ATF_All
INTO #BrandTransAll
FROM #BrandsToBeAssessed bt
INNER JOIN Warehouse.Relational.ConsumerTransaction ct
	ON bt.ConsumerCombinationID = ct.ConsumerCombinationID
GROUP BY BrandID, CC_BrandID, bt.ConsumerCombinationID, Narrative, MCCDesc
ORDER BY BrandID



IF OBJECT_ID ('tempdb..#BrandTransLY') IS NOT NULL DROP TABLE #BrandTransLY
SELECT	bt.ConsumerCombinationID,
	SUM(Amount) as TransactionAmount_LastYear,
	COUNT(1) as Transactions_LastYear,
	SUM(Amount)/COUNT(1) as ATV_LastYear,
	CAST(COUNT(1) AS NUMERIC(32,2))/CAST(COUNT(DISTINCT CINID) AS NUMERIC(32,2)) as ATF_LastYear
INTO #BrandTransLY
FROM #BrandsToBeAssessed bt
INNER JOIN Warehouse.Relational.ConsumerTransaction ct
	ON bt.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE	ct.TranDate BETWEEN DATEADD(YEAR,-1,DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(GETDATE()))+1,CAST(GETDATE() AS DATE))))  
			AND DATEADD(DAY,-DAY(GETDATE()),CAST(GETDATE() AS DATE))
GROUP BY bt.ConsumerCombinationID



INSERT INTO [Prototype].[SSRS_R0080_Test_Unbranded_BrandSuggestions]	
SELECT	bt.BrandID as Suggested_BrandID,
	b.BrandName as Suggested_BrandName,
	bt.CC_BrandID,
	bt.ConsumerCombinationID,
	bt.Narrative,
	bt.MCCDescription,
	LastTransaction,
	TransactionAmount_LastYear,
	Transactions_LastYear,
	ATV_LastYear,
	ATF_LastYear,
	a.SectorName
FROM #BrandTransAll bt
INNER JOIN Warehouse.Relational.Brand b
	ON bt.BrandID = b.BrandID
LEFT OUTER JOIN [Prototype].[SSRS_R0080_Test_Unbranded_CCsToBeExcluded] u
	ON bt.ConsumerCombinationID = u.ConsumerCombinationID
LEFT OUTER JOIN #BrandTransLY bt2	
	ON bt.ConsumerCombinationID = bt2.ConsumerCombinationID
Left Outer join [Relational].[BrandSector] as a
	on b.SectorID = a.SectorID
WHERE u.ConsumerCombinationID IS NULL

END

--EXEC [Prototype].[SSRS_R0080_Test_Unbranded_BrandSuggestions_SingleBrand] '379'