-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Update Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Update_CampaignKPIs_2]
	(
		@PartnerID AS INT
		,@Year AS INT
		,@Strategic_WOWs AS INT
		,@Tactical_WOWs AS INT
		,@Avg_Offer_Rate AS FLOAT
		,@Overall_Blended_Rate AS FLOAT
		,@Analysis_Start_Date AS VarChar(20)
	)
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE [Warehouse].[ExcelQuery].[TemporaryTest]
		SET		Strategic_WOWs=@Strategic_WOWs
			,	Tactical_WOWs=@Tactical_WOWs
			,	Avg_Offer_Rate=@Avg_Offer_Rate
			,	Overall_Blended_Rate=@Overall_Blended_Rate
			,	Analysis_Start_Date=@Analysis_Start_Date
	WHERE	PartnerID=@PartnerID 
		AND Year=@Year
END