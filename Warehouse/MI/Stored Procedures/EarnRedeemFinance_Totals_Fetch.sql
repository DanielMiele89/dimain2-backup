-- =============================================
-- Author:		JEA
-- Create date: 26/06/2014
-- Description:	Retrieves Earning and redemption information by brand TOTAL
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_Totals_Fetch] 
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

	SELECT BrandID 
		, PaymentMethodID
		, IsRBS
		, ChargeTypeID
		, SUM(Earnings) AS Earnings
		, SUM(RedemptionValue) AS RedemptionValue
		, SUM(EligibleEarnings)-SUM(RedemptionValue) AS EligibleEarnings
		, SUM(IneligibleEarnings) AS IneligibleEarnings
		, CAST(0 as MONEY) AS NoLiability
	FROM
	(

    SELECT e.BrandID 
		, e.PaymentMethodID
		, e.IsRBS
		, e.ChargeTypeID
		, SUM(EarnAmount) AS Earnings
		, CAST(0 AS MONEY) AS RedemptionValue
		, CAST(0 AS MONEY) AS EligibleEarnings
		, CAST(0 AS MONEY) AS IneligibleEarnings
	FROM MI.EarnRedeemFinance_Earnings e
	LEFT OUTER JOIN Relational.Brand b ON e.BrandID = b.BrandID
	WHERE TransactionDate < @EndDate
	GROUP BY e.BrandID
		, e.PaymentMethodID
		, e.IsRBS
		, e.ChargeTypeID

	UNION ALL

	SELECT e.BrandID 
		, e.PaymentMethodID
		, e.IsRBS
		, e.ChargeTypeID
		, CAST(0 AS MONEY) AS Earnings
		, SUM(E.ChargeAmount) AS RedemptionValue
		, CAST(0 AS MONEY) AS EligibleEarnings
		, CAST(0 AS MONEY) AS IneligibleEarnings
	FROM MI.EarnRedeemFinance_RedemptionCharge e
	LEFT OUTER JOIN Relational.Brand b ON e.BrandID = b.BrandID
	WHERE E.ChargeDate < @EndDate
	GROUP BY e.BrandID
		, e.PaymentMethodID
		, e.IsRBS
		, e.ChargeTypeID

	UNION ALL

	SELECT e.BrandID 
		, e.PaymentMethodID
		, e.IsRBS
		, e.ChargeTypeID
		, CAST(0 AS MONEY) AS Earnings
		, CAST(0 AS MONEY) AS RedemptionValue
		, SUM(E.EarnAmount) AS EligibleEarnings
		, CAST(0 AS MONEY) AS IneligibleEarnings
	FROM MI.EarnRedeemFinance_Earnings e
	LEFT OUTER JOIN Relational.Brand b ON e.BrandID = b.BrandID
	INNER JOIN MI.EarnRedeemFinance_CustomerEligible c on e.FanID = c.FanID
	WHERE TransactionDate < @EndDate
	AND C.CustomerActive = 1
	AND C.CustomerEligible = 1
	AND e.EligibleDate < @EndDate
	GROUP BY e.BrandID
		, e.PaymentMethodID
		, e.IsRBS
		, e.ChargeTypeID

	UNION ALL

	SELECT e.BrandID 
		, e.PaymentMethodID
		, e.IsRBS
		, e.ChargeTypeID
		, CAST(0 AS MONEY) AS Earnings
		, CAST(0 AS MONEY) AS RedemptionValue
		, CAST(0 AS MONEY) AS EligibleEarnings
		, SUM(E.EarnAmount) AS IneligibleEarnings
	FROM MI.EarnRedeemFinance_Earnings e
	LEFT OUTER JOIN Relational.Brand b ON e.BrandID = b.BrandID
	INNER JOIN MI.EarnRedeemFinance_CustomerEligible c on e.FanID = c.FanID
	WHERE TransactionDate < @EndDate
	AND C.CustomerActive = 1
	AND (C.CustomerEligible = 0 OR e.EligibleDate >= @EndDate)
	GROUP BY e.BrandID
		, e.PaymentMethodID
		, e.IsRBS
		, e.ChargeTypeID
	) E
	GROUP BY BrandID
		, e.PaymentMethodID
		, e.IsRBS
		, e.ChargeTypeID

END
