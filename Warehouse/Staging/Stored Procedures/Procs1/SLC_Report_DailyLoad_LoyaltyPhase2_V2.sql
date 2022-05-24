
CREATE PROCEDURE [Staging].[SLC_Report_DailyLoad_LoyaltyPhase2_V2]
AS
BEGIN

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	--------------------------------------------------------------------------------------------------*/

		INSERT INTO staging.JobLog_Temp
		SELECT	StoredProcedureName = OBJECT_NAME(@@PROCID),
				TableSchemaName = 'N/A',
				TableName = 'N/A',
				StartDate = GETDATE(),
				EndDate = NULL,
				TableRowCount  = NULL,
				AppendReload = ''
			
	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------	
	
		DECLARE @Date DATE = GETDATE()
			
		IF OBJECT_ID('tempdb..#IronOffer') IS NOT NULL DROP TABLE #IronOffer
		SELECT DISTINCT
			   a.IronOfferID
		INTO #IronOffer
		FROM [SLC_Report].[dbo].[BankAccountTypeEligibility] a
		INNER JOIN [Staging].[DirectDebit_EligibleAccounts] e
			ON a.BankAccountType = e.AccountType
			AND a.IssuerID = CASE
								WHEN e.ClubID = 138 THEN 1
								ELSE 2
							 END
		INNER JOIN [SLC_Report].[dbo].[IronOffer] iof
			ON a.IronOfferID  = iof.id
		WHERE a.DirectDebitEligible = 1
		AND e.LoyaltyFeeAccount = 1
		AND (@Date BETWEEN iof.StartDate AND iof.EndDate OR iof.EndDate IS NULL)

	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#LoyaltyAccounts') IS NOT NULL DROP TABLE #LoyaltyAccounts;
		WITH
		IronOfferMember AS (SELECT iom.CompositeID
							FROM [SLC_Report].[dbo].[IronOfferMember] iom
							WHERE EXISTS (SELECT 1
										  FROM #IronOffer iof
										  WHERE iom.IronOfferID = iof.IronOfferID)
							AND (@Date BETWEEN iom.StartDate AND iom.EndDate OR iom.EndDate IS NULL))

		SELECT fa.ID AS FanID
			 , CONVERT(NVARCHAR(20), fa.SourceUID) AS SourceUID
			 , CASE
					WHEN ClubID = 132 THEN 2
					ELSE 1
			   END AS IssuerID
		INTO #LoyaltyAccounts
		FROM [SLC_Report].[dbo].[Fan] fa
		WHERE fa.ClubID IN (132, 138)
		AND fa.[Status] = 1
		AND AgreedTCs = 1
		AND EXISTS (SELECT 1
					FROM IronOfferMember iom
					WHERE fa.CompositeID = iom.CompositeID)

		CREATE CLUSTERED INDEX CIX_All on #LoyaltyAccounts (FanID)


	-------------------------------------------------------------------------------------
	------------------------Populate Ware table for later use----------------------------
	-------------------------------------------------------------------------------------
			
		TRUNCATE Table Staging.LoyaltyPhase2Customers
		INSERT INTO Staging.LoyaltyPhase2Customers
		SELECT FanID
		FROM #LoyaltyAccounts
		

	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#AccountNames') IS NOT NULL DROP TABLE #AccountNames
		SELECT la.FanID
			 , REPLACE(e.AccountName, 'Account', 'account') AS AccountName
			 , ba.ID AS BankAccountID
			 , ba.MaskedAccountNumber
			 , ic.ID AS IssuerCustomerID
			 , ba.Date AccountSD
			 , ba.Status
			 , ba.Date BADate
			 , ba.LastStatusChangeDate
			 , BAh.StartDate AS TypeSD
			 , e.ID AS Ranking
		INTO #AccountNames
		FROM #LoyaltyAccounts la
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON la.SourceUID = ic.SourceUID
			AND la.IssuerID = ic.IssuerID
		INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
			ON ic.ID = iba.IssuerCustomerID
			AND (iba.CustomerStatus = 1 OR iba.CustomerStatus IS NULL)
		INNER JOIN [SLC_Report].[dbo].[BankAccount] ba 
			ON iba.BankAccountID = ba.ID
			AND (ba.[Status] = 1 OR ba.[Status] IS NULL)
		INNER JOIN [SLC_Report].[dbo].[BankAccountTypeHistory] bah 
			ON bah.BankAccountID = iba.BankAccountID
			AND bah.EndDate IS NULL	
		INNER JOIN Staging.DirectDebit_EligibleAccounts e
			ON bah.[Type] = e.AccountType
			AND ((la.IssuerID = 2 AND e.ClubID = 132) OR (la.IssuerID = 1 AND e.ClubID = 138))
			AND e.LoyaltyFeeAccount = 1
		WHERE NOT EXISTS (SELECT 1
						  FROM Staging.Customer_FirstEarnDDPhase2 dde
						  WHERE la.FanID = dde.FanID
						  AND ba.ID = dde.BankAccountID)


	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#NomineeAccounts') IS NOT NULL DROP TABLE #NomineeAccounts
		SELECT acn.FanID
			 , acn.BankAccountID
			 , acn.AccountName
			 , RIGHT(MaskedAccountNumber, 3) AS AccountNo
			 , CONVERT(DATE, ChangedDate) AS ChangeDate
		INTO #NomineeAccounts
		FROM #AccountNames acn
		INNER JOIN [SLC_Report].[dbo].[DDCashbackNominee] dd
			ON acn.BankAccountID = dd.BankAccountID
			AND acn.IssuerCustomerID = dd.IssuerCustomerID
			AND dd.EndDate IS NULL


	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
		
		TRUNCATE Table Staging.Customer_DDNotEarned
		INSERT INTO Staging.Customer_DDNotEarned
		SELECT FanID
			 , BankAccountID
			 , AccountName
			 , AccountNo
			 , ChangeDate
		FROM #NomineeAccounts
		WHERE ChangeDate IS NOT NULL
		AND AccountName IS NOT NULL
		AND AccountNo IS NOT NULL
		AND BankAccountID IS NOT NULL

	/*--------------------------------------------------------------------------------------------------
	---------------------------UPDATE entry in JobLog Table WITH End Date-------------------------------
	---------------------------------------------------------------------------------------------------*/

		UPDATE  staging.JobLog_Temp
		Set		EndDate = GETDATE()
		WHERE	StoredProcedureName = OBJECT_NAME(@@PROCID) and
				TableSchemaName = 'N/A' and
				TableName = 'N/A' and
				EndDate IS NULL

	/*--------------------------------------------------------------------------------------------------
	---------------------------------------  UPDATE JobLog Table ---------------------------------------
	---------------------------------------------------------------------------------------------------*/

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