-- =============================================
-- Author:		Beyers
-- Create date: 28/03/2017
-- Description:	ROC Engagement Forecast tool.  Excel Query link to get natural sales
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_NaturalSales_Fetch](@BrandID INT)

AS
BEGIN
	SET NOCOUNT ON;


	SELECT		*
	FROM 
	(SELECT		@BrandID as BrandID,
				CycleStart,
				Segment,
				Shopper_Segment,
				SPC/Spend_Index SPC_D,
				TPC/Txns_Index TPC_D,
				RR/Spenders_Index RR_D, 
				PercentageOnline
	FROM		Warehouse.ExcelQuery.ROCEFT_NaturalSpend a
	INNER JOIN	Warehouse.ExcelQuery.ROCEFT_Seasonality b on a.brandID = b.BrandID
	INNER JOIN	Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended c on a.cycleIDRef = c.ID and b.Seasonality_Cycle =  c.Seasonality_CycleID
	WHERE		a.BrandID = @BrandID
	UNION ALL
	SELECT		@BrandID as BrandID,
				CycleStart,
				Segment,
				'Universal' as Shopper_Segment,
				Sum(Spend)/Sum(Cardholders)/avg(Spend_Index),
				Sum(Transactions)*1.0/sum(Cardholders)/avg(Txns_Index),
				Sum(Spenders)*1.0/sum(Cardholders)/avg(Spenders_Index),
				Sum(Spend*PercentageOnline)/sum(Spend)
	FROM		Warehouse.ExcelQuery.ROCEFT_NaturalSpend a
	INNER JOIN	Warehouse.ExcelQuery.ROCEFT_Seasonality b on a.brandID = b.BrandID
	INNER JOIN	Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended c on a.cycleIDRef = c.ID and b.Seasonality_Cycle =  c.Seasonality_CycleID
	WHERE		a.BrandID = @BrandID
	GROUP BY	CycleStart, Segment) x
	ORDER BY	Segment, Shopper_Segment


END