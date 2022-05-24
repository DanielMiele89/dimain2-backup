-- =============================================
-- Author:		JEA
-- Create date: 13/11/2014
-- Description:	Retrieves customer information for
-- the previous month allowing determination of
-- whether RBS funded cashback is eligible for redemption
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_RBS_CustomerEligible_Fetch] 
	(
		@IsMonthEnd BIT = 1
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @EndDate DATETIME

	IF @IsMonthEnd = 1
	BEGIN
		SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	END
	ELSE
	BEGIN
		SET @EndDate = GETDATE()
	END

	SELECT a.FanID
		, a.ActivatedDate
		, a.DeactivatedDate
		, a.OptedOutDate
		, ISNULL(e.EarningsCleared,0) AS EarningsCleared
		, ISNULL(r.Redeemed,0) AS Redeemed
		, CAST(@EndDate AS DATE) AS EndDate
		, CAST(CASE WHEN a.IsRBS = 1 THEN 1 ELSE 2 END AS TINYINT) AS BankID
		, c.Rainbow_Customer AS IsRainbow
	FROM 
	MI.CustomerActiveStatus a
	LEFT OUTER JOIN
	(
		SELECT FanID, SUM(EarnAmount) AS EarningsCleared
		FROM MI.EarnRedeemFinance_RBS_Earnings
		WHERE EligibleDate < @EndDate
		GROUP BY FanID
	) e ON a.FanID = e.FanID
	LEFT OUTER JOIN
	(
		SELECT FanID, SUM(RedemptionAmount) AS Redeemed
		FROM MI.EarnRedeemFinance_RBS_Redemptions
		WHERE RedeemDate < @EndDate
		GROUP BY FanID
	) r ON a.FanID = r.FanID
	INNER JOIN Relational.Customer c ON a.FanID = c.FanID

END