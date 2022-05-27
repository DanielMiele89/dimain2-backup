-- =============================================
-- Author:		Beyers
-- Create date: 28/03/2017
-- Description:	ROC Engagement Forecast tool.  Excel Query link to get natural sales
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_Seasonality_Fetch(@BrandID INT)

AS
BEGIN
	SET NOCOUNT ON;

	SELECT		@BrandID as BrandID,
				'MyRewards' as Segment,
				Seasonality_Cycle,
				Spend_Index,
				Txns_Index,
				Spenders_Index
	FROM		Warehouse.ExcelQuery.ROCEFT_Seasonality 
	WHERE		BrandID = @BrandID


END
