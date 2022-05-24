-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Upload Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Fetch_SOWPartnerSettings]
AS
BEGIN
	SET NOCOUNT ON;
	SELECT * FROM Warehouse.Staging.ShareOfWallet_PartnerSettings
END