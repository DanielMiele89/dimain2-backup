-- =============================================
-- Author:		<Shaun H>
-- Create date: <19/06/2017>
-- Description:	<Tool Export - ROC Cumulative Gains Curve>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_GainsCurvesROC_Fetch]
		(@BrandID int)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	Publisher
			,BrandID
			,Shopper_Segment
			,Decile
			,ProportionOfCardholders
			,ProportionOfSpenders
			,ProportionOfSpend
			,ProportionOfTrans
	FROM	Warehouse.ExcelQuery.ROCEFT_ROCCumulativeGains
	WHERE	BrandID = @BrandID
END