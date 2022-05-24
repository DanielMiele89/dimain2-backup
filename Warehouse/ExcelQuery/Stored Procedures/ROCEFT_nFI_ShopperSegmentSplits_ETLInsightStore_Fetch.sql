-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_nFI_ShopperSegmentSplits_ETLInsightStore_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT BrandID
		, Publisher
		, ShopperSegment
		, PercentageSplit
	FROM ExcelQuery.ROCEFT_nFI_ShopperSegmentSplits

END
GO
GRANT EXECUTE
    ON OBJECT::[ExcelQuery].[ROCEFT_nFI_ShopperSegmentSplits_ETLInsightStore_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

