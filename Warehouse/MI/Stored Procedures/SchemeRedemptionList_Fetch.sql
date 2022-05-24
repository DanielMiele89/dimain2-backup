-- =============================================
-- Author:		JEA
-- Create date: 29/10/2013
-- Description:	Fetches redemption list
-- =============================================
CREATE PROCEDURE [MI].[SchemeRedemptionList_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT r.FanID
		, r.TranID
		, r.RedeemDate
		, ISNULL(r.RedeemType, 'Cash') AS RedeemType
		, r.RedemptionDescription
		, COALESCE(p.BrandID, rob.BrandID) AS BrandID
		, r.CashbackUsed AS RedeemValue
		, COALESCE(r.TradeUp_Value, r.CashbackUsed) AS TradeUpValue
		, ROW_NUMBER() OVER (PARTITION BY r.FanID ORDER BY r.RedeemDate) AS RedemptionOrdinal
	FROM Relational.Redemptions r
	INNER JOIN MI.CustomerActiveStatus c ON r.FanID = c.FanID
	LEFT OUTER JOIN Relational.[Partner] p ON r.PartnerID = p.PartnerID
	LEFT OUTER JOIN MI.RedemptionOnlyBrand rob ON r.PartnerID = rob.PartnerID
	WHERE r.Cancelled = 0
	AND r.RedeemDate >= c.ActivatedDate
    
END