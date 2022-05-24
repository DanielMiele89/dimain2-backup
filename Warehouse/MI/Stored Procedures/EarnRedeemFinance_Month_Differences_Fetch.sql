-- =============================================
-- Author:		JEA
-- Create date: 26/06/2014
-- Description:	Retrieves Earning and redemption information by brand by month
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_Month_Differences_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	/*
		JEA 01/07/2014
		This report shows data by month in the current financial year and "brought forward for previous financial years.
		The Reward financial year runs from 01/05/2014.  Therefore all data from the preceding April should be aggregated as previous.
		Where May of the current year is complete, it should show as the first month of the currently displayed financial year.
	*/

	DECLARE @MonthDate DATE, @ArchiveLast DATE, @ArchiveBeforeLast DATE, @MaxMonthDate DATE

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

	CREATE TABLE #ArchiveLastValues([ID] [int] PRIMARY KEY IDENTITY,
	[MonthDate] [date] NOT NULL,
	[BrandID] [smallint] NOT NULL,
	[Earnings] [money] NOT NULL,
	[RedemptionValue] [money] NOT NULL,
	[ChargeTypeID] [tinyint] NOT NULL,
	[PaymentMethodID] [tinyint] NOT NULL,
	[IsRBS] [bit] NOT NULL)

	CREATE TABLE #ArchiveBeforeLastValues([ID] [int] PRIMARY KEY IDENTITY,
	[MonthDate] [date] NOT NULL,
	[BrandID] [smallint] NOT NULL,
	[Earnings] [money] NOT NULL,
	[RedemptionValue] [money] NOT NULL,
	[ChargeTypeID] [tinyint] NOT NULL,
	[PaymentMethodID] [tinyint] NOT NULL,
	[IsRBS] [bit] NOT NULL)

	CREATE TABLE #ArchiveDifferences([ID] [int] PRIMARY KEY IDENTITY,
	[MonthDate] [date] NOT NULL,
	[BrandID] [smallint] NOT NULL,
	[Earnings] [money] NOT NULL,
	[RedemptionValue] [money] NOT NULL,
	[ChargeTypeID] [tinyint] NOT NULL,
	[PaymentMethodID] [tinyint] NOT NULL,
	[IsRBS] [bit] NOT NULL)

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

	SELECT @ArchiveLast = MAX(ArchiveDate) FROM MI.EarnRedeemFinance_EarnRedeemByMonth_Archive

	SELECT @ArchiveBeforeLast = MAX(ArchiveDate) FROM MI.EarnRedeemFinance_EarnRedeemByMonth_Archive WHERE ArchiveDate < @ArchiveLast

	INSERT INTO #MonthDates(MonthDate)
	SELECT DISTINCT MonthDate
	FROM MI.EarnRedeemFinance_EarnRedeemByMonth_Archive
	WHERE ArchiveDate = @ArchiveBeforeLast

	SELECT @MaxMonthDate = MAX(MonthDate)
	FROM MI.EarnRedeemFinance_EarnRedeemByMonth_Archive
	WHERE ArchiveDate = @ArchiveBeforeLast 

	INSERT INTO #ArchiveLastValues(MonthDate, BrandID, Earnings, RedemptionValue, ChargeTypeID, PaymentMethodID, IsRBS)

	SELECT MonthDate, BrandID, SUM(Earnings) AS Earnings, SUM(RedemptionValue) AS RedemptionValue, ChargeTypeID, PaymentMethodID, IsRBS
	FROM
	(
		SELECT MonthDate, BrandID, Earnings, RedemptionValue, ChargeTypeID, PaymentMethodID, IsRBS
		FROM MI.EarnRedeemFinance_EarnRedeemByMonth_Archive
		WHERE ArchiveDate = @ArchiveLast
		AND MonthDate <= @MaxMonthDate

		UNION ALL

		SELECT m.MonthDate, b.BrandID, CAST(0 AS MONEY) AS Earnings, CAST(0 AS MONEY) AS RedemptionValue, b.ChargeTypeID, p.PaymentMethodID, r.IsRBS
		FROM #MonthDates m
		CROSS JOIN #Brands b
		CROSS JOIN #RBS r
		CROSS JOIN #PaymentMethod p
		WHERE b.ChargeTypeID != 200
		AND b.ChargeTypeID != 255

		UNION ALL

		SELECT m.MonthDate, b.BrandID, CAST(0 AS MONEY) AS Earnings, CAST(0 AS MONEY) AS RedemptionValue, b.ChargeTypeID, b.ChargeTypeID AS PaymentMethodID, r.IsRBS
		FROM #MonthDates m
		CROSS JOIN #Brands b
		CROSS JOIN #RBS r
		WHERE b.ChargeTypeID IN (200,255)

	) a
	GROUP BY MonthDate, BrandID, ChargeTypeID, PaymentMethodID, IsRBS

	INSERT INTO #ArchiveBeforeLastValues(MonthDate, BrandID, Earnings, RedemptionValue, ChargeTypeID, PaymentMethodID, IsRBS)

	SELECT MonthDate, BrandID, SUM(Earnings) AS Earnings, SUM(RedemptionValue) AS RedemptionValue, ChargeTypeID, PaymentMethodID, IsRBS
	FROM
	(
		SELECT MonthDate, BrandID, Earnings, RedemptionValue, ChargeTypeID, PaymentMethodID, IsRBS
		FROM MI.EarnRedeemFinance_EarnRedeemByMonth_Archive
		WHERE ArchiveDate = @ArchiveBeforeLast

		UNION ALL

		SELECT m.MonthDate, b.BrandID, CAST(0 AS MONEY) AS Earnings, CAST(0 AS MONEY) AS RedemptionValue, b.ChargeTypeID, p.PaymentMethodID, r.IsRBS
		FROM #MonthDates m
		CROSS JOIN #Brands b
		CROSS JOIN #RBS r
		CROSS JOIN #PaymentMethod p
		WHERE b.ChargeTypeID != 200
		AND b.ChargeTypeID != 255

		UNION ALL

		SELECT m.MonthDate, b.BrandID, CAST(0 AS MONEY) AS Earnings, CAST(0 AS MONEY) AS RedemptionValue, b.ChargeTypeID, b.ChargeTypeID AS PaymentMethodID, r.IsRBS
		FROM #MonthDates m
		CROSS JOIN #Brands b
		CROSS JOIN #RBS r
		WHERE b.ChargeTypeID IN (200,255)
	) a
	GROUP BY MonthDate, BrandID, ChargeTypeID, PaymentMethodID, IsRBS

	INSERT INTO #ArchiveDifferences(MonthDate, BrandID, Earnings, RedemptionValue, ChargeTypeID, PaymentMethodID, IsRBS)
	SELECT a.MonthDate, a.BrandID, a.Earnings - b.Earnings, a.RedemptionValue - b.RedemptionValue, a.ChargeTypeID, a.PaymentMethodID, a.IsRBS
	FROM #ArchiveLastValues a
	INNER JOIN #ArchiveBeforeLastValues b ON a.MonthDate = b.MonthDate
		AND a.BrandID = b. BrandID
		AND a.ChargeTypeID = b.ChargeTypeID
		AND a.PaymentMethodID = b.PaymentMethodID
		AND a.IsRBS = b.IsRBS

	SELECT B.BrandListID 
		, B.BrandName AS Brand
		, a.PaymentMethodID
		, a.IsRBS
		, CAST(NULL AS DATE) AS MonthDate
		, CAST(1 AS BIT) AS IsPrevious
		, SUM(a.Earnings) AS Earnings
		, SUM(a.RedemptionValue) AS RedemptionValue
	FROM #ArchiveDifferences a
	INNER JOIN #Brands b ON a.BrandID = b.BrandID AND a.ChargeTypeID = b.ChargeTypeID
	WHERE a.MonthDate <= @MonthDate
	GROUP BY  B.BrandListID 
		, B.BrandName
		, a.PaymentMethodID
		, a.IsRBS

	UNION ALL

	SELECT B.BrandListID 
		, B.BrandName AS Brand
		, a.PaymentMethodID
		, a.IsRBS
		, a.MonthDate
		, CAST(0 AS BIT) AS IsPrevious
		, a.Earnings
		, a.RedemptionValue
	FROM #ArchiveDifferences a
	INNER JOIN #Brands b ON a.BrandID = b.BrandID AND a.ChargeTypeID = b.ChargeTypeID
	WHERE a.MonthDate > @MonthDate

	DROP TABLE #ArchiveBeforeLastValues
	DROP TABLE #ArchiveDifferences
	DROP TABLE #ArchiveLastValues
	DROP TABLE #Brands
	DROP TABLE #MonthDates
	DROP TABLE #PaymentMethod
	DROP TABLE #RBS

END