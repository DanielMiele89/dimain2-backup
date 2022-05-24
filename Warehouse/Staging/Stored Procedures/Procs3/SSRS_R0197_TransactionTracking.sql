
CREATE PROCEDURE [Staging].[SSRS_R0197_TransactionTracking] (@PartnerID INT
														  , @VectorID INT)
AS 
BEGIN
	
	IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet
	SELECT ro.ID AS RetailOutletID
		 , pa.Name AS PartnerName
	INTO #RetailOutlet
	FROM SLC_REPL..RetailOutlet ro
	INNER JOIN SLC_REPL..Partner pa
		ON ro.PartnerID = pa.ID
	WHERE ro.PartnerID = @PartnerID
	OR @PartnerID IS NULL

	CREATE CLUSTERED INDEX CIX_RetailOutletID ON #RetailOutlet (RetailOutletID)


	IF OBJECT_ID('tempdb..#TransactionVector') IS NOT NULL DROP TABLE #TransactionVector
	SELECT tv.ID AS VectorID
		 , tv.Name AS Matcher
	INTO #TransactionVector
	FROM SLC_REPL..TransactionVector tv
	WHERE tv.ID = @VectorID
	OR @VectorID IS NULL

	CREATE CLUSTERED INDEX CIX_VectorID ON #TransactionVector (VectorID)	

	IF OBJECT_ID('tempdb..#Match') IS NOT NULL DROP TABLE #Match
	SELECT ro.PartnerName
		 , tv.Matcher
		 , ro.RetailOutletID
		 , ma.MerchantID
		 , MIN(TransactionDate) AS FirstTransaction
		 , MAX(TransactionDate) AS LastTransaction
		 , SUM(Amount) AS TotalAmount
	INTO #Match
	FROM SLC_Repl..Match ma
	INNER JOIN #RetailOutlet ro
		ON ro.RetailOutletID = ma.RetailOutletID
	INNER JOIN #TransactionVector tv
		ON tv.VectorID = ma.VectorID
	GROUP BY ro.PartnerName
		   , tv.Matcher
		   , ro.RetailOutletID
		   , ma.MerchantID

	SELECT PartnerName
		 , Matcher
		 , RetailOutletID
		 , MerchantID
		 , FirstTransaction
		 , LastTransaction
		 , TotalAmount
	FROM #Match

END