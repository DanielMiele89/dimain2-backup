
-- =============================================
-- Author:		JEA
-- Create date: 10/08/2016
-- Description:	Retrieves retailer transactions for Weekly Summary
-- =============================================
CREATE PROCEDURE [APW].[SchemeTrans_WeekSum_Fetch] 
(@StartDate DATE, @EndDate DATE)	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT pt.MatchID AS ID
		, pt.TransactionAmount AS Spend
		, pt.CashbackEarned AS RetailerCashback
		, CAST(pt.TransactionDate AS DATE) AS TranDate
		, pt.AddedDate
		, pt.FanID
		, COALESCE(alt.AlternatePartnerID, pt.PartnerID) AS RetailerID
		, CAST(132 AS INT) AS PublisherID
		, pt.CommissionChargable - pt.CashbackEarned AS CommissionOverride
		, pt.CommissionChargable - pt.CashbackEarned AS PlatformFee
		, CAST(0 AS SMALLMONEY) AS PublisherShare
		, CAST(0 AS SMALLMONEY) AS OfferSourceShare
		, CAST(0 AS SMALLMONEY) AS AccMgtShare
		, CAST(0 AS SMALLMONEY) AS PublisherCashback
		, CAST(0 AS BIT) AS IsRoc
		, pt.CommissionChargable AS Investment
		, ISNULL(pt.IsOnline,0) AS IsOnline
		, CAST(CASE WHEN pe.ID IS NULL THEN 1 ELSE 0 END AS bit) AS IsWeeklySummary
		, pt.IronOfferID
		, CAST(CASE WHEN pt.TransactionAmount < 0 THEN 1 ELSE 0 END AS BIT) AS IsNegative
	FROM Relational.PartnerTrans pt
	LEFT OUTER JOIN APW.PartnerAlternate alt ON pt.PartnerID = alt.PartnerID
	LEFT OUTER JOIN APW.PublisherExclude pe ON pt.PartnerID = pe.RetailerID AND pt.TransactionDate BETWEEN pe.StartDate AND pe.EndDate
	WHERE pt.TransactionDate BETWEEN @StartDate AND @EndDate

END

