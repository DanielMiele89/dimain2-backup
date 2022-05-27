-- =============================================
-- Author:Suraj
-- Create date:27/04/2016
-- Description:Master Retailer File Update Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Update_ShopperSegment]
(@PartnerID AS SMALLINT, @SS_AcquireLength AS SMALLINT, @SS_LapsersDefinition AS SMALLINT, @SS_WelcomeEmail AS SMALLINT, @SS_Acq_Split AS DECIMAL(3,2))
AS
BEGIN
	SET NOCOUNT ON;

UPDATE Warehouse.Relational.MRF_ShopperSegmentDetails
SET	PartnerID = @PartnerID,
	SS_AcquireLength = @SS_AcquireLength,
	SS_LapsersDefinition = @SS_LapsersDefinition,
	SS_WelcomeEmail = @SS_WelcomeEmail,
	SS_Acq_Split = @SS_Acq_Split
WHERE	PartnerID = @PartnerID
	AND	(
		SS_AcquireLength <> @SS_AcquireLength
		OR SS_LapsersDefinition <> @SS_LapsersDefinition
		OR SS_WelcomeEmail <> @SS_WelcomeEmail
		OR SS_Acq_Split <> @SS_Acq_Split
		)

END
