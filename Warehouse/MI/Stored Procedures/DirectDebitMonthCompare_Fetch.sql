-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[DirectDebitMonthCompare_Fetch] 
	
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	SET NOCOUNT ON;

    DECLARE @CurrentMonthStart DATE
		, @CurrentMonthEnd DATE
		, @PrevMonthStart DATE
		, @PrevMonthEnd DATE
		, @YearMonthStart DATE
		, @YearMonthEnd DATE
		, @CurrentMonthCustomers FLOAT
		, @PrevMonthCustomers FLOAT
		, @YearMonthCustomers FLOAT

		SET @CurrentMonthStart = DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))
		SET @CurrentMonthEnd = EOMONTH(@CurrentMonthStart)
		SET @PrevMonthStart = DATEADD(MONTH, -1, @CurrentMonthStart)
		SET @PrevMonthEnd = EOMONTH(@PrevMonthStart)
		SET @YearMonthStart = DATEADD(YEAR, -1, @CurrentMonthStart)
		SET @YearMonthEnd = EOMONTH(@YearMonthStart)

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
			, @CurrentMonthStart AS CurrentMonthDate
			, ISNULL(b.Spend,0) AS CurrentMonthSpend
			, ISNULL(b.Cashback,0) AS CurrentMonthCashback
			, ISNULL(b.CustomerCount,0) AS CurrentMonthCustomers
			, @PrevMonthStart AS PrevMonthDate
			, ISNULL(c.Spend,0) AS PrevMonthSpend
			, ISNULL(c.Cashback,0) AS PrevMonthCashback
			, ISNULL(c.CustomerCount,0) AS PrevMonthCustomers
			, @YearMonthStart AS YearMonthDate
			, ISNULL(d.Spend,0) AS YearMonthSpend
			, ISNULL(d.Cashback,0) AS YearMonthCashback
			, ISNULL(d.CustomerCount,0) AS YearMonthCustomers
		FROM
		(
			SELECT DISTINCT Category2 AS Category
			FROM Relational.DirectDebitOriginator
		) a
		
		LEFT OUTER JOIN

		(
			SELECT d.Category2 AS Category, @CurrentMonthStart AS DDMonth, SUM(a.Amount) AS Spend, SUM(a.CashbackEarned) AS Cashback, @CurrentMonthCustomers AS CustomerCount
			FROM Relational.AdditionalCashbackAward a WITH (NOLOCK)
			INNER JOIN Relational.DirectDebitOriginator d ON a.DirectDebitOriginatorID = d.ID
			WHERE TranDate BETWEEN @CurrentMonthStart AND @CurrentMonthEnd
			GROUP BY d.Category2
		) b ON a.Category = b.Category

		LEFT OUTER JOIN

		(
			SELECT d.Category2 AS Category, @PrevMonthStart AS DDMonth, SUM(a.Amount) AS Spend, SUM(a.CashbackEarned) AS Cashback, @PrevMonthCustomers AS CustomerCount
			FROM Relational.AdditionalCashbackAward a WITH (NOLOCK)
			INNER JOIN Relational.DirectDebitOriginator d ON a.DirectDebitOriginatorID = d.ID
			WHERE TranDate BETWEEN @PrevMonthStart AND @PrevMonthEnd
			GROUP BY d.Category2
		) c ON a.Category = c.Category

		LEFT OUTER JOIN

		(
			SELECT d.Category2 AS Category, @YearMonthStart AS DDMonth, SUM(a.Amount) AS Spend, SUM(a.CashbackEarned) AS Cashback, @YearMonthCustomers AS CustomerCount
			FROM Relational.AdditionalCashbackAward a WITH (NOLOCK)
			INNER JOIN Relational.DirectDebitOriginator d ON a.DirectDebitOriginatorID = d.ID
			WHERE TranDate BETWEEN @YearMonthStart AND @YearMonthEnd
			GROUP BY d.Category2
		) d ON a.Category = d.Category

END