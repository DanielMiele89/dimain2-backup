

/********************************************************************************************************************************

	Auth:	Rory Francis
	Name:	[SmartEmail].[TriggerEmail_DirectDebit]
	Desc:	Fetch customers who have earnt on the Direct Debit Offer for the first time

	Change History:

********************************************************************************************************************************/

CREATE PROCEDURE [SmartEmail].[TriggerEmail_FirstEarnDirectDebit_Retrospective] (@SendDate DATE)

AS 
BEGIN

	SET NOCOUNT ON

/*******************************************************************************************************************************************
	1.	Fetch eligible customers
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
	SELECT *
	INTO #Customer
	FROM [Relational].[Customer] cu
	WHERE EXISTS (	SELECT 1
					FROM [SLC_Report].[dbo].[IronOfferMember] iom
					WHERE iom.IronOfferID IN (18295, 18296, 18297, 18298)
					AND iom.CompositeID = cu.CompositeID
					AND EndDate IS NULL)

	CREATE CLUSTERED INDEX CIX_FanID ON #Customer (FanID)

	IF OBJECT_ID('tempdb..#LoyaltyAccountCustomers') IS NOT NULL DROP TABLE #LoyaltyAccountCustomers
	SELECT	te.FanID
		,	fa.CompositeID
		,	fa.SourceUID
		,	ic.ID AS IssuerCustomerID
		,	te.LoyaltyAccount
		,	te.IsLoyalty
		,	iba.BankAccountID
		,	bat.Type
		,	CASE
				WHEN bat.Type = 'QE' THEN 'Premier Reward Black'
				WHEN bat.Type = 'QB' THEN 'Premier Reward'
				WHEN bat.Type = 'QD' THEN 'Reward Platinum'
				WHEN bat.Type = 'QC' THEN 'Reward Silver'
				WHEN bat.Type = 'QA' THEN 'Reward'
			END AS TypeDesc
	INTO #LoyaltyAccountCustomers
	FROM #Customer cu
	LEFT JOIN [SmartEmail].[TriggerEmailDailyFile_Calculated] te
		ON cu.FanID = te.FanID
	INNER JOIN [SLC_Report].[dbo].[Fan] fa
		ON cu.FanID = fa.ID
	INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
		ON fa.SourceUID = ic.SourceUID
		AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)
	INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
		ON ic.ID = iba.IssuerCustomerID
		AND iba.CustomerStatus = 1
	INNER JOIN [SLC_Report].[dbo].[BankAccountTypeHistory] bat
		ON iba.BankAccountID = bat.BankAccountID
		AND bat.EndDate IS NULL
	WHERE te.LoyaltyAccount = 1
	AND bat.Type IN ('QA', 'QB', 'QC', 'QD', 'QE')
	
	CREATE CLUSTERED INDEX CIX_FanID ON #LoyaltyAccountCustomers (FanID)


/*******************************************************************************************************************************************
	2.	Fetch customers that have earnt for the first time yesterday
*******************************************************************************************************************************************/

	DECLARE @EarnDate DATE = DATEADD(DAY, -1, GETDATE())
	
	IF OBJECT_ID('tempdb..#FirstEarnYesterday') IS NOT NULL DROP TABLE #FirstEarnYesterday
	SELECT	DISTINCT
			FanID
	INTO #FirstEarnYesterday
	FROM [SmartEmail].[TriggerEmail_MobileDDEarnDates] edy
	WHERE edy.FirstEarnDate = @EarnDate
	AND edy.EarnType = 'Direct Debit'
	AND NOT EXISTS (	SELECT 1
						FROM [SmartEmail].[TriggerEmail_MobileDDEarnDates] ed_all
						WHERE (edy.FanID = ed_all.FanID OR edy.BankAccountID = ed_all.BankAccountID)
						AND ed_all.FirstEarnDate < @EarnDate
						AND ed_all.EarnType = 'Direct Debit')

	CREATE CLUSTERED INDEX CIX_FanID ON #FirstEarnYesterday (FanID)


/*******************************************************************************************************************************************
	3.	Fetch customers that have earnt for the first time yesterday and assign them to the email they should get

			-------------------------------------------------------------
			|  Bank Accounts |	Core Marketing	|	Premier Marketing	|
			|----------------|------------------|-----------------------|
			|      Core		 |		Core		|		No Email		|
			|----------------|------------------|-----------------------|
			| Core & Premier |		Core		|		Premier			|
			|----------------|------------------|-----------------------|
			|     Premier	 |		Premier		|		Premier			|
			-------------------------------------------------------------

*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#CustomersToEmail') IS NOT NULL DROP TABLE #CustomersToEmail
	SELECT	lac.FanID
		,	lac.IsLoyalty
		,	MAX(CASE
					WHEN lac.Type IN ('QB', 'QE') THEN lac.TypeDesc
					ELSE NULL
				END) AS IsPremierBank
		,	MAX(CASE
					WHEN lac.Type IN ('QA', 'QC', 'QD') THEN lac.TypeDesc
					ELSE NULL
				END) AS IsCoreBank
	INTO #CustomersToEmail
	FROM #LoyaltyAccountCustomers lac
	WHERE EXISTS (	SELECT 1
					FROM #FirstEarnYesterday fey
					WHERE lac.FanID = fey.FanID)
	AND EXISTS (	SELECT 1
					FROM [SLC_Report].[dbo].[DDCashbackNominee] nom
					WHERE lac.BankAccountID = nom.BankAccountID
					AND lac.IssuerCustomerID = nom.IssuerCustomerID
					AND nom.EndDate IS NULL)
	GROUP BY	lac.FanID
			,	lac.IsLoyalty

	INSERT INTO [SmartEmail].[TriggerEmail_FirstEarn]
	SELECT	FanID
		,	CASE
				WHEN IsLoyalty = 0 AND IsCoreBank IS NOT NULL THEN IsCoreBank
				WHEN IsLoyalty = 0 AND IsPremierBank IS NOT NULL THEN IsPremierBank
				WHEN IsLoyalty = 1 THEN IsPremierBank
				ELSE NULL
			END AS ToUpload
		,	'Direct Debit' AS FirstEarnType
		,	@EarnDate AS FirstEarnDate
	FROM #CustomersToEmail cte
	WHERE NOT (IsLoyalty = 1 AND IsPremierBank IS NULL)
	AND NOT EXISTS (	SELECT 1
						FROM [SmartEmail].[TriggerEmail_FirstEarn] fe
						WHERE cte.FanID = fe.FanID
						AND fe.FirstEarnType = 'Direct Debit'
						AND fe.FirstEarnDate = @EarnDate)


END