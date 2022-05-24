-- =============================================
-- Author:		<Shaun H>
-- Create date: <07/08/2017>
-- Description:	<Tool Export - NaturalSales>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_NaturalSalesCycles_MyReward_Fetch_TEST]
	(@BrandID Int)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT		*
	FROM		Warehouse.ExcelQuery.ROCEFT_TEST_NaturalSpendCycles_MyReward
	WHERE		BrandID = @BrandID
	ORDER BY	BrandID
				,CycleID
				,Segment

END