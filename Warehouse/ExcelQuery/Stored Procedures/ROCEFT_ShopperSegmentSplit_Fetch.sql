-- =============================================
-- Author:		<Shaun H>
-- Create date: <19/06/2017>
-- Description:	<Tool Export - Shopper Segment Proportions>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_ShopperSegmentSplit_Fetch]
		(@BrandID int)
AS
BEGIN
	SET NOCOUNT ON;

	--	Select Shopper Segment Splits for Each Brand
		SELECT	BrandID
				,Segment
				,Shopper_Segment
				,SegmentPercentage
		FROM Warehouse.ExcelQuery.ROCEFT_ShopperSegmentSplit
		WHERE BrandID = @BrandID
	UNION
		SELECT	BrandID
				,Publisher
				,ShopperSegment
				,PercentageSplit
		FROM Warehouse.ExcelQuery.ROCEFT_nFI_ShopperSegmentSplits
		WHERE BrandID = @BrandID
END
