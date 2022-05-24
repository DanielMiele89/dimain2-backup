

CREATE PROCEDURE [SmartEmail].[TriggerEmail_MobileDormant_Retrospective] (@SendDate DATE)
AS 
BEGIN

	--	Testing
	--	DECLARE @SendDate DATE = '2020-10-13'

/*******************************************************************************************************************************************
	1.	Fetch eligible customers
*******************************************************************************************************************************************/

	DECLARE @ThreeMonthsAgo DATE = DATEADD(MONTH, -3, @SendDate)
	
	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
	SELECT *
	INTO #Customer
	FROM [Relational].[Customer] cu
	WHERE EXISTS (	SELECT iom.CompositeID
					FROM [SLC_Report].[dbo].[IronOfferMember] iom
					WHERE iom.IronOfferID IN (18295, 18296, 18297, 18298)
					AND iom.CompositeID = cu.CompositeID
					AND EndDate IS NULL
					GROUP BY iom.CompositeID
					HAVING MIN(StartDate) < @ThreeMonthsAgo)

	CREATE CLUSTERED INDEX CIX_FanID ON #Customer (FanID)

	IF OBJECT_ID('tempdb..#LoyaltyAccountCustomers') IS NOT NULL DROP TABLE #LoyaltyAccountCustomers
	SELECT	te.FanID
		,	fa.CompositeID
		,	fa.SourceUID
		,	te.LoyaltyAccount
		,	iba.BankAccountID
		,	bat.Type
	INTO #LoyaltyAccountCustomers
	FROM #Customer cu
	LEFT JOIN [SmartEmail].[TriggerEmailDailyFile_Calculated] te
		ON cu.FanID = te.FanID
	INNER JOIN [SLC_Report].[dbo].[Fan] fa
		ON cu.FanID = fa.ID
	INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
		ON fa.SourceUID = ic.SourceUID
		AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)
	INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
		ON ic.ID = iba.IssuerCustomerID
		AND iba.CustomerStatus = 1
	INNER JOIN [SLC_Report].[dbo].[BankAccountTypeHistory] bat
		ON iba.BankAccountID = bat.BankAccountID
		AND bat.EndDate IS NULL
	WHERE te.LoyaltyAccount = 1
	AND bat.Type IN ('QA', 'QB', 'QC', 'QD', 'QE')

	CREATE CLUSTERED INDEX CIX_FanID ON #LoyaltyAccountCustomers (FanID)


/*******************************************************************************************************************************************
	2.	Fetch customers that have earnt in the last 3 months
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		2.1.  Fetch the actual customers that earnt
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#EarntInLast3Months_Bank') IS NOT NULL DROP TABLE #EarntInLast3Months_Bank
		SELECT	BankAccountID
			,	FanID
		INTO #EarntInLast3Months_Bank
		FROM [SmartEmail].[TriggerEmail_MobileDDEarnDates] fe
		WHERE LastEarnDate > @ThreeMonthsAgo
		AND EarnType = 'Mobile Login'
	
		CREATE CLUSTERED INDEX CIX_BankAccountID ON #EarntInLast3Months_Bank (BankAccountID)
		CREATE NONCLUSTERED INDEX IX_BFanID ON #EarntInLast3Months_Bank (FanID)


	/***********************************************************************************************************************
		2.2.  Fetch customers that are linked to the customers that have earnt
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#EarntInLast3Months_Fan') IS NOT NULL DROP TABLE #EarntInLast3Months_Fan
		SELECT	DISTINCT
				fa.ID AS FanID
		INTO #EarntInLast3Months_Fan
		FROM #EarntInLast3Months_Bank el3
		INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
			ON el3.BankAccountID = iba.BankAccountID
			AND iba.CustomerStatus = 1
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON ic.SourceUID = fa.SourceUID
			AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)

		CREATE CLUSTERED INDEX CIX_FanID ON #EarntInLast3Months_Fan (FanID)

/*******************************************************************************************************************************************
	3.	Fetch eligible customers that have not earnt in the last three months
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#CustomersWhoHaveNotEarnt') IS NOT NULL DROP TABLE #CustomersWhoHaveNotEarnt
	SELECT	DISTINCT
			lac.FanID
		,	lac.CompositeID
		,	lac.SourceUID
	INTO #CustomersWhoHaveNotEarnt
	FROM #LoyaltyAccountCustomers lac
	INNER JOIN [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] dd
		ON lac.FanID = dd.FanID
	WHERE NOT EXISTS (	SELECT 1
						FROM #EarntInLast3Months_Bank el3
						WHERE lac.BankAccountID = el3.BankAccountID)
	AND NOT EXISTS (	SELECT 1
						FROM #EarntInLast3Months_Bank el3
						WHERE lac.FanID = el3.FanID)
	AND NOT EXISTS (	SELECT 1
						FROM #EarntInLast3Months_Fan el3
						WHERE lac.FanID = el3.FanID)
	AND dd.Nominee = 1

	CREATE CLUSTERED INDEX CIX_FanID ON #CustomersWhoHaveNotEarnt (SourceUID)
	

/*******************************************************************************************************************************************
	4.	Remove customers that have loged in in the last three days but have not had that login processed yet
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		4.1.  Fetch the actual customers that logged in
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#MobileLogin') IS NOT NULL DROP TABLE #MobileLogin
		SELECT	c.FanID
			,	c.CompositeID
			,	c.SourceUID
			,	MAX(ml.EventDateTime) AS EventDateTime
		INTO #MobileLogin
		FROM [Staging].[MobileLogins] ml
		INNER JOIN [Relational].[Customer] c
			ON ml.CustomerID = c.SourceUID
		WHERE EXISTS (	SELECT 1 
						FROM #CustomersWhoHaveNotEarnt c
						WHERE ml.CustomerID = c.SourceUID)
		GROUP BY	c.FanID
				,	c.CompositeID
				,	c.SourceUID
		HAVING @ThreeMonthsAgo < MAX(ml.EventDateTime)

		CREATE CLUSTERED INDEX CIX_FanID ON #MobileLogin (FanID)


	/***********************************************************************************************************************
		4.2.  Fetch the bank accounts of the customers who have logged in
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#MobileLogin_Bank') IS NOT NULL DROP TABLE #MobileLogin_Bank
		SELECT	DISTINCT
				iba.BankAccountID
		INTO #MobileLogin_Bank
		FROM #MobileLogin ml
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON ml.FanID = fa.ID
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON fa.SourceUID = ic.SourceUID
			AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)
		INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
			ON ic.ID = iba.IssuerCustomerID
			AND iba.CustomerStatus = 1

		CREATE CLUSTERED INDEX CIX_BankAccountID ON #MobileLogin_Bank (BankAccountID)


	/***********************************************************************************************************************
		4.3.  Fetch the bank accounts of the customers who have logged in
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#MobileLogin_Fan') IS NOT NULL DROP TABLE #MobileLogin_Fan
		SELECT	DISTINCT
				fa.ID AS FanID
		INTO #MobileLogin_Fan
		FROM #MobileLogin_Bank el3
		INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
			ON el3.BankAccountID = iba.BankAccountID
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON ic.SourceUID = fa.SourceUID
			AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)

		CREATE CLUSTERED INDEX CIX_FanID ON #MobileLogin_Fan (FanID)


	/***********************************************************************************************************************
		4.4.  Fetch the bank accounts of the customers who have logged in
	***********************************************************************************************************************/

		DELETE cu
		FROM #MobileLogin_Fan ml
		INNER JOIN #CustomersWhoHaveNotEarnt cu
			ON cu.FanID = ml.FanID
	

/*******************************************************************************************************************************************
	5.	Remove customers that have been emailed in the last 3 months
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		5.1.  Fetch the actual customers that logged in
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#TriggerEmailCustomers') IS NOT NULL DROP TABLE #TriggerEmailCustomers
		SELECT	FanID
		INTO #TriggerEmailCustomers
		FROM [SmartEmail].[DailyData_TriggerEmailCustomers] tec
		WHERE SendDate > @ThreeMonthsAgo
		AND TriggerEmail = 'Mobile Dormant'
	
		CREATE CLUSTERED INDEX CIX_FanID ON #TriggerEmailCustomers (FanID)


	/***********************************************************************************************************************
		5.2.  Fetch the bank accounts of the customers who have logged in
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#TriggerEmailCustomers_Bank') IS NOT NULL DROP TABLE #TriggerEmailCustomers_Bank
		SELECT	DISTINCT
				iba.BankAccountID
		INTO #TriggerEmailCustomers_Bank
		FROM #TriggerEmailCustomers ml
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON ml.FanID = fa.ID
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON fa.SourceUID = ic.SourceUID
			AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)
		INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
			ON ic.ID = iba.IssuerCustomerID
			AND iba.CustomerStatus = 1

		CREATE CLUSTERED INDEX CIX_BankAccountID ON #TriggerEmailCustomers_Bank (BankAccountID)


	/***********************************************************************************************************************
		5.3.  Fetch the bank accounts of the customers who have logged in
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#TriggerEmailCustomers_Fan') IS NOT NULL DROP TABLE #TriggerEmailCustomers_Fan
		SELECT	DISTINCT
				fa.ID AS FanID
		INTO #TriggerEmailCustomers_Fan
		FROM #TriggerEmailCustomers_Bank el3
		INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
			ON el3.BankAccountID = iba.BankAccountID
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON ic.SourceUID = fa.SourceUID
			AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)

		CREATE CLUSTERED INDEX CIX_FanID ON #TriggerEmailCustomers_Fan (FanID)


	/***********************************************************************************************************************
		5.4.  Fetch the bank accounts of the customers who have logged in
	***********************************************************************************************************************/

		DELETE cu
		FROM #TriggerEmailCustomers_Fan ml
		INNER JOIN #CustomersWhoHaveNotEarnt cu
			ON cu.FanID = ml.FanID


/*******************************************************************************************************************************************
	6.	Insert remaining customers to table for SFD Daily File population
*******************************************************************************************************************************************/
	
		DECLARE @Today DATE = GETDATE()
		
		--TRUNCATE TABLE [SmartEmail].[TriggerEmail_MobileDormantCustomers]
		INSERT INTO [SmartEmail].[TriggerEmail_MobileDormantCustomers] (FanID
																	,	MobileDormantDate)
		SELECT	FanID
			,	@SendDate
		FROM #CustomersWhoHaveNotEarnt

END