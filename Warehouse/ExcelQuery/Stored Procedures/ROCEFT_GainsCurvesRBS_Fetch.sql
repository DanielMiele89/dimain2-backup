-- =============================================
-- Author:		<Shaun H>
-- Create date: <19/06/2017>
-- Description:	<Tool Export - RBS Cumulative Gains Curve>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_GainsCurvesRBS_Fetch]
		(@BrandID int)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	Publisher
			,BrandID
			,Shopper_Segment
			,Decile
			,Gender
			,Age_Group_2
			,Social_Class
			,MarketableByEmail
			,DriveTimeBand
			,ProportionOfCardholders
			,ProportionOfSpenders
			,ProportionOfSpend
			,ProportionOfTrans
	FROM	Warehouse.ExcelQuery.ROCEFT_RBSCumulativeGains
	WHERE	BrandID = @BrandID
END