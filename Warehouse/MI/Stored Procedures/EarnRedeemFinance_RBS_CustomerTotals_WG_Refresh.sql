-- =============================================
-- Author:		JEA
-- Create date: 25/11/2014
-- Description:	Refreshes EarnRedeemFinance RBS customer totals
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_RBS_CustomerTotals_WG_Refresh] 
	(
		@IsMonthEnd BIT = 1
	)
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    CREATE TABLE #BrandCombos(ID TINYINT PRIMARY KEY IDENTITY
	, BrandID SMALLINT NOT NULL
	, PaymentMethodID TINYINT NOT NULL
	, IsRBS BIT NOT NULL
	, ChargeTypeID TINYINT NOT NULL
	)

	INSERT INTO #BrandCombos(BrandID, PaymentMethodID, IsRBS, ChargeTypeID)
	SELECT BrandID, PaymentMethodID, IsRBS, ChargeTypeID
	FROM MI.EarnRedeemFinance_RBS_Totals_WG

	DECLARE @ID TINYINT = 1

	DECLARE @BrandID SMALLINT, @PaymentMethodID TINYINT, @IsRBS BIT, @ChargeTypeID TINYINT, @EligibleCount INT, @EarnedCount INT
		, @EligibleCountNatWest INT, @EligibleCountRBS INT
		, @EarnedCountNatWest INT, @EarnedCountRBS INT

	DECLARE @EndDate DATETIME

	IF @IsMonthEnd = 1
	BEGIN
		SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	END
	ELSE
	BEGIN
		SET @EndDate = GETDATE()
	END

	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_EligibleCustomers_WG

	WHILE @ID IS NOT NULL
	BEGIN

		SELECT @BrandID = BrandID, @PaymentMethodID = PaymentMethodID, @IsRBS = IsRBS, @ChargeTypeID = ChargeTypeID
		FROM #BrandCombos WHERE ID = @ID


		SELECT @EligibleCount = COUNT(1)
		FROM
		(
		SELECT e.FanID, e.Earned, ISNULL(r.Redeemed, 0) AS Redeemed
		FROM
			(
				SELECT c.FanID, SUM(EarnAmount) AS Earned
				FROM MI.EarnRedeemFinance_RBS_Earnings e
				INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON e.FanID = c.FanID
				WHERE BrandID = @BrandID
					AND PaymentMethodID = @PaymentMethodID
					AND IsRBS = @IsRBS
					AND ChargeTypeID = @ChargeTypeID
					AND EligibleDate < @EndDate
					AND c.CustomerEligible = 1
					AND c.CustomerActive = 1
					AND c.IsRainbow = 1
				GROUP BY c.FanID
			) e
			LEFT OUTER JOIN
			(
				SELECT c.FanID, SUM(r.ChargeAmount) AS Redeemed
				FROM MI.EarnRedeemFinance_RBS_RedemptionCharge r
				INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON r.FanID = c.FanID
				WHERE BrandID = @BrandID
					AND PaymentMethodID = @PaymentMethodID
					AND IsRBS = @IsRBS
					AND ChargeTypeID = @ChargeTypeID
					AND c.CustomerEligible = 1
					AND c.CustomerActive = 1
					AND c.IsRainbow = 1
				GROUP BY c.FanID
			) r ON e.FanID = r.FanID
		) e
		WHERE e.Earned > e.Redeemed

		SELECT @EarnedCount = COUNT(1)
		FROM
		(
		SELECT e.FanID, e.Earned, ISNULL(r.Redeemed, 0) AS Redeemed
		FROM
			(
				SELECT c.FanID, SUM(EarnAmount) AS Earned
				FROM MI.EarnRedeemFinance_RBS_Earnings e
				INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON e.FanID = c.FanID
				WHERE BrandID = @BrandID
					AND PaymentMethodID = @PaymentMethodID
					AND IsRBS = @IsRBS
					AND ChargeTypeID = @ChargeTypeID
					AND c.CustomerActive = 1
					AND c.IsRainbow = 1
				GROUP BY c.FanID
			) e
			LEFT OUTER JOIN
			(
				SELECT c.FanID, SUM(r.ChargeAmount) AS Redeemed
				FROM MI.EarnRedeemFinance_RBS_RedemptionCharge r
				INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON r.FanID = c.FanID
				WHERE BrandID = @BrandID
					AND PaymentMethodID = @PaymentMethodID
					AND IsRBS = @IsRBS
					AND ChargeTypeID = @ChargeTypeID
					AND c.CustomerActive = 1
					AND c.IsRainbow = 1
				GROUP BY c.FanID
			) r ON e.FanID = r.FanID
		) e
		WHERE e.Earned > e.Redeemed

		INSERT INTO MI.EarnRedeemFinance_RBS_EligibleCustomers_WG(BrandID
			, PaymentMethodID
			, IsRBS
			, ChargeTypeID
			, EligibleCount
			, EarnedCount)
		VALUES(@BrandID, @PaymentMethodID, @IsRBS, @ChargeTypeID, ISNULL(@EligibleCount, 0), ISNULL(@EarnedCount,0))

		SELECT @ID = MIN(ID) FROM #BrandCombos
		WHERE ID > @ID

	END

	TRUNCATE TABLE MI.EarnRedeemFinance_RBS_EligibleCustomersTotal_WG

	SELECT @EligibleCountNatWest = COUNT(1)
	FROM
	(
	SELECT e.FanID, e.Earned, ISNULL(r.Redeemed, 0) AS Redeemed
	FROM
		(
			SELECT c.FanID, SUM(EarnAmount) AS Earned
			FROM MI.EarnRedeemFinance_RBS_Earnings e
			INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON E.FanID = C.FanID
			INNER JOIN #BrandCombos b ON e.BrandID = b.BrandID
				AND e.PaymentMethodID = b.PaymentMethodID
				AND e.ChargeTypeID = b.ChargeTypeID
				AND E.IsRBS = B.IsRBS
			WHERE b.IsRBS = 0
				AND e.EligibleDate < @EndDate
				AND c.CustomerEligible = 1
				AND C.CustomerActive = 1
				AND c.IsRainbow = 1
			GROUP BY c.FanID
		) e
		LEFT OUTER JOIN
		(
			SELECT c.FanID, SUM(ChargeAmount) AS Redeemed
			FROM MI.EarnRedeemFinance_RBS_RedemptionCharge r
			INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON r.FanID = C.FanID
			INNER JOIN #BrandCombos b ON r.BrandID = b.BrandID
				AND r.PaymentMethodID = b.PaymentMethodID
				AND r.ChargeTypeID = b.ChargeTypeID
				AND r.IsRBS = B.IsRBS
			WHERE b.IsRBS = 0
				AND c.CustomerEligible = 1
				AND C.CustomerActive = 1
				AND c.IsRainbow = 1
			GROUP BY c.FanID
		) r ON e.FanID = r.FanID
	) e
	WHERE e.Earned > e.Redeemed

	SELECT @EarnedCountNatWest = COUNT(1)
	FROM
	(
	SELECT e.FanID, e.Earned, ISNULL(r.Redeemed, 0) AS Redeemed
	FROM
		(
			SELECT c.FanID, SUM(EarnAmount) AS Earned
			FROM MI.EarnRedeemFinance_RBS_Earnings e
			INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON E.FanID = C.FanID
			INNER JOIN #BrandCombos b ON e.BrandID = b.BrandID
				AND e.PaymentMethodID = b.PaymentMethodID
				AND e.ChargeTypeID = b.ChargeTypeID
				AND E.IsRBS = B.IsRBS
			WHERE b.IsRBS = 0
				AND c.CustomerActive = 1
				AND c.IsRainbow = 1
			GROUP BY c.FanID
		) e
		LEFT OUTER JOIN
		(
			SELECT c.FanID, SUM(ChargeAmount) AS Redeemed
			FROM MI.EarnRedeemFinance_RBS_RedemptionCharge r
			INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON r.FanID = C.FanID
			INNER JOIN #BrandCombos b ON r.BrandID = b.BrandID
				AND r.PaymentMethodID = b.PaymentMethodID
				AND r.ChargeTypeID = b.ChargeTypeID
				AND r.IsRBS = B.IsRBS
			WHERE b.IsRBS = 0
				AND c.CustomerActive = 1
				AND c.IsRainbow = 1
			GROUP BY c.FanID
		) r ON e.FanID = r.FanID
	) e
	WHERE e.Earned > e.Redeemed

	SELECT @EligibleCountRBS = COUNT(1)
	FROM
	(
	SELECT e.FanID, e.Earned, ISNULL(r.Redeemed, 0) AS Redeemed
	FROM
		(
			SELECT c.FanID, SUM(EarnAmount) AS Earned
			FROM MI.EarnRedeemFinance_RBS_Earnings e
			INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON E.FanID = C.FanID
			INNER JOIN #BrandCombos b ON e.BrandID = b.BrandID
				AND e.PaymentMethodID = b.PaymentMethodID
				AND e.ChargeTypeID = b.ChargeTypeID
				AND E.IsRBS = B.IsRBS
			WHERE b.IsRBS = 1
				AND e.EligibleDate < @EndDate
				AND c.CustomerEligible = 1
				AND C.CustomerActive = 1
				AND c.IsRainbow = 1
			GROUP BY c.FanID
		) e
		LEFT OUTER JOIN
		(
			SELECT c.FanID, SUM(ChargeAmount) AS Redeemed
			FROM MI.EarnRedeemFinance_RBS_RedemptionCharge r
			INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON r.FanID = C.FanID
			INNER JOIN #BrandCombos b ON r.BrandID = b.BrandID
				AND r.PaymentMethodID = b.PaymentMethodID
				AND r.ChargeTypeID = b.ChargeTypeID
				AND r.IsRBS = B.IsRBS
			WHERE b.IsRBS = 1
				AND c.CustomerEligible = 1
				AND C.CustomerActive = 1
				AND c.IsRainbow = 1
			GROUP BY c.FanID
		) r ON e.FanID = r.FanID
	) e
	WHERE e.Earned > e.Redeemed

	SELECT @EarnedCountRBS = COUNT(1)
	FROM
	(
	SELECT e.FanID, e.Earned, ISNULL(r.Redeemed, 0) AS Redeemed
	FROM
		(
			SELECT c.FanID, SUM(EarnAmount) AS Earned
			FROM MI.EarnRedeemFinance_RBS_Earnings e
			INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON E.FanID = C.FanID
			INNER JOIN #BrandCombos b ON e.BrandID = b.BrandID
				AND e.PaymentMethodID = b.PaymentMethodID
				AND e.ChargeTypeID = b.ChargeTypeID
				AND E.IsRBS = B.IsRBS
			WHERE b.IsRBS = 1
				AND c.CustomerActive = 1
				AND c.IsRainbow = 1
			GROUP BY c.FanID
		) e
		LEFT OUTER JOIN
		(
			SELECT c.FanID, SUM(ChargeAmount) AS Redeemed
			FROM MI.EarnRedeemFinance_RBS_RedemptionCharge r
			INNER JOIN MI.EarnRedeemFinance_RBS_CustomerEligible c ON r.FanID = C.FanID
			INNER JOIN #BrandCombos b ON r.BrandID = b.BrandID
				AND r.PaymentMethodID = b.PaymentMethodID
				AND r.ChargeTypeID = b.ChargeTypeID
				AND r.IsRBS = B.IsRBS
			WHERE b.IsRBS = 1
				AND c.CustomerActive = 1
				AND c.IsRainbow = 1
			GROUP BY c.FanID
		) r ON e.FanID = r.FanID
	) e
	WHERE e.Earned > e.Redeemed

	INSERT INTO MI.EarnRedeemFinance_RBS_EligibleCustomersTotal_WG(
		EligibleCountNatWest
		, EliglbleCountRBS
		, EarnedCountNatWest
		, EarnedCountRBS
		)
	VALUES(ISNULL(@EligibleCountNatWest, 0), ISNULL(@EligibleCountRBS, 0), ISNULL(@EarnedCountNatWest, 0), ISNULL(@EarnedCountRBS, 0))

END
