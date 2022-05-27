-- =============================================
-- Author:		JEA
-- Create date: 17/03/2014
-- Description:	Returns daily stats for all Reward's schemes
-- (currently CB+ & Quidco)
-- =============================================
CREATE PROCEDURE [MI].[SchemeStats_Daily_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT 'Spend' AS FigureType
		, 'All' AS SchemeName
		, 1 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, Spend
		FROM MI.SchemeStats_Daily_TranDate
	) S
	PIVOT
	(
		SUM(Spend)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

	UNION

	SELECT 'Earnings' AS FigureType
		, 'All' AS SchemeName
		, 2 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, Earnings
		FROM MI.SchemeStats_Daily_TranDate
	) S
	PIVOT
	(
		SUM(Earnings)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

	UNION

	SELECT 'Transactions' AS FigureType
		, 'All' AS SchemeName
		, 3 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, TransactionCount
		FROM MI.SchemeStats_Daily_TranDate
	) S
	PIVOT
	(
		SUM(TransactionCount)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

		UNION

	SELECT 'Customers' AS FigureType
		, 'All' AS SchemeName
		, 4 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, CustomerCount
		FROM MI.SchemeStats_Daily_TranDate
	) S
	PIVOT
	(
		SUM(CustomerCount)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

	UNION

	SELECT 'Spend' AS FigureType
		, 'CashbackPlus' AS SchemeName
		, 1 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, Spend
		FROM MI.SchemeStats_Daily_TranDate
		WHERE SchemeName = 'CashbackPlus'
	) S
	PIVOT
	(
		SUM(Spend)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

	UNION

	SELECT 'Earnings' AS FigureType
		, 'CashbackPlus' AS SchemeName
		, 2 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, Earnings
		FROM MI.SchemeStats_Daily_TranDate
		WHERE SchemeName = 'CashbackPlus'
	) S
	PIVOT
	(
		SUM(Earnings)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

	UNION

	SELECT 'Transactions' AS FigureType
		, 'CashbackPlus' AS SchemeName
		, 3 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, TransactionCount
		FROM MI.SchemeStats_Daily_TranDate
		WHERE SchemeName = 'CashbackPlus'
	) S
	PIVOT
	(
		SUM(TransactionCount)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

		UNION

	SELECT 'Customers' AS FigureType
		, 'CashbackPlus' AS SchemeName
		, 4 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, CustomerCount
		FROM MI.SchemeStats_Daily_TranDate
		WHERE SchemeName = 'CashbackPlus'
	) S
	PIVOT
	(
		SUM(CustomerCount)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

	UNION

	SELECT 'Spend' AS FigureType
		, 'Quidco' AS SchemeName
		, 1 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, Spend
		FROM MI.SchemeStats_Daily_TranDate
		WHERE SchemeName = 'Quidco'
	) S
	PIVOT
	(
		SUM(Spend)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

	UNION

	SELECT 'Earnings' AS FigureType
		, 'Quidco' AS SchemeName
		, 2 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, Earnings
		FROM MI.SchemeStats_Daily_TranDate
		WHERE SchemeName = 'Quidco'
	) S
	PIVOT
	(
		SUM(Earnings)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

	UNION

	SELECT 'Transactions' AS FigureType
		, 'Quidco' AS SchemeName
		, 3 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, TransactionCount
		FROM MI.SchemeStats_Daily_TranDate
		WHERE SchemeName = 'Quidco'
	) S
	PIVOT
	(
		SUM(TransactionCount)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

		UNION

	SELECT 'Customers' AS FigureType
		, 'Quidco' AS SchemeName
		, 4 AS Sorter
		, CAST([1] AS DECIMAL(15,2)) AS LatestDate
		, CAST([2] AS DECIMAL(15,2)) AS LatestWeek
		, CAST([3] AS DECIMAL(15,2)) AS LatestMonth
		, CAST([4] AS DECIMAL(15,2)) AS PrevDate
		, CAST([5] AS DECIMAL(15,2)) AS PrevWeek
		, CAST([6] AS DECIMAL(15,2)) AS PrevMonth
		, CAST([7] AS DECIMAL(15,2)) AS YearDate
		, CAST([8] AS DECIMAL(15,2)) AS YearWeek
		, CAST([9] AS DECIMAL(15,2)) AS YearMonth
		
	FROM
	(
		SELECT DateID, CustomerCount
		FROM MI.SchemeStats_Daily_TranDate
		WHERE SchemeName = 'Quidco'
	) S
	PIVOT
	(
		SUM(CustomerCount)
		FOR DateID IN ([1], [2], [3], [4], [5], [6], [7], [8], [9])
	) P

	ORDER BY Sorter

END
