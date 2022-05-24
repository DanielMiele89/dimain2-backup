/*
		Author:			Stuart Barnley

		Date:			29th April 2016

		Purpose:		Find the customer who have earned for the first time on paid for 
						Direct Debit.

		UPDATE:			SB 2017-07-03 - Amendment made to INCLUDE both DD trans (3% and 2%)
		

*/

CREATE PROCEDURE [Staging].[SLC_Report_DailyLoad_FirstEarnDD_V2]
AS
BEGIN

		DECLARE @YesterdayDateTime DATETIME = DATEADD(day, DATEDIFF(dd, 0, GETDATE()) - 1, 0)

	---------------------------------------------------------------------------------------------------------
	---------------------Customers who are MyRewards DD Customers who have never earnt-----------------------
	---------------------------------------------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#DDCustomers') IS NOT NULL DROP TABLE #DDCustomers
		SELECT a.FanID
		INTO #DDCustomers
		FROM [Staging].[SLC_Report_DailyLoad_Phase2DataFields] a
		WHERE a.LoyaltyAccount = 1
		AND NOT EXISTS (SELECT 1
						FROM [Staging].[Customer_FirstEarnDDPhase2] b
						WHERE a.FanID = b.FanID)

		CREATE CLUSTERED INDEX CIX_FanID ON #DDCustomers (FanID)

	---------------------------------------------------------------------------------------------------------
	-------------------Transaction type entries that relate to Paid for DD incentivisation-------------------
	---------------------------------------------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#TranTypes') IS NOT NULL DROP TABLE #TranTypes
		SELECT TransactionTypeID
			 , ItemID
		INTO #TranTypes
		FROM [Relational].[AdditionalCashbackAwardType]
		WHERE [Description] LIKE '%Direct Debit%MyRewards%' --****** Changed AS new title does not INCLUDE the word MyRewards

		CREATE CLUSTERED INDEX CIX_All on #TranTypes (TransactionTypeID, ItemID)


	---------------------------------------------------------------------------------------------------------
	---------------------Customers who are MyRewards DD Customers who have never earnt-----------------------
	---------------------------------------------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
		SELECT DISTINCT
			   c.FanID
			 , t.ProcessDate
			 , t.IssuerBankAccountID
		INTO #Trans
		FROM #TranTypes tt
		INNER HASH JOIN [SLC_Report].[dbo].[Trans] t WITH (NOLOCK)
			ON t.TypeID = tt.TransactionTypeID
			AND t.ItemID = tt.ItemID
		INNER JOIN #DDCustomers c
			ON c.FanID = t.FanID
		WHERE CONVERT(DATE, t.ProcessDate) = @YesterdayDateTime


	---------------------------------------------------------------------------------------------------------
	-------------------------- Find the bank accounts that have earned cashback -----------------------------
	---------------------------------------------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#BankAccounts') IS NOT NULL DROP TABLE #BankAccounts
		SELECT FanID
			 , FirstEarnValue
			 , FirstEarndate
			 , BankAccountID
			 , MyRewardAccount
			 , ROW_NUMBER() OVER (PARTITION BY FanID ORDER BY CASE
																	WHEN MyRewardAccount LIKE '%Black%' THEN 0
																	WHEN MyRewardAccount LIKE '%Platin%' THEN 1
																	WHEN MyRewardAccount LIKE '%Silver%' THEN 2
																	WHEN MyRewardAccount LIKE '%Reward%' THEN 3
																	ELSE 99
															  END ASC) AS RowNo
		INTO #BankAccounts
		FROM (SELECT DISTINCT
	  				 FanID
	  			   , 0.00 AS FirstEarnValue
	  			   , @YesterdayDateTime AS FirstEarnDate
	  			   , ba.BankAccountID
	  			   , CASE
	  	     			WHEN ea.AccountType IS NULL THEN ''
	  	     			ELSE REPLACE(ea.AccountName, ' Account', '')
	  				 END AS MyRewardAccount
			  FROM #Trans t
			  INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iab
	  			  ON t.IssuerBankAccountID = iab.ID
			  INNER JOIN [SLC_Report].[dbo].[BankAccountTypeHistory] ba
	  			  ON iab.BankAccountID = ba.BankAccountID
				  AND ba.EndDate IS NULL
			  LEFT JOIN [Staging].[DirectDebit_EligibleAccounts] ea
	  			  ON ba.Type = ea.AccountType
				  AND ea.AccountType LIKE 'Q_') a -- Only paid for accounts


	---------------------------------------------------------------------------------------------------------
	---------------------------- Add entry to indicate earn for the first time ------------------------------
	---------------------------------------------------------------------------------------------------------

		INSERT INTO [Staging].[Customer_FirstEarnDDPhase2]
		SELECT FanID
			 , FirstEarnValue
			 , FirstEarnDate
			 , BankAccountID
			 , MyRewardAccount
		FROM #BankAccounts ba
		WHERE RowNo = 1

END

RETURN 0