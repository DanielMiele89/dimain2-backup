-- =============================================
-- Author:		JEA
-- Create date: 06/11/2014
-- Description:	Cashback Awards by type for the financial report
-- =============================================
CREATE PROCEDURE MI.EarnRedeemFinance_CashbackAwardsByType_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    CREATE TABLE #AwardsByType(ID INT PRIMARY KEY IDENTITY
		, AwardType VARCHAR(50) NOT NULL
		, TranMonthDate DATE NULL
		, IsPrevious BIT NOT NULL
		, Earnings MONEY NOT NULL)

	CREATE TABLE #AwardTypes(AwardType VARCHAR(50) PRIMARY KEY)

	CREATE TABLE #Dates(TranMonthDate DATE PRIMARY KEY)

	DECLARE @MinDate DATE, @MaxDate DATE

	DECLARE @MonthDate DATE

	IF MONTH(GETDATE()) < 6
	BEGIN
		SET @MonthDate = DATEFROMPARTS(YEAR(GETDATE()) -1,4,1) --if the report is run before June, the financial year dates from the previous May.
	END
	ELSE
	BEGIN
		SET @MonthDate = DATEFROMPARTS(YEAR(GETDATE()),4,1) --if the report is run in or after June, the financial year dates from the current May.
	END

	INSERT INTO #AwardsByType(AwardType, TranMonthDate, Earnings, IsPrevious)
	SELECT AwardType
		, CAST(NULL AS DATE) AS TranMonthDate
		, Earnings
		, CAST(1 AS BIT) AS IsPrevious
	FROM
	(

		SELECT AwardType, SUM(EarnAmount) AS Earnings
		FROM MI.EarnRedeemFinance_Earnings 
		WHERE brandid = 0 AND ChargeTypeID = 255 AND PaymentMethodID = 255
		AND TransactionDate <= @MonthDate
		GROUP BY AwardType

	) a
	ORDER BY TranMonthDate

	INSERT INTO #AwardsByType(AwardType, TranMonthDate, Earnings, IsPrevious)
	SELECT AwardType
		, DATEFROMPARTS(TranYear, TranMonth, 1) AS TranMonthDate
		, Earnings
		, CAST(0 AS BIT) AS IsPrevious
	FROM
	(

		SELECT AwardType, YEAR(TransactionDate) AS TranYear, MONTH(TransactionDate) AS TranMonth, SUM(EarnAmount) AS Earnings
		FROM MI.EarnRedeemFinance_Earnings 
		WHERE brandid = 0 AND ChargeTypeID = 255 AND PaymentMethodID = 255
		AND TransactionDate > @MonthDate
		GROUP BY AwardType, YEAR(TransactionDate), MONTH(TransactionDate)

	) a
	ORDER BY TranMonthDate

	INSERT INTO #AwardTypes(AwardType)
	SELECT DISTINCT AwardType
	FROM #AwardsByType
	ORDER BY AwardType

	SELECT @MinDate = MIN(TranMonthDate) FROM #AwardsByType

	WHILE @MinDate < DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	BEGIN
		INSERT INTO #Dates(TranMonthDate)
		VALUES(@MinDate)

		SET @MinDate = DATEADD(MONTH, 1, @MinDate)
	END

	SELECT AwardType, TranMonthDate, IsPrevious, SUM(Earnings) AS Earnings
	FROM
	(
		SELECT AwardType, TranMonthDate, IsPrevious, Earnings
		FROM #AwardsByType

		UNION

		SELECT DISTINCT AwardType, CAST(NULL AS DATE) AS TranMonthDate, CAST(1 AS BIT) AS IsPrevious, CAST(0 AS MONEY) AS Earnings
		FROM #AwardsByType

		UNION

		SELECT a.AwardType, d.TranMonthDate, CAST(0 AS BIT) AS IsPrevious, CAST(0 AS MONEY) AS Earnings
		FROM #AwardTypes a
		CROSS JOIN #Dates d
	) a
	GROUP BY AwardType, TranMonthDate, IsPrevious
	ORDER BY IsPrevious DESC, TranMonthDate, AwardType

	DROP TABLE #AwardsByType
	DROP TABLE #AwardTypes
	DROP TABLE #Dates

END