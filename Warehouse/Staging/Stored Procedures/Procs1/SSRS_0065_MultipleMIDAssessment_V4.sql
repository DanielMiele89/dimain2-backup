/*
		Author:			Stuart Barnley
		Date:			18-03-2015

		Purpose:		To assess one MID and return occurances on ConsumerTransactions

*/

CREATE PROCEDURE [Staging].[SSRS_0065_MultipleMIDAssessment_V4] (@MID VARCHAR(MAX))
AS
BEGIN
--------------------------------------------------------------------------------
---------------------------------Create table of MIDs---------------------------
--------------------------------------------------------------------------------

	--DECLARE @MID VARCHAR(MAX) = '09941523,34714202,12094875'
	DECLARE @MerchantID VARCHAR(MAX)
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

--------------------------------------------------------------------------------
-------------------Find a list of Consumer Combination IDs----------------------
--------------------------------------------------------------------------------

	IF OBJECT_ID ('tempdb..#CCs') IS NOT NULL DROP TABLE #CCs
	SELECT m.MerchantID_Searched
		 , m.MerchantID_Found
		 , cc.ConsumerCombinationID
		 , cc.Narrative
		 , cc.LocationCountry
		 , mcc.MCC
		 , mcc.MCCDesc
		 , b.BrandID
		 , b.BrandName
	INTO #CCs
	FROM #MIDs m
	LEFT JOIN Relational.ConsumerCombination cc
		ON m.MerchantID_Found = cc.MID
	LEFT JOIN Relational.MCCList mcc
		ON cc.MCCID = mcc.MCCID
	LEFT JOIN Relational.Brand b
		ON cc.BrandID = b.BrandID

	CREATE CLUSTERED INDEX IDX_CCs_CCID ON #CCs (ConsumerCombinationID)

--------------------------------------------------------------------------------
-------------------------Return Transactional Data------------------------------
--------------------------------------------------------------------------------

	IF OBJECT_ID ('tempdb..#TranInfo') IS NOT NULL DROP TABLE #TranInfo;
	WITH
	ConsumerTransaction AS (SELECT cc.MerchantID_Searched
							 		, cc.MerchantID_Found
							 		, cc.Narrative
							 		, cc.LocationCountry
							 		, cc.MCC
							 		, cc.MCCDesc
							 		, cc.BrandID
							 		, cc.BrandName
							 		, MIN(Trandate) AS FirstTrans
							 		, MAX(Trandate) AS LastTrans
							 		, COUNT(ct.ConsumerCombinationID) AS TranCount_Total
							 		, COALESCE(SUM(Amount), 0) AS TranAmount_Total
									, SUM(CASE WHEN ct.CardholderPresentData = 5 THEN 1 ELSE 0 END) TranCount_Online
									, SUM(CASE WHEN ct.CardholderPresentData = 5 THEN Amount ELSE 0 END) TranAmount_Online
									, SUM(CASE WHEN ct.CardholderPresentData != 5 THEN 1 ELSE 0 END) TranCount_Offline
									, SUM(CASE WHEN ct.CardholderPresentData != 5 THEN Amount ELSE 0 END) TranAmount_Offline
							FROM #CCs cc
							LEFT JOIN Relational.ConsumerTransaction ct
								ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
							GROUP BY cc.MerchantID_Searched
									 , cc.MerchantID_Found
									 , cc.Narrative
									 , cc.LocationCountry
									 , cc.MCC
									 , cc.MCCDesc
									 , cc.BrandID
									 , cc.BrandName),

	ConsumerTransactionHolding AS (SELECT cc.MerchantID_Searched
							   	 		, cc.MerchantID_Found
							   	 		, cc.Narrative
							   	 		, cc.LocationCountry
							   	 		, cc.MCC
							   	 		, cc.MCCDesc
							   	 		, cc.BrandID
							   	 		, cc.BrandName
							   	 		, MIN(Trandate) AS FirstTrans
							   	 		, MAX(Trandate) AS LastTrans
							   	 		, COUNT(ct.ConsumerCombinationID) AS TranCount_Total
							   	 		, COALESCE(SUM(Amount), 0) AS TranAmount_Total
										, SUM(CASE WHEN ct.CardholderPresentData = 5 THEN 1 ELSE 0 END) TranCount_Online
										, SUM(CASE WHEN ct.CardholderPresentData = 5 THEN Amount ELSE 0 END) TranAmount_Online
										, SUM(CASE WHEN ct.CardholderPresentData != 5 THEN 1 ELSE 0 END) TranCount_Offline
										, SUM(CASE WHEN ct.CardholderPresentData != 5 THEN Amount ELSE 0 END) TranAmount_Offline
								   FROM #CCs cc
								   LEFT JOIN Relational.ConsumerTransactionHolding ct
										ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
								   GROUP BY cc.MerchantID_Searched
							   			  , cc.MerchantID_Found
							   			  , cc.Narrative
							   			  , cc.LocationCountry
							   			  , cc.MCC
							   			  , cc.MCCDesc
							   			  , cc.BrandID
							   			  , cc.BrandName)

	SELECT MerchantID_Searched
		 , MerchantID_Found
		 , Narrative
		 , LocationCountry
		 , MCC
		 , MCCDesc
		 , BrandID
		 , BrandName
		 , MIN(FirstTrans) AS FirstTrans
		 , MAX(LastTrans) AS LastTrans
		 , SUM(TranCount_Total) AS TranCount_Total
		 , SUM(TranAmount_Total) AS TranAmount_Total
		 , SUM(TranCount_Online) AS TranCount_Online
		 , SUM(TranAmount_Online) AS TranAmount_Online
		 , SUM(TranCount_Offline) AS TranCount_Offline
		 , SUM(TranAmount_Offline) AS TranAmount_Offline
	INTO #TranInfo
	FROM (SELECT *
		  FROM ConsumerTransaction
		  UNION ALL
		  SELECT *
		  FROM ConsumerTransactionHolding) ct
	GROUP BY MerchantID_Searched
		   , MerchantID_Found
		   , Narrative
		   , LocationCountry
		   , MCC
		   , MCCDesc
		   , BrandID
		   , BrandName

--------------------------------------------------------------------------------
-----------------------------------Output---------------------------------------
--------------------------------------------------------------------------------

	SELECT REPLACE(MerchantID_Searched, ' ', '') AS MerchantID_Searched
		 , REPLACE(MerchantID_Found, ' ', '') AS MerchantID_Found
		 , Narrative
		 , LocationCountry
		 , MCC
		 , MCCDesc
		 , BrandID
		 , BrandName
		 , FirstTrans
		 , LastTrans
		 , TranCount_Total
		 , TranAmount_Total
		 , TranCount_Online
		 , TranAmount_Online
		 , TranCount_Offline
		 , TranAmount_Offline
	FROM #TranInfo
	ORDER BY MerchantID_Searched
		   , MerchantID_Found
		   , LastTrans

END