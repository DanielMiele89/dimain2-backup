
CREATE PROCEDURE [MI].[TotalBrandSpend_RBSG_Refresh]
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	INSERT INTO MI.TotalBrandSpendLoadAudit
	SELECT '[MI].[TotalBrandSpend_RBSG_Refresh]	- Started', GETDATE()

	/*******************************************************************************************************************************************
		1. Declare Variables
	*******************************************************************************************************************************************/

		DECLARE @CurrentMonthStart DATE
			  , @ThisYearStart DATE
			  , @ThisYearEnd DATE
			  , @LastYearStart DATE
			  , @LastYearEnd DATE

		SET @CurrentMonthStart = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	
		SELECT @ThisYearStart = DATEADD(MONTH, -12, @CurrentMonthStart)
			 , @ThisYearEnd = DATEADD(DAY, -1, @CurrentMonthStart)
		SELECT @LastYearStart = DATEADD(YEAR, -1, @ThisYearStart)
			 , @LastYearEnd = DATEADD(YEAR, -1, @ThisYearEnd)


	/*******************************************************************************************************************************************
		2. Fetch all customers
	*******************************************************************************************************************************************/

		--compile list of the relevant customers
		IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer;
		SELECT DISTINCT
			   cl.CINID
			 , fa.ID AS FanID
			 , CASE
					WHEN EXISTS (SELECT 1 FROM Relational.Customer cu WHERE fa.ID = cu.FanID) THEN 1
					ELSE 0
			   END AS MyRewardsCustomer
			 , fa.ClubID
			 , CASE
					WHEN rbs.CustomerSegment LIKE '%v%' THEN 1
					WHEN rbs.FanID IS NULL THEN NULL
					ELSE 0
			   END AS IsLoyalty
		INTO #Customer
		FROM SLC_Report..Fan fa
		LEFT JOIN Relational.CINList cl 
			ON fa.SourceUID = cl.CIN
		LEFT JOIN Relational.Customer_RBSGSegments rbs
			ON fa.ID = rbs.FanID
			AND rbs.EndDate IS NULL
		WHERE fa.ClubID IN (132, 138)
		AND NOT EXISTS (SELECT 1 FROM Staging.Customer_DuplicateSourceUID cds WHERE fa.SourceUID = cds.SourceUID)
		AND EXISTS (SELECT 1 FROM InsightArchive.SalesVisSuite_FixedBase fb WHERE cl.CINID = fb.CINID)

		DELETE
		FROM #Customer
		WHERE CINID IN (SELECT CINID FROM #Customer WHERE CINID IS NOT NULL GROUP BY CINID HAVING COUNT(*) > 1)
	
		CREATE CLUSTERED INDEX UCX_CINID ON #Customer (CINID)
		CREATE NONCLUSTERED INDEX UCX_FanID ON #Customer (FanID)

		INSERT INTO MI.TotalBrandSpendLoadAudit
		SELECT 'Total Brand Spend - Customers Fetched', GETDATE()


	/*******************************************************************************************************************************************
		3. Fetch all brand information
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Brands') IS NOT NULL DROP TABLE #Brands
		SELECT *
		INTO #Brands
		FROM Relational.Brand br
		WHERE br.BrandID NOT IN (944)

		CREATE CLUSTERED INDEX UCX_BrandID ON #Brands (BrandID)


		-- Find all Curve Card mIDs & exclude as they throw off online / offline transaction flags

		IF OBJECT_ID('tempdb..#CurveCard') IS NOT NULL DROP TABLE #CurveCard;
		WITH
		CurveCard AS (SELECT ConsumerCombinationID
						   , MID
					  FROM [Relational].[ConsumerCombination] cc
					  WHERE cc.BrandID != 944
					  AND (cc.Narrative LIKE 'CRV*%' OR cc.Narrative LIKE 'CURVE*%'))

		SELECT ConsumerCombinationID
		INTO #CurveCard
		FROM CurveCard
		UNION
		SELECT ConsumerCombinationID
		FROM [Relational].[ConsumerCombination] cc
		WHERE EXISTS (SELECT 1
					  FROM CurveCard cu
					  WHERE cc.MID = cu.MID
					  AND LEN(cu.MID) > 0)
		AND cc.BrandID != 944

		CREATE CLUSTERED INDEX CIX_RedeemID ON #CurveCard (ConsumerCombinationID)

		--compile list of the relevant combinations
		IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
		SELECT c.ConsumerCombinationID
			 , br.BrandID
			 , br.BrandName
			 , br.SectorID
			 , bs.SectorName
			 , CASE
					WHEN br.IsOnlineOnly = 1 THEN 1
			   END AS IsOnlineOnly
		INTO #CC
		FROM Relational.ConsumerCombination c
		INNER JOIN #Brands br
			ON c.BrandID = br.BrandID 
		INNER JOIN Relational.BrandSector bs
			ON br.SectorID = bs.SectorID
		WHERE NOT EXISTS (SELECT 1
						  FROM #CurveCard cc
						  WHERE c.ConsumerCombinationID = cc.ConsumerCombinationID)

		CREATE UNIQUE CLUSTERED INDEX UCX_CCID ON #CC (ConsumerCombinationID);
	-- 00:00:04


		--compile list of the relevant combinations
		IF OBJECT_ID('tempdb..#CC_DD') IS NOT NULL DROP TABLE #CC_DD;
		SELECT c.ConsumerCombinationID_DD
			 , br.BrandID
			 , br.BrandName
			 , br.SectorID
			 , bs.SectorName
			 , CASE
					WHEN br.IsOnlineOnly = 1 THEN 1
			   END AS IsOnlineOnly
		INTO #CC_DD
		FROM Relational.ConsumerCombination_DD c
		INNER JOIN #Brands br
			ON c.BrandID = br.BrandID 
		INNER JOIN Relational.BrandSector bs
			ON br.SectorID = bs.SectorID

		CREATE UNIQUE CLUSTERED INDEX UCX_CCID ON #CC_DD (ConsumerCombinationID_DD);
		
		INSERT INTO MI.TotalBrandSpendLoadAudit
		SELECT 'Total Brand Spend - Combinations Fetched', GETDATE()


	/*******************************************************************************************************************************************
		4. Fetch all transactional data
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			4.1. Fetch all debit transactions
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CT_AllTrans') IS NOT NULL DROP TABLE #CT_AllTrans;
			CREATE TABLE #CT_AllTrans (BrandID SMALLINT NOT NULL
									 , SectorID TINYINT
									 , IsOnline BIT NOT NULL
									 , DirectDebit TINYINT
									 , MyRewardsCustomer INT
									 , FanID INT
									 , CurrentYear INT
									 , Amount MONEY NOT NULL
									 , Transactions INT);

			INSERT INTO #CT_AllTrans WITH (TABLOCK) (BrandID
												   , SectorID
												   , IsOnline
												   , DirectDebit
												   , MyRewardsCustomer
												   , FanID
												   , CurrentYear
												   , Amount
												   , Transactions) 

			SELECT cc.BrandID
				 , cc.SectorID
				 , COALESCE(cc.IsOnlineOnly, ct.IsOnline) AS IsOnline
				 , 0 AS DirectDebit
				 , cu.MyRewardsCustomer
				 , cu.FanID
				 , CASE
		 				WHEN ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd THEN 1
		 				ELSE 0
				   END AS CurrentYear
				 , SUM(ct.Amount) AS Amount
				 , SUM(CASE
		   					WHEN ct.Amount > 0 THEN 1
		   					ELSE 0
		 				 END) AS Transactions
			FROM #CC cc
			INNER JOIN Relational.ConsumerTransaction ct
				  ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
			INNER JOIN #Customer cu
				  ON ct.CINID = cu.CINID
				  AND cu.CINID IS NOT NULL
			WHERE ct.TranDate BETWEEN @LastYearStart AND @ThisYearEnd
			GROUP BY cc.BrandID
				   , cc.SectorID
				   , COALESCE(cc.IsOnlineOnly, ct.IsOnline)
				   , cu.FanID
				   , cu.MyRewardsCustomer
				   , CASE
						WHEN ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd THEN 1
						ELSE 0
					 END
		
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Transactions Fetched - ConsumerTransaction', GETDATE()


		/***********************************************************************************************************************
			4.2. Fetch all credit transactions
		***********************************************************************************************************************/

			INSERT INTO #CT_AllTrans WITH (TABLOCK) (BrandID
												   , SectorID
												   , IsOnline
												   , DirectDebit
												   , MyRewardsCustomer
												   , FanID
												   , CurrentYear
												   , Amount
												   , Transactions) 

			SELECT cc.BrandID
				 , cc.SectorID
				 , COALESCE(cc.IsOnlineOnly, ct.IsOnline) AS IsOnline
				 , 0 AS DirectDebit
				 , cu.MyRewardsCustomer
				 , cu.FanID
				 , CASE
		 				WHEN ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd THEN 1
		 				ELSE 0
				   END AS CurrentYear
				 , SUM(ct.Amount) AS Amount
				 , SUM(CASE
		   					WHEN ct.Amount > 0 THEN 1
		   					ELSE 0
		 				 END) AS Transactions
			FROM #CC cc
			INNER JOIN Relational.ConsumerTransaction_CreditCard ct
				  ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
			INNER JOIN #Customer cu
				  ON ct.CINID = cu.CINID
				  AND cu.CINID IS NOT NULL
			WHERE ct.TranDate BETWEEN @LastYearStart AND @ThisYearEnd
			GROUP BY cc.BrandID
				   , cc.SectorID
				   , COALESCE(cc.IsOnlineOnly, ct.IsOnline)
				   , cu.FanID
				   , cu.MyRewardsCustomer
				   , CASE
						WHEN ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd THEN 1
						ELSE 0
					 END
		
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Transactions Fetched - ConsumerTransaction_CreditCard', GETDATE()


		/***********************************************************************************************************************
			4.3. Fetch all direct debit transactions
		***********************************************************************************************************************/

			INSERT INTO #CT_AllTrans WITH (TABLOCK) (BrandID
												   , SectorID
												   , IsOnline
												   , DirectDebit
												   , MyRewardsCustomer
												   , FanID
												   , CurrentYear
												   , Amount
												   , Transactions) 
			SELECT cc.BrandID
				 , cc.SectorID
				 , COALESCE(cc.IsOnlineOnly, 0) AS IsOnline
				 , 1 AS DirectDebit
				 , cu.MyRewardsCustomer
				 , cu.FanID
				 , CASE
		 				WHEN ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd THEN 1
		 				ELSE 0
				   END AS CurrentYear
				 , SUM(ct.Amount) AS Amount
				 , SUM(CASE
		   					WHEN ct.Amount > 0 THEN 1
		   					ELSE 0
		 			   END) AS Transactions
			FROM #CC_DD cc
			INNER JOIN Relational.ConsumerTransaction_DD ct
				ON ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD
			INNER JOIN #Customer cu
				ON ct.FanID = cu.FanID
			WHERE ct.TranDate BETWEEN @LastYearStart AND @ThisYearEnd
			GROUP BY cc.BrandID
				   , cc.SectorID
				   , COALESCE(cc.IsOnlineOnly, 0)
				   , cu.FanID
				   , cu.MyRewardsCustomer
				   , CASE
			  			  WHEN ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd THEN 1
			  			  ELSE 0
					 END
		
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Transactions Fetched - ConsumerTransaction_DD', GETDATE()

		/***********************************************************************************************************************
			4.4. Create index on table
		***********************************************************************************************************************/
			 
			CREATE COLUMNSTORE INDEX CSX_All ON #CT_AllTrans (DirectDebit, IsOnline, MyRewardsCustomer, BrandID, SectorID, CurrentYear, Amount, Transactions, FanID) -- 00:06:00
			
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Transactions Fetched - Table Indexed', GETDATE()


	/*******************************************************************************************************************************************
		5. Create an aggregated view of each combination of filters available in the final report and insert to permanent table
	*******************************************************************************************************************************************/

		DECLARE @TotalCustomers BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans)
			  , @TotalCustomers_FilterID_1 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0, 1) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_2 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0, 1) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_3 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0, 1) AND DirectDebit IN (0, 1))
			  , @TotalCustomers_FilterID_4 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_5 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_6 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0) AND DirectDebit IN (0, 1))
			  , @TotalCustomers_FilterID_7 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (1) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_8 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (1) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_9 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (1) AND DirectDebit IN (0, 1))
			  , @TotalCustomers_FilterID_10 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (1) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_11 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (1) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_12 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (1) AND DirectDebit IN (0, 1))
			  , @TotalCustomers_FilterID_13 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_14 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_15 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0) AND DirectDebit IN (0, 1))
			  , @TotalCustomers_FilterID_16 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0, 1) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_17 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0, 1) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_18 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0, 1) AND DirectDebit IN (0, 1))

		INSERT INTO MI.TotalBrandSpendLoadAudit
		SELECT 'Total Brand Spend - Distinct Customer Counts Calculated', GETDATE()

		/***********************************************************************************************************************
			5.1. Aggregate to brand level
		***********************************************************************************************************************/

			TRUNCATE TABLE [MI].[TotalBrandSpend_RBSG_Brand]

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 1 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_1 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 2 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_2 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 3 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_3 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 4 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_4 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Offline, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 5 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_5 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Offline, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 6 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_6 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Offline, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 7 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_7 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 8 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_8 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 9 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_9 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 10 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_10 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 11 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_11 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 12 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_12 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online, MyRewards Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 13 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_13 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Offline, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 14 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_14 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Offline, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 15 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_15 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Offline, MyRewards Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 16 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_16 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 17 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_17 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 18 AS FilterID
				 , BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_18 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, MyRewards Customers, Direct Debit & POS', GETDATE()


		/***********************************************************************************************************************
			5.2. Aggregate to sector level
		***********************************************************************************************************************/
				   
			TRUNCATE TABLE [MI].[TotalBrandSpend_RBSG_Sector]

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 1 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_1 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 2 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_2 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 3 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_3 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 4 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_4 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Offline, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 5 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_5 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Offline, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 6 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_6 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Offline, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 7 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_7 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 8 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_8 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 9 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_9 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 10 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_10 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 11 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_11 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 12 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_12 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online, MyRewards Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 13 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_13 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Offline, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 14 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_14 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Offline, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 15 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_15 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Offline, MyRewards Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 16 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_16 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 17 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_17 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear)
			SELECT 18 AS FilterID
				 , SectorID
				 , SectorName = (SELECT bs.SectorName FROM Relational.BrandSector bs WHERE bs.SectorID = ct.SectorID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_18 AS TotalCustomers
				 , CurrentYear
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO MI.TotalBrandSpendLoadAudit
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, MyRewards Customers, Direct Debit & POS', GETDATE()


	/*******************************************************************************************************************************************
		6. Update Sector Names to differeniate between product & services
	*******************************************************************************************************************************************/

		UPDATE tbs
		SET tbs.SectorName = tbs.SectorName + ' - ' + bsg.GroupName
		FROM [MI].[TotalBrandSpend_RBSG_Brand] tbs
		INNER JOIN [Relational].[BrandSector] bs
			ON tbs.SectorID = bs.SectorID
		INNER JOIN [Relational].[BrandSectorGroup] bsg
			 ON bs.SectorGroupID = bsg.SectorGroupID
		WHERE bs.SectorName IN (SELECT bs.SectorName
								FROM [Relational].[BrandSector] bs
								INNER JOIN [Relational].[BrandSectorGroup] bsg
									 ON bs.SectorGroupID = bsg.SectorGroupID
								GROUP BY bs.SectorName
								HAVING COUNT(DISTINCT bsg.GroupName) > 1)

		UPDATE tbs
		SET tbs.SectorName = tbs.SectorName + ' - ' + bsg.GroupName
		FROM [MI].[TotalBrandSpend_RBSG_Sector] tbs
		INNER JOIN [Relational].[BrandSector] bs
			ON tbs.SectorID = bs.SectorID
		INNER JOIN [Relational].[BrandSectorGroup] bsg
			 ON bs.SectorGroupID = bsg.SectorGroupID
		WHERE bs.SectorName IN (SELECT bs.SectorName
								FROM [Relational].[BrandSector] bs
								INNER JOIN [Relational].[BrandSectorGroup] bsg
									 ON bs.SectorGroupID = bsg.SectorGroupID
								GROUP BY bs.SectorName
								HAVING COUNT(DISTINCT bsg.GroupName) > 1)
								
		INSERT INTO MI.TotalBrandSpendLoadAudit
		SELECT 'Total Brand Spend - Update Sector Names', GETDATE()
				   

	/*******************************************************************************************************************************************
		7. Combine Brand & Sector values for past & current year into single row for report
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ConsumerCombination_ChangeLog') IS NOT NULL DROP TABLE #ConsumerCombination_ChangeLog
		SELECT BrandID
			 , MAX(DateResolved) AS LastAudited
		INTO #ConsumerCombination_ChangeLog
		FROM Staging.ConsumerCombination_ChangeLog
		GROUP BY BrandID
								
		INSERT INTO MI.TotalBrandSpendLoadAudit
		SELECT 'Total Brand Spend - Fetch Branding Audit Log ', GETDATE()


		TRUNCATE TABLE [MI].[TotalBrandSpend_RBSG]
		INSERT INTO [MI].[TotalBrandSpend_RBSG]
		SELECT ROW_NUMBER() OVER (ORDER BY bs.FilterID, bs.BrandName, NEWID()) AS ID
			 , *
		FROM (	SELECT DISTINCT
					   bs.FilterID
					 , CASE
							WHEN pa.PartnerID IS NULL THEN 0
							ELSE 1
					   END AS IsRewardPartner
					 , bs.BrandID
					 , bs.BrandName
					 , bs.SectorID
					 , bs.SectorName
					 , bs.TransactionChannel
					 , bs.CustomerType
					 , bs.TransactionType
					 , bs.Amount
					 , bso.Amount AS AmountOnline
					 , bs.Transactions
					 , bs.Customers
					 , ss.Customers AS CustomersPerSector
					 , bs.TotalCustomers
					 , bs2.Amount AS AmountLastYear
					 , bso2.Amount AS AmountOnlineLastYear
					 , bs2.Transactions AS TransactionsLastYear
					 , bs2.Customers AS CustomersLastYear
					 , ss2.Customers AS CustomersPerSectorLastYear
					 , COALESCE(cl.LastAudited, '2012-01-01') AS LastAudited
				FROM [MI].[TotalBrandSpend_RBSG_Brand] bs
				LEFT JOIN [MI].[TotalBrandSpend_RBSG_Brand] bso
					ON bs.BrandID = bso.BrandID
					AND bs.CustomerType = bso.CustomerType
					AND bs.TransactionType = bso.TransactionType
					AND bs.CurrentYear = bso.CurrentYear
					AND bso.TransactionChannel = 'Online'
				LEFT JOIN [MI].[TotalBrandSpend_RBSG_Brand] bs2
					ON bs.BrandID = bs2.BrandID
					AND bs.FilterID = bs2.FilterID
					AND bs.CurrentYear > bs2.CurrentYear
				LEFT JOIN [MI].[TotalBrandSpend_RBSG_Brand] bso2
					ON bs2.BrandID = bso2.BrandID
					AND bs2.CustomerType = bso2.CustomerType
					AND bs2.TransactionType = bso2.TransactionType
					AND bs2.CurrentYear = bso2.CurrentYear
					AND bso2.TransactionChannel = 'Online'
				LEFT JOIN [MI].[TotalBrandSpend_RBSG_Sector] ss
					ON bs.SectorID = ss.SectorID
					AND bs.FilterID = ss.FilterID
					AND bs.CurrentYear = ss.CurrentYear
				LEFT JOIN [MI].[TotalBrandSpend_RBSG_Sector] ss2
					ON ss.SectorID = ss2.SectorID
					AND ss.FilterID = ss2.FilterID
					AND ss.CurrentYear > ss2.CurrentYear
				LEFT JOIN #ConsumerCombination_ChangeLog cl
					ON bs.BrandID = cl.BrandID
				LEFT JOIN MI.PartnerBrand pa
					ON bs.BrandID = pa.BrandID
					AND EXISTS (SELECT 1
								FROM SLC_Report..IronOffer iof
								WHERE pa.PartnerID = iof.PartnerID
								AND iof.EndDate > DATEADD(MONTH, -6, @ThisYearEnd)
								AND iof.Name NOT LIKE '%SPARE%'
								AND iof.IsAboveTheLine = 0
								AND iof.IsDefaultCollateral = 0
								AND iof.IsSignedOff = 1)
				WHERE bs.CurrentYear = 1) bs
								
		INSERT INTO MI.TotalBrandSpendLoadAudit
		SELECT 'Total Brand Spend - Output To Final Table ', GETDATE()
		

	INSERT INTO MI.TotalBrandSpendLoadAudit
	SELECT '[MI].[TotalBrandSpend_RBSG_Refresh]	- Completed', GETDATE()

END