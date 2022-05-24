/*
		Author:		Rory Francis
		
		Date:		2019-04-26

		Purpose:	For those people that have had a MyReward account open 60 or 120 days and did not earn enough in the last calendar month

		UPDATE:		06-04-2017 SB - Amended to deal WITH new cashback rate and therefore they now only need to earn £2
								  - Also CONVERTed heaps to CLUSTERED INDEXed tables
*/

CREATE PROCEDURE [SmartEmail].[TriggerEmail_ProductMonitoring] (@Days INT)
AS
BEGIN

	INSERT INTO staging.JobLog_Temp
	SELECT	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'SLC_Report_ProductMonitoring',
			StartDate = GETDATE(),
			EndDate = NULL,
			TableRowCount  = NULL,
			AppendReload = 'R'
			


/*******************************************************************************************************************************************
	1.	Fetch offer, account & transaction type details
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		1.1.  Fetch all Accounts and IronOfferIDs that can be earnt on
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#AccountsOffers') IS NOT NULL DROP TABLE #AccountsOffers
		SELECT BankAccountType
			 , IssuerID
			 , ClubID
			 , IronOfferID
			 , iof.EndDate AS IronOfferEndDate
		INTO #AccountsOffers
		FROM [SLC_Report].[dbo].[BankAccountTypeEligibility] bate
		INNER JOIN [Staging].[DirectDebit_EligibleAccounts] dde
			ON bate.BankAccountType = dde.AccountType
			AND bate.IssuerID = (CASE WHEN dde.ClubID = 138 THEN 1 ELSE 2 END)
		INNER JOIN [SLC_Report].[dbo].[IronOffer] iof
			ON bate.IronOfferID = iof.ID
		WHERE bate.DirectDebitEligible = 1
		AND dde.LoyaltyFeeAccount = 1
		AND (iof.EndDate IS NULL OR iof.EndDate > GETDATE())

		CREATE CLUSTERED INDEX CIX_IronOfferID ON #AccountsOffers (IronOfferID)

	/***********************************************************************************************************************
		1.2.  Fetch the transaction TypeIDs that these come through
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Types') IS NOT NULL DROP TABLE #Types
		SELECT a.AdditionalCashbackAwardTypeID
			 , a.TransactionTypeID
			 , a.ItemID
		INTO #Types
		FROM [Relational].[AdditionalCashbackAwardType] a
		WHERE [Description] LIKE '%Reward%3%'

		CREATE CLUSTERED INDEX CIX_TransID_ItemID ON #Types (TransactionTypeID, ItemID)

/*******************************************************************************************************************************************
	2.	Fetch relevant customers, their account and the details of customers who they are on joint accounts with
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		2.1.  Fetch all all current loyalty customers
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#Loyalty') IS NOT NULL DROP TABLE #Loyalty
		SELECT fa.ID AS FanID
			 , fa.CompositeID
			 , fa.SourceUID
			 , fa.ClubID
		INTO #Loyalty
		FROM [SLC_Report].[dbo].[Fan] fa
		WHERE EXISTS (SELECT 1
						FROM [Staging].[SLC_Report_DailyLoad_Phase2DataFields] p2d
						WHERE p2d.LoyaltyAccount = 1
						AND p2d.FanID = fa.ID)

		CREATE CLUSTERED INDEX CIX_Fan on #Loyalty (CompositeID)

	/***********************************************************************************************************************
		2.2.  Fetch all current loyalty customers that opened an account x days ago
	***********************************************************************************************************************/

		--DECLARE @Days INT = 125
		DECLARE @Date DATE = DATEADD(day, - @Days, GETDATE())


		IF OBJECT_ID('tempdb..#CustomersToReview') IS NOT NULL DROP TABLE #CustomersToReview
		SELECT l.FanID
			 , l.CompositeID
			 , l.SourceUID
			 , l.ClubID
			 , MIN(iom.StartDate) AS StartDate
		INTO #CustomersToReview
		FROM #Loyalty l
		INNER JOIN [SLC_Report].[dbo].[IronOfferMember] iom
			ON l.CompositeID = iom.CompositeID
		INNER JOIN #AccountsOffers ao
			ON iom.IronOfferID = ao.IronOfferID
		GROUP BY l.FanID
			   , l.CompositeID
			   , l.ClubID
			   , l.SourceUID
		HAVING MAX(CASE WHEN iom.EndDate IS NULL THEN 1 ELSE 0 END) = 1
		AND MIN(iom.StartDate) = @Date

		CREATE CLUSTERED INDEX CIX_SourceUID ON #CustomersToReview (SourceUID)
		CREATE NONCLUSTERED INDEX IX_FanID ON #CustomersToReview (FanID)


	/***********************************************************************************************************************
		2.3.  Fetch all the accounts of the previously fetched customers
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#BankAccountID') IS NOT NULL DROP TABLE #BankAccountID
		SELECT DISTINCT
			   bat.BankAccountID
			 , bat.Type
		INTO #BankAccountID
		FROM #CustomersToReview cu
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON cu.SourceUID = ic.SourceUID
			AND CONCAT(cu.ClubID, ic.IssuerID) IN (1322, 1381)
		INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
			ON ic.ID = iba.IssuerCustomerID
		INNER JOIN [SLC_Report].[dbo].[BankAccountTypeHistory] bat
			ON iba.BankAccountID = bat.BankAccountID
		WHERE bat.EndDate IS NULL
		AND iba.CustomerStatus = 1
		AND EXISTS (	SELECT 1
						FROM #AccountsOffers ao
						WHERE bat.Type = ao.BankAccountType)

		CREATE CLUSTERED INDEX CIX_ID ON #BankAccountID (BankAccountID, Type)
		
		IF OBJECT_ID('tempdb..#BankAccounts') IS NOT NULL DROP TABLE #BankAccounts
		SELECT DISTINCT
			   bat.BankAccountID
			 , bat.Type
			 , CASE
					WHEN bat.Type = 'QE' THEN 'Premier Reward Black'
					WHEN bat.Type = 'QB' THEN 'Premier Reward'
					WHEN bat.Type = 'QD' THEN 'Reward Platinum'
					WHEN bat.Type = 'QC' THEN 'Reward Silver'
					WHEN bat.Type = 'QA' THEN 'Reward'
			   END AS TypeDesc
			 , CASE
					WHEN bat.Type = 'QE' THEN 1
					WHEN bat.Type = 'QB' THEN 2
					WHEN bat.Type = 'QD' THEN 3
					WHEN bat.Type = 'QC' THEN 4
					WHEN bat.Type = 'QA' THEN 5
			   END AS TypeRank
			 , iba.ID AS IssuerBankAccountID
			 , fa.ID AS FanID
			 , fa.CompositeID
			 , ic.SourceUID
			 , fa.ClubID
			 , CASE
					WHEN ctr.FanID IS NOT NULL THEN 1
					ELSE 0
			   END AS CustomerToReview
			 , CONVERT(INT, NULL) AS CustomersPerAccount
		INTO #BankAccounts
		FROM [SLC_Report].[dbo].[BankAccountTypeHistory] bat
		INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
			ON bat.BankAccountID = iba.BankAccountID
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON ic.SourceUID = fa.SourceUID
			AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)
		LEFT JOIN #CustomersToReview ctr
			ON fa.ID = ctr.FanID
		WHERE bat.EndDate IS NULL
		AND iba.CustomerStatus = 1
		AND EXISTS (	SELECT 1
						FROM #BankAccountID ba
						WHERE bat.BankAccountID = ba.BankAccountID
						AND bat.Type = ba.Type)

		;WITH
		BankAccountsUpdater AS (SELECT BankAccountID
									 , COUNT(DISTINCT FanID) AS CustomersPerAccount
								FROM #BankAccounts
								GROUP BY BankAccountID)

		UPDATE ba
		SET ba.CustomersPerAccount = bau.CustomersPerAccount
		FROM #BankAccounts ba
		INNER JOIN BankAccountsUpdater bau
			ON ba.BankAccountID = bau.BankAccountID

		CREATE CLUSTERED INDEX CIX_FanID ON #BankAccounts (FanID)


/*******************************************************************************************************************************************
	3.	Fetch all relevant transactions in the last 35 days and aggregate
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		3.1.  Fetch all relevant transactions in the last 35 days
	***********************************************************************************************************************/

		DECLARE @Today DATETIME = GETDATE()
			  , @35DaysAgo DATETIME = DATEADD(DAY, -35, GETDATE())

		IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
		SELECT tr.IssuerBankAccountID
			 , SUM(tr.ClubCash) AS ClubCash
		INTO #Trans
		FROM [SLC_Report].[dbo].[Trans] tr
		WHERE tr.Date BETWEEN @35DaysAgo AND @Today
		AND EXISTS (SELECT 1
					FROM #Types ty
					WHERE tr.TypeID = ty.TransactionTypeID
					AND tr.ItemID = ty.ItemID)
		AND EXISTS (SELECT 1
					FROM #BankAccounts ba
					WHERE tr.FanID = ba.FanID)
		GROUP BY tr.IssuerBankAccountID


	/***********************************************************************************************************************
		3.2.  Identify accounts that have £2 or above spend
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#AccountEarnings') IS NOT NULL DROP TABLE #AccountEarnings
		SELECT ba.BankAccountID
			 , SUM(ClubCash) AS ClubCash
		INTO #AccountEarnings
		FROM #Trans tr
		INNER JOIN #BankAccounts ba
			ON tr.IssuerBankAccountID = ba.IssuerBankAccountID
		GROUP BY ba.BankAccountID


/*******************************************************************************************************************************************
	4.	Select only customers who have not less than £2
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#CustomersToEmail') IS NOT NULL DROP TABLE #CustomersToEmail
	SELECT ba.FanID
		 , ba.BankAccountID
		 , ba.Type
		 , ba.TypeDesc
		 , ba.TypeRank
		 , ba.ClubID
		 , COALESCE(ae.ClubCash, 0) AS ClubCashAccount
		 , SUM(COALESCE(ae.ClubCash, 0)) OVER (PARTITION BY ba.FanID) AS ClubCashCustomer
		 , CASE
				WHEN CustomersPerAccount = 1 THEN 0
				ELSE 1
		   END AS JointAccount
	INTO #CustomersToEmail
	FROM #BankAccounts ba
	LEFT JOIN #AccountEarnings ae
		ON ba.BankAccountID = ae.BankAccountID
	WHERE CustomerToReview = 1
	AND COALESCE(ae.ClubCash, 0) < 2

	;WITH
	PriortyBankAccount AS (	SELECT cte.FanID
								 , cte.BankAccountID
								 , RANK() OVER (PARTITION BY cte.FanID ORDER BY cte.TypeRank, cte.BankAccountID) AS TypeRankNew
							FROM #CustomersToEmail cte)

	UPDATE cte
	SET cte.TypeRank = pba.TypeRankNew
	FROM #CustomersToEmail cte
	INNER JOIN PriortyBankAccount pba
		ON cte.FanID = pba.FanID
		AND cte.BankAccountID = pba.BankAccountID


/*******************************************************************************************************************************************
	5.	Select the highest priority account type to email
*******************************************************************************************************************************************/

	IF @Days = 65
		BEGIN
			TRUNCATE TABLE [Staging].[SLC_Report_ProductMonitoring]
			INSERT INTO [Staging].[SLC_Report_ProductMonitoring] (FanID
																, Day60AccountName
																, Day120AccountName
																, JointAccount)
			SELECT cte.FanID AS [Customer ID]
				 , cte.TypeDesc
				 , NULL
				 , cte.JointAccount
			FROM #CustomersToEmail cte
			WHERE cte.TypeRank = 1
		END

	IF @Days = 125
		BEGIN
			INSERT INTO [Staging].[SLC_Report_ProductMonitoring] (FanID
																, Day60AccountName
																, Day120AccountName
																, JointAccount)
			SELECT DISTINCT
				   cte.FanID
				 , NULL
				 , cte.TypeDesc
				 , cte.JointAccount
			FROM #CustomersToEmail cte
			WHERE cte.TypeRank = 1
		END

/*--------------------------------------------------------------------------------------------------
---------------------------UPDATE entry in JobLog Table WITH End Date-------------------------------
----------------------------------------------------------------------------------------------------*/

UPDATE  staging.JobLog_Temp
Set		EndDate = GETDATE(),
		TableRowCount = (SELECT Count(FanID) FROM [Staging].[SLC_Report_ProductMonitoring])
WHERE	StoredProcedureName = OBJECT_NAME(@@PROCID) and
		TableSchemaName = 'Staging' and
		TableName = 'SLC_Report_ProductMonitoring' and
		EndDate IS NULL

/*--------------------------------------------------------------------------------------------------
---------------------------------------  UPDATE JobLog Table ---------------------------------------
----------------------------------------------------------------------------------------------------*/

INSERT INTO staging.JobLog
SELECT [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
FROM staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp


END