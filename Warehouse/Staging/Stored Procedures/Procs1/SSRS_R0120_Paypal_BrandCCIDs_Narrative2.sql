


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 15/04/2016
-- Description: Brand ConsumerCombinationID's with respective narrative.
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0120_Paypal_BrandCCIDs_Narrative2](
			@ShouldYouBrand varchar(3),
			@ID int
			)
						
			
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @A varchar(10)
SET		@A = @ShouldYouBrand

IF @A = 'yes'
BEGIN
UPDATE Relational.ConsumerCombination 
SET BrandID = (	SELECT BrandID
				FROM Staging.R_0120_Paypal_Temp_BrandID
				WHERE ID = @ID)
FROM Relational.ConsumerCombination cc
INNER JOIN Staging.R_0120_Paypal_Temp_CCIDs b 
	on cc.ConsumerCombinationID = b.ConsumerCombinationID
END

END
