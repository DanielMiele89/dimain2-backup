-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_ShopperSegmentSplit_ETLInsightStore_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT BrandID
		, Segment
		, Shopper_Segment
		, SegmentPercentage
	FROM ExcelQuery.ROCEFT_ShopperSegmentSplit

END
GO
GRANT EXECUTE
    ON OBJECT::[ExcelQuery].[ROCEFT_ShopperSegmentSplit_ETLInsightStore_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

