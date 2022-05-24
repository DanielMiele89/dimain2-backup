
-- =============================================
-- Author:		JEA
-- Create date: 03/09/2014
-- Description:	Retrieves CBP retailer transactions
-- for Reward BI population
-- =============================================
CREATE PROCEDURE [RewardBI].[CBP_PartnerTrans_Earnings_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT pt.CashbackEarned AS Earnings 
		, S.SchemeTransID AS SourceTransID
		, pt.MatchID
		, pt.AddedDate
		, CAST(CASE WHEN b.ChargeOnRedeem = 1 THEN 'Publisher-Funded Retailer' ELSE 'Partner-Funded' END AS VARCHAR(50)) AS EarningType
		, CAST(0 AS MONEY) AS PublisherCommission
		, CAST(CASE WHEN p.PartnerID = 3960 THEN 0 ELSE pt.CommissionChargable - pt.CashbackEarned END AS MONEY) AS RewardCommission
	FROM Relational.PartnerTrans pt
	INNER JOIN Relational.[Partner] p ON pt.PartnerID = p.PartnerID
	INNER JOIN Relational.Brand b ON p.BrandID = b.BrandID
	INNER JOIN MI.SchemeTransUniqueID S on pt.MatchID = s.MatchID

END