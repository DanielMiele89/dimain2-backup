-- =============================================
-- Author:		Jason Shipp
-- Create date: 13/10/2017
-- Description:	Fetch extra Reward earnings, earned through EAYB Trade Up Redemptions, and group by month and item description
-- =============================================
CREATE PROCEDURE [MI].[EAYB_Earnings_By_Month_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT 
		DATEFROMPARTS(YEAR(adj.AddedDate), MONTH(adj.AddedDate),1) AS MonthDate
		, cat.Category
		, subcat.[Description]
		, SUM(adj.CashbackEarned) AS EAYB_Earnings
	FROM Relational.AdditionalCashbackAdjustment adj
	INNER JOIN Relational.AdditionalCashbackAdjustmentType subcat -- See the Warehouse.WHB.AdditionalCashbackAward_Adjustment_AmazonRedemptions stored procedure for setting up this dependency
		ON adj.AdditionalCashbackAdjustmentTypeID = subcat.AdditionalCashbackAdjustmentTypeID
	INNER JOIN Relational.AdditionalCashbackAdjustmentCategory cat
		ON subcat.AdditionalCashbackAdjustmentCategoryID = cat.AdditionalCashbackAdjustmentCategoryID
	WHERE 
		adj.AddedDate >= '2012-01-01'
		AND subcat.AdditionalCashbackAdjustmentCategoryID = 4 -- EAYB redemptions
	GROUP BY 
		DATEFROMPARTS(YEAR(adj.AddedDate), MONTH(adj.AddedDate),1)
		, cat.Category
		, subcat.[Description];

END