-- =============================================
-- Author:		JEA
-- Create date: 19/04/2016
-- Description:	Retrieves retailer transactions for AllPublisherWarehouse
-- =============================================
CREATE PROCEDURE [APW].[SchemeTrans_Fetch] 
	
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
		, CAST(CASE WHEN pe.ID IS NULL THEN 1 ELSE 0 END AS bit) AS IsMonthlyReport
		, pt.IronOfferID
	FROM Relational.PartnerTrans pt
	LEFT OUTER JOIN APW.PartnerAlternate alt ON pt.PartnerID = alt.PartnerID
	LEFT OUTER JOIN APW.PublisherExclude pe ON pt.PartnerID = pe.RetailerID AND pt.TransactionDate BETWEEN pe.StartDate AND pe.EndDate

END
