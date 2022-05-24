CREATE PROC [Report].[RedemptionItemActuals_HistoricalDateRange]
(@NumberOfMonths AS INT = 24)
AS
;WITH CTE_Recursive_Date AS (
	SELECT	1 AS Number, 
			DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) -1, 0) AS StartOfMonth, 
			DATEADD(MM, DATEDIFF(MONTH, 0, GETDATE()), 0) AS EndOfMonth
	UNION ALL
	SELECT	Number + 1 AS Number, 
			DATEADD(MONTH, -1, StartOfMonth) AS StartOfMonth, 
			DATEADD(MONTH, DATEDIFF(MONTH, 0, EndOfMonth)-1, 0) AS EndOfMonth
	FROM CTE_Recursive_Date
	WHERE Number < @NumberOfMonths
)

SELECT StartOfMonth, EndOfMonth FROM CTE_Recursive_Date;
