/*
		Author:			Stuart Barnley
		
		Date:			06th July 2015
		
		Description		This stored procedure finds Loyalty DD data

		-- CJM/NB 20161116 Perf
		-- CJM 20170203 Perf
		-- CJM 20180302 Perf
		
*/

CREATE PROCEDURE [Staging].[SLC_Report_DailyLoad_CBP_ProcessDirectDebitStats_SFD_V2]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED										

	DECLARE @TodayDate DATE = GETDATE()
		  , @TodayDATETIME DATETIME = GETDATE()

	--------------------------------------------------------------------------------------
	--------------------------- Find list of all DD IronOffers ---------------------------
	--------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#OffersAccountsAll') IS NOT NULL DROP TABLE #OffersAccountsAll
	SELECT DISTINCT
		   ba.IronOfferID
	INTO #OffersAccountsAll
	FROM [SLC_Report].[dbo].[IronOffer] iof
	INNER JOIN [SLC_Report].[dbo].[BankAccountTypeEligibility] ba
		ON iof.ID = ba.IronOfferID
	INNER JOIN [SLC_Report].[dbo].[IronOfferClub] ioc
		ON iof.ID = ioc.IronOfferID
	WHERE iof.StartDate <= @TodayDate
	AND ba.DirectDebitEligible = 1
	-- (6 rows affected) / 00:00:00


	--------------------------------------------------------------------------------------
	------------------Find list of eligible IronOffers AND AccountTypes-------------------
	--------------------------------------------------------------------------------------
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
	WHERE i.StartDate <= @TodayDATETIME
	AND (i.EndDate >= @TodayDate OR i.EndDate IS NULL)
	AND ba.DirectDebitEligible = 1
	-- (10 rows affected) / 00:00:01


	--------------------------------------------------------------------------------------
	--------------------------------List of TranTypes AND ItemIDs-------------------------
	--------------------------------------------------------------------------------------		
	IF OBJECT_ID('tempdb..#TranTypes') IS NOT NULL DROP TABLE #TranTypes
	SELECT TransactionTypeID
		 , ItemID
	INTO #TranTypes
	FROM Relational.AdditionalCashbackAwardType
	WHERE Title LIKE 'Direct Debit%'

	CREATE CLUSTERED INDEX ucx_Stuff ON #TranTypes (ItemID, TransactionTypeID)
	-- (3 rows affected) / 00:00:01

	--------------------------------------------------------------------------------------
	--------------------------------List IronOfferMember entries -------------------------
	--------------------------------------------------------------------------------------		
	IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember						
	SELECT CompositeID
	INTO #IronOfferMember
	FROM [SLC_Report].[dbo].[IronOfferMember] iom
	WHERE (iom.StartDate <= @TodayDate OR iom.StartDate IS NULL)
	AND (iom.EndDate >= @TodayDATETIME OR iom.EndDate IS NULL)
	AND EXISTS (SELECT 1
				FROM #OffersAccounts oa
				WHERE iom.IronOfferID = oa.IronOfferID)

	CREATE CLUSTERED INDEX ucx_Stuff ON #IronOfferMember (CompositeID)
	-- (3 rows affected) / 00:00:01
	

	--------------------------------------------------------------------------------------
	--------------------------CREATE list of Customers WITH RowNo-------------------------
	--------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	SELECT FanID
		 , SourceUID
		 , IssuerCustomerID
		 , CustomerSegment
		 , ClubID
		 , CompositeID
		 , CONVERT(INT, ROW_NUMBER() OVER (ORDER BY (SELECT NULL))) AS RowNo --CJM/NB
	INTO #Customers
	FROM (
		SELECT F.ID AS FanID
			 , f.SourceUID
			 , ic.ID AS IssuerCustomerID
			 , MAX(CASE
			   			WHEN ica.Value = 'V' THEN 'V'
			   			ELSE ''
			   	   END) AS CustomerSegment
			 , f.ClubID
			 , f.CompositeID
		FROM [SLC_Report].[dbo].[Fan] f
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON f.SourceUID = ic.SourceUID
			AND CASE
					WHEN f.ClubID = 132 THEN 2
					ELSE 1
				END = ic.issuerID
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomerAttribute] ica
			ON ic.ID = ica.IssuerCustomerID 
			AND ica.EndDate IS NULL
			AND ica.AttributeID = 1 --CJM/NB
		WHERE EXISTS (SELECT 1
					  FROM #IronOfferMember iom
					  WHERE f.CompositeID = iom.CompositeID)
		GROUP BY f.ID
			   , f.SourceUID
			   , ic.ID
			   , f.ClubID
			   , f.CompositeID) a
-- (2152094 rows affected) / 00:01:41

	CREATE CLUSTERED INDEX ucx_Stuff ON #Customers (IssuerCustomerID)
						
	--------------------------------------------------------------------------------------
	--------------------------------- CREATE Temporary Tables ----------------------------
	--------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Accounts') IS NOT NULL DROP TABLE #Accounts
	CREATE TABLE #Accounts (ID INT IDENTITY(1,1) NOT NULL
						  , FanID INT NOT NULL
						  , SourceUID VARCHAR(20) NOT NULL
						  , IssuerCustomerID INT NOT NULL
						  , CustomerSegment VARCHAR(8)
						  , clubid INT NOT NULL
						  , CompositeID BIGINT NOT NULL
						  , RowNo INT NOT NULL
						  , [Type] VARCHAR(3) NOT NULL
						  , BankAccountID INT NOT NULL
						  , AccountNumber VARCHAR(3) NOT NULL
						  , AlreadyValid BIT NOT NULL
						  , Nominee BIT NOT NULL)

	IF OBJECT_ID('tempdb..#FirstTrans') IS NOT NULL DROP TABLE #FirstTrans
	CREATE TABLE #FirstTrans (FanID INT NOT NULL
							, FirstTran DATE NOT NULL
							, PRIMARY KEY (FanID)) 

	---------------************ CREATE TABLE to hold First Eligible for DD Date****************----------------							
	IF OBJECT_ID('tempdb..#FirstEligible') IS NOT NULL DROP TABLE #FirstEligible
	CREATE TABLE #FirstEligible (FanID INT NOT NULL
							   , FirstEligibleDate DATE NOT NULL
							   , PRIMARY KEY (FanID))
							
	---------------************ CREATE TABLE to hold Eligible Account Names AND Numbers ****************----------------							
	IF OBJECT_ID('tempdb..#EligibleAccounts') IS NOT NULL DROP TABLE #EligibleAccounts
	CREATE TABLE #EligibleAccounts (FanID INT NOT NULL
								  , AccountName VARCHAR(40) NOT NULL
								  , AccountNumber VARCHAR(3) NOT NULL
								  , RowNo INT NOT NULL)

	---------------************ CREATE TABLE to hold whether the nominee has been changed by RBS data feed ****************----------------							
	IF OBJECT_ID('tempdb..#RBSNomChange') IS NOT NULL DROP TABLE #RBSNomChange
	CREATE TABLE #RBSNomChange (FanID INT NOT NULL)


	-- Find WHERE the Nominee has been changed by the data feed
	-- To be uncommented once the one off file additions FROM the start of the program end
	INSERT INTO #RBSNomChange (FanID)
	SELECT f.ID
	FROM [SLC_Report].[dbo].[Fan] f
	WHERE EXISTS (SELECT 1
				  FROM [SLC_Report].[dbo].[DDCashbackNominee] nc
				  INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
				  	  ON nc.IssuerCustomerID = ic.ID
				  WHERE ChangeSourceType = 3 -- 3	= RBS Feed 
				  AND StartDate = DATEADD(day, DATEDIFF(dd, 0, @TodayDATETIME) -1, 0) --or EndDate >= Dateadd(day,DATEDIFF(dd, 0, GETDATE())-2,0))
				  AND f.SourceUID = ic.SourceUID
				  AND f.ClubID = CASE
									WHEN ic.IssuerID = 2 THEN 132
									ELSE 138
								 END)
	-- (298 rows affected) / 00:00:38

	--Pull list of accounts
	INSERT INTO #Accounts
	SELECT c.FanID
		 , c.SourceUID
		 , c.IssuerCustomerID
		 , c.CustomerSegment
		 , c.ClubID
		 , c.CompositeID
		 , c.RowNo
		 , bah.[Type]
		 , bah.BankAccountID
		 , RIGHT(ba.MaskedAccountNumber, 3) AS AccountNumber
		 , CASE
				WHEN oa.CustomerSegment IS NULL THEN 1
				WHEN oa.CustomerSegment = c.CustomerSegment THEN 1
				ELSE 0
		   END AS AlreadyValid
		 , 0 AS Nominee
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
	-- (2160478 rows affected) / 00:00:11


	
	--UPDATE Nominee Field			
	UPDATE a
	SET Nominee = 1
	FROM #Accounts a
	INNER JOIN [SLC_Report].[dbo].[DDCashbackNominee] dd
		ON a.BankAccountID = dd.BankAccountID
		AND a.IssuerCustomerID = dd.IssuerCustomerID
		AND dd.enddate IS NULL
	-- (1484719 rows affected) / 00:00:08

	
	--UPDATE Already Valid - Non V Customers on V accounts WITH V members
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


	-- Find the First Tran Date
	;WITH
	Preagg AS (SELECT c.FanID
			   	    , t.TypeID
			   	    , t.ItemID
			   	    , MIN([ProcessDate]) AS FirstTrans
			   FROM #Customers c
			   INNER HASH JOIN [SLC_Report].[dbo].[Trans] t
					ON c.FanID = t.FanID
			   GROUP BY c.FanID
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
	-- (1579598 rows affected) / 00:00:40 (00:05:02 in DIDEVTEST WITH different INDEXing)

			
	-- Find the First Eligible Date
	INSERT INTO #FirstEligible
	SELECT c.FanID
		 , MIN(iom.StartDate) AS FirstEligibleDate
	FROM #Customers c
	INNER JOIN [SLC_Report].[dbo].[IronOfferMember] iom
		ON c.CompositeID = iom.CompositeID
	INNER JOIN #OffersAccountsAll oaa
		ON iom.IronOfferID = oaa.IronOfferID
	GROUP BY c.FanID
	-- (2152094 rows affected) / 00:00:04

	
	-- Delete Invalid Accounts
	DELETE
	FROM #Accounts
	WHERE AlreadyValid = 0 
	-- 0 / 00:00:01

	CREATE INDEX ix_Stuff ON #Accounts ([ClubID], [Type]) INCLUDE ([FanID], [AccountNumber])
	-- 00:00:09
	
	-- Find account Names AND numbers 
	INSERT INTO #EligibleAccounts
	SELECT a.FanID
		 , a.AccountName
		 , a.AccountNumber
		 , ROW_NUMBER() OVER (PARTITION BY a.FanID ORDER BY a.Ranking ASC, CASE
																				WHEN a.AccountName LIKE '%Black%' THEN 1
																				WHEN a.AccountName LIKE '%Plat%' THEN 2
																				WHEN a.AccountName LIKE '%Silver%' THEN 3
																				ELSE 4
																		  END) AS RowNo
	FROM (SELECT a.FanID
			   , e.AccountName
			   , MIN(e.Ranking) AS Ranking
			   , MIN(a.AccountNumber) AS AccountNumber
		  FROM #Accounts a
		  INNER JOIN [Staging].[DirectDebit_EligibleAccounts] e
			  ON a.Type = e.AccountType
			  AND a.ClubID = e.ClubID 				
		  GROUP BY a.FanID
				 , e.AccountName) a
	-- (2156899 rows affected) / 00:00:35
		
	IF OBJECT_ID('tempdb..#FanSFDDailyUploadData_DirectDebit') IS NOT NULL DROP TABLE #FanSFDDailyUploadData_DirectDebit
	SELECT FanID
		 , CASE
				WHEN AccountName1 IS NULL THEN 0
				ELSE 1
		   END AS OnTrial
		 , Coalesce(Nominee, 0) AS Nominee
		 , FirstDDEarn
		 , AccountName1
		 , AccountName2
		 , AccountName3
		 , Coalesce(OVER3Accounts,0) AS OVER3Accounts
		 , AccountNumber1
		 , AccountNumber2
		 , AccountNumber3
		 , FirstEligibleDate
		 , RBSNomineeChange
	INTO #FanSFDDailyUploadData_DirectDebit
	FROM (SELECT c.FanID
			   , MAX(CONVERT(INT, a.Nominee)) AS Nominee
			   , MAX(CASE
						WHEN ea.RowNo = 1 THEN ea.AccountName
						ELSE NULL
					 END) AS AccountName1
			   , MAX(CASE
						WHEN ea.RowNo = 2 THEN ea.AccountName
						ELSE NULL
					 END) AS AccountName2
			   , MAX(CASE
						WHEN ea.RowNo = 3 THEN ea.AccountName
						ELSE NULL
					 END) AS AccountName3
			   , MAX(CASE
						WHEN ea.RowNo > 3 THEN 1
						ELSE 0
					 END) AS OVER3Accounts
			   , MAX(CASE
						WHEN ea.RowNo = 1 THEN ea.AccountNumber
						ELSE NULL
					 END) AS AccountNumber1
			   , MAX(CASE
						WHEN ea.RowNo = 2 THEN ea.AccountNumber
						ELSE NULL
					 END) AS AccountNumber2
			   , MAX(CASE
						WHEN ea.RowNo = 3 THEN ea.AccountNumber
						ELSE NULL
					 END) AS AccountNumber3
			   , MIN(ft.FirstTran) AS FirstDDEarn
			   , MIN(fe.FirstEligibleDate) AS FirstEligibleDate
			   , MAX(CASE
						WHEN nc.FanID IS NOT NULL THEN 1
						ELSE 0
					 END) AS RBSNomineeChange
		  FROM #Customers c
		  LEFT JOIN #Accounts a
		  	  ON c.FanID = a.FanID
		  LEFT JOIN #EligibleAccounts ea
		  	  ON c.FanID = ea.FanID
		  LEFT JOIN #FirstTrans ft
		  	  ON c.FanID = ft.fanid
		  LEFT JOIN #FirstEligible fe
		  	  ON c.FanID = fe.FanID
		  LEFT JOIN #RBSNomChange nc
		  	  ON c.FanID = nc.FanID
		  --WHERE NOT EXISTS (SELECT 1
				--			FROM [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] 
		  --					WHERE FanID = c.FanID) --Messy hack to deal WITH duplicate IssuerCustomer records
		  GROUP BY c.FanID
				 , ft.FirstTran) a

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