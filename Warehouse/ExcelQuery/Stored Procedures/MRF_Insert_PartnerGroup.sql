-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Insert Missing Data
-- =============================================

CREATE PROCEDURE [ExcelQuery].[MRF_Insert_PartnerGroup]
(@PartnerGroupID INT, @PartnerGroupName VARCHAR(50), @PartnerID INT, @UseForReport BIT, @PartnerName VARCHAR(50))
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO [Warehouse].[Relational].[PartnerGroups] 
	SELECT @PartnerGroupID, @PartnerGroupName, @PartnerID, @UseForReport, @PartnerName
	WHERE NOT EXISTS (SELECT 1 FROM [Warehouse].[Relational].[PartnerGroups] 
	WHERE PartnerID=@PartnerID AND PartnerGroupID=@PartnerGroupID)
END