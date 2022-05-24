-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Insert Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Insert_CampaignKPIs]
(@PartnerID AS INT, @Year AS INT, @Strategic_WOWs AS INT, @Tactical_WOWs AS INT, @Avg_Offer_Rate AS FLOAT, @Overall_Blended_Rate AS FLOAT)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO [Warehouse].[Relational].[Partner_CampaignKPIs] 
	SELECT @PartnerID, @Year, @Strategic_WOWs, @Tactical_WOWs, @Avg_Offer_Rate, @Overall_Blended_Rate
	WHERE NOT EXISTS (SELECT 1 FROM [Warehouse].[Relational].[Partner_CampaignKPIs] 
				    WHERE PartnerID=@PartnerID AND Year=@Year)
END
