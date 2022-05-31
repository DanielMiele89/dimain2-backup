
-- =============================================
-- Author:		JEA
-- Create date: 10/08/2016
-- Description:	Retrieves transaction data for the weekly summary report
-- =============================================
CREATE PROCEDURE [APW].[SchemeTrans_WeekSum_Fetch] 
	(@StartDate DATE, @EndDate DATE)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT pt.ID
		, pt.MatchID
		, pt.TransactionAmount AS Spend
		, pt.CashbackEarned AS RetailerCashback
		, CAST(pt.TransactionDate AS DATE) AS TranDate
		, pt.AddedDate
		, pt.FanID
		, COALESCE(alt.AlternatePartnerID, pt.PartnerID) AS RetailerID
		, c.ClubID AS PublisherID
		, pt.CommissionChargable - pt.CashbackEarned AS CommissionOverride
		, ISNULL(pd.RewardAllocation,0) AS RewardAllocation
		, ISNULL(pd.PublisherAllocation,0) AS PublisherAllocation
		, CAST(0 AS SMALLMONEY) AS OfferSourceShare
		, CAST(0 AS SMALLMONEY) AS AccMgtShare
		, CAST(0 AS SMALLMONEY) AS PublisherCashback
		, ISNULL(o.isROC,0) AS IsRoc
		, i.OfferID
		, pt.CommissionChargable AS Investment
		, CAST(0 AS BIT) AS IsOnline
		, CAST(CASE WHEN pe.ID IS NULL THEN 1 ELSE 0 END AS bit) AS IsWeeklySummary
		, pt.IronOfferID
		, CAST(CASE WHEN pt.TransactionAmount < 0 THEN 1 ELSE 0 END AS BIT) AS IsNegative
	FROM Relational.PartnerTrans pt
	LEFT OUTER JOIN APW.PartnerAlternate alt ON pt.PartnerID = alt.PartnerID
	INNER JOIN Relational.Customer c ON pt.FanID = c.FanID
	INNER JOIN Relational.IronOffer i ON pt.IronOfferID = i.ID
	INNER JOIN Relational.Offer o ON i.OfferID = o.ID
	LEFT OUTER JOIN APW.PartnerDeal pd ON pt.PartnerID = pd.RetailerID
		AND c.ClubID = pd.PublisherID 
		AND pt.TransactionDate >= pd.StartDate 
		AND pt.TransactionDate < pd.EndDate
	LEFT OUTER JOIN APW.PublisherExclude pe ON pt.PartnerID = pe.RetailerID AND c.ClubID = pe.PublisherID AND pt.TransactionDate BETWEEN pe.StartDate AND pe.EndDate
	WHERE pt.TransactionDate BETWEEN @StartDate AND @EndDate

END

