-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Update Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Update_Lapsers]
(@PartnerGroupID AS INT, @PartnerID AS INT, @Months AS INT, @UpdatedDate AS DATE)
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE [Warehouse].[Stratification].[LapsersDefinition]
	SET PartnerGroupID=@PartnerGroupID, PartnerID=@PartnerID, Months=@Months, UpdatedDate=@UpdatedDate
	WHERE (PartnerID=@PartnerID OR PartnerGroupID=@PartnerGroupID)
	AND Months<>@Months
END
