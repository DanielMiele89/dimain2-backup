-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_ROCCumulativeGains_ETLInsightStore_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT Publisher
		, BrandID
		, Shopper_Segment
		, Decile
		, ProportionOfCardholders
		, ProportionOfSpenders
		, ProportionOfSpend
		, ProportionOfTrans
	FROM ExcelQuery.ROCEFT_ROCCumulativeGains

END
