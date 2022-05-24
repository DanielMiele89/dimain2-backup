/********************************************************************************************
	Name: SmartEmail.SFD_DailyLoad_TrigEmail_MFDD
	Desc: Identify customers who are set to recieve either their first or second earn on MFDD offers
	Auth: Rory Francis

	Change History
				
	
*********************************************************************************************/

CREATE PROCEDURE [SmartEmail].[SFD_DailyLoad_TrigEmail_MFDD]
AS
BEGIN

	SET NOCOUNT ON

/*******************************************************************************************************************************************
	1. Declare variables
*******************************************************************************************************************************************/

	DECLARE @Yesterday DATE = DATEADD(day, -1, GETDATE())
		  , @Today DATE = GETDATE()

/*******************************************************************************************************************************************
	2. Fetch all live MFDD offers
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#IronOffer') IS NOT NULL DROP TABLE #IronOffer
	SELECT iof.PartnerID
		 , iof.IronOfferID
		 , iof.IronOfferName
		 , iof.StartDate
		 , iof.EndDate
	INTO #IronOffer
	FROM [Relational].[IronOffer] iof
	WHERE IronOfferName LIKE '%MFDD%'

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOffer (IronOfferID, StartDate, EndDate)

	
/***********************************************************************************************************************
	3. Fetch all live offer memberships
***********************************************************************************************************************/

	DECLARE @MinStartDate DATE = (SELECT MIN(StartDate) FROM #IronOffer)

	IF OBJECT_ID('tempdb..#IOM') IS NOT NULL DROP TABLE #IOM
	SELECT iof.PartnerID
		 , iom.IronOfferID
		 , iom.CompositeID
		 , MIN(iom.StartDate) AS StartDate
		 , MAX(iom.EndDate) AS EndDate
	INTO #IOM
	FROM [Relational].[IronOfferMember] iom
	INNER JOIN #IronOffer iof
		ON iom.IronOfferID = iof.IronOfferID
		AND iom.StartDate BETWEEN iof.StartDate AND iof.EndDate
	WHERE @MinStartDate <= iom.StartDate
	GROUP BY iof.PartnerID
		   , iom.IronOfferID
		   , iom.CompositeID

	CREATE CLUSTERED INDEX CIX_CompositeID ON #IOM (CompositeID)

	IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember
	SELECT	DISTINCT
			iom.PartnerID
		,	iom.IronOfferID
		,	fa.ID AS FanID
		,	iom.CompositeID
		,	fa.SourceUID
		,	ic.ID AS IssuerCustomerID
		,	iom.StartDate
		,	iom.EndDate
	INTO #IronOfferMember
	FROM #IOM iom
	INNER JOIN [SLC_Report].[dbo].[Fan] fa
		ON iom.CompositeID = fa.CompositeID
	INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
		ON fa.SourceUID = ic.SourceUID
		
	CREATE CLUSTERED INDEX CIX_IssuerCustomerID ON #IronOfferMember (IssuerCustomerID)
	CREATE NONCLUSTERED INDEX IX_SourceUID ON #IronOfferMember (SourceUID)
	CREATE NONCLUSTERED INDEX IX_FanID ON #IronOfferMember (FanID)
	

/*******************************************************************************************************************************************
	4. Fetch all eligible entries for MFDD offers in the match table
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		4.1. Fetch all DirectDebitOriginator ID's for MFDD incentivised OINs
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#IncentivisedOINs') IS NOT NULL DROP TABLE #IncentivisedOINs
		SELECT	DISTINCT
				ddo.ID
			,	ino.PartnerID
			,	pcr.RequiredIronOfferID AS IronOfferID
			,	ino.OIN
			,	pcr.ID AS PartnerCommissionRuleID
		INTO #IncentivisedOINs
		FROM [Relational].[DirectDebitOriginator] ddo
		INNER JOIN [Relational].[DirectDebit_MFDD_IncentivisedOINs] ino
			ON ddo.OIN = ino.OIN
		INNER JOIN [SLC_Report].[dbo].[PartnerCommissionRule] pcr
			ON ino.PartnerID = pcr.PartnerID
		WHERE EXISTS (SELECT 1
					  FROM #IronOffer iof
					  WHERE ino.PartnerID = iof.PartnerID)

		CREATE CLUSTERED INDEX CIX_ID ON #IncentivisedOINs (PartnerCommissionRuleID, ID)


	/***********************************************************************************************************************
		4.2. Fetch all entries for OINs having a RewardStatus of incentivised or 'MFDD insufficient prior transactions'
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#Match_Temp') IS NOT NULL DROP TABLE #Match_Temp
		SELECT	TOP 10000000
				ma.ID AS MatchID
			,	ma.IssuerBankAccountID
			,	ma.Amount
			,	ma.TransactionDate
			,	ma.RewardStatus
			,	ma.Status
			,	ma.AddedDate
			,	ma.DirectDebitOriginatorID
			,	ma.PartnerCommissionRuleID
			,	ino.PartnerID
			,	ino.IronOfferID
			,	ino.OIN
		INTO #Match_Temp
		FROM [SLC_Report].[dbo].[Match] ma
		INNER JOIN #IncentivisedOINs ino
			ON ma.DirectDebitOriginatorID = ino.ID
			AND ma.PartnerCommissionRuleID = ino.PartnerCommissionRuleID
		WHERE 275968085 < ma.ID
		AND ma.VectorID = 40
		AND RewardStatus IN (1, 15)
		ORDER BY ma.ID DESC

		CREATE CLUSTERED INDEX CIX_ID ON #Match_Temp (IssuerBankAccountID)

		IF OBJECT_ID('tempdb..#Match') IS NOT NULL DROP TABLE #Match
		SELECT	ma.MatchID
			,	ma.IssuerBankAccountID
			,	fa.ID AS FanID
			,	ma.Amount
			,	ma.TransactionDate
			,	ma.RewardStatus
			,	ma.Status
			,	ma.AddedDate
			,	ma.DirectDebitOriginatorID
			,	ma.PartnerCommissionRuleID
			,	ma.PartnerID
			,	ma.IronOfferID
			,	ma.OIN
		INTO #Match
		FROM #Match_Temp ma
		INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
			ON ma.IssuerBankAccountID = iba.ID
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON ic.SourceUID = fa.SourceUID
		
		CREATE CLUSTERED INDEX CIX_IssuerBankAccountID ON #Match (IssuerBankAccountID)
		CREATE NONCLUSTERED INDEX IX_MatchID ON #Match (MatchID)
	

/*******************************************************************************************************************************************
	5. Fetch all banck account infomration including nominee details
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		5.1. Fetch all banck account details where a member is on the offer and has had transaction
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#IssuerBankAccount') IS NOT NULL DROP TABLE #IssuerBankAccount
		SELECT iba.BankAccountID
			 , iba.ID AS IssuerBankAccountID
			 , iba.IssuerCustomerID
			 , fa.ID AS FanID
			 , fa.CompositeID
			 , ic.SourceUID
			 , NULL AS IsAccountNominee
			 , COUNT(*) OVER (PARTITION BY iba.BankAccountID) AS CustomerPerBankAccount
			 , MIN(iba.IssuerCustomerID) OVER (PARTITION BY iba.BankAccountID) AS MinIssuerCustomerID
		INTO #IssuerBankAccount
		FROM [SLC_Report].[dbo].[IssuerBankAccount] iba
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON ic.SourceUID = fa.SourceUID
		WHERE CustomerStatus = 1
		AND EXISTS (SELECT 1
					FROM #IronOfferMember iom
					INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba_o
						ON iom.IssuerCustomerID = iba_o.IssuerCustomerID
					WHERE CustomerStatus = 1
					AND iba.BankAccountID = iba_o.BankAccountID)
		AND EXISTS (SELECT 1
					FROM #Match ma
					INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba_o
						ON ma.IssuerBankAccountID = iba_o.ID
					WHERE CustomerStatus = 1
					AND iba.BankAccountID = iba_o.BankAccountID)
		
		CREATE CLUSTERED INDEX CIX_BankAccountID ON #IssuerBankAccount (BankAccountID)
		CREATE NONCLUSTERED INDEX IX_SourceUID ON #IssuerBankAccount (SourceUID)

	/***********************************************************************************************************************
		5.2. Fetch the nominees from each of the above accounts
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#DDCashbackNominee') IS NOT NULL DROP TABLE #DDCashbackNominee
		SELECT nm.BankAccountID
			 , fa.CompositeID
		INTO #DDCashbackNominee
		FROM [SLC_Report].[dbo].[DDCashbackNominee] nm
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
			ON nm.IssuerCustomerID = ic.ID
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON ic.SourceUID = fa.SourceUID
		WHERE nm.EndDate IS NULL
		AND EXISTS (SELECT 1
					FROM #IssuerBankAccount iba
					WHERE nm.BankAccountID = iba.BankAccountID)
		
		CREATE CLUSTERED INDEX CIX_BankAccountID ON #DDCashbackNominee (BankAccountID)

	/***********************************************************************************************************************
		5.3. Update nominee details
	***********************************************************************************************************************/
					
		/*******************************************************************************************************************
			5.3.1. For customers with joint accounts, set the Nominee flag for each account
		*******************************************************************************************************************/

			UPDATE iba
			SET IsAccountNominee = CASE
										WHEN iba.CompositeID = nm.CompositeID THEN 1
										ELSE 0
								   END
			FROM #IssuerBankAccount iba
			INNER JOIN #DDCashbackNominee nm
				ON iba.BankAccountID = nm.BankAccountID;
					
		/*******************************************************************************************************************
			5.3.2. For customers with sole accounts, set the Nominee flag for the account
		*******************************************************************************************************************/
		
			WITH
			SoleAccounts AS (SELECT iba.BankAccountID
							 	  , iba.IsAccountNominee
							 FROM #IssuerBankAccount iba
							 WHERE CustomerPerBankAccount = 1
							 AND NOT EXISTS (SELECT 1
							 				 FROM #DDCashbackNominee nm
							 				 WHERE iba.BankAccountID = nm.BankAccountID))
			
			UPDATE SoleAccounts
			SET IsAccountNominee = 1
					
		/*******************************************************************************************************************
			5.3.3. For customers with joint accounts but no assign the nominee, assume the customer with lowest ID
		*******************************************************************************************************************/
		
			UPDATE iba
			SET IsAccountNominee = CASE
										WHEN IssuerCustomerID = MinIssuerCustomerID THEN 1
										ELSE 0
								   END
			FROM #IssuerBankAccount iba
			WHERE IsAccountNominee IS NULL
			

/*******************************************************************************************************************************************
	6. Restrict the IronOfferMember table to those bank accounts that have had a transaction
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#IronOfferMember_Bank') IS NOT NULL DROP TABLE #IronOfferMember_Bank
		SELECT DISTINCT
			   iom.PartnerID
			 , iom.IronOfferID
			 , iom.StartDate
			 , iom.EndDate
			 , iba.BankAccountID
			 , iba.IssuerBankAccountID
			 , iom.IssuerCustomerID
			 , iom.FanID
			 , iom.CompositeID
			 , iom.SourceUID
			 , iba.IsAccountNominee
			 , iba.CustomerPerBankAccount
			 , ROW_NUMBER() OVER (PARTITION BY iba.BankAccountID, iom.PartnerID ORDER BY iba.IsAccountNominee DESC, iba.IssuerCustomerID) AS EmailEligibiltyPriority
			 , CONVERT(INT, NULL) AS FanID_Email
		INTO #IronOfferMember_Bank
		FROM #IronOfferMember iom
		INNER JOIN #IssuerBankAccount iba
			ON iom.SourceUID = iba.SourceUID;

		WITH
		EmailEligible AS (SELECT BankAccountID
							   , FanID
						  FROM #IronOfferMember_Bank
						  WHERE EmailEligibiltyPriority = 1)

		UPDATE iom
		SET iom.FanID_Email = ee.FanID
		FROM #IronOfferMember_Bank iom
		INNER JOIN EmailEligible ee
			ON iom.BankAccountID = ee.BankAccountID


/*******************************************************************************************************************************************
	7. Fetch all incentivised transactions
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT tr.MatchID
		 , tr.FanID
		 , fa.CompositeID
		 , tr.ClubCash
	INTO #Trans
	FROM [SLC_Report].[dbo].[Trans] tr
	INNER JOIN [SLC_Report].[dbo].[Fan] fa
		ON tr.FanID = fa.ID
	WHERE ItemID = 89
	AND TypeID != 24
			

/*******************************************************************************************************************************************
	8. Join Match & Trans tables
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions
	SELECT	ma.PartnerID
		,	ma.IronOfferID
		 , ma.OIN
		 , iba.BankAccountID
		 , iba.CustomerPerBankAccount
		 , ma.IssuerBankAccountID 
		 , iba.FanID AS FanID_Match
		 , tr.FanID AS FanID_Trans
		 , iom_b.FanID_Email
		 , CASE WHEN iom_m.FanID IS NOT NULL THEN 1 ELSE 0 END AS FanID_Match_OnOffer
		 , CASE WHEN iom_t.FanID IS NOT NULL THEN 1 ELSE 0 END AS FanID_Trans_OnOffer
		 , ma.TransactionDate
		 , ma.Amount
		 , tr.ClubCash
		 , ma.AddedDate
		 , CASE
				WHEN ma.RewardStatus = 15 THEN 1
				WHEN ma.RewardStatus = 1 THEN 2
		   END AS TransactionNumber
		 , iom_b.FanID
		 , iom_b.IsAccountNominee
		 , iom_b.EmailEligibiltyPriority
	INTO #Transactions
	FROM #Match ma
	LEFT JOIN #Trans tr
		ON ma.MatchID = tr.MatchID
	LEFT JOIN #IssuerBankAccount iba
		ON ma.IssuerBankAccountID = iba.IssuerBankAccountID
	LEFT JOIN #IronOfferMember iom_m
		ON ma.FanID = iom_m.FanID
		AND ma.IronOfferID = iom_m.IronOfferID
	LEFT JOIN #IronOfferMember iom_t
		ON tr.FanID = iom_t.FanID
		AND ma.IronOfferID = iom_t.IronOfferID
	LEFT JOIN #IronOfferMember_Bank iom_b
		ON iba.BankAccountID = iom_b.BankAccountID
		AND ma.PartnerID = iom_b.PartnerID
		AND ma.IronOfferID = iom_b.IronOfferID

/*******************************************************************************************************************************************
	9. Populate final table
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#CustomerstoBeEmailed') IS NOT NULL DROP TABLE #CustomerstoBeEmailed
	SELECT DISTINCT
		   PartnerID
		 , IronOfferID
		 , OIN
		 , BankAccountID
		 , COALESCE(FanID, FanID_Trans, FanID_Match) AS FanID
		 , TransactionNumber
		 , @Today AS EmailDate
	INTO #CustomerstoBeEmailed
	FROM #Transactions t
	WHERE AddedDate >= @Yesterday
	AND EmailEligibiltyPriority = 1
	AND NOT EXISTS (SELECT 1
					FROM SmartEmail.SFD_DailyLoad_MFDD_TriggerEmail te
					WHERE t.PartnerID = te.PartnerID
					AND t.TransactionNumber = te.TransactionNumber
					AND t.BankAccountID = te.BankAccountID)

	INSERT INTO #CustomerstoBeEmailed
	SELECT DISTINCT
		   PartnerID
		 , IronOfferID
		 , OIN
		 , BankAccountID
		 , COALESCE(FanID, FanID_Trans, FanID_Match) AS FanID
		 , TransactionNumber
		 , @Today AS EmailDate
	FROM #Transactions t
	WHERE AddedDate >= '2021-02-16 10:15:40.470'
	AND @Today = '2021-02-24'
	AND EmailEligibiltyPriority = 1
	AND NOT EXISTS (SELECT 1
					FROM SmartEmail.SFD_DailyLoad_MFDD_TriggerEmail te
					WHERE t.PartnerID = te.PartnerID
					AND t.TransactionNumber = te.TransactionNumber
					AND t.BankAccountID = te.BankAccountID)
	AND NOT EXISTS (SELECT 1
					FROM #CustomerstoBeEmailed te
					WHERE t.PartnerID = te.PartnerID
					AND t.TransactionNumber = te.TransactionNumber
					AND t.BankAccountID = te.BankAccountID)


	INSERT INTO SmartEmail.SFD_DailyLoad_MFDD_TriggerEmail (PartnerID
														  , IronOfferID
														  , OIN
														  , BankAccountID
														  , FanID
														  , TransactionNumber
														  , EmailDate)
	SELECT PartnerID
		 , IronOfferID
		 , OIN
		 , BankAccountID
		 , FanID
		 , TransactionNumber
		 , EmailDate
	FROM #CustomerstoBeEmailed

END

