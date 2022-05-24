-- =============================================
-- Author:		JEA
-- Create date: 06/03/2014
-- Description:	
-- =============================================
CREATE PROCEDURE gas.SideBySide_PaypalUnbrandableCombos_Create 
	
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO Relational.ConsumerCombination(BrandMIDID, BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, IsUKSpend, PaymentGatewayStatusID)
	SELECT DISTINCT 142652, 943, '%', 'PAYPAL%', LocationCountry, MCCID, OriginatorID, 1, CAST(CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END AS BIT), 1
	FROM Staging.ConsumerTransactionPaypalSecondary
	WHERE BrandCombinationID IS NULL

END