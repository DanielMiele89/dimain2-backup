-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Sets Paypal combinations
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_PayPalCombos_Set] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    CREATE TABLE #PaypalCombos(BrandCombinationID INT PRIMARY KEY
		, MID VARCHAR(50) NOT NULL
		, Narrative VARCHAR(50) NOT NULL
		, MCCID SMALLINT NOT NULL
		, LocationCountry VARCHAR(3) NOT NULL
		, OriginatorID VARCHAR(11) NOT NULL
		, IsHighVariance BIT NOT NULL
		, RequiresSecondaryID BIT NOT NULL)

	INSERT INTO #PaypalCombos(BrandCombinationID, MID, Narrative, MCCID, LocationCountry, OriginatorID, IsHighVariance, RequiresSecondaryID)
	SELECT ConsumerCombinationID 
		, MID
		, Narrative
		, MCCID
		, LocationCountry
		, OriginatorID
		, IsHighVariance
		, CAST(CASE WHEN PaymentGatewayStatusID = 1 THEN 1 ELSE 0 END AS BIT)
	FROM Relational.ConsumerCombination
	WHERE BrandMIDID = 142652

	CREATE INDEX IX_TMP_ukCombos ON #PaypalCombos(MID, Narrative, MCCID, LocationCountry, OriginatorID, BrandCombinationID, IsHighVariance, RequiresSecondaryID)

	UPDATE Staging.ConsumerTransactionWorking
	SET BrandCombinationID = f.BrandCombinationID, RequiresSecondaryID = f.RequiresSecondaryID
	FROM Staging.ConsumerTransactionWorking h
	INNER JOIN #PaypalCombos f
		ON h.MID = f.MID
		AND h.Narrative = f.Narrative
		AND h.MCCID = f.MCCID
		AND h.LocationCountry = f.LocationCountry
		AND h.OriginatorID = f.OriginatorID
	WHERE f.IsHighVariance = 0
		AND h.BrandCombinationID IS NULL

	UPDATE Staging.ConsumerTransactionWorking
	SET BrandCombinationID = f.BrandCombinationID, RequiresSecondaryID = f.RequiresSecondaryID
	FROM Staging.ConsumerTransactionWorking h
	INNER JOIN #PaypalCombos f
		ON h.MID = f.MID
		AND h.Narrative LIKE f.Narrative
		AND h.MCCID = f.MCCID
		AND h.LocationCountry = f.LocationCountry
		AND h.OriginatorID = f.OriginatorID
	WHERE f.IsHighVariance = 1
		AND h.BrandCombinationID IS NULL

	UPDATE Staging.ConsumerTransactionWorking SET RequiresSecondaryID = 1 WHERE BrandCombinationID IS NULL

	DROP TABLE #PaypalCombos

END