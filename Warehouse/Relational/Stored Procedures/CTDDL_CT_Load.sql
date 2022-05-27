
/*
DIMAIN2 VERSION
Migration changes 25/08/2021 CJM
Remove columnstore index
Remove clustered index
Create PK
Update statistics

Ordinary indexes will be applied later
*/
CREATE PROCEDURE [Relational].[CTDDL_CT_Load]
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @Time DATETIME, @Msg VARCHAR(2048)

	SET @Msg = 'CTDDL_CT_Load started'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

	/*******************************************************************************************************************************************
		1.	Declare variables
	*******************************************************************************************************************************************/
		
		DECLARE @MaxConsumerCombinationID BIGINT = (SELECT MAX(ConsumerCombinationID_DD) FROM Relational.ConsumerCombination_DD)
			,	@MinTranDate DATE = (SELECT MIN(TranDate) FROM [Relational].[ConsumerTransaction_DD])
			  , @Proceed BIT = 1
		TRUNCATE TABLE [Staging].[ConsumerTransaction_DD_Holding]


	/*******************************************************************************************************************************************
		2.	Fetch any new Files
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#FileIDs') IS NOT NULL DROP TABLE #FileIDs
		SELECT TOP(100) -- CJM migration
			CONVERT(INT, ID) AS FileID, 0 AS Inserted
		INTO #FileIDs
		FROM SLC_REPL..NobleFiles nf
		WHERE EXISTS (SELECT 1
					  FROM [DIMAIN].[Archive_Light].[dbo].[CBP_DirectDebit_TransactionHistory] dd
					  WHERE nf.ID = dd.FileID
					  AND dd.Date >= @MinTranDate)
		AND NOT EXISTS (SELECT 1
						FROM [Relational].[ConsumerTransaction_DD] ct
						WHERE nf.ID = ct.FileID)
		ORDER BY FileID

		CREATE CLUSTERED INDEX CIX_FileID ON #FileIDs (FileID)

		SET @Msg = '2.	Fetch any new Files'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output


	/*******************************************************************************************************************************************
		3.	If they are no new files to load then exit
	*******************************************************************************************************************************************/

		IF (SELECT COUNT(*) FROM #FileIDs) = 0
			BEGIN
				RETURN
			END


	/*******************************************************************************************************************************************
		4.	Fetch MyRewards customers
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#MyRewardsCustomers') IS NOT NULL DROP TABLE #MyRewardsCustomers
		SELECT DISTINCT
			   iba.BankAccountID
		INTO #MyRewardsCustomers
		FROM [SLC_Report].[dbo].[IssuerBankAccount] iba
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN [Relational].[Customer] cu
			ON ic.SourceUID = cu.SourceUID
		WHERE iba.CustomerStatus = 1
		AND cu.CurrentlyActive = 1

		CREATE CLUSTERED INDEX CIX_BankAccountID ON #MyRewardsCustomers (BankAccountID)

		SET @Msg = '4.	Fetch MyRewards customers'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

	/*******************************************************************************************************************************************
		5.	Fetch all customer IDs relating to sole account customers
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

		CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #IssuerBankAccount_SoleAccount (BankAccountID, IssuerCustomerID, IssuerBankAccountID, FanID, SourceUID)

		SET @Msg = '5.	Fetch all customer IDs relating to sole account customers'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

	/*******************************************************************************************************************************************
		6.	Fetch all customer IDs per bank account
	*******************************************************************************************************************************************/
		
		/***********************************************************************************************************************
			6.1.	Select all customer details for every bank account
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

			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #IssuerBankAccount_JointAccount (BankAccountID, IssuerCustomerID, IssuerBankAccountID, FanID, SourceUID)

			SET @Msg = '6.1.	Select all customer details for every bank account'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output
		
		/***********************************************************************************************************************
			6.2.	Select one customer bank account that is currently active and has the minimum IssuerCustomerID
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
				
			CREATE CLUSTERED INDEX CIX_Bank ON #EarliestJoniingCustomer (BankAccountID, FanID)

			SET @Msg = '6.2.	Select one customer bank account that is currently active and has the minimum IssuerCustomerID'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output



	/*******************************************************************************************************************************************
		7.	Loop through each new FileID adding transactions to a holding table
	*******************************************************************************************************************************************/
		SET @Msg = 'LOOP STARTS #####'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

		DECLARE	@FileID INT
			  , @FileDate DATE
	
		WHILE EXISTS (SELECT 1 FROM #FileIDs WHERE Inserted = 0)
		BEGIN
		
		/***********************************************************************************************************************
			7.1.	Select next FileID to extract
		***********************************************************************************************************************/
	
			SET @FileID = (SELECT MIN(FileID) FROM #FileIDs WHERE Inserted = 0)

			SET @Msg = '7.1.	Next FileID to extract: ' + CAST(@FileID AS VARCHAR(10)); EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output		

		/***********************************************************************************************************************
			7.2.	Fetch all transactions for the looped FileID
		***********************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#TransactionHistory') IS NOT NULL DROP TABLE #TransactionHistory
			SELECT FileID
				 , RowNum
				 , OIN
				 , Narrative = CAST(Narrative AS VARCHAR(18)) -- CJM Migration
				 , Amount
				 , Date
				 , BankAccountID
				 , IssuerBankAccountID
				 , IssuerCustomerID
				 , SourceUID
				 , FanID
				 , NULL AS ConsumerCombinationID_DD
			INTO #TransactionHistory
			FROM [DIMAIN].[Archive_Light].[dbo].[CBP_DirectDebit_TransactionHistory] dd
			WHERE FileID = @FileID	--	20391

			CREATE CLUSTERED INDEX CIX_OIN ON #TransactionHistory (OIN, Narrative)
			CREATE NONCLUSTERED INDEX IX_OIN ON #TransactionHistory (BankAccountID) INCLUDE (IssuerBankAccountID, IssuerCustomerID, SourceUID, FanID)

			SET @Msg = '7.2.	Fetch all transactions for the looped FileID'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output
		

		/***********************************************************************************************************************
			7.3.	Update all missing Customer IDs
		***********************************************************************************************************************/
					
			/*******************************************************************************************************************
				7.3.1.	Update all Customer IDs for sole accounts
			*******************************************************************************************************************/

				UPDATE th
				SET th.IssuerBankAccountID = COALESCE(th.IssuerBankAccountID, ba.IssuerBankAccountID)
				  , th.IssuerCustomerID = COALESCE(th.IssuerCustomerID, ba.IssuerCustomerID)
				  , th.SourceUID = COALESCE(th.SourceUID, ba.SourceUID)
				  , th.FanID = COALESCE(th.FanID, ba.FanID)
				FROM #TransactionHistory th
				INNER JOIN #IssuerBankAccount_SoleAccount ba
					ON th.BankAccountID = ba.BankAccountID

				SET @Msg = '7.3.1.	Update all Customer IDs for sole accounts'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output
					
			/*******************************************************************************************************************
				7.3.2.	Update all Customer IDs for joint accounts
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

				SET @Msg = '7.3.2.	Update all Customer IDs for joint accounts'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output
					
			/*******************************************************************************************************************
				7.3.3.	Update FanID with the earliset currently active customer per bank account
			*******************************************************************************************************************/

				UPDATE th
				SET th.FanID = ejc.FanID
				FROM #TransactionHistory th
				INNER JOIN #EarliestJoniingCustomer ejc
					ON th.BankAccountID = ejc.BankAccountID
				WHERE th.FanID IS NULL

				SET @Msg = '7.3.3.	Update FanID with the earliset currently active customer per bank account'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

		/***********************************************************************************************************************
			7.4.	Find all new ConsumerCombinations
		***********************************************************************************************************************/
					
			/*******************************************************************************************************************
				7.4.1.	Fetch all unique OIN, Narrative combinations from the fetched transactions
			*******************************************************************************************************************/

				IF OBJECT_ID('tempdb..#Combos') IS NOT NULL DROP TABLE #Combos;
				WITH
				CC_DD AS (SELECT DISTINCT
						  	     OIN
						  	   , Narrative
						  FROM #TransactionHistory),
					
			/*******************************************************************************************************************
				7.4.2.	Fetch all Voca File entries
			*******************************************************************************************************************/
		
				VocaFile_OINs AS (SELECT ServiceUserNumber AS OIN
								  	   , ServiceUserName AS Narrative
								  FROM [Staging].[VocaFile_OriginatorRecord])					

			/*******************************************************************************************************************
				7.4.3.	Fetch all unique OIN, Narrative combinations from the fetched transactions & Voca File
				CJM it makes no sense to have a clustered index on all of the columns, there's no advantage to it that I can see.
				Also, it generated a warning and occasionally an error.
			*******************************************************************************************************************/

				SELECT DISTINCT
					   dd.OIN
					 , dd.Narrative AS Narrative_RBS
					 , CONVERT(VARCHAR(500), vf.Narrative) AS Narrative_VF
					 , COALESCE(CONVERT(VARCHAR(500), vf.Narrative), '') AS Narrative_VF_Filled
				INTO #Combos
				FROM CC_DD dd
				LEFT JOIN VocaFile_OINs vf
					ON dd.OIN = vf.OIN
					
				--CREATE CLUSTERED INDEX CIX_All ON #Combos (OIN, Narrative_RBS, Narrative_VF, Narrative_VF_Filled) 
				CREATE CLUSTERED INDEX CIX_OIN ON #Combos (OIN, Narrative_RBS) -- CJM
				-- this index is too big, generates a warning

				SET @Msg = '7.4.3.	Fetch all unique OIN, Narrative combinations from the fetched transactions & Voca File'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

			/*******************************************************************************************************************
				7.4.4.	Insert new combinations to the ConumberCombination_DD table as unbranded
				The LIKE operator without wildcards (%) is the same as the = operator
			*******************************************************************************************************************/
			
				IF OBJECT_ID('tempdb..#ConsumerCombination_DD') IS NOT NULL DROP TABLE #ConsumerCombination_DD
				CREATE TABLE #ConsumerCombination_DD (ConsumerCombinationID_DD BIGINT
													--, OIN VARCHAR(50) -- CJM Migration
													, OIN INT -- CJM Migration
													, Narrative_RBS VARCHAR(50)
													, Narrative_VF VARCHAR(50)
													, Narrative_VF_Filled VARCHAR(50))

				--CREATE CLUSTERED INDEX CIX_All ON #ConsumerCombination_DD (OIN, Narrative_RBS, Narrative_VF_Filled)
				CREATE CLUSTERED INDEX CIX_OIN ON #ConsumerCombination_DD (OIN, Narrative_RBS)


				INSERT INTO #ConsumerCombination_DD WITH (TABLOCK)
				SELECT ConsumerCombinationID_DD
					 , OIN
					 , Narrative_RBS
					 , Narrative_VF
					 , COALESCE(Narrative_VF, '') AS Narrative_VF_Filled
				FROM [Relational].[ConsumerCombination_DD] cc
				WHERE EXISTS (SELECT 1
							  FROM #Combos c
							  WHERE c.OIN = cc.OIN)
				ORDER BY cc.OIN
					

				INSERT INTO [Relational].[ConsumerCombination_DD] WITH (TABLOCK)
					(OIN, Narrative_RBS, Narrative_VF, BrandID)
				SELECT DISTINCT
					   OIN
					 , Narrative_RBS
					 , Narrative_VF
					 , 944
				FROM #Combos c
				WHERE NOT EXISTS (SELECT 1
								  FROM #ConsumerCombination_DD cc
								  WHERE c.OIN = cc.OIN
								  AND c.Narrative_RBS LIKE cc.Narrative_RBS
								  AND c.Narrative_VF_Filled LIKE cc.Narrative_VF_Filled)

				SET @Msg = '7.4.4.	Insert new combinations to the ConumberCombination_DD table as unbranded'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

			/*******************************************************************************************************************
				7.4.6.	Fetch all the consumer combination IDs for each combination in the transaction file
			*******************************************************************************************************************/
				
				INSERT INTO #ConsumerCombination_DD
				SELECT ConsumerCombinationID_DD
					 , OIN
					 , Narrative_RBS
					 , Narrative_VF
					 , COALESCE(Narrative_VF, '') AS Narrative_VF_Filled
				FROM [Relational].[ConsumerCombination_DD] cc
				WHERE EXISTS (SELECT 1
							  FROM #Combos c
							  WHERE c.OIN = cc.OIN)
				AND NOT EXISTS (SELECT 1
								FROM #ConsumerCombination_DD c
								WHERE cc.ConsumerCombinationID_DD = c.ConsumerCombinationID_DD)

					   
				IF OBJECT_ID('tempdb..#NewCombos') IS NOT NULL DROP TABLE #NewCombos
				SELECT DISTINCT
					   OIN
					 , Narrative_RBS
					 , Narrative_VF
					 , ConsumerCombinationID_DD
				INTO #NewCombos
				FROM #ConsumerCombination_DD cc
				WHERE EXISTS (SELECT 1
							  FROM #Combos c
							  WHERE c.OIN = cc.OIN
							  AND c.Narrative_RBS LIKE cc.Narrative_RBS
							  AND c.Narrative_VF_Filled LIKE COALESCE(cc.Narrative_VF, ''))

				CREATE CLUSTERED INDEX CIX_OIN ON #NewCombos (OIN, Narrative_RBS)

				SET @Msg = '7.4.6.	Fetch all the consumer combination IDs for each combination in the transaction file'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

		/***********************************************************************************************************************
			7.5.	Update the ConsumerCombinationIDs in the transaction file
		***********************************************************************************************************************/

			UPDATE th
			SET th.ConsumerCombinationID_DD = nc.ConsumerCombinationID_DD
			FROM #TransactionHistory th
			INNER JOIN #NewCombos nc
				ON th.OIN = nc.OIN
				AND th.Narrative LIKE nc.Narrative_RBS

			SET @Msg = '7.5.	Update the ConsumerCombinationIDs in the transaction file'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

		/***********************************************************************************************************************
			7.6.	Insert the entries into [Staging].[ConsumerTransaction_DD_Holding]
		***********************************************************************************************************************/
			
			INSERT INTO [Staging].[ConsumerTransaction_DD_Holding] WITH (TABLOCK)
				([FileID], [RowNum], [ConsumerCombinationID_DD], [TranDate], [BankAccountID], [FanID], [Amount])
			SELECT FileID
				 , RowNum
				 , ConsumerCombinationID_DD
				 , [Date]
				 , BankAccountID
				 , FanID
				 , Amount
			FROM #TransactionHistory th

			SET @Msg = '7.6.	Insert the entries into [Staging].[ConsumerTransaction_DD_Holding]'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

		/***********************************************************************************************************************
			7.7.	Update the #FileID table to show insert is completed
		***********************************************************************************************************************/

			UPDATE #FileIDs
			SET Inserted = 1
			WHERE FileID = @FileID
			
		END

		SET @Msg = 'LOOP ENDS #####'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output


	/*******************************************************************************************************************************************
		8.	Fetch existing entries from [Relational].[ConsumerTransaction_DD] where the FanID can be backpopulated
	*******************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#ConsumerTransaction_DD_NoFanID') IS NOT NULL DROP TABLE #ConsumerTransaction_DD_NoFanID
		SELECT FileID
			 , RowNum
			 , BankAccountID
			 , FanID
		INTO #ConsumerTransaction_DD_NoFanID
		FROM [Relational].[ConsumerTransaction_DD] ct
		WHERE ct.FanID IS NULL
		AND EXISTS (SELECT 1
					FROM #MyRewardsCustomers mrc
					WHERE ct.BankAccountID = mrc.BankAccountID)

		CREATE NONCLUSTERED INDEX IX_BankAccountID ON #ConsumerTransaction_DD_NoFanID (BankAccountID, FanID)

		SET @Msg = '8.	Fetch existing entries from [Relational].[ConsumerTransaction_DD] where the FanID can be backpopulated'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

		/***********************************************************************************************************************
			8.1.	Update accounts with only one customer
		***********************************************************************************************************************/

			UPDATE ct
			SET ct.FanID = sa.FanID
			FROM #ConsumerTransaction_DD_NoFanID ct
			INNER JOIN #IssuerBankAccount_SoleAccount sa
				ON ct.BankAccountID = sa.BankAccountID

			SET @Msg = '8.1.	Update accounts with only one customer'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

		/***********************************************************************************************************************
			8.2.	Update joint accounts with the first customer to join
		***********************************************************************************************************************/

			UPDATE ct
			SET ct.FanID = ejc.FanID
			FROM #ConsumerTransaction_DD_NoFanID ct
			INNER JOIN #EarliestJoniingCustomer ejc
				ON ct.BankAccountID = ejc.BankAccountID
			WHERE ct.FanID IS NULL

			CREATE CLUSTERED INDEX CIX_All ON #ConsumerTransaction_DD_NoFanID (FileID, RowNum, FanID)

			SET @Msg = '8.2.	Update joint accounts with the first customer to join'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

	/*******************************************************************************************************************************************
		9.	Insert to [Relational].[ConsumerTransaction_DD]
	*******************************************************************************************************************************************/

			--IF INDEXPROPERTY(OBJECT_ID('[Relational].[ConsumerTransaction_DD]'), 'CSX_All', 'IndexId') IS NOT NULL
			--	BEGIN
			--		DROP INDEX [CSX_All] ON [Relational].[ConsumerTransaction_DD]

			--		DROP INDEX [UCX_FileIDRowNum] ON [Relational].[ConsumerTransaction_DD] 

			--		ALTER TABLE [Relational].[ConsumerTransaction_DD] ADD  CONSTRAINT [PK_Relational_ConsumerTransaction_DD] PRIMARY KEY CLUSTERED 
			--			([FileID] ASC,[RowNum] ASC,[TranDate] ASC) WITH (FILLFACTOR=90)
			--	END

			BEGIN TRY

				INSERT INTO [Relational].[ConsumerTransaction_DD] WITH (TABLOCK)
					(FileID, RowNum, ConsumerCombinationID_DD, TranDate, BankAccountID, FanID, Amount)
				SELECT 
					FileID, RowNum, ConsumerCombinationID_DD, TranDate, BankAccountID, FanID, Amount
				FROM [Staging].[ConsumerTransaction_DD_Holding] WITH (TABLOCK)

				SET @Msg = '9.	Insert to [Relational].[ConsumerTransaction_DD]'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output
	
			END TRY

			BEGIN CATCH

				DELETE ct
				FROM [Relational].[ConsumerTransaction_DD] ct
				WHERE EXISTS (SELECT 1
							  FROM #FileIDs fi
							  WHERE ct.FileID = fi.FileID)

				SET @Proceed = 0

			END CATCH

			UPDATE STATISTICS [Relational].[ConsumerTransaction_DD]

			--IF INDEXPROPERTY(OBJECT_ID('[Relational].[ConsumerTransaction_DD]'), 'CSX_All', 'IndexId') IS NULL
			--	BEGIN
			--		CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_All] ON [Relational].[ConsumerTransaction_DD] ([TranDate]
			--																								, [FanID]
			--																								, [Amount]
			--																								, [ConsumerCombinationID_DD]
			--																								, [BankAccountID]) ON Warehouse_Columnstores
			--	END

		IF @Proceed = 0
			BEGIN
				RETURN
			END

	/*******************************************************************************************************************************************
		10.	Insert new transactions to [AWSFile].[ConsumerTransaction_DDForFile]
	*******************************************************************************************************************************************/
		
		INSERT INTO [AWSFile].[ConsumerTransaction_DDForFile] WITH (TABLOCK)
			(FileID, RowNum, Amount, TranDate, BankAccountID, FanID, ConsumerCombinationID_DD)
		SELECT FileID
			 , RowNum
			 , Amount
			 , TranDate
			 , BankAccountID
			 , FanID
			 , ConsumerCombinationID_DD
		FROM [Staging].[ConsumerTransaction_DD_Holding] ct
		WHERE NOT EXISTS (SELECT 1
						  FROM [AWSFile].[ConsumerTransaction_DDForFile] ff
						  WHERE ct.FileID = ff.FileID
						  AND ct.RowNum = ff.RowNum)

		SET @Msg = '10.	Insert new transactions to [AWSFile].[ConsumerTransaction_DDForFile]'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

	/*******************************************************************************************************************************************
		11.	Insert new CCs to [Staging].[ConsumerCombination_DD_OINI]
	*******************************************************************************************************************************************/
		
		TRUNCATE TABLE [Staging].[ConsumerCombination_DD_OINI]
		INSERT INTO [Staging].[ConsumerCombination_DD_OINI] (ConsumerCombinationID_DD
														   , OIN
														   , Narrative_RBS
														   , Narrative_VF
														   , BrandID)
		SELECT ConsumerCombinationID_DD
			 , OIN
			 , Narrative_RBS
			 , Narrative_VF
			 , BrandID
		FROM [Relational].[ConsumerCombination_DD]
		WHERE ConsumerCombinationID_DD > @MaxConsumerCombinationID

		SET @Msg = '11.	Insert new CCs to [Staging].[ConsumerCombination_DD_OINI]'; EXEC [Staging].[oo_TimerMessage_V2] @Msg , @Time Output

		
				UPDATE ct
				SET ct.FanID = nf.FanID
				FROM [Relational].[ConsumerTransaction_DD] ct
				INNER JOIN #ConsumerTransaction_DD_NoFanID nf
					ON ct.FileID = nf.FileID
					AND ct.RowNum = nf.RowNum

END