CREATE PROCEDURE [Reporting].[RedemptionItem_EAYB_Fetch_OLD]
AS
BEGIN

	SELECT
		act.TypeDescription
		, COUNT(1) AS TranCount
		, SUM(Earnings) AS Earnings
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0) MonthDate 
	FROM Dbo.Transactions t
	JOIN dbo.AdditionalCashbackAdjustmentType act
		ON t.AdditionalCashbackAdjustmentTypeID = act.AdditionalCashbackAdjustmentTypeID
	WHERE t.AdditionalCashbackAdjustmentCategoryID = 4
	GROUP BY act.TypeDescription
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0)
	
END


