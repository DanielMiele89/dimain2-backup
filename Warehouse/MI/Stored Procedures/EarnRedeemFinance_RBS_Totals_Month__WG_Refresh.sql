-- =============================================
-- Author:		JEA
-- Create date: 25/11/2014
-- Description:	Refreshes Earning and redemption information by brand TOTAL
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_RBS_Totals_Month__WG_Refresh] 
	(
		@IsMonthEnd BIT = 1
	)
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATETIME

	IF @IsMonthEnd = 1
	BEGIN
		SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
		SET @StartDate = DATEADD(MONTH, -1, @StartDate)
	END
	ELSE
	BEGIN
		SET @EndDate = GETDATE()
		SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	END

	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_Totals_Month

	INSERT INTO MI.EarnRedeemFinance_RBS_Totals_Month_WG(BrandID, PaymentMethodID, IsRBS, ChargeTypeID, Earnings, RedemptionValue, EligibleEarnings, IneligibleEarnings, NoLiability)

	SELECT BrandID 
		, PaymentMethodID
		, IsRBS
		, ChargeTypeID
		, SUM(Earnings) AS Earnings
		, SUM(RedemptionValue) AS RedemptionValue
		, SUM(EligibleEarnings) AS EligibleEarnings
		, SUM(IneligibleEarnings) AS IneligibleEarnings
		, SUM(NoLiability) AS NoLiability
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
		, CAST(0 AS MONEY) AS NoLiability
	FROM MI.EarnRedeemFinance_RBS_Earnings e
	LEFT OUTER JOIN Relational.Brand b ON e.BrandID = b.BrandID
	INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c on e.FanID = c.FanID
	WHERE TransactionDate < @EndDate
	AND  TransactionDate >= @StartDate
	AND (b.ChargeOnRedeem = 1 OR (E.BrandID = 0 AND E.PaymentMethodID < 200))
	AND c.IsRainbow = 1
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
		, CAST(0 AS MONEY) AS NoLiability
	FROM MI.EarnRedeemFinance_RBS_RedemptionCharge e
	LEFT OUTER JOIN Relational.Brand b ON e.BrandID = b.BrandID
	INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c on e.FanID = c.FanID
	WHERE E.ChargeDate < @EndDate
	AND E.ChargeDate >= @StartDate
	AND (b.ChargeOnRedeem = 1 OR (E.BrandID = 0 AND E.PaymentMethodID < 200))
	AND c.IsRainbow = 1
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
		, CAST(0 AS MONEY) AS NoLiability
	FROM MI.EarnRedeemFinance_RBS_Earnings e
	LEFT OUTER JOIN Relational.Brand b ON e.BrandID = b.BrandID
	INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c on e.FanID = c.FanID
	WHERE TransactionDate < @EndDate
	AND TransactionDate >= @StartDate
	AND (b.ChargeOnRedeem = 1 OR (E.BrandID = 0 AND E.PaymentMethodID < 200))
	AND C.CustomerActive = 1
	AND C.CustomerEligible = 1
	AND e.EligibleDate < @EndDate
	AND c.IsRainbow = 1
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
		, CAST(0 AS MONEY) AS NoLiability
	FROM MI.EarnRedeemFinance_RBS_Earnings e
	LEFT OUTER JOIN Relational.Brand b ON e.BrandID = b.BrandID
	INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c on e.FanID = c.FanID
	WHERE TransactionDate < @EndDate
	AND TransactionDate >= @StartDate
	AND (b.ChargeOnRedeem = 1 OR (E.BrandID = 0 AND E.PaymentMethodID < 200))
	AND C.CustomerActive = 1
	AND (C.CustomerEligible = 0 OR e.EligibleDate >= @EndDate)
	AND c.IsRainbow = 1
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
		, CAST(0 AS MONEY) AS IneligibleEarnings
		, SUM(E.EarnAmount) AS NoLiability
	FROM MI.EarnRedeemFinance_RBS_Earnings e
	LEFT OUTER JOIN Relational.Brand b ON e.BrandID = b.BrandID
	INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c on e.FanID = c.FanID
	WHERE TransactionDate < @EndDate
	AND TransactionDate >= @StartDate
	AND (b.ChargeOnRedeem = 1 OR (E.BrandID = 0 AND E.PaymentMethodID < 200))
	AND C.CustomerActive = 0
	AND c.IsRainbow = 1
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