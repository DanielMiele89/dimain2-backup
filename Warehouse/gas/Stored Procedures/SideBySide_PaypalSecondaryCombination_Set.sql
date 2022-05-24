-- =============================================
-- Author:		JEA
-- Create date: 06/03/2014
-- Description:	Sets combinationIDs on Staging.ConsumerTransactionPaypalSecondary
-- =============================================
CREATE PROCEDURE gas.SideBySide_PaypalSecondaryCombination_Set

AS
BEGIN
	
	SET NOCOUNT ON;

	CREATE TABLE #PaypalCombos(ConsumerCombinationID INT PRIMARY KEY, LocationCountry VARCHAR(3) NOT NULL, MCCID SMALLINT NOT NULL, OriginatorID VARCHAR(11) NOT NULL)

	INSERT INTO #PaypalCombos(ConsumerCombinationID, LocationCountry, MCCID, OriginatorID)
	SELECT ConsumerCombinationID, LocationCountry, MCCID, OriginatorID
	FROM Relational.ConsumerCombination
	WHERE PaymentGatewayStatusID = 1 -- paypal generic

	CREATE NONCLUSTERED INDEX IX_TMP_PayPalCombos ON #PaypalCombos(LocationCountry, MCCID, OriginatorID)

	UPDATE Staging.ConsumerTransactionPaypalSecondary
	SET BrandCombinationID = c.ConsumerCombinationID
	FROM Staging.ConsumerTransactionPaypalSecondary s
	INNER JOIN #PaypalCombos c ON s.LocationCountry = c.LocationCountry
		AND s.MCCID = c.MCCID
		AND s.OriginatorID = c.OriginatorID
	
	DROP TABLE #PaypalCombos

END