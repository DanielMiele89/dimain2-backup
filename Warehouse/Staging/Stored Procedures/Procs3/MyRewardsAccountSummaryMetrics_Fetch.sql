/******************************************************************************
Author: Jason Shipp
Created: 08/07/2019
Purpose: 
	- Fetch top line MyRewards metrics: Customers active, Reward account holders, Reward credit card holders
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.MyRewardsAccountSummaryMetrics_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

	-- Script to be run on the first Monday of every Month
	-- Output is 3 integers
	
	-- Fetch all MyRewards accounts

	IF OBJECT_ID ('tempdb..#BaID') IS NOT NULL DROP TABLE #BaID;

	SELECT 
		h.BankAccountID
		, h.[Type]
	INTO #BaID
	FROM SLC_Report.dbo.BankAccountTypeHistory h
	WHERE 
		h.EndDate is null and
	LEFT ([Type], 1) = 'Q';

	CREATE CLUSTERED INDEX INX ON #BaID(BankAccountID, [Type]);

	IF OBJECT_ID ('tempdb..#RewardAccounts') IS NOT NULL DROP TABLE #RewardAccounts;

	SELECT DISTINCT 
		ic.SourceUID
	INTO #RewardAccounts
	FROM SLC_Report..IssuerCustomer ic
	INNER JOIN SLC_Report.dbo.IssuerBankAccount iba
		ON ic.ID = iba.IssuerCustomerID
	INNER JOIN SLC_Report.dbo.BankAccount ba
		ON iba.BankAccountID = ba.ID
	INNER JOIN Warehouse.Relational.customer c 
		ON c.SourceUID = ic.SourceUID
	WHERE 
		EXISTS (
			SELECT 1
			FROM #BaID b
			WHERE 
			b.BankAccountID = ba.ID
		);

	CREATE CLUSTERED INDEX INX ON #RewardAccounts(SourceUID);

	-- Fetch current Credit Card Customers

	IF OBJECT_ID('tempdb..#CC_Customers') IS NOT NULL DROP TABLE #CC_Customers;

	SELECT DISTINCT 
		FanID	
	INTO #CC_Customers
	FROM Warehouse.[Relational].CustomerPaymentMethodsAvailable cpa
	WHERE
		cpa.PaymentMethodsAvailableID in (1,2)
		AND EndDate IS NULL;

	-- Outputs 1, 2 and 3: Number of customers active, Reward account holders, Reward CC holders

	SELECT
		COUNT(1) AS [Total Membership Count]
		, SUM(CASE WHEN ra.SourceUID IS NOT NULL THEN 1 ELSE 0 END) AS [Reward Account Holders]
		, SUM(CASE WHEN cc.FanID IS NOT NULL THEN 1 ELSE 0 END) AS [Reward Credit Card Holders]
	FROM Warehouse.Relational.Customer c
	LEFT JOIN #RewardAccounts ra 
		ON ra.SourceUID = c.SourceUID
	LEFT JOIN #CC_Customers cc 
		ON cc.FanID = c.FanID
	WHERE
		c.CurrentlyActive = 1;

END