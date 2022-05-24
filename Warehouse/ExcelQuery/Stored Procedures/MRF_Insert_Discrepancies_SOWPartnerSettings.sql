-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Insert Missing Data
-- =============================================

CREATE PROCEDURE [ExcelQuery].[MRF_Insert_Discrepancies_SOWPartnerSettings]
(@PartnerID INT, @Mth_MasterFile INT, @Loyalty_MasterFile INT, @CategorySpend_MasterFile MONEY, 
@Mth_CurrentSetting INT, @Loyalty_CurrentSetting INT, @CategorySpend_CurrentSetting MONEY)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO Warehouse.ExcelQuery.MRF_Discrepancies_SOWPartnerSettings
	SELECT @PartnerID, @Mth_MasterFile, @Loyalty_MasterFile, @CategorySpend_MasterFile, 
		  @Mth_CurrentSetting, @Loyalty_CurrentSetting, @CategorySpend_CurrentSetting
END