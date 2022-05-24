-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Update Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Update_PartnerGroup]
(@PartnerGroupID INT, @PartnerGroupName VARCHAR(50), @PartnerID INT, @UseForReport BIT, @PartnerName VARCHAR(50))
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE [Warehouse].[Relational].[PartnerGroups] 
	SET PartnerGroupName=@PartnerGroupName,  UseForReport=@UseForReport, PartnerName=@PartnerName
	WHERE PartnerID=@PartnerID AND PartnerGroupID=@PartnerGroupID
END
