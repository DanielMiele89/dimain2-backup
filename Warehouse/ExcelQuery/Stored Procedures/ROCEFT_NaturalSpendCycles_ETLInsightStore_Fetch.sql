-- =============================================
-- Author:		JEA
-- Create date: 07/08/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_NaturalSpendCycles_ETLInsightStore_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT BrandID
		, CycleID
		, Seasonality_CycleID
		, Segment
		, SegmentSize
		, Promoted
		, Demoted
		, OnOffer
		, Sales
		, OnlineSales
		, Transactions
		, Spenders
		, DecayRate
		, PromotionRate
		, OnOfferRate
	FROM ExcelQuery.ROCEFT_NaturalSpendCycles

END

GO
GRANT EXECUTE
    ON OBJECT::[ExcelQuery].[ROCEFT_NaturalSpendCycles_ETLInsightStore_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

