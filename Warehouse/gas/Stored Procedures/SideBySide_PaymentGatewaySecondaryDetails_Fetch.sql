-- =============================================
-- Author:		JEA
-- Create date: 06/03/2014
-- Description:	Fetches new payment gateway information
-- =============================================
CREATE PROCEDURE gas.SideBySide_PaymentGatewaySecondaryDetails_Fetch

AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT DISTINCT BrandCombinationID, MID, Narrative
	FROM Staging.ConsumerTransactionPaypalSecondary
	WHERE SecondaryID IS NULL

END