
-- =============================================
-- Author:		JEA
-- Create date: 15/09/2014
-- Description:	Retrieves for Reward BI
-- =============================================
CREATE PROCEDURE [RewardBI].[Redemptions_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT CashbackUsed AS Amount
		, CashbackUsed AS Worth
		, CAST(RedemptionDate AS DATE) AS RedeemDate
		, FanID
		, CAST(i.RedemptionDescription AS VARCHAR(50)) AS RedeemType
		, CAST(2 AS TINYINT) AS SchemeID
		, CAST(2 AS TINYINT) AS PublisherID
		, CAST(0 AS INT) AS RetailerID
		, CAST(CASE WHEN CashbackUsed < 0 THEN 1 ELSE 0 END AS BIT) AS IsRefund
	FROM Relational.Redemption r
	INNER JOIN Relational.RedemptionItem i ON r.RedemptionItemID = i.RedemptionItemID

END

