/*
Migration changes 21/09/2021
Columnstore index is removed
*/

CREATE PROCEDURE [Relational].[CTDDL_CT_MyRewards_Load]
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	/*******************************************************************************************************************************************
		1.	Fetch MyRewards customers
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
		-- 4,318,978 / 00:00:12

		CREATE CLUSTERED INDEX CIX_BankAccountID ON #MyRewardsCustomers (BankAccountID)
		-- 00:00:08

	/*******************************************************************************************************************************************
		2.	Insert to [Relational].[ConsumerTransaction_DD_MyRewards] on Mondays
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Fetch all transactions 
		***********************************************************************************************************************/
	

			IF OBJECT_ID('tempdb..#MissingEntries') IS NOT NULL DROP TABLE #MissingEntries
			SELECT ct.*
			INTO #MissingEntries
			FROM [Relational].[ConsumerTransaction_DD] ct
			INNER JOIN #MyRewardsCustomers mrc
				ON ct.BankAccountID = mrc.BankAccountID
			WHERE NOT EXISTS (SELECT 1
							  FROM [Relational].[ConsumerTransaction_DD_MyRewards] ctmr
							  WHERE ct.FileID = ctmr.FileID
							  AND ct.RowNum = ctmr.RowNum)
			-- 34,565,305 / 01:42:58


		/***********************************************************************************************************************
			2.2. Add all new transactions to [Relational].[ConsumerTransaction_DD_MyRewards]
		***********************************************************************************************************************/

			IF INDEXPROPERTY(OBJECT_ID('[Relational].[ConsumerTransaction_DD_MyRewards]'), 'CSX_All', 'IndexId') IS NOT NULL BEGIN
				DROP INDEX [CSX_All] ON [Relational].[ConsumerTransaction_DD_MyRewards]
			END

			INSERT INTO [Relational].[ConsumerTransaction_DD_MyRewards] WITH (TABLOCK)
				([FileID], [RowNum], [ConsumerCombinationID_DD], [TranDate], [BankAccountID], [FanID], [Amount])
			SELECT 
					[FileID], [RowNum], [ConsumerCombinationID_DD], [TranDate], [BankAccountID], [FanID], [Amount]
			FROM #MissingEntries WITH (TABLOCK)
			ORDER BY FileID, RowNum, TranDate
			-- 34,565,305 / 00:04:54 
			

			--IF INDEXPROPERTY(OBJECT_ID('[Relational].[ConsumerTransaction_DD_MyRewards]'), 'CSX_All', 'IndexId') IS NULL
			--	BEGIN
			--		CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_All] ON [Relational].[ConsumerTransaction_DD_MyRewards] ([TranDate]
			--																										  , [FanID]
			--																										  , [Amount]
			--																										  , [ConsumerCombinationID_DD]
			--																										  , [BankAccountID])
			--	END

END