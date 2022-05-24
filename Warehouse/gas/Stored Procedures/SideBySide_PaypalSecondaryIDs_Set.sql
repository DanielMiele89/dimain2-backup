-- =============================================
-- Author:		JEA
-- Create date: 06/03/2014
-- Description:	Assigns secondary IDs to Paypal transactions
-- =============================================
CREATE PROCEDURE gas.SideBySide_PaypalSecondaryIDs_Set
	
AS
BEGIN

	SET NOCOUNT ON;

    UPDATE Staging.ConsumerTransactionPaypalSecondary SET SecondaryID = p.PaymentGatewayID
	FROM Staging.ConsumerTransactionPaypalSecondary s
	INNER JOIN Relational.PaymentGatewaySecondaryDetail p ON s.BrandCombinationID = p.ConsumerCombinationID
		AND s.MID = p.MID
		AND s.Narrative = p.Narrative

END