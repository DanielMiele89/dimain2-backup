-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Upload Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Fetch_PartnerGroup]
AS
BEGIN
	SET NOCOUNT ON;
	SELECT PartnerGroupID,	PartnerGroupName,	PartnerID,	CAST(UseForReport AS INT),	PartnerName
     FROM Warehouse.Relational.PartnerGroups
END
