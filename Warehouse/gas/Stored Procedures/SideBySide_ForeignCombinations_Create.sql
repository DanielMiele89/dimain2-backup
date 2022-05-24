-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Creates new foreign combinations
-- =============================================
CREATE PROCEDURE gas.SideBySide_ForeignCombinations_Create 
	
AS
BEGIN

	SET NOCOUNT ON;

    INSERT INTO Relational.ConsumerCombination(BrandMIDID, BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, IsUKSpend, PaymentGatewayStatusID)
	SELECT DISTINCT 147179, 944, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, 0, 0
	FROM Staging.ConsumerCombinationReview

END