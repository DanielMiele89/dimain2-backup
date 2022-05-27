-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Upload Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Fetch_Partner]
AS
BEGIN
	SET NOCOUNT ON;
	SELECT SequenceNumber,	PartnerID,	PartnerName,	BrandID,	BrandName
     FROM Warehouse.Relational.Partner
	ORDER BY 3
END
