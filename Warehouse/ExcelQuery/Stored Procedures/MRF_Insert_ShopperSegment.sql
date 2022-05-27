
-- =============================================
-- Author:Suraj
-- Create date:27/04/2016
-- Description:Master Retailer File Insert Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Insert_ShopperSegment]
(@PartnerID AS SMALLINT, @SS_AcquireLength AS SMALLINT, @SS_LapsersDefinition AS SMALLINT, @SS_WelcomeEmail AS SMALLINT, @SS_Acq_Split AS DECIMAL(3,2))
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO Warehouse.Relational.MRF_ShopperSegmentDetails
	SELECT	@PartnerID,
		@SS_AcquireLength,
		@SS_LapsersDefinition, 
		@SS_WelcomeEmail,
		@SS_Acq_Split
	WHERE NOT EXISTS (SELECT 1 FROM Warehouse.Relational.MRF_ShopperSegmentDetails
				WHERE PartnerID=@PartnerID)
END

