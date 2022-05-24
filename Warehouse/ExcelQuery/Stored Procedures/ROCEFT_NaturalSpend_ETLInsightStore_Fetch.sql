-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_NaturalSpend_ETLInsightStore_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT CycleIDRef
		, BrandId
		, Segment
		, Shopper_Segment
		, Incentivised
		, Spend
		, Transactions
		, Spenders
		, Cardholders
		, RR
		, SPC
		, SPS
		, ATV
		, ATF
		, TPC
		, PercentageOnline							--  Added by BG 21/06/2017
	FROM ExcelQuery.ROCEFT_NaturalSpend

END
GO
GRANT EXECUTE
    ON OBJECT::[ExcelQuery].[ROCEFT_NaturalSpend_ETLInsightStore_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

