

-- =============================================
-- Author:		JEA
-- Create date: 10/04/2015
-- Description:	<Description,,>
-- CJM 20161116 Last run  02:15 - 03:02
-- Table Relational.AdditionalCashbackAward INDEX ON MatchID INCLUDE (CashbackEarned, FanID, AddedDate) for 35% improvement 
-- =============================================
CREATE PROCEDURE [RBSMIPortal].[SchemeTransaction_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT pt.MatchID
		, pt.FanID
		, pt.AddedDate
		, p.PartnerName
		, pt.TransactionAmount AS Spend
		, CAST(CASE WHEN pt.AboveBase = 1 THEN 0 ELSE pt.TransactionAmount END AS MONEY) AS SpendAtBase
		, CAST(CASE WHEN pt.AboveBase = 1 THEN pt.TransactionAmount ELSE 0 END AS MONEY) AS SpendAboveBase
		, pt.CashbackEarned + ISNULL(A.CashbackEarned,0) AS Earnings
		, CAST(CASE WHEN pt.AboveBase = 1 THEN 0 ELSE pt.CashbackEarned END AS MONEY) AS EarningsAtBase
		, CAST(CASE WHEN pt.AboveBase = 1 THEN pt.CashbackEarned ELSE 0 END AS MONEY) AS EarningsAboveBase
		, ISNULL(A.CashbackEarned,0) + CASE WHEN b.ChargeOnRedeem = 1 THEN pt.CashbackEarned ELSE 0 END AS RBSEarnings
		, CAST(CASE WHEN a.MatchID IS NOT NULL THEN 1 WHEN b.ChargeOnRedeem = 1 THEN 1 ELSE 0 END AS BIT) AS IsRBS
		, pt.PaymentMethodID
		, CAST(CASE WHEN a.MatchID IS NOT NULL OR b.ChargeOnRedeem = 1 THEN pt.FanID ELSE NULL END AS INT) AS RBSFanID
		, c.GenderID
		, c.AgeBandID
		, c.RainbowID
		, c.BankID
		, c.ActivationMethodID
		, c.ChannelPreferenceID
		, wm.TranMonthDesc AS SchemeMonth
		, wm.TranWeekDesc AS SchemeWeek
		, bi.SectorID
		, bi.TierID
	FROM Relational.PartnerTrans pt
	INNER JOIN RBSMIPortal.Customer c ON pt.FanID = c.FanID
	INNER JOIN RBSMIPortal.CalendarWeekMonth wm ON pt.AddedDate = wm.CalendarDate
	LEFT OUTER JOIN (SELECT MatchID, SUM(CashbackEarned) AS CashbackEarned
						FROM Relational.AdditionalCashbackAward
						WHERE matchid IS NOT NULL
						GROUP BY MatchID)a ON pt.MatchID = a.MatchID
	INNER JOIN Relational.[Partner] p ON pt.PartnerID = p.PartnerID
	LEFT OUTER JOIN Relational.Brand b ON p.BrandID = b.BrandID
	LEFT OUTER JOIN RBSMIPortal.BrandListInfo bi ON b.BrandID = bi.BrandID
	-- CJM 20161117 this part takes about an hour without the recommended index

	UNION ALL

	SELECT a.MatchID AS MatchID
		, a.FanID
		, a.AddedDate
		, COALESCE(d.DDOfferName, t.[Description] + ' Unbranded') AS PartnerName
		, a.Amount AS Spend
		, a.Amount AS SpendAtBase
		, CAST(0 AS money) AS SpendAboveBase
		, a.CashbackEarned AS Earnings
		, a.CashbackEarned AS EarningsAtBase
		, CAST(0 AS money) AS EarningsAboveBase
		, A.CashbackEarned AS RBSEarnings
		, CAST(1 AS BIT) AS IsRBS
		, a.PaymentMethodID
		, a.FanID AS RBSFanID
		, c.GenderID
		, c.AgeBandID
		, c.RainbowID
		, c.BankID
		, c.ActivationMethodID
		, c.ChannelPreferenceID
		, wm.TranMonthDesc AS SchemeMonth
		, wm.TranWeekDesc AS SchemeWeek
		, CAST(1 AS tinyint) AS SectorID
		, CAST(1 AS tinyint) AS TierID
	FROM Relational.AdditionalCashbackAward a
	INNER JOIN Relational.AdditionalCashbackAwardType T ON a.AdditionalCashbackAwardTypeID = t.AdditionalCashbackAwardTypeID
	INNER JOIN RBSMIPortal.Customer c ON a.FanID = c.FanID
	INNER JOIN RBSMIPortal.CalendarWeekMonth wm ON a.AddedDate = wm.CalendarDate
	LEFT OUTER JOIN MI.DirectDebitOfferName d ON t.AdditionalCashbackAwardTypeID = d.AdditionalCashbackAwardTypeID
	WHERE A.MatchID IS NULL

END