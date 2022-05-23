CREATE PROCEDURE [Reporting].[RedemptionItem_EAYB_Fetch]
AS
BEGIN

	SELECT
		es.SourceName
		, COUNT(1) AS TranCount
		, SUM(Earning) AS Earnings
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0) MonthDate 
	FROM Dbo.Transactions t
	JOIN dbo.EarningSource es
		ON t.EarningSourceID = es.EarningSourceID
	WHERE es.SourceTypeID in (22) -- Redemption Suppliers
	GROUP BY es.SourceName
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0)
	
END
