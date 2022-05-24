
CREATE PROCEDURE [Selections].[NTV_PreSelection_sProc]
AS
BEGIN

/***********************************************************************************************************************
	Get the relevant telecom OINs
***********************************************************************************************************************/

	IF OBJECT_ID('tempdb..#CCD') IS NOT NULL DROP TABLE #CCD
	SELECT OIN
		 , ConsumerCombinationID_DD
	INTO #CCD
	FROM Relational.ConsumerCombination_DD
	WHERE BrandID = 395

	CREATE CLUSTERED INDEX CIX_DDs_OIN ON #CCD (ConsumerCombinationID_DD)


/***********************************************************************************************************************
	Fetch list of customer IDs for all transactions within the designated period
***********************************************************************************************************************/

	DECLARE @Today DATE
		  , @2MonthsAgo DATE

	SET @Today = GETDATE()
	SET @2MonthsAgo = DATEADD(month, -2, @Today)

	IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT
	SELECT DISTINCT
		   BankAccountID
		 , FanID
	INTO #CT
	FROM Relational.ConsumerTransaction_DD_MyRewards ct
	WHERE ct.TranDate >= @2MonthsAgo
	AND EXISTS (SELECT 1
				FROM #CCD cc
				WHERE ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD)

	CREATE CLUSTERED INDEX CIX_BA ON #CT (BankAccountID)


/***********************************************************************************************************************
	Fetch list of bank details for primary account holders
***********************************************************************************************************************/

	--IF OBJECT_ID('tempdb..#MFDD_Households') IS NOT NULL DROP TABLE #MFDD_Households
	--SELECT DISTINCT FanID
	--INTO #MFDD_Households
	--FROM Relational.MFDD_Households hh
	--WHERE EXISTS (SELECT 1 FROM #CT ct WHERE hh.FanID = ct.FanID)
	--AND EndDate IS NULL
	--UNION
	--SELECT DISTINCT FanID
	--FROM Relational.MFDD_Households hh
	--WHERE EXISTS (SELECT 1 FROM #CT ct WHERE hh.BankAccountID = ct.BankAccountID)
	--AND EndDate IS NULL

	--CREATE CLUSTERED INDEX CIX_FanID on #MFDD_Households (FanID)

	
	--IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	--SELECT *
	--INTO #Customers
	--FROM #MFDD_Households

	IF OBJECT_ID('tempdb..#IssuerBankAccount') IS NOT NULL DROP TABLE #IssuerBankAccount
	SELECT DISTINCT FanID
	INTO #IssuerBankAccount
	FROM #CT
	--UNION
	--SELECT DISTINCT FanID
	--FROM SLC_Report..IssuerBankAccount iba
	--INNER JOIN SLC_Report..IssuerCustomer ic
	--	ON iba.IssuerCustomerID = ic.ID
	--INNER JOIN Relational.Customer cu
	--	ON ic.SourceUID = cu.SourceUID
	--	AND cu.CurrentlyActive = 1
	--WHERE EXISTS (SELECT 1 FROM #CT ct WHERE iba.BankAccountID = ct.BankAccountID)

	CREATE CLUSTERED INDEX CIX_FanID on #IssuerBankAccount (FanID)

	
	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	SELECT *
	INTO #Customers
	FROM #IssuerBankAccount

/***********************************************************************************************************************
	Insert to Preselections table
***********************************************************************************************************************/
	
	IF OBJECT_ID('Warehouse.Selections.NTV_PreSelection_Exclusion') IS NOT NULL DROP TABLE Warehouse.Selections.NTV_PreSelection_Exclusion
	SELECT DISTINCT
		   dd.FanID
	INTO Warehouse.Selections.NTV_PreSelection_Exclusion
	FROM #Customers dd

END