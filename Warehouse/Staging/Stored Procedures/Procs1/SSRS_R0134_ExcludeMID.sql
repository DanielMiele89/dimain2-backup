


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 17/10/2016
-- Description: Exclude MID from report.
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0134_ExcludeMID](
				@MID VARCHAR(50))
						
			
AS

	SET NOCOUNT ON;

DECLARE			@MerchantID VARCHAR(50)
SET				@MerchantID = @MID

/***************************************************************************
*********** Exclude a MID from the report so no longer shows ***************
***************************************************************************/
INSERT INTO Warehouse.Staging.R_0134_MIDs_tobeExcluded
SELECT			@MerchantID AS MID
