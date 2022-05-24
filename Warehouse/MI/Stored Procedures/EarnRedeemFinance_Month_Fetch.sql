-- =============================================
-- Author:		JEA
-- Create date: 26/06/2014
-- Description:	Retrieves Earning and redemption information by brand by month
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_Month_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	/*
		JEA 01/07/2014
		This report shows data by month in the current financial year and brought forward for previous financial years.
		The Reward financial year runs from 01/05/2014.  Therefore all data from the preceding April should be aggregated as previous.
		Where May of the current year is complete, it should show as the first month of the currently displayed financial year.
	*/

	DECLARE @MonthDate DATE

	IF MONTH(GETDATE()) < 6
	BEGIN
		SET @MonthDate = DATEFROMPARTS(YEAR(GETDATE()) -1,4,1) --if the report is run before June, the financial year dates from the previous May.
	END
	ELSE
	BEGIN
		SET @MonthDate = DATEFROMPARTS(YEAR(GETDATE()),4,1) --if the report is run in or after June, the financial year dates from the current May.
	END

	CREATE TABLE #RBS(IsRBS BIT)
	
	INSERT INTO #RBS(IsRBS)
	VALUES(0), (1)

	CREATE TABLE #PaymentMethod(PaymentMethodID TINYINT PRIMARY KEY)

	INSERT INTO #PaymentMethod(PaymentMethodID)
	VALUES(0), (1)

--Create a list of brand names iwth an identity column for row colours
	CREATE TABLE #Brands(BrandID SMALLINT
		, BrandListID SMALLINT PRIMARY KEY IDENTITY
		, ChargeTypeID TINYINT NOT NULL
		, BrandName VARCHAR(50) NOT NULL)

	CREATE TABLE #MonthDates(MonthDate DATE PRIMARY KEY)

	INSERT INTO #Brands(BrandID, ChargeTypeID, BrandName)

	SELECT DISTINCT B.BrandID, 0 AS ChargeTypeID, B.BrandName
	FROM MI.EarnRedeemFinance_EarnRedeemByMonth e
	INNER JOIN Relational.Brand b ON e.BrandID = b.BrandID

	UNION ALL

	SELECT 0 AS BrandID, 255 AS ChargeTypeID, 'Cashback Award' AS BrandName

	UNION ALL

	SELECT 0 AS BrandID, AdditionalCashbackAwardTypeID, 'RBS ' + Title AS BrandName
	FROM Relational.AdditionalCashbackAwardType

	UNION ALL

	SELECT 0 AS BrandID, 200 AS ChargeTypeID, 'Unallocated Redemption' AS BrandName

	ORDER BY BrandName

	INSERT INTO #MonthDates(MonthDate)
	SELECT DISTINCT E.MonthDate
	FROM MI.EarnRedeemFinance_EarnRedeemByMonth E
	INNER JOIN #Brands b ON e.BrandID = b.BrandID
	WHERE MonthDate > @MonthDate

	--return the query result
    SELECT B.BrandListID 
		, B.BrandName AS Brand
		, e.PaymentMethodID
		, e.IsRBS
		, CAST(NULL AS DATE) AS MonthDate
		, CAST(1 AS BIT) AS IsPrevious
		, SUM(Earnings) AS Earnings
		, SUM(RedemptionValue) AS RedemptionValue
	FROM MI.EarnRedeemFinance_EarnRedeemByMonth e
	INNER JOIN #Brands b ON e.BrandID = b.BrandID AND e.ChargeTypeID = b.ChargeTypeID
	WHERE MonthDate <= @MonthDate
	GROUP BY b.BrandName
		, b.BrandListID
		, e.PaymentMethodID
		, e.IsRBS

	UNION ALL

	SELECT BrandListID
		, Brand
		, PaymentMethodID
		, IsRBS
		, MonthDate
		, IsPrevious
		, SUM(Earnings) AS Earnings
		, SUM(RedemptionValue) AS RedemptionValue
	FROM
	(
		SELECT b.brandListID
			, B.BrandName AS Brand
			, e.PaymentMethodID
			, e.IsRBS
			, MonthDate
			, CAST(0 AS BIT) AS IsPrevious
			, Earnings
			, RedemptionValue
		FROM MI.EarnRedeemFinance_EarnRedeemByMonth E
		INNER JOIN #Brands b ON e.BrandID = b.BrandID AND e.ChargeTypeID = b.ChargeTypeID
		WHERE MonthDate > @MonthDate

		UNION ALL

		SELECT b.brandListID
			, B.BrandName AS Brand
			, p.PaymentMethodID
			, r.IsRBS
			, m.MonthDate
			, CAST(0 AS BIT) AS IsPrevious
			, CAST(0 AS MONEY) AS Earnings
			, CAST(0 AS MONEY) AS RedemptionValue
		FROM #Brands b
		CROSS JOIN #MonthDates m
		CROSS JOIN #RBS r
		CROSS JOIN #PaymentMethod p
		WHERE b.ChargeTypeID != 255
		AND (P.PaymentMethodID = 1 OR (B.ChargeTypeID != 2 AND B.ChargeTypeID != 3))
		AND b.ChargeTypeID != 200

		UNION ALL

		SELECT b.brandListID
			, B.BrandName AS Brand
			, CAST(255 AS TINYINT) AS PaymentMethodID
			, r.IsRBS
			, m.MonthDate
			, CAST(0 AS BIT) AS IsPrevious
			, CAST(0 AS MONEY) AS Earnings
			, CAST(0 AS MONEY) AS RedemptionValue
		FROM #Brands b
		CROSS JOIN #MonthDates m
		CROSS JOIN #RBS r
		WHERE b.ChargeTypeID = 255

		UNION ALL

		SELECT b.brandListID
			, B.BrandName AS Brand
			, CAST(200 AS TINYINT) AS PaymentMethodID
			, r.IsRBS
			, m.MonthDate
			, CAST(0 AS BIT) AS IsPrevious
			, CAST(0 AS MONEY) AS Earnings
			, CAST(0 AS MONEY) AS RedemptionValue
		FROM #Brands b
		CROSS JOIN #MonthDates m
		CROSS JOIN #RBS r
		WHERE b.ChargeTypeID = 200

	) T
	GROUP BY BrandListID
		, PaymentMethodID
		, IsRBS
		, Brand
		, MonthDate
		, IsPrevious

END