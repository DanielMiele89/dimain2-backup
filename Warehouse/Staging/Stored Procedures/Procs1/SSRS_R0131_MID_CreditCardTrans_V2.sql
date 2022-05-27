

-- ***************************************************************************--
-- ***************************************************************************--
-- Author:		Ijaz Amjad													  --
-- Create date: 23/09/2016													  --
-- Description: Shows MID Data for Credit Card Transactions					  --
-- ***************************************************************************--
-- ***************************************************************************--
CREATE PROCEDURE [Staging].[SSRS_R0131_MID_CreditCardTrans_V2](@MID VARCHAR(MAX))
With execute as owner
AS
BEGIN

	--DECLARE @MID VARCHAR(MAX) = '30996425,30996505'
	DECLARE	@MerchantID VARCHAR(MAX)

	SET @MerchantID = REPLACE(@MID, ' ', '')

	IF OBJECT_ID ('tempdb..#SplitStringMIDs') IS NOT NULL DROP TABLE #SplitStringMIDs
	SELECT m.Item AS MerchantID
	INTO #SplitStringMIDs
	FROM dbo.il_SplitDelimitedStringArray (@MerchantID, ',') m

	CREATE CLUSTERED INDEX CIX_MID ON #SplitStringMIDs (MerchantID)

	IF OBJECT_ID ('tempdb..#MIDs') IS NOT NULL DROP TABLE #MIDs
	SELECT DISTINCT
		   m.MerchantID AS MerchantID_Searched
		 , cc.MID AS MerchantID_Found
	INTO #MIDs
	FROM #SplitStringMIDs m
	INNER JOIN Relational.ConsumerCombination cc
		ON COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(INT, cc.MID)), cc.MID) = COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(INT, m.MerchantID)), m.MerchantID)

	INSERT INTO #MIDs
	SELECT DISTINCT
		   ssm.MerchantID AS MerchantID_Searched
		 , ro.MerchantID AS MerchantID_Found
	FROM #SplitStringMIDs ssm
	INNER JOIN SLC_REPL..RetailOutlet ro
		ON COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(INT, ro.MerchantID)), ro.MerchantID) = COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(INT, ssm.MerchantID)), ssm.MerchantID)
	WHERE NOT EXISTS (SELECT 1
					  FROM #MIDs m
					  WHERE ssm.MerchantID = m.MerchantID_Searched
					  AND ro.MerchantID = m.MerchantID_Found)

	CREATE CLUSTERED INDEX CIX_MerchantID_Found ON #MIDs (MerchantID_Found)


	IF OBJECT_ID ('tempdb..#CTH') IS NOT NULL DROP TABLE #CTH
	SELECT th.MerchantDBAName
		 , th.MerchantDBACity
		 , th.MerchantZip
		 , th.MerchantID
		 , th.TranDate
		 , m.MerchantID_Found
		 , m.MerchantID_Searched
	INTO #CTH
	FROM Archive_Light.dbo.CBP_Credit_TransactionHistory th
	INNER JOIN #MIDs m
		ON th.MerchantID = m.MerchantID_Found


	IF OBJECT_ID ('tempdb..#Info') IS NOT NULL DROP TABLE #Info
	SELECT MerchantID_Searched
		 , MerchantID_Found
		 , MerchantDBAName
		 , MerchantDBACity
		 , MerchantZip
		 , MIN(TranDate) AS FirstTranDate
		 , MAX(Trandate) AS LastTranDate
		 , COUNT(*) AS Transactions
	INTO #Info
	FROM #CTH
	GROUP BY MerchantID_Searched
		   , MerchantID_Found
		   , MerchantDBAName
		   , MerchantDBACity
		   , MerchantZip

	SELECT *
	FROM #Info
	ORDER BY MerchantID_Searched
		   , LastTranDate

END