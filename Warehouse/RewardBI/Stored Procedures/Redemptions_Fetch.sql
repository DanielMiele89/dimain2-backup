-- =============================================
-- Author:		JEA
-- Create date: 15/09/2014
-- Description:	Retrieves Redemptions for Reward BI
-- =============================================
CREATE PROCEDURE [RewardBI].[Redemptions_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT CashbackUsed AS Amount
		, COALESCE(TradeUp_Value, CashbackUsed) AS Worth
		, CAST(RedeemDate AS DATE) AS RedeemDate
		, CAST(RedeemType AS VARCHAR(50)) AS RedeemType
		, RedemptionDescription
		, FanID
		, CAST(1 AS TINYINT) AS SchemeID
		, CAST(1 AS TINYINT) AS PublisherID
		, PartnerID
		, CAST(0 AS BIT) AS IsRefund
	FROM Relational.Redemptions

END
