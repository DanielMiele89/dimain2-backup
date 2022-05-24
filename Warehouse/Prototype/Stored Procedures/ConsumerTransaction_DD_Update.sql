

CREATE PROCEDURE [Prototype].[ConsumerTransaction_DD_Update]
AS
BEGIN

		SET NOCOUNT ON

		--TRUNCATE TABLE Sandbox.Rory.DDFileIDs
		--INSERT INTO Sandbox.Rory.DDFileIDs
		--SELECT CONVERT(INT, nf.ID) AS FileID
		--	 , MIN(Date) AS InDate
		--	 , 0 AS Inserted
		--FROM SLC_Report..NobleFiles nf
		--INNER JOIN Archive_Light.dbo.CBP_DirectDebit_TransactionHistory dd
		--	ON nf.ID = dd.FileID
		--WHERE NOT EXISTS (SELECT 1 FROM Relational.ConsumerTransaction_DD ct WHERE nf.ID = ct.FileID)
		--GROUP BY CONVERT(INT, nf.ID)


		IF OBJECT_ID('tempdb..#FileIDs') IS NOT NULL DROP TABLE #FileIDs
		SELECT FileID
			 , InDate
			 , Inserted
		INTO #FileIDs
		FROM Sandbox.Rory.DDFileIDs

		CREATE CLUSTERED INDEX CIX_FileID ON #FileIDs (FileID)


	/*******************************************************************************************************************************************
		4. Fetch all customer IDs relating to sole account customers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#IssuerBankAccount_SoleAccount') IS NOT NULL DROP TABLE #IssuerBankAccount_SoleAccount;
		WITH
		BankAccountID AS (SELECT BankAccountID
						  FROM SLC_Report..IssuerBankAccount iba
						  WHERE iba.CustomerStatus = 1
						  GROUP BY BankAccountID
						  HAVING COUNT(DISTINCT IssuerCustomerID) = 1)

		SELECT DISTINCT
			   iba.BankAccountID
			 , iba.ID AS IssuerBankAccountID
			 , iba.IssuerCustomerID
			 , fa.SourceUID
			 , fa.ID AS FanID
		INTO #IssuerBankAccount_SoleAccount
		FROM SLC_Report..IssuerBankAccount iba
		INNER JOIN SLC_Report..IssuerCustomer ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN SLC_Report..Fan fa
			ON ic.SourceUID = fa.SourceUID
			AND fa.ClubID IN (132, 138)
		WHERE iba.CustomerStatus = 1
		AND EXISTS (SELECT 1
					FROM BankAccountID ba
					WHERE iba.BankAccountID = ba.BankAccountID);
					
		WITH
		BankAccountID AS (SELECT BankAccountID
						  FROM SLC_Report..IssuerBankAccount iba
						  GROUP BY BankAccountID
						  HAVING COUNT(DISTINCT IssuerCustomerID) = 1)

		INSERT INTO #IssuerBankAccount_SoleAccount
		SELECT DISTINCT
			   iba.BankAccountID
			 , iba.ID AS IssuerBankAccountID
			 , iba.IssuerCustomerID
			 , fa.SourceUID
			 , fa.ID AS FanID
		FROM SLC_Report..IssuerBankAccount iba
		INNER JOIN SLC_Report..IssuerCustomer ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN SLC_Report..Fan fa
			ON ic.SourceUID = fa.SourceUID
			AND fa.ClubID IN (132, 138)
		WHERE NOT EXISTS (SELECT 1
						  FROM #IssuerBankAccount_SoleAccount sa
						  WHERE iba.BankAccountID = sa.BankAccountID)
		AND EXISTS (SELECT 1
					FROM BankAccountID ba
					WHERE iba.BankAccountID = ba.BankAccountID)	

		CREATE CLUSTERED INDEX CIX_BankAccountID ON #IssuerBankAccount_SoleAccount (BankAccountID)


	/*******************************************************************************************************************************************
		5. Fetch all customer IDs per bank account
	*******************************************************************************************************************************************/
		
		/***********************************************************************************************************************
			5.1. Select all customer details for every bank account
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#IssuerBankAccount_JointAccount') IS NOT NULL DROP TABLE #IssuerBankAccount_JointAccount;
			SELECT iba.BankAccountID
				 , iba.ID AS IssuerBankAccountID
				 , iba.IssuerCustomerID
				 , iba.CustomerStatus
				 , fa.SourceUID
				 , fa.ID AS FanID
			INTO #IssuerBankAccount_JointAccount
			FROM SLC_Report..IssuerBankAccount iba
			INNER JOIN SLC_Report..IssuerCustomer ic
				ON iba.IssuerCustomerID = ic.ID
			INNER JOIN SLC_Report..Fan fa
				ON ic.SourceUID = fa.SourceUID
				AND fa.ClubID IN (132, 138)

			CREATE CLUSTERED INDEX CIX_Fan ON #IssuerBankAccount_JointAccount (FanID)

		
		/***********************************************************************************************************************
			5.2. Select one customer er bank account that is currently active and has the minimum IssuerCustomerID
		***********************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#EarliestJoniingCustomer') IS NOT NULL DROP TABLE #EarliestJoniingCustomer;
			WITH
			FirstIssuerID AS (SELECT iba.BankAccountID
								   , iba.IssuerCustomerID
								   , iba.CustomerStatus
								   , RANK() OVER (PARTITION BY iba.BankAccountID ORDER BY iba.CustomerStatus DESC, iba.IssuerCustomerID) AS RankPerBank
							  FROM #IssuerBankAccount_JointAccount iba)

			SELECT iba.BankAccountID
				 , iba.FanID
			INTO #EarliestJoniingCustomer
			FROM #IssuerBankAccount_JointAccount iba
			INNER JOIN FirstIssuerID fii
				ON iba.BankAccountID = fii.BankAccountID
				AND iba.IssuerCustomerID = fii.IssuerCustomerID
				AND fii.RankPerBank = 1

			CREATE CLUSTERED INDEX CIX_Bank ON #EarliestJoniingCustomer (BankAccountID)

	/*******************************************************************************************************************************************
		6. Loop through each new FileID adding transactions to a holding table
	*******************************************************************************************************************************************/
	
		DECLARE	@msg VARCHAR(250)
			  , @Start DATETIME
			  , @RowCount BIGINT
			  , @Seconds VARCHAR(10)
			  , @FileDate DATE
			  , @StartDate DATE = GETDATE()
			  , @LoopNumber INT = 1
			  , @FinalLoopNumber VARCHAR(10) = (SELECT COUNT(DISTINCT InDate) FROM #FileIDs WHERE Inserted = 0)

		WHILE EXISTS (SELECT 1 FROM #FileIDs WHERE Inserted = 0) AND (SELECT CONVERT(DATE, GETDATE())) = @StartDate
		BEGIN
	
			SET @Start = GETDATE()
			SET @FileDate = (SELECT MIN(InDate) FROM #FileIDs WHERE Inserted = 0)



			IF OBJECT_ID('tempdb..#FileIDsInsert') IS NOT NULL DROP TABLE #FileIDsInsert
			SELECT FileID
			INTO #FileIDsInsert
			FROM #FileIDs fi
			WHERE fi.InDate = @FileDate

			CREATE CLUSTERED INDEX CIX_FileID ON #FileIDsInsert (FileID)


			IF OBJECT_ID('tempdb..#TransactionHistory') IS NOT NULL DROP TABLE #TransactionHistory
			SELECT [FileID]
				 , [RowNum]
				 , [OIN]
				 , [Narrative]
				 , [Amount]
				 , [Date]
				 , [BankAccountID]
				 , [IssuerBankAccountID]
				 , [IssuerCustomerID]
				 , [SourceUID]
				 , [FanID]
				 , NULL AS [ConsumerCombinationID_DD]
			INTO #TransactionHistory
			FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory al
			WHERE EXISTS (SELECT 1 FROM #FileIDsInsert fi WHERE al.[FileID] = fi.[FileID])
			AND NOT EXISTS (SELECT 1
							FROM [Relational].[ConsumerTransaction_DD] ct
							WHERE al.[FileID] = ct.FileID
							AND al.RowNum = ct.RowNum)

			SET @RowCount = @@ROWCOUNT

			CREATE CLUSTERED INDEX CIX_OIN ON #TransactionHistory (OIN)

		/***********************************************************************************************************************
			6.3. Update all missing Customer IDs
		***********************************************************************************************************************/
					
			/*******************************************************************************************************************
				6.3.1. Update all Customer IDs for sole accounts
			*******************************************************************************************************************/

				UPDATE th
				SET th.IssuerBankAccountID = COALESCE(th.IssuerBankAccountID, ba.IssuerBankAccountID)
				  , th.IssuerCustomerID = COALESCE(th.IssuerCustomerID, ba.IssuerCustomerID)
				  , th.SourceUID = COALESCE(th.SourceUID, ba.SourceUID)
				  , th.FanID = COALESCE(th.FanID, ba.FanID)
				FROM #TransactionHistory th
				INNER JOIN #IssuerBankAccount_SoleAccount ba
					ON th.BankAccountID = ba.BankAccountID
					
			/*******************************************************************************************************************
				6.3.2. Update all Customer IDs for joint accounts
			*******************************************************************************************************************/
		
				UPDATE th
				SET th.FanID = fa.FanID
				FROM #TransactionHistory th
				INNER JOIN #IssuerBankAccount_JointAccount fa
					ON th.IssuerBankAccountID = fa.IssuerBankAccountID
				WHERE th.FanID IS NULL
		
				UPDATE th
				SET th.FanID = fa.FanID
				FROM #TransactionHistory th
				INNER JOIN #IssuerBankAccount_JointAccount fa
					ON th.IssuerCustomerID = fa.IssuerCustomerID
				WHERE th.FanID IS NULL
		
				UPDATE th
				SET th.FanID = fa.FanID
				FROM #TransactionHistory th
				INNER JOIN #IssuerBankAccount_JointAccount fa
					ON th.SourceUID = fa.SourceUID
				WHERE th.FanID IS NULL
					
			/*******************************************************************************************************************
				6.3.3. Update FanID with the earliset currently active customer per bank account
			*******************************************************************************************************************/

				UPDATE th
				SET th.FanID = ejc.FanID
				FROM #TransactionHistory th
				INNER JOIN #EarliestJoniingCustomer ejc
					ON th.BankAccountID = ejc.BankAccountID
				WHERE th.FanID IS NULL

			-- Find CCs
			
			IF OBJECT_ID('tempdb..#VocaFile_OriginatorRecord_AllEntries') IS NOT NULL DROP TABLE #VocaFile_OriginatorRecord_AllEntries;
			SELECT ServiceUserNumber AS OIN
			 	 , ServiceUserName AS Narrative
			INTO #VocaFile_OriginatorRecord_AllEntries
			FROM [Staging].[VocaFile_OriginatorRecord_AllEntries]
			WHERE StartDate = (SELECT MAX(StartDate)
							   FROM [Staging].[VocaFile_OriginatorRecord_AllEntries]
							   WHERE StartDate <= @FileDate)

			IF OBJECT_ID('tempdb..#OIN_Narrative') IS NOT NULL DROP TABLE #OIN_Narrative;
			SELECT DISTINCT
				   OIN
				 , Narrative
			INTO #OIN_Narrative
			FROM #TransactionHistory

			
			IF OBJECT_ID('tempdb..#Combos') IS NOT NULL DROP TABLE #Combos;
			WITH
			CC_DD AS (SELECT OIN
					  	   , Narrative
					  FROM #OIN_Narrative),
		
			VocaFile_OINs AS (SELECT OIN
							  	   , Narrative
							  FROM #VocaFile_OriginatorRecord_AllEntries)

			SELECT DISTINCT
				   dd.OIN
				 , dd.Narrative AS Narrative_RBS
				 , vf.Narrative AS Narrative_VF
			INTO #Combos
			FROM CC_DD dd
			OUTER APPLY (SELECT Narrative
						 FROM #VocaFile_OriginatorRecord_AllEntries vf
						 WHERE dd.OIN = vf.OIN) vf

			INSERT INTO [Relational].[ConsumerCombination_DD] (OIN
															 , Narrative_RBS
															 , Narrative_VF
															 , BrandID)
			SELECT OIN
				 , Narrative_RBS
				 , Narrative_VF
				 , 944
			FROM #Combos c
				WHERE NOT EXISTS (SELECT 1
								  FROM [Relational].[ConsumerCombination_DD] cc
								  WHERE c.OIN = cc.OIN
								  AND c.Narrative_RBS = cc.Narrative_RBS
								  AND COALESCE(c.Narrative_VF, '') = COALESCE(cc.Narrative_VF, ''))
							   

			IF OBJECT_ID('tempdb..#NewCombos') IS NOT NULL DROP TABLE #NewCombos
			SELECT *
			INTO #NewCombos
			FROM [Relational].[ConsumerCombination_DD] c
			WHERE EXISTS (SELECT 1
						  FROM #Combos cc
						  WHERE c.OIN = cc.OIN
						  AND c.Narrative_RBS = cc.Narrative_RBS
						  AND COALESCE(c.Narrative_VF, '') = COALESCE(cc.Narrative_VF, ''))

			CREATE CLUSTERED INDEX CIX_OIN ON #NewCombos (OIN)
		
			UPDATE th
			SET th.[ConsumerCombinationID_DD] = nc.ConsumerCombinationID_DD
			FROM #TransactionHistory th
			INNER JOIN #NewCombos nc
				ON th.OIN = nc.OIN
				AND th.Narrative = nc.Narrative_RBS


			INSERT INTO [Prototype].[ConsumerTransaction_DD_Missing_RF]
			SELECT DISTINCT
				   [FileID]
				 , [RowNum]
				 , [Amount]
				 , [Date] AS [TranDate]
				 , [BankAccountID]
				 , [FanID]
				 , [ConsumerCombinationID_DD]
			FROM #TransactionHistory th

			UPDATE #FileIDs
			SET Inserted = 1
			WHERE InDate = @FileDate

			SET @Seconds = CONVERT(VARCHAR(10), DATEDIFF(second, @Start, GETDATE()))
			SET @msg = CONVERT(VARCHAR(10), @FileDate) + ' - ' + LEFT(CONVERT(VARCHAR(10), @LoopNumber) + '   ', 4) + ' of ' +  @FinalLoopNumber + ' - ' + LEFT(CONVERT(VARCHAR(10), @RowCount) + '       ', 7) + ' rows inserted in ' + LEFT(CONVERT(VARCHAR(10), @Seconds) + '   ', 4) + ' seconds'

			raiserror(@msg,0,1) with nowait

			SET @LoopNumber = @LoopNumber + 1

		END
	
		SET NOCOUNT OFF

END