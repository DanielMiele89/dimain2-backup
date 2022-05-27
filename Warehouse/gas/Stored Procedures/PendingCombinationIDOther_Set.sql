-- =============================================
-- Author:		JEA
-- Create date: 17/02/2014
-- Description:	Sets the BrandCombinationID
-- for foreign and Paypal transactions
-- =============================================
CREATE PROCEDURE [gas].[PendingCombinationIDOther_Set] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    CREATE TABLE #ForeignCombos(BrandCombinationID INT PRIMARY KEY
		, MID VARCHAR(50) NOT NULL
		, Narrative VARCHAR(50) NOT NULL
		, MCCID SMALLINT NOT NULL
		, LocationCountry VARCHAR(3) NOT NULL
		, OriginatorID VARCHAR(11) NOT NULL
		, IsHighVariance BIT NOT NULL)

	INSERT INTO #ForeignCombos(BrandCombinationID, MID, Narrative, MCCID, LocationCountry, OriginatorID, IsHighVariance)
	SELECT ConsumerCombinationID 
		, MID
		, Narrative
		, MCCID
		, LocationCountry
		, OriginatorID
		, IsHighVariance
	FROM Relational.ConsumerCombination
	WHERE BrandMIDID = 147179

	UPDATE Staging.ConsumerTransactionPending
	SET BrandCombinationID = f.BrandCombinationID
	FROM Staging.ConsumerTransactionPending h
	INNER JOIN #ForeignCombos f
		ON h.MID = f.MID
		AND h.Narrative = f.Narrative
		AND h.MCCID = f.MCCID
		AND h.LocationCountry = f.LocationCountry
		AND h.OriginatorID = f.OriginatorID
	WHERE h.BrandMIDID = 147179
		AND f.IsHighVariance = 0
		AND h.BrandCombinationID IS NULL

	UPDATE Staging.ConsumerTransactionPending
	SET BrandCombinationID = f.BrandCombinationID
	FROM Staging.ConsumerTransactionPending h
	INNER JOIN #ForeignCombos f
		ON h.MID = f.MID
		AND h.Narrative LIKE f.Narrative
		AND h.MCCID = f.MCCID
		AND h.LocationCountry = f.LocationCountry
		AND h.OriginatorID = f.OriginatorID
	WHERE h.BrandMIDID = 147179
		AND f.IsHighVariance = 1
		AND h.BrandCombinationID IS NULL

	DROP TABLE #ForeignCombos

	CREATE TABLE #PaypalCombos(BrandCombinationID INT PRIMARY KEY
		, MID VARCHAR(50) NOT NULL
		, Narrative VARCHAR(50) NOT NULL
		, MCCID SMALLINT NOT NULL
		, LocationCountry VARCHAR(3) NOT NULL
		, OriginatorID VARCHAR(11) NOT NULL
		, IsHighVariance BIT NOT NULL
		, PaymentGatewayStatusID TINYINT NOT NULL)

	INSERT INTO #PaypalCombos(BrandCombinationID, MID, Narrative, MCCID, LocationCountry, OriginatorID, IsHighVariance, PaymentGatewayStatusID)
	SELECT ConsumerCombinationID 
		, MID
		, Narrative
		, MCCID
		, LocationCountry
		, OriginatorID
		, IsHighVariance
		, PaymentGatewayStatusID
	FROM Relational.ConsumerCombination
	WHERE BrandMIDID = 142652

	UPDATE Staging.ConsumerTransactionPending
	SET BrandCombinationID = f.BrandCombinationID
	FROM Staging.ConsumerTransactionPending h
	INNER JOIN #PaypalCombos f
		ON h.MID = f.MID
		AND h.Narrative = f.Narrative
		AND h.MCCID = f.MCCID
		AND h.LocationCountry = f.LocationCountry
		AND h.OriginatorID = f.OriginatorID
	WHERE h.BrandMIDID = 142652
		AND f.IsHighVariance = 0
		AND h.BrandCombinationID IS NULL
		AND f.PaymentGatewayStatusID = 2

	UPDATE Staging.ConsumerTransactionPending
	SET BrandCombinationID = f.BrandCombinationID
	FROM Staging.ConsumerTransactionPending h
	INNER JOIN #PaypalCombos f
		ON h.MID = f.MID
		AND h.Narrative LIKE f.Narrative
		AND h.MCCID = f.MCCID
		AND h.LocationCountry = f.LocationCountry
		AND h.OriginatorID = f.OriginatorID
	WHERE h.BrandMIDID = 142652
		AND f.IsHighVariance = 1
		AND h.BrandCombinationID IS NULL
		AND f.PaymentGatewayStatusID = 2

END
