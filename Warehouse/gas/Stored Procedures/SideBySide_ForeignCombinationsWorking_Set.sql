-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Clears combination working table
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_ForeignCombinationsWorking_Set] 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE Staging.ConsumerCombinationReview

	INSERT INTO Staging.ConsumerCombinationReview(BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance)
	SELECT DISTINCT 944, MID, Narrative, LocationCountry, MCCID, OriginatorID, 0
	FROM Staging.ConsumerTransactionWorking
	WHERE BrandCombinationID IS NULL

END
