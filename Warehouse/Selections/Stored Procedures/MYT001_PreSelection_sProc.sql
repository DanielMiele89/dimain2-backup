-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-05-14>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.MYT001_PreSelection_sProcASBEGIN	--	Premier Reward Account holders

	IF OBJECT_ID('tempdb..#PremierCustomers') IS NOT NULL DROP TABLE #PremierCustomers
	SELECT FanID
	INTO #PremierCustomers
	FROM Relational.Customer_RBSGSegments
	WHERE EndDate IS NULL
	AND CustomerSegment LIKE '%V%'

	--	Black Reward customers 

	IF OBJECT_ID('tempdb..#RewardBlack') IS NOT NULL DROP TABLE #RewardBlack
	SELECT cu.FanID
	INTO #RewardBlack
	FROM [Relational].[Customer] cu
	INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
		ON cu.SourceUID = ic.SourceUID
		AND ((cu.ClubID = 132 AND IssuerID = 2) OR (cu.ClubID = 138 AND IssuerID = 1))
	INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
		ON ic.ID = iba.IssuerCustomerID
		AND iba.CustomerStatus = 1
	INNER JOIN [slc_report].[dbo].[BankAccountTypeHistory] bat
		ON iba.BankAccountID = bat.BankAccountID
		AND bat.EndDate IS NULL
		AND bat.Type IN ('QE')

	--	Core base- target AB Cameo Profile

	IF OBJECT_ID('tempdb..#CoreAB') IS NOT NULL DROP TABLE #CoreAB
	SELECT cu.FanID
	INTO #CoreAB
	FROM [Relational].[Customer] cu
	INNER JOIN Relational.CAMEO ca
		ON ca.Postcode = cu.PostCode
	INNER JOIN Relational.CAMEO_CODE cc
		ON cc.CAMEO_CODE = ca.CAMEO_CODE
	WHERE cc.Social_Class = 'AB'

	--	All customers
	
	IF OBJECT_ID('tempdb..#AllCustomers') IS NOT NULL DROP TABLE #AllCustomers
	SELECT FanID
	INTO #AllCustomers
	FROM [Relational].[Customer] cu
	WHERE EXISTS (	SELECT 1
					FROM #CoreAB co
					WHERE cu.FanID = co.FanID)
	OR EXISTS (		SELECT 1
					FROM #RewardBlack rb
					WHERE cu.FanID = rb.FanID)
	OR EXISTS (		SELECT 1
					FROM #PremierCustomers pc
					WHERE cu.FanID = pc.FanID)If Object_ID('Warehouse.Selections.MYT001_PreSelection') Is Not Null Drop Table Warehouse.Selections.MYT001_PreSelectionSelect FanIDInto Warehouse.Selections.MYT001_PreSelectionFROM  #ALLCUSTOMERSEND