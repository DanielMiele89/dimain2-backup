
CREATE VIEW [Outbound].[MICustomer_View]  
AS
WITH Redemptions
AS
(
	select 
		FanID
		, SUM(CASE WHEN RedemptionType = '' THEN CashbackUsed ELSE 0 END) AS RedeemValueCashToBank
		, SUM(CASE WHEN RedemptionType = 'Pay Card' THEN CashbackUsed ELSE 0 END) AS RedeemValueCashToCreditCard
		, SUM(CASE WHEN RedemptionType = 'Trade Up' THEN CashbackUsed ELSE 0 END) AS RedeemValueTradup
		, SUM(CASE WHEN RedemptionType = 'Charity' THEN CashbackUsed ELSE 0 END) AS RedeemValueCharity
		, SUM(CashbackUsed) AS TotalRedeemedValue --  TOTAL REDEEMED VALUE
	from [Derived].[Redemptions]
	GROUP BY FanID
),
PartnerTrans
AS
(
	SELECT 
		fanID
		, SUM(CASE WHEN PaymentMethodID = 0 THEN TransactionAmount ELSE 0 END) TranAmountDebit
		, SUM(CASE WHEN PaymentMethodID = 1 THEN TransactionAmount ELSE 0 END) TranAmountCredit
		, SUM(CASE WHEN PaymentMethodID = 0 THEN 1 ELSE 0 END) AS TranCountDebit
		, SUM(CASE WHEN PaymentMethodID = 1 THEN 1 ELSE 0 END) AS TranCountCredit
	FROM [Derived].[PartnerTrans]
	GROUP BY FanID
),
ContactHistory
AS
(
	SELECT	FanID
		,	count(distinct CampaignKey) CampaignKey
	FROM Derived.EmailEvent
	GROUP BY FanID
)
SELECT	c.FanID AS Customer_ID														--	CUSTOMER ID
	,	PII.Email																	--	EMAIL
	,	PII.MobileTelephone AS Mobile												--	MOBILE
	,	'BARC' AS Bank_ID															--	BANK ID
	,	'N/A' AS isMarketingSuppressedSMS											--	IS MARKETING SUPPRESSED SMS
	,	c.MarketableByEmail AS isMarketingSuppresseEmail							--	IS MARKETING SUPPRESSED EMAIL
	,	c.MarketableByPush AS isMarketingSuppressedDM								--	IS MARKETING SUPPRESSED DM
	,	CASE																		--	OPTED OUT
			WHEN ic.OptedOutDate IS NULL THEN 0										--	OPTED OUT
			ELSE 1																	--	OPTED OUT
		END AS OptedOut																--	OPTED OUT
	,	ic.OptedOutDate																--	OPTED OUT DATE
	,	c.CurrentlyActive															--	CURRENTLY ACTIVE		??
	,	1 AS ActivationChannel														--	ACTIVATION CHANNEL		??
	,	c.RegistrationDate AS ActivatedDate											--	ACTIVATED DATE
	,	1 AS isRegistered															--	IS REGISTERED			??
	,	COALESCE(pt.TranAmountDebit, 0) AS TotalTransactionAmountDebit				--	TOTAL TRANSACTION AMOUNT DEBIT
	,	COALESCE(pt.TranAmountCredit, 0) AS TotalTransactionAmountCredit			--	TOTAL TRANSACTION AMOUNT CREDIT
	,	COALESCE(pt.TranCountDebit, 0) AS TotalTransactionCountDebit				--  TOTAL TRANSACTION COUNT DEBIT
	,	COALESCE(pt.TranCountCredit, 0) AS TotalTransactionCountCredit				--  TOTAL TRANSACTION COUNT CREDIT
	,	c.CashbackPending AS CashbackBalance_Pending								--  CASHBACK BALANCE - PENDING
	,	c.CashbackAvailable AS CashbackBalance_Cleared								--  CASHBACK BALANCE – CLEARED
	,	COALESCE(r.TotalRedeemedValue, 0) AS TotalRedeemedValue						--  TOTAL REDEEMED VALUE
	,	COALESCE(r.RedeemValueCashToBank, 0) AS RedeemValueCashToBank				--  REDEEMED VALUE CASH TO BANK ACCOUNT
	,	COALESCE(r.RedeemValueCashToCreditCard, 0) AS RedeemValueCashToCreditCard	--  REDEEMED VALUE CASH TO CREDIT CARD
	,	COALESCE(r.RedeemValueTradup, 0) AS RedeemValueTradup						--  REDEEMED VALUE IN TRADEUP
	,	COALESCE(r.RedeemValueCharity, 0) AS RedeemValueCharity						--  REDEEMED VALUE IN CHARITY
	,	COALESCE(ch.CampaignKey, 0) AS ContactHistory								--  CONTACT HISTORY
--	,	AS RedeemedTodayBankAccount													--  REDEEMED TODAY CASH TO BANK ACCOUNT
--	,	AS RedeemedTodayCreditCard													--  REDEEMED TODAY CASH TO CREDIT CARD
--	,	AS RedeemedTodayTradeUp														--  REDEEMED TODAY IN TRADEUP
--	,	AS RedeemedTodayCharity														--  REDEEMED TODAY IN CHARITY
FROM [Derived].[Customer] c 
INNER JOIN [WHB].[Inbound_Customers] ic
	ON c.FanID = ic.CustomerID
INNER JOIN [Derived].[Customer_PII] pii
	ON c.FanID = PII.FanID
LEFT JOIN PartnerTrans pt
	ON c.FanID = pt.FanID
LEFT JOIN Redemptions r
	ON c.FanID = r.FanID
LEFT JOIN ContactHistory ch
	ON c.FanID = ch.FanID

