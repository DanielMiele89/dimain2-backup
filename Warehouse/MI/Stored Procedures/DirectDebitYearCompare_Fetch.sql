-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[DirectDebitYearCompare_Fetch] 
	
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SET NOCOUNT ON;

    DECLARE @CurrentYearStart DATE
		, @CurrentMonthEnd DATE
		, @PrevYearStart DATE
		, @PrevMonthEnd DATE
		, @YearMonthEnd DATE
		, @CurrentMonthCustomers FLOAT
		, @PrevMonthCustomers FLOAT
		, @YearMonthCustomers FLOAT

		, @ThisMonthStart DATE
		, @CurrentMonthDate DATE
		, @PrevMonthDate DATE
		, @YearMonthDate DATE

		SET @ThisMonthStart = DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
		SET @CurrentMonthEnd = DATEADD(DAY,-1,@ThisMonthStart)
		SET @CurrentYearStart = DATEFROMPARTS(YEAR(@CurrentMonthEnd),1,1)
		SET @PrevYearStart = DATEADD(YEAR, -1, @CurrentYearStart)
		SET @PrevMonthEnd = EOMONTH(DATEADD(MONTH, -2, @ThisMonthStart))
		SET @YearMonthEnd = DATEADD(DAY, -1, DATEADD(YEAR, -1, @ThisMonthStart))

		SET @CurrentMonthDate = DATEADD(MONTH, -1, @ThisMonthStart)
		SET @PrevMonthDate = DATEADD(MONTH, -1, @CurrentMonthDate)
		SET @YearMonthDate = DATEADD(YEAR, -1, @CurrentMonthDate)

		SET @CurrentMonthCustomers = (SELECT COUNT(*)
			FROM Relational.Customer c 
			INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID
			INNER JOIN Relational.Customer_SchemeMembership sc on c.FanID = sc.FanID
			WHERE sc.StartDate <= @CurrentMonthEnd
			AND (sc.EndDate IS NULL OR sc.EndDate > @CurrentMonthEnd)
			AND sc.SchemeMembershipTypeID IN (6,7))

		SET @PrevMonthCustomers = (SELECT COUNT(*)
			FROM Relational.Customer c 
			INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID
			INNER JOIN Relational.Customer_SchemeMembership sc on c.FanID = sc.FanID
			WHERE sc.StartDate <= @PrevMonthEnd
			AND (sc.EndDate IS NULL OR sc.EndDate > @PrevMonthEnd)
			AND sc.SchemeMembershipTypeID IN (6,7))

		SET @YearMonthCustomers = (SELECT COUNT(*)
			FROM Relational.Customer c 
			INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID
			INNER JOIN Relational.Customer_SchemeMembership sc on c.FanID = sc.FanID
			WHERE sc.StartDate <= @YearMonthEnd
			AND (sc.EndDate IS NULL OR sc.EndDate > @YearMonthEnd)
			AND sc.SchemeMembershipTypeID IN (6,7))

		SELECT a.Category
			, @CurrentMonthDate AS CurrentCurrentMonthDate
			, ISNULL(b.Spend,0) AS CurrentMonthSpendYTD
			, ISNULL(b.Cashback,0) AS CurrentMonthCashbackYTD
			, ISNULL(b.CustomerCount,0) AS CurrentMonthCustomers
			, @PrevMonthDate AS PrevMonthDate
			, ISNULL(c.Spend,0) AS PrevMonthSpendYTD
			, ISNULL(c.Cashback,0) AS PrevMonthCashbackYTD
			, ISNULL(c.CustomerCount,0) AS PrevMonthCustomers
			, @YearMonthDate AS YearMonthDate
			, ISNULL(d.Spend,0) AS YearMonthSpendYTD
			, ISNULL(d.Cashback,0) AS YearMonthCashbackYTD
			, ISNULL(d.CustomerCount,0) AS YearMonthCustomers
		FROM
		(
			SELECT DISTINCT Category2 AS Category
			FROM Relational.DirectDebitOriginator
		) a
		
		LEFT OUTER JOIN

		(
			SELECT d.Category2 AS Category, SUM(a.Amount) AS Spend, SUM(a.CashbackEarned) AS Cashback, @CurrentMonthCustomers AS CustomerCount
			FROM Relational.AdditionalCashbackAward a WITH (NOLOCK)
			INNER JOIN Relational.DirectDebitOriginator d ON a.DirectDebitOriginatorID = d.ID
			WHERE TranDate BETWEEN @CurrentYearStart AND @CurrentMonthEnd
			GROUP BY d.Category2
		) b ON a.Category = b.Category

		LEFT OUTER JOIN

		(
			SELECT d.Category2 AS Category, SUM(a.Amount) AS Spend, SUM(a.CashbackEarned) AS Cashback, @PrevMonthCustomers AS CustomerCount
			FROM Relational.AdditionalCashbackAward a WITH (NOLOCK)
			INNER JOIN Relational.DirectDebitOriginator d ON a.DirectDebitOriginatorID = d.ID
			WHERE TranDate BETWEEN @CurrentYearStart AND @PrevMonthEnd
			GROUP BY d.Category2
		) c ON a.Category = c.Category

		LEFT OUTER JOIN

		(
			SELECT d.Category2 AS Category, SUM(a.Amount) AS Spend, SUM(a.CashbackEarned) AS Cashback, @YearMonthCustomers AS CustomerCount
			FROM Relational.AdditionalCashbackAward a WITH (NOLOCK)
			INNER JOIN Relational.DirectDebitOriginator d ON a.DirectDebitOriginatorID = d.ID
			WHERE TranDate BETWEEN @PrevYearStart AND @YearMonthEnd
			GROUP BY d.Category2
		) d ON a.Category = d.Category

END