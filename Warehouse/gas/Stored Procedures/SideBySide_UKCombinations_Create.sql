-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Creates new foreign combinations
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_UKCombinations_Create] 
	
AS
BEGIN

	SET NOCOUNT ON;

    INSERT INTO Relational.ConsumerCombination(BrandMIDID, BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, IsUKSpend, PaymentGatewayStatusID)
	SELECT DISTINCT B.BrandMiDID, B.BrandID, W.MID, B.Narrative, B.Country, W.MCCID, W.OriginatorID, B.IsHighVariance, 1, 0
	FROM Staging.ConsumerTransactionWorking w
	INNER JOIN Relational.BrandMID b ON w.BrandMIDID = b.BrandMIDID
	WHERE w.BrandCombinationID IS NULL

END