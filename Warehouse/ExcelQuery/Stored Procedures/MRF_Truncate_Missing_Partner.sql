-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Truncate Missing Data
-- =============================================

CREATE PROCEDURE [ExcelQuery].[MRF_Truncate_Missing_Partner]
AS
BEGIN
	SET NOCOUNT ON;
	DELETE FROM  Warehouse.ExcelQuery.MRF_Missing_Partner	
END