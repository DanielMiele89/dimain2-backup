-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-04-04>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[NMG001_PreSelection_sProc]ASBEGIN	IF OBJECT_ID('tempdb..#PaymentCardProductType') IS NOT NULL DROP TABLE #PaymentCardProductType
	SELECT	PaymentCardID
	INTO #PaymentCardProductType
	FROM [SLC_Report].[dbo].[PaymentCardProductType] pcpt
	WHERE ProductTypeID IN (2, 4)

	CREATE CLUSTERED INDEX CIX_PCID ON #PaymentCardProductType (PaymentCardID)

	IF OBJECT_ID('tempdb..#IssuerPaymentCard') IS NOT NULL DROP TABLE #IssuerPaymentCard
	SELECT	*
	INTO #IssuerPaymentCard
	FROM [SLC_Report].[dbo].[IssuerPaymentCard] ipc
	WHERE EXISTS (	SELECT 1
					FROM #PaymentCardProductType pcpt
					WHERE ipc.PaymentCardID = pcpt.PaymentCardID)
	AND ipc.Status = 1

	CREATE CLUSTERED INDEX CIX_IssuerCustomerID ON #IssuerPaymentCard (IssuerCustomerID)

		
	IF OBJECT_ID('tempdb..#BankAccountTypeHistory') IS NOT NULL DROP TABLE #BankAccountTypeHistory
	SELECT	bat.BankAccountID
	INTO #BankAccountTypeHistory
	FROM [SLC_Report].[dbo].[BankAccountTypeHistory] bat
	WHERE bat.EndDate IS NULL
	AND bat.Type IN ('QB', 'QE')

	CREATE CLUSTERED INDEX CIX_BankAccountID ON #BankAccountTypeHistory (BankAccountID)
	
	IF OBJECT_ID('tempdb..#IssuerBankAccount') IS NOT NULL DROP TABLE #IssuerBankAccount
	SELECT	iba.IssuerCustomerID
	INTO #IssuerBankAccount
	FROM [SLC_Report].[dbo].[IssuerBankAccount] iba
	WHERE CustomerStatus = 1
	AND EXISTS (SELECT 1
				FROM #BankAccountTypeHistory bat
				WHERE iba.BankAccountID = bat.BankAccountID)

	CREATE CLUSTERED INDEX CIX_IssuerCustomerID ON #IssuerBankAccount (IssuerCustomerID)

	IF OBJECT_ID('tempdb..#IssuerCustomer') IS NOT NULL DROP TABLE #IssuerCustomer
	SELECT	IssuerID
		,	SourceUID
	INTO #IssuerCustomer
	FROM [SLC_Report].[dbo].[IssuerCustomer] ic
	WHERE EXISTS (	SELECT 1
					FROM #IssuerPaymentCard ipc
					WHERE ic.ID = ipc.IssuerCustomerID)
	OR EXISTS (		SELECT 1
					FROM #IssuerBankAccount iba
					WHERE ic.ID = iba.IssuerCustomerID)
					
	CREATE CLUSTERED INDEX CIX_IssuerSourceUID ON #IssuerCustomer (IssuerID, SourceUID)

	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	SELECT	cu.FanID
	INTO #Customers
	FROM [Relational].[Customer] cu
	WHERE NOT EXISTS (	SELECT 1
						FROM #IssuerCustomer ic
						WHERE cu.SourceUID = ic.SourceUID
						AND CONCAT(cu.ClubID, ic.IssuerID) IN (1322, 1381))
	AND cu.CurrentlyActive = 1	If Object_ID('Warehouse.Selections.NMG001_PreSelection') Is Not Null Drop Table Warehouse.Selections.NMG001_PreSelection	Select FanID	Into Warehouse.Selections.NMG001_PreSelection	FROM  #CustomersEND