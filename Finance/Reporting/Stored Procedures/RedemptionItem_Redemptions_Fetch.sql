CREATE PROCEDURE [Reporting].[RedemptionItem_Redemptions_Fetch]
AS
BEGIN

	SELECT
		ro.RedemptionDescription
		, ro.RedemptionPartnerID
		, p.RedemptionPartnerName AS PartnerName
		, SUM(RedemptionValue) RedemptionValue
		, COUNT(1) RedemptionCount
		, RedemptionType
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, RedemptionDate), 0) MonthDate
	FROM dbo.Redemptions r
	JOIN dbo.RedemptionItem ro
		ON r.RedemptionItemID = ro.RedemptionItemID
	JOIN dbo.RedemptionPartner p
		ON ro.RedemptionPartnerID = p.RedemptionPartnerID
	GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, RedemptionDate), 0)
		, RedemptionType
		, ro.RedemptionPartnerID
		, ro.RedemptionDescription
		, p.RedemptionPartnerName
	
END

