

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 02/07/2015
-- Description: Find unbranded Websites which we can assign brands to
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0083_Unbranded_Website_BrandSuggestions]
									
AS
BEGIN
	SET NOCOUNT ON;


/************************************************************************
******************************Initial Script*****************************
************************************************************************/
IF OBJECT_ID ('tempdb..#HighlightedBrands') IS NOT NULL DROP TABLE #HighlightedBrands
SELECT  cc.ConsumerCombinationID,
	cc.MID,
        cc.Narrative,
        cc.LocationCountry,
        b.BrandID,
        b.brandname,
	bs.SectorName as BrandSectorName,
	cc.MCCID
INTO #HighlightedBrands
FROM Warehouse.Relational.ConsumerCombination cc (NOLOCK)
INNER JOIN Warehouse.Relational.Brand b
      ON cc.narrative LIKE 'WWW.'+REPLACE(BrandName,' ','')+'%'
INNER JOIN Warehouse.Relational.BrandSector bs
	ON b.SectorID = bs.SectorID
WHERE	cc.brandid = 944 
	AND Narrative LIKE 'WWW.%' 
	AND LEN(BrandName) >= 9

CREATE CLUSTERED INDEX IDX_HB ON #HighlightedBrands (ConsumerCombinationID)

/************************************************************************
****************************Finding Trans Ever***************************
************************************************************************/
IF OBJECT_ID ('tempdb..#BrandSpendEver') IS NOT NULL DROP TABLE #BrandSpendEver
SELECT	hb.ConsumerCombinationID,
	SUM(ct.Amount) as TransactionAmount,
	COUNT(1) as Transactions
INTO #BrandSpendEver
FROM #HighlightedBrands hb
INNER JOIN Warehouse.Relational.ConsumerTransaction ct (NOLOCK)
	ON hb.ConsumerCombinationID = ct.ConsumerCombinationID
GROUP BY hb.ConsumerCombinationID


/************************************************************************
****************************Finding Trans LY*****************************
************************************************************************/
IF OBJECT_ID ('tempdb..#BrandSpendLY') IS NOT NULL DROP TABLE #BrandSpendLY
SELECT	hb.ConsumerCombinationID,
	SUM(ct.Amount) as TransactionAmount,
	COUNT(1) as Transactions
INTO #BrandSpendLY
FROM #HighlightedBrands hb
INNER JOIN Warehouse.Relational.ConsumerTransaction ct (NOLOCK)
	ON hb.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE	ct.TranDate BETWEEN DATEADD(YEAR,-1,DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(GETDATE()))+1,CAST(GETDATE() AS DATE))))  
			AND DATEADD(DAY,-DAY(GETDATE()),CAST(GETDATE() AS DATE))
GROUP BY hb.ConsumerCombinationID


SELECT	MID,
        Narrative,
        LocationCountry,
        BrandID as Suggested_BrandID,
        BrandName as Suggested_BrandName,
	BrandSectorName,
	MCCDesc as MCCDescription,
	SUM(bse.TransactionAmount) as TransactionAmount_Ever,
	SUM(bse.Transactions) as Transactions_Ever,
	SUM(bsl.TransactionAmount) as TransactionAmount_LastYear,
	SUM(bsl.Transactions) as Transactions_LastYear	
FROM #HighlightedBrands hb
INNER JOIN Warehouse.Relational.MCCList mcc
	ON hb.MCCID = mcc.MCCID
LEFT OUTER JOIN #BrandSpendEver bse
	ON hb.ConsumerCombinationID = bse.ConsumerCombinationID
LEFT OUTER JOIN #BrandSpendLY bsl
	ON hb.ConsumerCombinationID = bsl.ConsumerCombinationID
GROUP BY MID, Narrative, LocationCountry, BrandID, BrandName, BrandSectorName, MCCDesc
ORDER BY BrandID


END