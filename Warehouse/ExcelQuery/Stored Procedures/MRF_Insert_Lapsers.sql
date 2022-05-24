-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Insert Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Insert_Lapsers]
(@PartnerGroupID AS INT, @PartnerID AS INT, @Months AS INT, @UpdateDate AS DATE)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO [Warehouse].[Stratification].[LapsersDefinition]
	SELECT @PartnerGroupID, @PartnerID, @Months, @UpdateDate
	WHERE NOT EXISTS (SELECT 1 FROM [Warehouse].[Stratification].[LapsersDefinition]
	WHERE PartnerID=@PartnerID OR PartnerGroupID=@PartnerGroupID)
END
