
-- =============================================
-- Author:		JEA
-- Create date: 13/11/2014
-- Description:	Retrieves list of redemptions to refresh the list of charges to RBS
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_RBS_RedemptionsToCharge_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT r.ID
		, r.FanID
		, r.RedeemDate
		, r.RedemptionAmount
		, CAST(CASE WHEN c.ClubID = 138 THEN 1 ELSE 0 END AS BIT) AS IsRBS
	FROM MI.EarnRedeemFinance_RBS_Redemptions r
	INNER JOIN Relational.Customer c ON r.FanID = c.FanID
	ORDER BY FanID, RedeemDate

END