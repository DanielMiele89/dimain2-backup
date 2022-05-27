
-- =============================================
-- Author:		JEA
-- Create date: 03/09/2014
-- Description:	Retrieves CBP retailer transactions
-- for Reward BI population
-- =============================================
CREATE PROCEDURE [RewardBI].[CBP_PartnerTrans_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT S.SchemeTransID AS SourceID
		, pt.TransactionAmount AS Spend
		, pt.CashbackEarned + ISNULL(a.AdditEarnings, 0) AS EarningsTotal
		, pt.TransactionDate AS TranDate
		, pt.AddedDate
		, pt.FanID AS CustomerID
		, p.PartnerID AS PartnerID
		, p.PartnerName AS RetailerName
		, CAST (1 AS TINYINT) AS PublisherID
		, CAST('RBSG' AS VARCHAR(50)) AS PublisherName
		, CAST(pt.CardHolderPresentData AS TINYINT) AS PaymentChannelID
		, pt.IronOfferID
		, CAST(ISNULL(pt.AboveBase, 0) AS BIT) as AboveBase
		, m.[Description] AS PaymentMethod
		, o.OutletID
		, CAST(0 AS MONEY) AS PublisherCommission
		, CAST(CASE WHEN p.PartnerID = 3960 THEN 0 ELSE pt.CommissionChargable - pt.CashbackEarned END AS MONEY) AS RewardCommission
		, CAST(CASE WHEN P.PartnerID IN (3960,4447,4433) THEN pt.CashbackEarned ELSE 0 END + ISNULL(a.AdditEarnings,0) AS MONEY) AS RBSEarnings
	FROM Relational.PartnerTrans pt
	INNER JOIN Relational.[Partner] p ON pt.PartnerID = p.PartnerID
	INNER JOIN MI.SchemeTransUniqueID S on pt.MatchID = s.MatchID
	INNER JOIN Relational.PaymentMethod m ON pt.PaymentMethodID = m.PaymentMethodID
	INNER JOIN RewardBI.Outlet_AllSchemes o ON pt.OutletID = o.SourceOutletID AND o.SchemeID = 1
	LEFT OUTER JOIN
		(
			SELECT MatchID, SUM(CashbackEarned) AS AdditEarnings
			FROM Relational.AdditionalCashbackAward
			WHERE MatchID IS  NOT NULL
			GROUP BY MatchID
		) a ON pt.MatchID = a.MatchID

END

