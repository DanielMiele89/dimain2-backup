-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Insert Missing Data
-- =============================================

CREATE PROCEDURE [ExcelQuery].[MRF_Insert_Missing_Partner]
(@PartnerName AS VARCHAR(100))
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO ExcelQuery.MRF_Missing_Partner
	SELECT @PartnerName
END
