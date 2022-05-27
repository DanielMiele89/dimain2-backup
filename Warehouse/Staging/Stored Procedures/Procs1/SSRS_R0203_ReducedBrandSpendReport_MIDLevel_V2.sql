
CREATE Procedure [Staging].[SSRS_R0203_ReducedBrandSpendReport_MIDLevel_V2]  (@BrandID VarChar(200))
As
Begin

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	/*******************************************************************************************************************************************
		1. Declare Variables
	*******************************************************************************************************************************************/

		--DECLARE @BrandID INT = 1391

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
		FROM [SLC_Report].[dbo].[Fan] fa
		LEFT JOIN [Relational].[CINList] cl 
			ON fa.SourceUID = cl.CIN
		LEFT JOIN [Relational].[Customer_RBSGSegments] rbs
			ON fa.ID = rbs.FanID
			AND rbs.EndDate IS NULL
		WHERE fa.ClubID IN (132, 138)
		AND NOT EXISTS (SELECT 1 FROM [Staging].[Customer_DuplicateSourceUID] cds WHERE fa.SourceUID = cds.SourceUID)

		DELETE
		FROM #Customer
		WHERE CINID IN (SELECT CINID FROM #Customer WHERE CINID IS NOT NULL GROUP BY CINID HAVING COUNT(*) > 1)
	
		CREATE CLUSTERED INDEX UCX_CINID ON #Customer (CINID)
		CREATE NONCLUSTERED INDEX UCX_FanID ON #Customer (FanID)
		

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
		WHERE br.BrandID = @BrandID

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
					WHEN c.MID LIKE 'VCR%' THEN 'VCR'
					ELSE c.MID
			   END AS MID
			 , c.Narrative
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
			 , c.OIN
			 , c.Narrative_RBS
			 , CASE
					WHEN br.IsOnlineOnly = 1 THEN 1
			   END AS IsOnlineOnly
		INTO #CC_DD
		FROM [Relational].[ConsumerCombination_DD] c
		INNER JOIN #Brands br
			ON c.BrandID = br.BrandID 

		CREATE UNIQUE CLUSTERED INDEX UCX_CCID ON #CC_DD (ConsumerCombinationID_DD);


	/*******************************************************************************************************************************************
		4. Fetch all transactional data
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			4.1. Fetch all debit transactions
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CT_AllTrans') IS NOT NULL DROP TABLE #CT_AllTrans;
			CREATE TABLE #CT_AllTrans (BrandID SMALLINT NOT NULL
									 , MyRewardsCustomer INT
									 , TransactionType VARCHAR(3)
									 , MIDorOIN VARCHAR(500)
									 , Narrative VARCHAR(500)
									 , IsOnline BIT NOT NULL
									 , FanID INT
									 , Amount MONEY NOT NULL
									 , Transactions INT
									 , ActualTransactions INT);

			INSERT INTO #CT_AllTrans WITH (TABLOCK) (BrandID
												   , MyRewardsCustomer
												   , TransactionType
												   , MIDorOIN
												   , Narrative
												   , IsOnline
												   , FanID
												   , Amount
												   , Transactions
												   , ActualTransactions)

			SELECT cc.BrandID
				 , cu.MyRewardsCustomer
				 , 'POS' AS TransactionType
				 , cc.MID
				 , cc.Narrative
				 , COALESCE(cc.IsOnlineOnly, ct.IsOnline) AS IsOnline
				 , cu.FanID
				 , SUM(ct.Amount) AS Amount
				 , SUM(CASE
		   					WHEN ct.Amount > 0 THEN 1
		   					ELSE 0
		 				 END) AS Transactions
				 , COUNT(*) AS ActualTransactions
			FROM #CC cc
			INNER JOIN [Relational].[ConsumerTransaction] ct
				  ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
			INNER JOIN #Customer cu
				  ON ct.CINID = cu.CINID
				  AND cu.CINID IS NOT NULL
			WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
			GROUP BY cc.BrandID
				   , cu.MyRewardsCustomer
				   , cc.MID
				   , cc.Narrative
				   , COALESCE(cc.IsOnlineOnly, ct.IsOnline)
				   , cu.FanID

		/***********************************************************************************************************************
			4.2. Fetch all credit transactions
		***********************************************************************************************************************/
		
			INSERT INTO #CT_AllTrans WITH (TABLOCK) (BrandID
												   , MyRewardsCustomer
												   , TransactionType
												   , MIDorOIN
												   , Narrative
												   , IsOnline
												   , FanID
												   , Amount
												   , Transactions
												   , ActualTransactions)

			SELECT cc.BrandID
				 , cu.MyRewardsCustomer
				 , 'POS' AS TransactionType
				 , cc.MID
				 , cc.Narrative
				 , COALESCE(cc.IsOnlineOnly, ct.IsOnline) AS IsOnline
				 , cu.FanID
				 , SUM(ct.Amount) AS Amount
				 , SUM(CASE
		   					WHEN ct.Amount > 0 THEN 1
		   					ELSE 0
		 				 END) AS Transactions
				 , COUNT(*) AS ActualTransactions
			FROM #CC cc
			INNER JOIN [Relational].[ConsumerTransaction_CreditCard] ct
				  ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
			INNER JOIN #Customer cu
				  ON ct.CINID = cu.CINID
				  AND cu.CINID IS NOT NULL
			WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
			GROUP BY cc.BrandID
				   , cu.MyRewardsCustomer
				   , cc.MID
				   , cc.Narrative
				   , COALESCE(cc.IsOnlineOnly, ct.IsOnline)
				   , cu.FanID

		/***********************************************************************************************************************
			4.3. Fetch all direct debit transactions
		***********************************************************************************************************************/
		
			INSERT INTO #CT_AllTrans WITH (TABLOCK) (BrandID
												   , MyRewardsCustomer
												   , TransactionType
												   , MIDorOIN
												   , Narrative
												   , IsOnline
												   , FanID
												   , Amount
												   , Transactions
												   , ActualTransactions)

			SELECT cc.BrandID
				 , cu.MyRewardsCustomer
				 , 'DD' AS TransactionType
				 , cc.OIN
				 , cc.Narrative_RBS
				 , COALESCE(cc.IsOnlineOnly, 0) AS IsOnline
				 , cu.FanID
				 , SUM(ct.Amount) AS Amount
				 , SUM(CASE
		   					WHEN ct.Amount > 0 THEN 1
		   					ELSE 0
		 				 END) AS Transactions
				 , COUNT(*) AS ActualTransactions
			FROM #CC_DD cc
			INNER JOIN [Relational].[ConsumerTransaction_DD] ct
				ON ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD
			INNER JOIN #Customer cu
				ON ct.FanID = cu.FanID
			WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
			GROUP BY cc.BrandID
				   , cu.MyRewardsCustomer
				   , cc.OIN
				   , cc.Narrative_RBS
				   , COALESCE(cc.IsOnlineOnly, 0)
				   , cu.FanID

		/***********************************************************************************************************************
			4.4. Create index on table
		***********************************************************************************************************************/
			 
			CREATE COLUMNSTORE INDEX CSX_All ON #CT_AllTrans (BrandID
															, MyRewardsCustomer
															, TransactionType
															, MIDorOIN
															, Narrative
															, IsOnline
															, FanID
															, Amount
															, Transactions
															, ActualTransactions) -- 00:06:00
			

	/*******************************************************************************************************************************************
		5. Create an aggregated view of each combination of filters available in the final report and insert to permanent table
	*******************************************************************************************************************************************/

		DECLARE @TotalCustomers BIGINT = (SELECT COUNT(DISTINCT FanID) FROM #CT_AllTrans)

		/***********************************************************************************************************************
			5.1. Aggregate to brand level
		***********************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#CT_AllTrans_Agg') IS NOT NULl DROP TABLE #CT_AllTrans_Agg
			SELECT BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID = (SELECT br.SectorID FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorName = (SELECT br.SectorName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , 'MyRewards Customer' AS CustomerType
				 , TransactionType
				 , MIDorOIN
				 , Narrative
				 , IsOnline
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , SUM(ActualTransactions) AS ActualTransactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers AS TotalCustomers
			INTO #CT_AllTrans_Agg
			FROM #CT_AllTrans ct
			WHERE MyRewardsCustomer = 1
			GROUP BY BrandID
				   , TransactionType
				   , MIDorOIN
				   , Narrative
				   , IsOnline
			UNION ALL
			SELECT BrandID
				 , BrandName = (SELECT br.BrandName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorID = (SELECT br.SectorID FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , SectorName = (SELECT br.SectorName FROM #Brands br WHERE br.BrandID = ct.BrandID)
				 , 'All Customers' AS CustomerType
				 , TransactionType
				 , MIDorOIN
				 , Narrative
				 , IsOnline
				 , SUM(Amount) AS Amount
				 , SUM(Transactions) AS Transactions
				 , SUM(ActualTransactions) AS ActualTransactions
				 , COUNT(DISTINCT FanID) AS Customers
				 , @TotalCustomers AS TotalCustomers
			FROM #CT_AllTrans ct
			GROUP BY BrandID
				   , TransactionType
				   , MIDorOIN
				   , Narrative
				   , IsOnline

			SELECT BrandID
				 , BrandName
				 , SectorID
				 , SectorName
				 , CustomerType
				 , TransactionType
				 , MIDorOIN
				 , Narrative
				 , IsOnline
				 , Amount
				 , ActualTransactions AS Transactions
				 , Customers
				 , TotalCustomers
				 , Amount / ActualTransactions AS ATV
				 , ActualTransactions / Customers AS ATF
				 , Amount / Customers AS SPS
			FROM #CT_AllTrans_Agg

END


