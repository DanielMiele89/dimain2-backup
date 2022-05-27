-- =============================================
-- Author:		JEA
-- Create date: 18/06/2013
-- Description:	Fetches redemption list
-- =============================================
CREATE PROCEDURE [Staging].[SchemeRedemptionList_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT r.FanID
		, r.TranID
		, r.RedeemDate
		, ISNULL(r.RedeemType, 'Cash') AS RedeemType
		, p.BrandID
		, r.CashbackUsed AS RedeemValue
		, TradeUp_Value AS TradeUpValue
		, ROW_NUMBER() OVER (PARTITION BY r.FanID ORDER BY r.RedeemDate) AS RedemptionOrdinal
	FROM Relational.Redemptions r
	INNER JOIN MI.CustomerActiveStatus c ON r.FanID = c.FanID
	LEFT OUTER JOIN Relational.[Partner] p ON r.PartnerID = p.PartnerID
	WHERE r.Cancelled = 0
	AND r.RedeemDate >= c.ActivatedDate
    
END
