-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_RBSCumulativeGains_ETLInsightStore_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT Publisher
		, BrandID
		, Shopper_Segment
		, Decile
		, Gender
		, Age_Group_2
		, Social_Class
		, MarketableByEmail
		, DriveTimeBand
		, ProportionOfCardholders
		, ProportionOfSpenders
		, ProportionOfSpend
		, ProportionOfTrans
	FROM ExcelQuery.ROCEFT_RBSCumulativeGains

END
