-- =============================================
-- Author:		JEA
-- Create date: 27/08/2013
-- Description:	Retrieves customer information for
-- the previous month allowing determination of
-- whether RBS funded cashback is eligible for redemption
-- =============================================
CREATE PROCEDURE [MI].[ChargeOnRedeem_CustomerEligible_Fetch] 
	(
		@UseCurrentDate bit = 0
	)
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @EndDate DATETIME

	IF @UseCurrentDate = 0
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
		, @EndDate AS EndDate
		, CAST(CASE WHEN a.IsRBS = 1 THEN 1 ELSE 2 END AS TINYINT) AS BankID
	FROM 
	MI.CustomerActiveStatus a
	LEFT OUTER JOIN
	(
		SELECT FanID
			, SUM(EarnAmount) AS EarningsCleared
		FROM MI.ChargeOnRedeem_Earnings
		WHERE EligibleDate <= @EndDate
		GROUP BY FanID
	) e ON a.FanID = e.FanID
	LEFT OUTER JOIN
	(
		SELECT FanID, SUM(CashBackUsed) AS Redeemed
		FROM Relational.Redemptions
		WHERE Cancelled = 0
		AND RedeemDate < @EndDate
		GROUP BY FanID
	) r ON a.FanID = r.FanID

END