-- =============================================
-- Author:		JEA
-- Create date: 05/12/2014
-- Description: Populates the CPB_DailyMIReport table
-- =============================================
CREATE PROCEDURE [MI].[CBP_DailyMIReport_Load] 
	
AS
BEGIN

	SET NOCOUNT ON;

	exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients='Christopher.Morris@rewardinsight.com;',
	@subject = 'Warning 42',
	@body='MI.CBP_DailyMIReport_Load called unexpectedly',
	@body_format = 'TEXT', 
	@importance = 'HIGH', 
	@exclude_query_output = 1

	TRUNCATE TABLE MI.CBP_DailyMIReport

	DECLARE @MinID INT, @MaxID INT, @MaxCustID INT

	SELECT @MaxCustID = MAX(FanID) FROM Relational.Customer

	SET @MinID = 1
	SET @MaxID = 500000

	WHILE @MinID <= @MaxCustID
	BEGIN
		INSERT INTO MI.CBP_DailyMIReport
		(
			[CUSTOMER ID],
			[E-MAIL ADDRESS],
			[MOBILE NUMBER],
			[BANK ID],
			[IS MARKETING SUPPRESSED SMS],
			[IS MARKETING SUPPRESSED EMAIL],
			[IS MARKETING SUPPRESSED DM],
			[OPTED OUT],
			[OPTED OUT DATE],
			[CURRENTLY ACTIVE],
			[ACTIVATION CHANNEL],
			[ACTIVATED BY CREDIT CARD],
			[ACTIVATED DATE],
			[IS REGISTERED],
			[TOTAL TRANSACTION AMOUNT DEBIT],
			[TOTAL TRANSACTION AMOUNT CREDIT],
			[TOTAL TRANSACTION COUNT DEBIT],
			[TOTAL TRANSACTION COUNT CREDIT],
			[CASHBACK BALANCE - PENDING],
			[CASHBACK BALANCE – CLEARED],
			[TOTAL REDEEMED VALUE],
			[REDEEMED VALUE CASH TO BANK ACCOUNT],
			[REDEEMED VALUE CASH TO CREDIT CARD],
			[REDEEMED VALUE IN TRADEUP],
			[REDEEMED VALUE IN CHARITY],
			[CONTACT HISTORY]
		)

		SELECT f.SourceUID As CustomerID
			, LEFT(f.Email,255) As EmailAddress
			, LEFT(f.MobileTelephone,20)
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
			, ISNULL(ptD.TransAmount, 0) AS TotalTransactionAmountDebit
			, ISNULL(ptC.TransAmount, 0) AS TotalTransactionAmountCredit
			, ISNULL(ptD.TransCount,0) AS TotalTransactionCountDebit
			, ISNULL(ptC.TransCount,0) AS TotalTransactionCountCredit
			, f.ClubCashPending AS TotalCashbackBalancePending
			, f.ClubCashAvailable AS TotalCashbackBalanceCleared
			, ISNULL(r.RedeemCash,0) + ISNULL(r.RedeemCreditCard,0) + ISNULL(r.RedeemTradeUp,0) + ISNULL(r.RedeemCharity,0) + ISNULL(r.RedeemNotype,0) AS TotalRedeemedValue
			, ISNULL(r.RedeemCash,0) AS RedeemedValueCashToBank
			, ISNULL(r.RedeemCreditCard,0) AS RedeemedValueCashToCreditCard
			, ISNULL(r.RedeemTradeUp,0) AS RedeemedValueInTradeUp
			, ISNULL(r.RedeemCharity,0) AS RedeemedValueInCharity
			, ISNULL(e.ContactCount, 0) AS ContactHistory
		FROM SLC_Report.dbo.Fan f
		LEFT OUTER JOIN Relational.Customer c ON f.ID = c.FanID
		INNER JOIN MI.CustomerActiveStatus s on f.ID = s.FanID
		LEFT OUTER JOIN (SELECT SourceUID, ClubID, COUNT(1) AS Frequency
							FROM Relational.Customer
							GROUP BY SourceUID, ClubID
							HAVING COUNT(1) > 1) X on f.SourceUID = X.SourceUID
		LEFT OUTER JOIN (SELECT FanID, SUM(TransactionAmount) AS TransAmount, COUNT(DISTINCT SchemeTransID) As TransCount
						FROM (
								SELECT u.SchemeTransID, pt.FanID, pt.TransactionAmount
								FROM Relational.PartnerTrans pt
								INNER JOIN MI.SchemeTransUniqueID u ON pt.MatchID = u.MatchID
								WHERE pt.EligibleForCashback = 1 AND PaymentMethodID = 0

								UNION ALL

								SELECT u.SchemeTransID, FanID, Amount AS TransAmount 
								FROM Relational.AdditionalCashbackAward a
								INNER JOIN MI.SchemeTransUniqueID u ON a.FileID = u.FileID AND a.RowNum = u.RowNum
								WHERE a.MatchID IS NULL AND PaymentMethodID = 0
						) p
						GROUP BY FanID) ptD ON f.ID = ptD.FanID
		LEFT OUTER JOIN (SELECT FanID, SUM(TransactionAmount) AS TransAmount, COUNT(DISTINCT SchemeTransID) As TransCount
						FROM (
								SELECT u.SchemeTransID, pt.FanID, pt.TransactionAmount
								FROM Relational.PartnerTrans pt
								INNER JOIN MI.SchemeTransUniqueID u ON pt.MatchID = u.MatchID
								WHERE pt.EligibleForCashback = 1 AND PaymentMethodID = 1

								UNION ALL

								SELECT u.SchemeTransID, FanID, Amount AS TransAmount 
								FROM Relational.AdditionalCashbackAward a
								INNER JOIN MI.SchemeTransUniqueID u ON a.FileID = u.FileID AND a.RowNum = u.RowNum
								WHERE a.MatchID IS NULL AND PaymentMethodID = 1
						) p
						GROUP BY FanID) ptC ON f.ID = ptC.FanID
		LEFT OUTER JOIN (SELECT  FanID
							, [Cash] AS RedeemCash
							, [Credit Card] AS RedeemCreditCard
							, [Trade Up] AS RedeemTradeUp
							, [Charity] AS RedeemCharity
							, [NoType] AS RedeemNoType
						FROM

							(SELECT t.FanID
								, t.Price As RedeemedValue
								, isnull(COALESCE(ri.CreditCheck, ri.RedeemType), 'NoType') As RedeemType
							FROM SLC_Report.dbo.Trans t
										INNER JOIN slc_report.dbo.Redeem r on r.id = t.ItemID
										INNER JOIN slc_report.dbo.RedeemAction ra on t.ID = ra.transid and ra.[Status] = 1
										LEFT OUTER JOIN (SELECT *, CASE WHEN PrivateDescription LIKE '%credit%' THEN 'Credit Card' ELSE NULL END AS CreditCheck 
															FROM Relational.RedemptionItem) ri on ri.RedeemID = r.ID
							) s
							PIVOT
							(
								SUM(RedeemedValue)
								FOR RedeemType IN ([Cash], [Credit Card], [Trade Up], [Charity], [NoType])
							) p) R ON f.ID = R.FanID
		LEFT OUTER JOIN (SELECT ea.FanID, Count(1) AS ContactCount
						FROM slc_report.dbo.EmailActivity ea
						INNER JOIN Relational.EmailCampaign ec on ea.EmailCampaignID = ec.ID
						INNER JOIN Relational.CampaignLionSendIDs cl on ec.CampaignKey = cl.CampaignKey
						GROUP BY ea.FanID
						) e ON f.ID = e.FanID

		WHERE f.ClubID IN (132,138)
		AND X.SourceUID IS NULL
		AND f.ID BETWEEN @MinID AND @MaxID

		SET @MinID = @MinID + 500000
		SET @MaxID = @MaxID + 500000
	END
END
