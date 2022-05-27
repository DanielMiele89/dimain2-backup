
CREATE PROCEDURE [MI].[TotalBrandSpend_RBSG_Refresh_V3]
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	INSERT INTO [MI].[TotalBrandSpendLoadAudit]
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

		DECLARE @Today DATE = GETDATE()
		DECLARE @Yesterday DATE = DATEADD(DAY, -1, @Today)

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
			 , fa.Postcode
			 , fa.Sex AS Gender
			 , fa.DOB
			 , CONVERT(TINYINT, CASE	
									WHEN fa.DOB > CONVERT(DATE, @Today) THEN 0
									WHEN MONTH(fa.DOB) > MONTH(@Today) THEN DATEDIFF(yyyy, fa.DOB, @Today) - 1 
									WHEN MONTH(fa.DOB) < MONTH(@Today) THEN DateDiff(yyyy, fa.DOB, @Today) 
									WHEN MONTH(fa.DOB) = MONTH(@Today) THEN CASE
																			  	  When day(fa.DOB) > day(@Today) THEN DateDiff(yyyy, fa.DOB,@Today) - 1 
																			  	  Else DateDiff(yyyy, fa.DOB,@Today) 
																			  End 
								 End) as AgeCurrent
			 , DATEDIFF(HOUR, fa.DOB, @Today) / 8766 AS AgeYearsIntTrunc
		INTO #Customer
		FROM [SLC_Report].[dbo].[Fan] fa
		LEFT JOIN [Relational].[CINList] cl 
			ON fa.SourceUID = cl.CIN
		LEFT JOIN [Relational].[Customer_RBSGSegments] rbs
			ON fa.ID = rbs.FanID
			AND rbs.EndDate IS NULL
		WHERE fa.ClubID IN (132, 138)
		AND NOT EXISTS (SELECT 1 FROM [Staging].[Customer_DuplicateSourceUID] cds WHERE fa.SourceUID = cds.SourceUID)
		AND EXISTS (SELECT 1 FROM [InsightArchive].[SalesVisSuite_FixedBase] fb WHERE cl.CINID = fb.CINID)

		DELETE
		FROM #Customer
		WHERE CINID IN (SELECT CINID FROM #Customer WHERE CINID IS NOT NULL GROUP BY CINID HAVING COUNT(*) > 1)
	
		CREATE CLUSTERED INDEX UCX_CINID ON #Customer (CINID)
		CREATE NONCLUSTERED INDEX UCX_FanID ON #Customer (FanID)

		INSERT INTO [MI].[TotalBrandSpendLoadAudit]
		SELECT 'Total Brand Spend - Customers Fetched', GETDATE()


	/*******************************************************************************************************************************************
		3. Fetch all brand information
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Brands') IS NOT NULL DROP TABLE #Brands
		SELECT br.BrandID
			 , br.BrandName
			 , bs.SectorID
			 , bs.SectorName
			 , bs.SectorGroupID
			 , bsg.GroupName AS SectorGroupName
			 , br.IsOnlineOnly
		INTO #Brands
		FROM [Relational].[Brand] br
		INNER JOIN [Relational].[BrandSector] bs
			ON br.SectorID = bs.SectorID
		INNER JOIN [Relational].[BrandSectorGroup] bsg
			ON bs.SectorGroupID = bsg.SectorGroupID
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
			 , br.SectorGroupID
			 , CASE
					WHEN br.IsOnlineOnly = 1 THEN 1
			   END AS IsOnlineOnly
		INTO #CC
		FROM [Relational].[ConsumerCombination] c
		INNER JOIN #Brands br
			ON c.BrandID = br.BrandID 
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
			 , br.SectorGroupID
			 , CASE
					WHEN br.IsOnlineOnly = 1 THEN 1
			   END AS IsOnlineOnly
		INTO #CC_DD
		FROM [Relational].[ConsumerCombination_DD] c
		INNER JOIN #Brands br
			ON c.BrandID = br.BrandID 

		CREATE UNIQUE CLUSTERED INDEX UCX_CCID ON #CC_DD (ConsumerCombinationID_DD);
		
		INSERT INTO [MI].[TotalBrandSpendLoadAudit]
		SELECT 'Total Brand Spend - Combinations Fetched', GETDATE()


	/*******************************************************************************************************************************************
		4. Fetch all transactional data
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			4.1. Fetch all debit transactions
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..##CT_AllTrans') IS NOT NULL DROP TABLE ##CT_AllTrans;
			CREATE TABLE ##CT_AllTrans (BrandID SMALLINT NOT NULL
									  , SectorID TINYINT
									  , SectorGroupID TINYINT
									  , IsOnline BIT NOT NULL
									  , DirectDebit TINYINT
									  , MyRewardsCustomer INT
									  , FanID INT
									  , CurrentYear INT
									  , Amount MONEY NOT NULL
									  , Transactions INT
									  , AmountExclRefunds MONEY NOT NULL);

			INSERT INTO ##CT_AllTrans WITH (TABLOCK) (BrandID
													, SectorID
													, SectorGroupID
													, IsOnline
													, DirectDebit
													, MyRewardsCustomer
													, FanID
													, CurrentYear
													, Amount
													, Transactions
													, AmountExclRefunds) 

			SELECT cc.BrandID
				 , cc.SectorID
				 , cc.SectorGroupID
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
				, SUM(CASE
		   					WHEN ct.Amount > 0 THEN ct.Amount
		   					ELSE 0
		 				 END) AS AmountExclRefunds
			FROM #CC cc
			INNER JOIN [Relational].[ConsumerTransaction] ct
				  ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
			INNER JOIN #Customer cu
				  ON ct.CINID = cu.CINID
				  AND cu.CINID IS NOT NULL
			WHERE ct.TranDate BETWEEN @LastYearStart AND @ThisYearEnd
			GROUP BY cc.BrandID
				   , cc.SectorID
				   , cc.SectorGroupID
				   , COALESCE(cc.IsOnlineOnly, ct.IsOnline)
				   , cu.FanID
				   , cu.MyRewardsCustomer
				   , CASE
						WHEN ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd THEN 1
						ELSE 0
					 END
		

			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Transactions Fetched - ConsumerTransaction', GETDATE()


		/***********************************************************************************************************************
			4.2. Fetch all credit transactions
		***********************************************************************************************************************/

			INSERT INTO ##CT_AllTrans WITH (TABLOCK) (BrandID
													, SectorID
													, SectorGroupID
													, IsOnline
													, DirectDebit
													, MyRewardsCustomer
													, FanID
													, CurrentYear
													, Amount
													, Transactions
													, AmountExclRefunds) 

			SELECT cc.BrandID
				 , cc.SectorID
				 , cc.SectorGroupID
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
				, SUM(CASE
		   					WHEN ct.Amount > 0 THEN ct.Amount
		   					ELSE 0
		 				 END) AS AmountExclRefunds
			FROM #CC cc
			INNER JOIN [Relational].[ConsumerTransaction_CreditCard] ct
				  ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
			INNER JOIN #Customer cu
				  ON ct.CINID = cu.CINID
				  AND cu.CINID IS NOT NULL
			WHERE ct.TranDate BETWEEN @LastYearStart AND @ThisYearEnd
			GROUP BY cc.BrandID
				   , cc.SectorID
				   , cc.SectorGroupID
				   , COALESCE(cc.IsOnlineOnly, ct.IsOnline)
				   , cu.FanID
				   , cu.MyRewardsCustomer
				   , CASE
						WHEN ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd THEN 1
						ELSE 0
					 END
		
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Transactions Fetched - ConsumerTransaction_CreditCard', GETDATE()


		/***********************************************************************************************************************
			4.3. Fetch all direct debit transactions
		***********************************************************************************************************************/

			INSERT INTO ##CT_AllTrans WITH (TABLOCK) (BrandID
												   , SectorID
												   , SectorGroupID
												   , IsOnline
												   , DirectDebit
												   , MyRewardsCustomer
												   , FanID
												   , CurrentYear
												   , Amount
												   , Transactions
												   , AmountExclRefunds) 
			SELECT cc.BrandID
				 , cc.SectorID
				 , cc.SectorGroupID
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
				 , SUM(CASE
		   					WHEN ct.Amount > 0 THEN ct.Amount
		   					ELSE 0
		 			   END) AS AmountExclRefunds
			FROM #CC_DD cc
			INNER JOIN [Relational].[ConsumerTransaction_DD] ct
				ON ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD
			INNER JOIN #Customer cu
				ON ct.FanID = cu.FanID
			WHERE ct.TranDate BETWEEN @LastYearStart AND @ThisYearEnd
			GROUP BY cc.BrandID
				   , cc.SectorID
				   , cc.SectorGroupID
				   , COALESCE(cc.IsOnlineOnly, 0)
				   , cu.FanID
				   , cu.MyRewardsCustomer
				   , CASE
			  			  WHEN ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd THEN 1
			  			  ELSE 0
					 END
		
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Transactions Fetched - ConsumerTransaction_DD', GETDATE()

		/***********************************************************************************************************************
			4.4. Create index on table
		***********************************************************************************************************************/
			 
			CREATE COLUMNSTORE INDEX CSX_All ON ##CT_AllTrans (DirectDebit, IsOnline, MyRewardsCustomer, BrandID, SectorID, SectorGroupID, CurrentYear, Amount, Transactions, FanID,AmountExclRefunds) -- 00:06:00
			
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Transactions Fetched - Table Indexed', GETDATE()


	/*******************************************************************************************************************************************
		5. Create an aggregated view of each combination of filters available in the final report and insert to permanent table
	*******************************************************************************************************************************************/

		DECLARE @TotalCustomers BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans)
			  , @TotalCustomers_FilterID_1 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0, 1) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_2 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0, 1) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_3 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0, 1) AND DirectDebit IN (0, 1))
			  , @TotalCustomers_FilterID_4 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_5 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_6 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (0) AND DirectDebit IN (0, 1))
			  , @TotalCustomers_FilterID_7 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (1) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_8 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (1) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_9 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (0, 1) AND IsOnline IN (1) AND DirectDebit IN (0, 1))
			  , @TotalCustomers_FilterID_10 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (1) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_11 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (1) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_12 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (1) AND DirectDebit IN (0, 1))
			  , @TotalCustomers_FilterID_13 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_14 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_15 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0) AND DirectDebit IN (0, 1))
			  , @TotalCustomers_FilterID_16 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0, 1) AND DirectDebit IN (1))
			  , @TotalCustomers_FilterID_17 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0, 1) AND DirectDebit IN (0))
			  , @TotalCustomers_FilterID_18 BIGINT = (SELECT COUNT(DISTINCT FanID) FROM ##CT_AllTrans WHERE MyRewardsCustomer IN (1) AND IsOnline IN (0, 1) AND DirectDebit IN (0, 1))

		INSERT INTO [MI].[TotalBrandSpendLoadAudit]
		SELECT 'Total Brand Spend - Distinct Customer Counts Calculated', GETDATE()

		/***********************************************************************************************************************
			5.1. Aggregate to brand level
		***********************************************************************************************************************/

			TRUNCATE TABLE [MI].[TotalBrandSpend_RBSG_Brand]

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear, AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Offline, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Offline, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Offline, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online, MyRewards Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Offline, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Offline, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Offline, MyRewards Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Brand] (FilterID, BrandID, BrandName, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0, 1)
			GROUP BY BrandID
				   , SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Brand Counts - Online & Offline, MyRewards Customers, Direct Debit & POS', GETDATE()


		/***********************************************************************************************************************
			5.2. Aggregate to sector level
		***********************************************************************************************************************/
				   
			TRUNCATE TABLE [MI].[TotalBrandSpend_RBSG_Sector]

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Offline, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Offline, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Offline, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online, MyRewards Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Offline, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Offline, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Offline, MyRewards Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_Sector] (FilterID, SectorID, SectorName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
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
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Counts - Online & Offline, MyRewards Customers, Direct Debit & POS', GETDATE()


		/***********************************************************************************************************************
			5.3. Aggregate to sector level
		***********************************************************************************************************************/
				   
			TRUNCATE TABLE [MI].[TotalBrandSpend_RBSG_SectorGroup]

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 1 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_1 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online & Offline, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 2 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_2 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online & Offline, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 3 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_3 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online & Offline, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 4 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_4 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Offline, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 5 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_5 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Offline, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 6 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Offline' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_6 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Offline, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 7 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_7 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online, All Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 8 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_8 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online, All Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 9 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online' AS TransactionChannel
				 , 'All Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_9 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (0, 1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online, All Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 10 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_10 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 11 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_11 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 12 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_12 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online, MyRewards Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 13 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_13 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Offline, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 14 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_14 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Offline, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 15 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_15 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Offline, MyRewards Customers, Direct Debit & POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 16 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_16 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online & Offline, MyRewards Customers, Direct Debit', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 17 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_17 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online & Offline, MyRewards Customers, POS', GETDATE()

			INSERT INTO [MI].[TotalBrandSpend_RBSG_SectorGroup] (FilterID, SectorGroupID, SectorGroupName, TransactionChannel, CustomerType, TransactionType, Amount, Transactions, Customers, TotalCustomers, CurrentYear,AmountExclRefunds)
			SELECT 18 AS FilterID
				 , SectorGroupID
				 , SectorGroupName = (SELECT bs.GroupName FROM Relational.BrandSectorGroup bs WHERE bs.SectorGroupID = ct.SectorGroupID)
				 , 'Online & Offline' AS TransactionChannel
				 , 'MyRewards Customers' AS CustomerType
				 , 'Direct Debit & POS' AS TransactionType
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers_FilterID_18 AS TotalCustomers
				 , CurrentYear
				 , SUM(AmountExclRefunds) AS AmountExclRefunds
			FROM ##CT_AllTrans ct
			WHERE MyRewardsCustomer IN (1)
			AND IsOnline IN (0, 1)
			AND DirectDebit IN (0, 1)
			GROUP BY SectorGroupID
				   , CurrentYear
				   
			INSERT INTO [MI].[TotalBrandSpendLoadAudit]
			SELECT 'Total Brand Spend - Sector Group Counts - Online & Offline, MyRewards Customers, Direct Debit & POS', GETDATE()

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
								
		INSERT INTO [MI].[TotalBrandSpendLoadAudit]
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
								
		INSERT INTO [MI].[TotalBrandSpendLoadAudit]
		SELECT 'Total Brand Spend - Fetch Branding Audit Log ', GETDATE()

		TRUNCATE TABLE [MI].[TotalBrandSpend_RBSG_V2];
		WITH
		BrandOnline AS (SELECT BrandID
							 , CustomerType
							 , TransactionType
							 , MAX(CASE WHEN TransactionChannel = 'Online' AND CurrentYear = 1 THEN Amount ELSE 0 END) AS AmountOnline
							 , MAX(CASE WHEN TransactionChannel = 'Online' AND CurrentYear = 0 THEN Amount ELSE 0 END) AS AmountOnlineLastYear
							 , MAX(CASE WHEN TransactionChannel = 'Online' AND CurrentYear = 1 THEN AmountExclRefunds ELSE 0 END) AS AmountExclRefundsOnline
							 , MAX(CASE WHEN TransactionChannel = 'Online' AND CurrentYear = 0 THEN AmountExclRefunds ELSE 0 END) AS AmountExclRefundsOnlineLastYear
						FROM [MI].[TotalBrandSpend_RBSG_Brand] bs_c
						GROUP BY BrandID
							   , CustomerType
							   , TransactionType),

		Brand AS (	SELECT bs_c.FilterID
						 , bs_c.BrandID
						 , br.BrandName
						 , br.SectorID
						 , br.SectorName
						 , br.SectorGroupID
						 , br.SectorGroupName
						 , bs_c.TransactionChannel
						 , bs_c.CustomerType
						 , bs_c.TransactionType
						 , bs_c.TotalCustomers AS TotalCustomers
						 , bs_c.Amount
						 , bs_c.AmountExclRefunds
						 , bro.AmountOnline
						 , bro.AmountExclRefundsOnline
						 , bs_c.Transactions
						 , bs_c.Customers
						 , COALESCE(bs_l.Amount, 0) AS AmountLastYear
						 , COALESCE(bs_l.AmountExclRefunds, 0) AS AmountExclRefundsLastYear
						 , bro.AmountOnlineLastYear
						 , bro.AmountExclRefundsOnlineLastYear
						 , COALESCE(bs_l.Transactions, 0) AS TransactionsLastYear
						 , COALESCE(bs_l.Customers, 0) AS CustomersLastYear
					FROM [MI].[TotalBrandSpend_RBSG_Brand] bs_c
					LEFT JOIN [MI].[TotalBrandSpend_RBSG_Brand] bs_l
						ON bs_c.FilterID = bs_l.FilterID
						AND bs_c.BrandID = bs_l.BrandID
						AND bs_c.CurrentYear > bs_l.CurrentYear
					LEFT JOIN BrandOnline bro
						ON bs_c.BrandID = bro.BrandID
						AND bs_c.CustomerType = bro.CustomerType
						AND bs_c.TransactionType = bro.TransactionType
					INNER JOIN #Brands br
						ON bs_c.BrandID = br.BrandID
					WHERE bs_c.CurrentYear = 1),

		SectorGroup AS (SELECT bs_c.FilterID
							 , bs_c.SectorGroupID
							 , bs_c.TransactionChannel
							 , bs_c.CustomerType
							 , bs_c.TransactionType
							 , bs_c.Customers
							 , bs_l.Customers AS CustomersLastYear
						FROM [MI].[TotalBrandSpend_RBSG_SectorGroup] bs_c
						INNER JOIN [MI].[TotalBrandSpend_RBSG_SectorGroup] bs_l
							ON bs_c.FilterID = bs_l.FilterID
							AND bs_c.SectorGroupID = bs_l.SectorGroupID
							AND bs_c.CurrentYear > bs_l.CurrentYear),

		Sector AS (	SELECT bs_c.FilterID
						 , bs_c.SectorID
						 , bs_c.TransactionChannel
						 , bs_c.CustomerType
						 , bs_c.TransactionType
						 , bs_c.Customers
						 , bs_l.Customers AS CustomersLastYear
					FROM [MI].[TotalBrandSpend_RBSG_Sector] bs_c
					INNER JOIN [MI].[TotalBrandSpend_RBSG_Sector] bs_l
						ON bs_c.FilterID = bs_l.FilterID
						AND bs_c.SectorID = bs_l.SectorID
						AND bs_c.CurrentYear > bs_l.CurrentYear),

		RewardPartner AS (	SELECT DISTINCT
								   pa.BrandID
							FROM MI.PartnerBrand pa
							WHERE EXISTS (	SELECT 1
											FROM SLC_Report..IronOffer iof
											WHERE pa.PartnerID = iof.PartnerID
											AND iof.EndDate > DATEADD(MONTH, -6, @ThisYearEnd)
											AND iof.Name NOT LIKE '%SPARE%'
											AND iof.IsAboveTheLine = 0
											AND iof.IsDefaultCollateral = 0
											AND iof.IsSignedOff = 1))

		INSERT INTO [MI].[TotalBrandSpend_RBSG_V2]
		SELECT ROW_NUMBER() OVER (ORDER BY br.FilterID, br.BrandName, NEWID()) AS ID
			 , br.FilterID
			 , CASE
					WHEN pa.BrandID IS NULL THEN 0
					ELSE 1
			   END AS IsRewardPartner
			 , br.BrandID
			 , br.BrandName
			 , br.SectorID
			 , br.SectorName
			 , br.SectorGroupID
			 , br.SectorGroupName
			 , br.TransactionChannel
			 , br.CustomerType
			 , br.TransactionType
			 , br.Amount
			 , br.AmountOnline
			 , br.Transactions
			 , br.Customers
			 , s.Customers AS CustomersPerSector
			 , sg.Customers AS CustomersPerSectorGroup
			 , br.TotalCustomers
			 , br.AmountLastYear
			 , br.AmountOnlineLastYear
			 , br.TransactionsLastYear
			 , br.CustomersLastYear
			 , s.CustomersLastYear AS CustomersPerSectorLastYear
			 , sg.CustomersLastYear AS CustomersPerSectorGroupLastYear
			 , COALESCE(cl.LastAudited, '2012-01-01') AS LastAudited
			 , br.AmountExclRefunds
			 , br.AmountExclRefundsOnline
			 , br.AmountExclRefundsLastYear
			 , br.AmountExclRefundsOnlineLastYear
		FROM Brand br
		INNER JOIN SectorGroup sg
			ON br.FilterID = sg.FilterID
			AND br.SectorGroupID = sg.SectorGroupID
		INNER JOIN Sector s
			ON br.FilterID = s.FilterID
			AND br.SectorID = s.SectorID
		LEFT JOIN RewardPartner pa
			ON br.BrandID = pa.BrandID
		LEFT JOIN #ConsumerCombination_ChangeLog cl
			ON br.BrandID = cl.BrandID

		INSERT INTO [MI].[TotalBrandSpendLoadAudit]
		SELECT 'Total Brand Spend - Output To Final Table ', GETDATE()
		

	INSERT INTO [MI].[TotalBrandSpendLoadAudit]
	SELECT '[MI].[TotalBrandSpend_RBSG_Refresh]	- Completed', GETDATE()

END


