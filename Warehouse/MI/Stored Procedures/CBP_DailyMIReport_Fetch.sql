
-- =============================================
-- Author:		JEA
-- Create date: 02/07/2015
-- Description: Fetches data for the CPB_DailyMIReport table
-- =============================================
create PROCEDURE [MI].[CBP_DailyMIReport_Fetch] 
/*
Amended CJM 20180711 taken from SSIS package
*/	
AS
BEGIN


	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE	@Time DATETIME,	@Msg VARCHAR(2048), @SSMS BIT = 1;
	EXEC dbo.oo_TimerMessagev2 'Start CBP_DailyMIReport_Fetch', @Time OUTPUT, @SSMS OUTPUT; 
	
    TRUNCATE TABLE MI.CBP_DailyMIReport;

	IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL DROP TABLE #Redemptions;
	SELECT  FanID
		, [Cash] AS RedeemCash
		, [Credit Card] AS RedeemCreditCard
		, [Trade Up] AS RedeemTradeUp
		, [Charity] AS RedeemCharity
		, [NoType] AS RedeemNoType
	INTO #Redemptions
	FROM (
		SELECT t.FanID
			, t.Price As RedeemedValue
			, COALESCE(ri.CreditCheck, ri.RedeemType, 'NoType') As RedeemType
		FROM SLC_Report.dbo.Trans t --TEST
		INNER JOIN SLC_Report.dbo.Redeem r on r.id = t.ItemID --TEST
		INNER JOIN SLC_Report.dbo.RedeemAction ra on t.ID = ra.transid and ((ra.[Status] = 1 AND r.FulfillmentTypeID not in (4, 5)) OR (ra.Status = 6 AND r.FulfillmentTypeID in (4, 5))) --TEST
		LEFT OUTER JOIN (
			SELECT *, CASE WHEN PrivateDescription LIKE '%credit%' THEN 'Credit Card' ELSE NULL END AS CreditCheck 
			FROM Relational.RedemptionItem) ri on ri.RedeemID = r.ID
		) s
		PIVOT
		(
			SUM(RedeemedValue)
			FOR RedeemType IN ([Cash], [Credit Card], [Trade Up], [Charity], [NoType])
	) p

	CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #Redemptions (FanID)

	EXEC dbo.oo_TimerMessagev2 'Finished Redemptions', @Time OUTPUT, @SSMS OUTPUT; 


	SELECT FanID 
		, TotalTransactionAmountDebit = SUM(CASE WHEN PaymentMethodID = 0 THEN TransAmount ELSE 0 END)
		, TotalTransactionAmountCredit = SUM(CASE WHEN PaymentMethodID = 1 THEN TransAmount ELSE 0 END)
		, TotalTransactionAmountDirectDebit = SUM(CASE WHEN PaymentMethodID = 2 THEN TransAmount ELSE 0 END)
		, TotalTransactionCountDebit = SUM(CASE WHEN PaymentMethodID = 0 THEN TransCount ELSE 0 END)
		, TotalTransactionCountCredit = SUM(CASE WHEN PaymentMethodID = 1 THEN TransCount ELSE 0 END)
		, TotalTransactionCountDirectDebit = SUM(CASE WHEN PaymentMethodID = 2 THEN TransCount ELSE 0 END)
	INTO #CustomerSpend
	FROM MI.CBP_CustomerSpend
	GROUP BY FanID

	CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #CustomerSpend (FanID)

	EXEC dbo.oo_TimerMessagev2 'Finished CustomerSpend', @Time OUTPUT, @SSMS OUTPUT; 


	INSERT INTO MI.[CBP_DailyMIReport] (
		[Customer ID],
		[E-mail Address],
		[Mobile Number],
		[Bank ID],
		[Is Marketing Suppressed SMS],
		[Is Marketing Suppressed Email],
		[Is Marketing Suppressed DM],
		[Opted Out],
		[Opted Out Date],
		[Currently Active],
		[Activation Channel],
		[Activated By Credit Card],
		[Activated Date],
		[Is Registered],
		[Total Transaction Amount Debit],
		[Total Transaction Amount Credit],
		[Total Transaction Amount DD],
		[Total Transaction Count Debit],
		[Total Transaction Count Credit],
		[Total Transaction Count DD],
		[Cashback Balance - Pending],
		[CASHBACK BALANCE – CLEARED],
		[Total Redeemed Value],
		[REDEEMED VALUE CASH TO BANK ACCOUNT],
		[REDEEMED VALUE CASH TO CREDIT CARD],
		[REDEEMED VALUE IN TRADEUP],
		[REDEEMED VALUE IN CHARITY],
		[CONTACT HISTORY],
		[EMAIL HARDBOUNCED]	
	)
	SELECT f.SourceUID As CustomerID
		, CAST(LEFT(f.Email,255) AS VARCHAR(255)) As EmailAddress
		, CAST(LEFT(f.MobileTelephone,20) AS VARCHAR(20)) AS MobileTelephone
		, CASE f.ClubID WHEN 132 THEN '0278' ELSE '0365' END AS BankID
		, CAST(CASE WHEN f.ContactBySMS = 1 THEN 0 ELSE 1 END AS CHAR(1)) AS IsMarketingSuppressedSMS
		, CAST(CASE WHEN f.Unsubscribed = 1 THEN 0 ELSE 1 END AS CHAR(1)) AS IsMarketingSuppressedEmail
		, CAST(CASE WHEN f.ContactByPost = 1 THEN 0 ELSE 1 END AS CHAR(1)) AS IsMarketingSuppressedDM
		, CAST(CASE WHEN s.OptedOutDate IS NULL THEN 0 ELSE 1 END AS CHAR(1)) AS OptedOut
		, s.OptedOutDate AS OptOutDate
		, CAST(CASE WHEN s.OptedOutDate IS NULL AND s.DeactivatedDate IS NULL THEN 1 ELSE 0 END AS CHAR(1)) AS CurrentlyActive
		, CAST(CASE WHEN f.OfflineOnly = 1 AND s.OptedOutDate IS NULL AND s.DeactivatedDate IS NULL THEN 2 WHEN f.ActivationChannel = 3 THEN 3 ELSE 1 END AS TinyInt) AS ActivationChannel
		, CAST(CASE WHEN f.ActivationChannel = 4 THEN '1' ELSE '0' END AS CHAR(1)) AS ActivatedByCreditCard
		, s.ActivatedDate
		, CASE WHEN c.Registered = 1 THEN '1' ELSE '0' END AS IsRegistered

		, ISNULL(pt.TotalTransactionAmountDebit, 0) AS TotalTransactionAmountDebit
		, ISNULL(pt.TotalTransactionAmountCredit, 0) AS TotalTransactionAmountCredit
		, ISNULL(pt.TotalTransactionAmountDirectDebit,0) AS TotalTransactionAmountDirectDebit
		, ISNULL(pt.TotalTransactionCountDebit,0) AS TotalTransactionCountDebit
		, ISNULL(pt.TotalTransactionCountCredit,0) AS TotalTransactionCountCredit
		, ISNULL(pt.TotalTransactionCountDirectDebit,0) AS TotalTransactionCountDirectDebit

		, f.ClubCashPending AS TotalCashbackBalancePending
		, f.ClubCashAvailable AS TotalCashbackBalanceCleared
		, ISNULL(r.RedeemCash,0) + ISNULL(r.RedeemCreditCard,0) + ISNULL(r.RedeemTradeUp,0) + ISNULL(r.RedeemCharity,0) + ISNULL(r.RedeemNotype,0) AS TotalRedeemedValue
		, ISNULL(r.RedeemCash,0) AS RedeemedValueCashToBank
		, ISNULL(r.RedeemCreditCard,0) AS RedeemedValueCashToCreditCard
		, ISNULL(r.RedeemTradeUp,0) AS RedeemedValueInTradeUp
		, ISNULL(r.RedeemCharity,0) AS RedeemedValueInCharity
		, ISNULL(e.ContactCount, 0) AS ContactHistory
		, ISNULL(c.Hardbounced, 0) AS HardBounced
	FROM SLC_Report.dbo.Fan f
	LEFT OUTER JOIN Relational.Customer c ON f.ID = c.FanID
	INNER JOIN MI.CustomerActiveStatus s on f.ID = s.FanID 
	LEFT OUTER JOIN (
		SELECT SourceUID, ClubID, COUNT(1) AS Frequency
		FROM Relational.Customer
		GROUP BY SourceUID, ClubID
		HAVING COUNT(1) > 1
	) X on f.SourceUID = X.SourceUID

	LEFT JOIN #CustomerSpend pt ON pt.FanID = f.ID

	LEFT OUTER JOIN #Redemptions r ON f.ID = r.FanID

	LEFT OUTER JOIN (
		SELECT ea.FanID, Count(1) AS ContactCount
		FROM SLC_Report.dbo.EmailActivity ea
		INNER JOIN Relational.EmailCampaign ec on ea.EmailCampaignID = ec.ID
		INNER JOIN Relational.CampaignLionSendIDs cl on ec.CampaignKey = cl.CampaignKey
		GROUP BY ea.FanID
	) e ON f.ID = e.FanID

	WHERE f.ClubID IN (132,138)
		AND X.SourceUID IS NULL
		and f.ID != 23854726
		and f.ID != 23944954
		and f.ID != 24267733
		and f.ID != 25035536
		and f.ID != 26191518
		AND f.ID != 26310976	--	TSYS Customer with dupicated SourceUID 2020-12-07, duplicted SourceUID appended with 'd'
		AND f.ID != 26400732	--	TSYS Customer with dupicated SourceUID 2020-12-28, duplicted SourceUID appended with 'd'

	EXEC dbo.oo_TimerMessagev2 'Finished INSERT', @Time OUTPUT, @SSMS OUTPUT; 

				
END

RETURN 0