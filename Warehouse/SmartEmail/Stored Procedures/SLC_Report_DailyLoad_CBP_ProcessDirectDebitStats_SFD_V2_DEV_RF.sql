/*
		Author:			Stuart Barnley
		
		Date:			06th July 2015
		
		Description		This stored procedure finds Loyalty DD data
						

		-- CJM/NB 20161116 Perf
		-- CJM 20170203 Perf
		-- CJM 20180302 Perf
		-- RF 20200804 Perf
		
*/

CREATE PROCEDURE [SmartEmail].[SLC_Report_DailyLoad_CBP_ProcessDirectDebitStats_SFD_V2_DEV_RF]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @TodayDate DATE = GETDATE()
		,	@YesterdayDate DATE = DATEADD(DAY, -1, GETDATE())
		  , @TodayDateTime DATETIME = GETDATE()



/*******************************************************************************************************************************************
	1.	Fetch all DD Earning Eligible Customers
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		1.1.	Find list of all DD IronOffers
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#OffersAccountsAll') IS NOT NULL DROP TABLE #OffersAccountsAll
		SELECT	DISTINCT
				ba.IronOfferID
			,	iof.Name AS IronOfferName
			,	iof.StartDate
			,	iof.EndDate
		INTO #OffersAccountsAll
		FROM [SLC_Report].[dbo].[IronOffer] iof
		INNER JOIN [SLC_Report].[dbo].[BankAccountTypeEligibility] ba
			ON iof.ID = ba.IronOfferID
		INNER JOIN [SLC_Report].[dbo].[IronOfferClub] ioc
			ON iof.ID = ioc.IronOfferID
		WHERE iof.StartDate <= @TodayDate
		AND ba.DirectDebitEligible = 1

		-- (10 rows affected) / 00:00:00
		

	/***********************************************************************************************************************
		1.2.	Find list of eligible IronOffers AND AccountTypes
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#OffersAccounts') IS NOT NULL DROP TABLE #OffersAccounts
		SELECT ba.IronOfferID
			 , ba.BankAccountType
			 , ba.CustomerSegment
			 , ioc.ClubID
		INTO #OffersAccounts
		FROM [SLC_Report].[dbo].[IronOffer] i
		INNER JOIN [SLC_Report].[dbo].[BankAccountTypeEligibility] ba 
			ON i.ID = ba.IronOfferID
		INNER JOIN [SLC_Report].[dbo].IronOfferClub ioc
			ON i.ID = ioc.IronOfferID
		WHERE i.StartDate <= @TodayDateTime
		AND (i.EndDate >= @TodayDate OR i.EndDate IS NULL)
		AND ba.DirectDebitEligible = 1
		
		-- (10 rows affected) / 00:00:00
		

	/***********************************************************************************************************************
		1.3.	List of TranTypes AND ItemIDs
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#TranTypes') IS NOT NULL DROP TABLE #TranTypes
		SELECT TransactionTypeID
			 , ItemID
		INTO #TranTypes
		FROM Relational.AdditionalCashbackAwardType
		WHERE Title LIKE 'Direct Debit%'

		CREATE CLUSTERED INDEX ucx_Stuff ON #TranTypes (ItemID, TransactionTypeID)

		-- (4 rows affected) / 00:00:00
		

	/***********************************************************************************************************************
		1.4.	List IronOfferMember entries
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember						
		SELECT	iom.CompositeID
		INTO #IronOfferMember
		FROM [SLC_Report].[dbo].[IronOfferMember] iom
		WHERE (iom.StartDate <= @TodayDate OR iom.StartDate IS NULL)
		AND (iom.EndDate >= @TodayDateTime OR iom.EndDate IS NULL)
		AND EXISTS (SELECT 1
					FROM #OffersAccounts oa
					WHERE iom.IronOfferID = oa.IronOfferID)

		CREATE CLUSTERED INDEX CIX_Comp ON #IronOfferMember (CompositeID)

		-- (2542386 rows affected) / 00:00:03


	/***********************************************************************************************************************
		1.5.	Create list of Customers
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
		SELECT	fa.ID AS FanID
			,	fa.SourceUID
			,	ic.ID AS IssuerCustomerID
			,	MAX(CASE
		   				WHEN ica.Value = 'V' THEN 'V'
		   				ELSE ''
		   			END) AS CustomerSegment
			,	fa.ClubID
			,	fa.CompositeID
		INTO #Customers
		FROM [SLC_Report].[dbo].[Fan] fa
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON fa.SourceUID = ic.SourceUID
			AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomerAttribute] ica
			ON ic.ID = ica.IssuerCustomerID 
			AND ica.AttributeID = 1 --CJM/NB
			AND ica.EndDate IS NULL
		WHERE EXISTS (SELECT 1
					  FROM #IronOfferMember iom
					  WHERE fa.CompositeID = iom.CompositeID)
		GROUP BY	fa.ID
				,	fa.SourceUID
				,	ic.ID
				,	fa.ClubID
				,	fa.CompositeID

		-- (2540934 rows affected) / 00:00:08

		CREATE CLUSTERED INDEX CIX_IssuerCustomerID ON #Customers (IssuerCustomerID)
		CREATE NONCLUSTERED INDEX IX_FanID ON #Customers (FanID)
		CREATE NONCLUSTERED INDEX IX_CompositeID ON #Customers (CompositeID)


/*******************************************************************************************************************************************
	2.	Fetch all casses where the Nominee has been changed by the data feed
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#RBSNomChange') IS NOT NULL DROP TABLE #RBSNomChange
	CREATE TABLE #RBSNomChange (FanID INT NOT NULL)
		
	/***********************************************************************************************************************
		2.1.	Create list of SourceUID & IssuerIDs with Nominee changes
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#CustomersWithNomineeUpdates') IS NOT NULL DROP TABLE #CustomersWithNomineeUpdates
		SELECT	ic.IssuerID
			,	ic.SourceUID
		INTO #CustomersWithNomineeUpdates
		FROM [SLC_Report].[dbo].[DDCashbackNominee] nc
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			  ON nc.IssuerCustomerID = ic.ID
		WHERE ChangeSourceType = 3 -- 3	= RBS Feed
		AND StartDate = @YesterdayDate

		-- (51 rows affected) / 00:00:00
		
	/***********************************************************************************************************************
		2.2.	Insert to temp table for holding
	***********************************************************************************************************************/

		INSERT INTO #RBSNomChange (FanID)
		SELECT fa.ID
		FROM [SLC_Report].[dbo].[Fan] fa
		WHERE EXISTS (	SELECT 1
						FROM #CustomersWithNomineeUpdates cwnu
						WHERE fa.SourceUID = cwnu.SourceUID
						AND CONCAT(fa.ClubID, cwnu.IssuerID) IN (1322, 1381))

		-- (51 rows affected) / 00:00:00


/*******************************************************************************************************************************************
	3.	Fetch list of all customers & their Bank Accounts
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Accounts') IS NOT NULL DROP TABLE #Accounts
	CREATE TABLE #Accounts (ID INT IDENTITY(1,1) NOT NULL
						  , FanID INT NOT NULL
						  , SourceUID VARCHAR(20) NOT NULL
						  , IssuerCustomerID INT NOT NULL
						  , CustomerSegment VARCHAR(8)
						  , ClubID INT NOT NULL
						  , CompositeID BIGINT NOT NULL
						  , [Type] VARCHAR(3) NOT NULL
						  , BankAccountID INT NOT NULL
						  , AccountNumber VARCHAR(3) NOT NULL
						  , AlreadyValid BIT NOT NULL
						  , Nominee BIT NOT NULL)
		
	/***********************************************************************************************************************
		3.1.	Fetch initial list of customers & Bank Accounts
	***********************************************************************************************************************/
	
		INSERT INTO #Accounts
		SELECT	c.FanID
			,	c.SourceUID
			,	c.IssuerCustomerID
			,	c.CustomerSegment
			,	c.ClubID
			,	c.CompositeID
			,	bah.[Type]
			,	bah.BankAccountID
			,	RIGHT(ba.MaskedAccountNumber, 3) AS AccountNumber
			,	CASE
					WHEN oa.CustomerSegment IS NULL THEN 1
					WHEN oa.CustomerSegment = c.CustomerSegment THEN 1
					ELSE 0
				END AS AlreadyValid
			,	0 AS Nominee
		FROM #Customers c
		INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
			ON c.IssuerCustomerID = iba.IssuerCustomerID 
			AND (iba.CustomerStatus = 1 OR iba.CustomerStatus IS NULL)
		INNER JOIN [SLC_Report].[dbo].[BankAccount] ba 
			ON iba.BankAccountID = ba.ID 
			AND (ba.[Status] = 1 OR ba.[Status] IS NULL)
		INNER JOIN [SLC_Report].[dbo].[BankAccountTypeHistory] bah 
			ON bah.BankAccountID = iba.BankAccountID
			AND bah.EndDate IS NULL	
		INNER JOIN #OffersAccounts oa
			ON oa.BankAccountType = bah.[Type]
			AND oa.ClubID = c.ClubID

		-- (2556448 rows affected) / 00:00:07

		CREATE CLUSTERED INDEX CIX_BankAccountIssuerCustID ON #Accounts (BankAccountID, IssuerCustomerID)
		CREATE NONCLUSTERED INDEX IX_ClubTypeCust ON #Accounts ([ClubID], [Type]) INCLUDE ([FanID], [AccountNumber])

		
	/***********************************************************************************************************************
		3.2.	Update Nominee Field
	***********************************************************************************************************************/
	
		UPDATE a
		SET Nominee = 1
		FROM #Accounts a
		WHERE EXISTS (	SELECT 1
						FROM [SLC_Report].[dbo].[DDCashbackNominee] dd
						WHERE a.BankAccountID = dd.BankAccountID
						AND a.IssuerCustomerID = dd.IssuerCustomerID
						AND dd.EndDate IS NULL)

		-- (1796036 rows affected) / 00:00:05

		
	/***********************************************************************************************************************
		3.3.	Update Already Valid - Non V Customers on V accounts WITH V members
	***********************************************************************************************************************/

		UPDATE a
		SET AlreadyValid = 1
		FROM #Accounts a
		INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
			ON a.BankAccountID = iba.BankAccountID 
			AND (iba.CustomerStatus = 1 OR iba.CustomerStatus IS NULL)
			AND a.IssuerCustomerID != iba.IssuerCustomerID
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomerAttribute] ica
			ON	iba.IssuerCustomerID = ica.IssuerCustomerID 
			AND ica.EndDate IS NULL
		INNER JOIN #OffersAccounts oa
			ON oa.BankAccountType = a.[Type] 
			AND oa.ClubID = a.ClubID
		WHERE AlreadyValid = 0
		AND (oa.CustomerSegment IS NULL OR oa.CustomerSegment = ica.Value)

		-- (0 rows affected) / 00:00:01

		
	/***********************************************************************************************************************
		3.4.	Delete Invalid Accounts
	***********************************************************************************************************************/
	
		DELETE
		FROM #Accounts
		WHERE AlreadyValid = 0 

		-- 0 / 00:00:01


/*******************************************************************************************************************************************
	4.	Fetch the first DD Transaction earning per customer
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#FirstTrans') IS NOT NULL DROP TABLE #FirstTrans
	CREATE TABLE #FirstTrans (FanID INT NOT NULL
							, FirstTran DATE NOT NULL
							, PRIMARY KEY (FanID))

	/***********************************************************************************************************************
		4.1.	Insert customers previously calculated
	***********************************************************************************************************************/
		
		INSERT INTO #FirstTrans
		SELECT	FanID
			,	FirstDDEarn
		FROM [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit]
		WHERE FirstDDEarn IS NOT NULL

	/***********************************************************************************************************************
		4.2.	Find the First Trans ID
	***********************************************************************************************************************/

		;WITH
		Preagg AS (SELECT cu.FanID
			   			, t.TypeID
			   			, t.ItemID
			   			, MIN([ProcessDate]) AS FirstTrans
				   FROM #Customers cu
				   INNER HASH JOIN [SLC_Report].[dbo].[Trans] t
						ON cu.FanID = t.FanID
					WHERE NOT EXISTS (	SELECT 1
										FROM #FirstTrans ft
										WHERE cu.FanID = ft.FanID)
				   GROUP BY cu.FanID
			   			  , t.TypeID
			   			  , t.ItemID)

	
		INSERT INTO #FirstTrans
		SELECT t.FanID
			 , MIN(FirstTrans) AS FirstTrans
		FROM Preagg t
		INNER JOIN #TranTypes AS tt
			ON t.TypeID = tt.TransactionTypeID 
			AND t.ItemID = tt.ItemID
		GROUP BY t.FanID

		-- (0 rows affected) / 00:00:19


/*******************************************************************************************************************************************
	5.	Fetch the date which a customer was eligbile for the DD offer
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#FirstEligible') IS NOT NULL DROP TABLE #FirstEligible
	CREATE TABLE #FirstEligible (FanID INT NOT NULL
							   , FirstEligibleDate DATE NOT NULL
							   , PRIMARY KEY (FanID))

	/***********************************************************************************************************************
		5.1.	Fetch the ealiest offer memberships from all sources
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#SLC_IronOfferMember') IS NOT NULL DROP TABLE #SLC_IronOfferMember
		SELECT cu.FanID
			 , MIN(iom.StartDate) AS FirstEligibleDate
		INTO #SLC_IronOfferMember
		FROM #Customers cu
		INNER JOIN [SLC_Report].[dbo].[IronOfferMember] iom
			ON cu.CompositeID = iom.CompositeID
		INNER JOIN #OffersAccountsAll oaa
			ON iom.IronOfferID = oaa.IronOfferID
		GROUP BY cu.FanID

		-- (2540934 rows affected) / 00:00:03
	
		IF OBJECT_ID('tempdb..#Relational_IronOfferMember') IS NOT NULL DROP TABLE #Relational_IronOfferMember
		SELECT cu.FanID
			 , MIN(iom.StartDate) AS FirstEligibleDate
		INTO #Relational_IronOfferMember
		FROM #Customers cu
		INNER JOIN [Relational].[IronOfferMember] iom
			ON cu.CompositeID = iom.CompositeID
		INNER JOIN #OffersAccountsAll oaa
			ON iom.IronOfferID = oaa.IronOfferID
		GROUP BY cu.FanID

		-- (2537634 rows affected) / 00:00:03
	
		IF OBJECT_ID('tempdb..#IronOfferMember_Archive') IS NOT NULL DROP TABLE #IronOfferMember_Archive
		SELECT cu.FanID
			 , MIN(iom.StartDate) AS FirstEligibleDate
		INTO #IronOfferMember_Archive
		FROM #Customers cu
		INNER JOIN [Relational].[IronOfferMember_Archive] iom
			ON cu.CompositeID = iom.CompositeID
		INNER JOIN #OffersAccountsAll oaa
			ON iom.IronOfferID = oaa.IronOfferID
		GROUP BY cu.FanID
		
		-- (1825774 rows affected) / 00:00:04


	/***********************************************************************************************************************
		5.2.	Find the First Eligible Date
	***********************************************************************************************************************/
	
		INSERT INTO #FirstEligible
		SELECT	iom.FanID
			,	MIN(iom.FirstEligibleDate) AS FirstEligibleDate
		FROM (	SELECT *
				FROM #Relational_IronOfferMember
				UNION ALL
				SELECT *
				FROM #IronOfferMember_Archive
				UNION ALL
				SELECT *
				FROM #SLC_IronOfferMember) iom
		GROUP BY iom.FanID
		
		-- (2540934 rows affected) / 00:00:05


/*******************************************************************************************************************************************
	6.	Fetch account names and numbers
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#EligibleAccounts') IS NOT NULL DROP TABLE #EligibleAccounts
	CREATE TABLE #EligibleAccounts (FanID INT NOT NULL
								  , AccountName VARCHAR(40) NOT NULL
								  , AccountNumber VARCHAR(3) NOT NULL
								  , RowNo INT NOT NULL)

	/***********************************************************************************************************************
		6.1.	Fetch all accounts 
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#EligibleAccountsInterim') IS NOT NULL DROP TABLE #EligibleAccountsInterim
		SELECT	a.FanID
			,	ea.AccountName
			,	MIN(ea.Ranking) AS Ranking
			,	MIN(a.AccountNumber) AS AccountNumber
			,	MAX(CASE
						WHEN ea.AccountName LIKE '%Black%' THEN 1
						WHEN ea.AccountName LIKE '%Plat%' THEN 2
						WHEN ea.AccountName LIKE '%Silver%' THEN 3
						ELSE 4
					END) AS AccountNameRank
			,	COUNT(*) AS BankAccounts
		INTO #EligibleAccountsInterim
		FROM #Accounts a
		INNER JOIN [Staging].[DirectDebit_EligibleAccounts] ea
			ON a.Type = ea.AccountType
			AND a.ClubID = ea.ClubID 				
		GROUP BY	a.FanID
				,	ea.AccountName

		-- (2549561 rows affected) / 00:00:03
		

	/***********************************************************************************************************************
		6.2.	Rank & insert to temp table
	***********************************************************************************************************************/

		INSERT INTO #EligibleAccounts
		SELECT	ea.FanID
			,	ea.AccountName
			,	ea.AccountNumber
			,	ROW_NUMBER() OVER (PARTITION BY ea.FanID ORDER BY ea.Ranking ASC, AccountNameRank) AS RowNo
		FROM #EligibleAccountsInterim ea

		-- (2549561 rows affected) / 00:00:03
		

	/***********************************************************************************************************************
		6.3.	Pivot the data for ease of use
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#EligibleAccountsPivot') IS NOT NULL DROP TABLE #EligibleAccountsPivot
		;WITH
		AccountName AS (SELECT	FanID
							,	MAX(pvt_ana.[1]) AS AccountName1
							,	MAX(pvt_ana.[2]) AS AccountName2
							,	MAX(pvt_ana.[3]) AS AccountName3
						FROM #EligibleAccounts
						PIVOT (MAX(AccountName) FOR RowNo IN ([1], [2], [3])) AS pvt_ana
						GROUP BY FanID),
						
		AccountNumber AS (SELECT	FanID
							,	MAX(pvt_ana.[1]) AS AccountNumber1
							,	MAX(pvt_ana.[2]) AS AccountNumber2
							,	MAX(pvt_ana.[3]) AS AccountNumber3
						FROM #EligibleAccounts
						PIVOT (MAX(AccountNumber) FOR RowNo IN ([1], [2], [3])) AS pvt_ana
						GROUP BY FanID),

		Over3Accounts AS (	SELECT FanID
							FROM #EligibleAccounts ea
							GROUP BY FanID
							HAVING MAX(RowNo) > 3)

		SELECT ea.FanID
			 , MAX(ana.AccountName1) AS AccountName1
			 , MAX(ana.AccountName2) AS AccountName2
			 , MAX(ana.AccountName3) AS AccountName3
			 , MAX(anu.AccountNumber1) AS AccountNumber1
			 , MAX(anu.AccountNumber2) AS AccountNumber2
			 , MAX(anu.AccountNumber3) AS AccountNumber3
			 , MAX(ISNUMERIC(o3a.FanID)) AS Over3Accounts
		INTO #EligibleAccountsPivot
		FROM #EligibleAccounts ea
		LEFT JOIN AccountName ana
			ON ea.FanID = ana.FanID
		LEFT JOIN AccountNumber anu
			ON ea.FanID = anu.FanID
		LEFT JOIN Over3Accounts o3a
			ON ea.FanID = o3a.FanID
		GROUP BY ea.FanID

		-- (2540934 rows affected) / 00:00:07
	
	
	
	IF OBJECT_ID('tempdb..#FanSFDDailyUploadData_DirectDebit') IS NOT NULL DROP TABLE #FanSFDDailyUploadData_DirectDebit
	SELECT	cu.FanID
		,	MAX(CASE
					WHEN ea.AccountName1 IS NULL THEN 0
					ELSE 1
				END) AS OnTrial
		,	MAX(CONVERT(INT, a.Nominee)) AS Nominee
		,	MIN(ft.FirstTran) AS FirstDDEarn
		,	MAX(AccountName1) AS AccountName1
		,	MAX(AccountName2) AS AccountName2
		,	MAX(AccountName3) AS AccountName3
		 
		,	MAX(COALESCE(Over3Accounts, 0)) AS OVER3Accounts
		,	MAX(AccountNumber1) AS AccountNumber1
		,	MAX(AccountNumber2) AS AccountNumber2
		,	MAX(AccountNumber3) AS AccountNumber3
		,	MIN(fe.FirstEligibleDate) AS FirstEligibleDate
		,	MAX(CASE
					WHEN nc.FanID IS NOT NULL THEN 1
					ELSE 0
				 END) AS RBSNomineeChange
	INTO #FanSFDDailyUploadData_DirectDebit
	FROM #Customers cu
	LEFT JOIN #Accounts a
		  ON cu.FanID = a.FanID
	LEFT JOIN #EligibleAccountsPivot ea
		  ON cu.FanID = ea.FanID
	LEFT JOIN #FirstTrans ft
		  ON cu.FanID = ft.fanid
	LEFT JOIN #FirstEligible fe
		  ON cu.FanID = fe.FanID
	LEFT JOIN #RBSNomChange nc
		  ON cu.FanID = nc.FanID

		
	--IF OBJECT_ID('tempdb..#FanSFDDailyUploadData_DirectDebit') IS NOT NULL DROP TABLE #FanSFDDailyUploadData_DirectDebit
	--SELECT FanID
	--	 , CASE
	--			WHEN AccountName1 IS NULL THEN 0
	--			ELSE 1
	--	   END AS OnTrial
	--	 , Coalesce(Nominee, 0) AS Nominee
	--	 , FirstDDEarn
	--	 , AccountName1
	--	 , AccountName2
	--	 , AccountName3
	--	 , Coalesce(OVER3Accounts,0) AS OVER3Accounts
	--	 , AccountNumber1
	--	 , AccountNumber2
	--	 , AccountNumber3
	--	 , FirstEligibleDate
	--	 , RBSNomineeChange
	--INTO #FanSFDDailyUploadData_DirectDebit
	--FROM (SELECT c.FanID
	--		   , MAX(CONVERT(INT, a.Nominee)) AS Nominee
	--		   , MAX(CASE
	--					WHEN ea.RowNo = 1 THEN ea.AccountName
	--					ELSE NULL
	--				 END) AS AccountName1
	--		   , MAX(CASE
	--					WHEN ea.RowNo = 2 THEN ea.AccountName
	--					ELSE NULL
	--				 END) AS AccountName2
	--		   , MAX(CASE
	--					WHEN ea.RowNo = 3 THEN ea.AccountName
	--					ELSE NULL
	--				 END) AS AccountName3
	--		   , MAX(CASE
	--					WHEN ea.RowNo > 3 THEN 1
	--					ELSE 0
	--				 END) AS OVER3Accounts
	--		   , MAX(CASE
	--					WHEN ea.RowNo = 1 THEN ea.AccountNumber
	--					ELSE NULL
	--				 END) AS AccountNumber1
	--		   , MAX(CASE
	--					WHEN ea.RowNo = 2 THEN ea.AccountNumber
	--					ELSE NULL
	--				 END) AS AccountNumber2
	--		   , MAX(CASE
	--					WHEN ea.RowNo = 3 THEN ea.AccountNumber
	--					ELSE NULL
	--				 END) AS AccountNumber3
	--		   , MIN(ft.FirstTran) AS FirstDDEarn
	--		   , MIN(fe.FirstEligibleDate) AS FirstEligibleDate
	--		   , MAX(CASE
	--					WHEN nc.FanID IS NOT NULL THEN 1
	--					ELSE 0
	--				 END) AS RBSNomineeChange
	--	  FROM #Customers c
	--	  LEFT JOIN #Accounts a
	--	  	  ON c.FanID = a.FanID
	--	  LEFT JOIN #EligibleAccounts ea
	--	  	  ON c.FanID = ea.FanID
	--	  LEFT JOIN #FirstTrans ft
	--	  	  ON c.FanID = ft.fanid
	--	  LEFT JOIN #FirstEligible fe
	--	  	  ON c.FanID = fe.FanID
	--	  LEFT JOIN #RBSNomChange nc
	--	  	  ON c.FanID = nc.FanID
	--	  --WHERE NOT EXISTS (SELECT 1
	--			--			FROM [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] 
	--	  --					WHERE FanID = c.FanID) --Messy hack to deal WITH duplicate IssuerCustomer records
	--	  GROUP BY c.FanID
	--			 , ft.FirstTran) a

--------------------------------------------------------------------------------------------------------
-----------------------------------------Find RBSG Nominee Changes--------------------------------------
--------------------------------------------------------------------------------------------------------
		
	IF OBJECT_ID('tempdb..#RBSNomineeChangeCustomers') IS NOT NULL DROP TABLE #RBSNomineeChangeCustomers
	SELECT DISTINCT
		   f.ID AS FanID
		 , ic.ID AS IssuerCustomerID
	INTO #RBSNomineeChangeCustomers
	FROM [SLC_Report].[dbo].[Fan] f
	INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
		ON f.SourceUID = ic.SourceUID
		AND (CASE
				WHEN ClubID = 132 THEN 2
				ELSE 1
			  END) = ic.IssuerID
	WHERE EXISTS (SELECT 1
				  FROM #FanSFDDailyUploadData_DirectDebit dd
				  WHERE f.ID = dd.FanID
				  AND dd.RBSNomineeChange = 1)

--------------------------------------------------------------------------------------------------------
-----------------------------------------Add INDEX to Customer Table------------------------------------
--------------------------------------------------------------------------------------------------------

	CREATE CLUSTERED INDEX IX_Customers_ID on #RBSNomineeChangeCustomers (IssuerCustomerID)
	
--------------------------------------------------------------------------------------------------------
-----------------------------------------Find Nominee Change Accounts-----------------------------------
--------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#BA') IS NOT NULL DROP TABLE #BA
	SELECT FanID
		 , c.IssuerCustomerID
		 , BankAccountID
	INTO #BA
	FROM #RBSNomineeChangeCustomers c
	INNER JOIN [SLC_Report].[dbo].[DDCashbackNominee] n
		ON c.IssuerCustomerID = n.IssuerCustomerID
		AND DATEADD(day, DATEDIFF(dd, 0, n.ChangedDate) - 0, 0) = DATEADD(day, DATEDIFF(dd, 0, GETDATE()) -1, 0)
		

--------------------------------------------------------------------------------------------------------
------------------------------------Isolate Accounts That have changed Types----------------------------
--------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#BackAccountChanges') IS NOT NULL DROP TABLE #BackAccountChanges
	SELECT DISTINCT
		   FanID
	INTO #BackAccountChanges
	FROM #BA a
	INNER JOIN [SLC_Report].[dbo].[BankAccountTypeHistory] b
		ON a.BankAccountID = b.BankAccountID
	WHERE EndDate IS NULL
	AND StartDate >= DATEADD(day, DATEDIFF(dd, 0, GETDATE()) -2 ,0)

--------------------------------------------------------------------------------------------------------
-------------------------------------Find date of previous entry to assess------------------------------
--------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#LastED') IS NOT NULL DROP TABLE #LastED
	SELECT a.FanID
		 , a.IssuerCustomerID
		 , a.BankAccountID
		 , MAX(n.EndDate) AS LastEndDates
	INTO #LastED
	FROM (SELECT a.FanID
			   , a.IssuerCustomerID
			   , a.BankAccountID
		  FROM #BA a
		  LEFT JOIN #BackAccountChanges b
				ON a.FanID = b.FanID
		  WHERE b.FanID IS NULL) a
	INNER LOOP JOIN [SLC_Report].[dbo].[DDCashbackNominee] n
		ON a.BankAccountID = n.BankAccountID
	GROUP BY a.FanID
		   , a.IssuerCustomerID
		   , a.BankAccountID

--------------------------------------------------------------------------------------------------------
--------------------------------Find entries WHERE Nominee change to same nominee ----------------------
--------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#NomNotChanged') IS NOT NULL DROP TABLE #NomNotChanged
	SELECT a.FanID
		 , a.BankAccountID
		 , a.IssuerCustomerID
	INTO #NomNotChanged
	FROM #LastED a
	INNER JOIN [SLC_Report].[dbo].[DDCashbackNominee] b
		ON a.LastEndDates = b.EndDate
		AND a.BankAccountID = b.BankAccountID
	WHERE a.IssuerCustomerID = b.IssuerCustomerID

--------------------------------------------------------------------------------------------------------
--------------------------------Find entries WHERE Nominee change to same nominee ----------------------
--------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#FinalNomChangeUPDATEs') IS NOT NULL DROP TABLE #FinalNomChangeUPDATEs
	SELECT DISTINCT
		   c.FanID
	INTO #FinalNomChangeUPDATEs
	FROM #RBSNomineeChangeCustomers c
	LEFT JOIN #BackAccountChanges a
		ON c.FanID = a.FanID
	LEFT JOIN #NomNotChanged n
		on c.fanid = n.FanID
	WHERE a.FanID IS NULL
	OR n.FanID IS NULL
	
--------------------------------------------------------------------------------------------------------
-------------------------------- UPDATE SLC_Report Table ----------------------
--------------------------------------------------------------------------------------------------------

	UPDATE #FanSFDDailyUploadData_DirectDebit
	SET RBSNomineeChange = 0
	WHERE FanID IN (SELECT FanID
					FROM #FinalNomChangeUPDATEs)

	-----------------************ Truncate final storeage table ****************----------------							
	TRUNCATE TABLE [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit]
	-- Correlate data	
	INSERT INTO [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit]
	SELECT FanID
		 , OnTrial
		 , Nominee
		 , FirstDDEarn
		 , AccountName1
		 , AccountName2
		 , AccountName3
		 , OVER3Accounts
		 , AccountNumber1
		 , AccountNumber2
		 , AccountNumber3
		 , FirstEligibleDate
		 , RBSNomineeChange
	FROM #FanSFDDailyUploadData_DirectDebit

END