CREATE PROCEDURE [Reporting].[RedemptionItem_Redemptions_Fetch_OLD]
AS
BEGIN

	SELECT
		RedeemDescription
		, ro.PartnerID
		, p.Name AS PartnerName
		, SUM(RedemptionValue) RedemptionValue
		, COUNT(1) RedemptionCount
		, RedemptionType
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, RedemptionDate), 0) MonthDate
	FROM dbo.Redemptions r
	JOIN dbo.RedeemOffer ro
		ON r.RedeemOfferID = ro.RedeemOfferID
	JOIN dbo.Partner p
		ON ro.PartnerID = p.PartnerID
	GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, RedemptionDate), 0)
		, RedemptionType
		, ro.PartnerID
		, RedeemDescription
		, p.Name
	
END

