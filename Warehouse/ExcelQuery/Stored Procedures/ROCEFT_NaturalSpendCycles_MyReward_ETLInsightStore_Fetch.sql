-- =============================================
-- Author:		JEA
-- Create date: 03/05/2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_NaturalSpendCycles_MyReward_ETLInsightStore_Fetch]
	
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
		, OnlineTransactions
		, Spenders
		, OnlineSpenders
		, DecayRate
		, PromotionRate
		, OnOfferRate
	FROM ExcelQuery.ROCEFT_NaturalSpendCycles_MyReward

END
