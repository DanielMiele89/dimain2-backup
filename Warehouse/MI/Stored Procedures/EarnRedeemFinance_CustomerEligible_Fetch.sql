-- =============================================
-- Author:		JEA
-- Create date: 25/06/2014
-- Description:	Retrieves customer information for
-- the previous month allowing determination of
-- whether RBS funded cashback is eligible for redemption
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_CustomerEligible_Fetch] 

AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @EndDate DATETIME

	SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)

	SELECT a.FanID
		, a.ActivatedDate
		, a.DeactivatedDate
		, a.OptedOutDate
		, ISNULL(e.EarningsCleared,0) AS EarningsCleared
		, ISNULL(r.Redeemed,0) AS Redeemed
		, @EndDate AS EndDate
		, CAST(CASE WHEN a.IsRBS = 1 THEN 1 ELSE 2 END AS TINYINT) AS BankID
	FROM 
	MI.CustomerActiveStatus a
	LEFT OUTER JOIN
	(
		SELECT FanID, SUM(EarnAmount) AS EarningsCleared
		FROM MI.EarnRedeemFinance_Earnings
		WHERE EligibleDate < @EndDate
		GROUP BY FanID
	) e ON a.FanID = e.FanID
	LEFT OUTER JOIN
	(
		SELECT FanID, SUM(RedemptionAmount) AS Redeemed
		FROM EarnRedeemFinance_Redemptions
		WHERE RedeemDate < @EndDate
		GROUP BY FanID
	) r ON a.FanID = r.FanID

END