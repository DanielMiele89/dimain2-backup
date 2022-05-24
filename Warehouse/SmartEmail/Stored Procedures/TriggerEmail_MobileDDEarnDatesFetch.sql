
/********************************************************************************************************************************

	Auth:	Rory Francis
	Name:	[SmartEmail].[TriggerEmail_MobileDDEarnDatesFetch]
	Desc:	Populate table storing the first & last earn dates for the Reward 3.0 offers

	Change History:

********************************************************************************************************************************/

CREATE PROCEDURE [SmartEmail].[TriggerEmail_MobileDDEarnDatesFetch]
AS 
BEGIN

/*******************************************************************************************************************************************
	1.	Fetch offer types
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#TransactionType') IS NOT NULL DROP TABLE #TransactionType
	SELECT	ID AS TransactionTypeID
		,	Name
		,	CASE
				WHEN tt.ID IN (29, 30) THEN 'Direct Debit'
				WHEN tt.ID IN (31, 32) THEN 'Mobile Login'
			END AS EarnType
	INTO #TransactionType
	FROM [SLC_Report].[dbo].[TransactionType] tt
	WHERE tt.ID IN (29, 30, 31, 32)


/*******************************************************************************************************************************************
	2.	Fetch all new Earning Transactions
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans;
	WITH
	Trans AS (	SELECT	--TOP 7500000
						FanID
					,	TypeID
					,	ItemID
					,	IssuerBankAccountID
					,	ClubCash
					,	Date
					,	ProcessDate
				FROM [SLC_Report].[dbo].[Trans]
				WHERE ID > 966284045
				--ORDER BY ID DESC
				)


	SELECT	iba.BankAccountID
		,	tr.IssuerBankAccountID
		,	iba.IssuerCustomerID
		,	fa.SourceUID
		,	tr.FanID
		,	acat.EarnType
		,	MAX(tr.ClubCash) AS ClubCash
		,	MIN(ProcessDate) AS FirstEarnDate
		,	MAX(ProcessDate) AS LastEarnDate
	INTO #Trans
	FROM Trans tr
	INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
		ON tr.IssuerBankAccountID = iba.ID
	INNER JOIN [SLC_Report].[dbo].[Fan] fa
		ON tr.FanID = fa.ID
	INNER JOIN #TransactionType acat
		ON tr.TypeID = acat.TransactionTypeID
	GROUP BY	iba.BankAccountID
			,	tr.IssuerBankAccountID
			,	iba.IssuerCustomerID
			,	fa.SourceUID
			,	tr.FanID
			,	acat.EarnType

	CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #Trans (BankAccountID, IssuerBankAccountID, IssuerCustomerID, SourceUID, FanID, FirstEarnDate, LastEarnDate)
	

/*******************************************************************************************************************************************
	3.	Update the LastEarnDate of entries that have earnt previously
*******************************************************************************************************************************************/
	
	UPDATE fe
	SET fe.LastEarnDate = tr.LastEarnDate
	FROM #Trans tr
	INNER JOIN [SmartEmail].[TriggerEmail_MobileDDEarnDates] fe
		ON tr.EarnType = fe.EarnType
		AND tr.BankAccountID = fe.BankAccountID
		AND tr.IssuerBankAccountID = fe.IssuerBankAccountID
		AND tr.IssuerCustomerID = fe.IssuerCustomerID
		AND tr.SourceUID = fe.SourceUID
		AND tr.FanID = fe.FanID


/*******************************************************************************************************************************************
	4.	Insert all entries that have not earnt previously
*******************************************************************************************************************************************/

	INSERT INTO [SmartEmail].[TriggerEmail_MobileDDEarnDates]
	SELECT	tr.BankAccountID
		,	tr.IssuerBankAccountID
		,	tr.IssuerCustomerID
		,	tr.SourceUID
		,	tr.FanID
		,	tr.EarnType
		,	MIN(tr.FirstEarnDate) AS FirstEarnDate
		,	MAX(tr.LastEarnDate) AS LastEarnDate
	FROM #Trans tr
	WHERE NOT EXISTS (	SELECT 1
						FROM [SmartEmail].[TriggerEmail_MobileDDEarnDates] fe
						WHERE tr.EarnType = fe.EarnType
						AND tr.BankAccountID = fe.BankAccountID
						AND tr.IssuerBankAccountID = fe.IssuerBankAccountID
						AND tr.IssuerCustomerID = fe.IssuerCustomerID
						AND tr.SourceUID = fe.SourceUID
						AND tr.FanID = fe.FanID)
	GROUP BY	tr.BankAccountID
			,	tr.IssuerBankAccountID
			,	tr.IssuerCustomerID
			,	tr.SourceUID
			,	tr.FanID
			,	tr.EarnType

END