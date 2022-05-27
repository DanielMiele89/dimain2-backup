-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	sets non-paypal combinations in the staging area
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_CombinationsMIDIHolding_Set_CJM]
		WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @PaypalCount INT


	--update non-high variance non-paypal combinations
	--update high variance non-paypal combinations
    UPDATE cth
		SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM Staging.CTLoad_MIDIHolding cth
	INNER JOIN Relational.ConsumerCombination c 
		ON cth.MID = c.MID
		AND cth.Narrative = c.Narrative
		AND cth.LocationCountry = c.LocationCountry
		AND cth.MCCID = c.MCCID
		AND cth.OriginatorID = c.OriginatorID
	WHERE cth.ConsumerCombinationID IS NULL
		AND c.IsHighVariance IN (0,1)
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal

	UPDATE cch
	SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM staging.creditcardload_midiholding cch
	INNER JOIN Relational.ConsumerCombination c 
		ON cch.MID = c.MID
		AND cch.Narrative = c.Narrative
		AND cch.LocationCountry = c.LocationCountry
		AND cch.MCCID = c.MCCID
		AND cch.OriginatorReference = c.OriginatorID
	WHERE cch.ConsumerCombinationID IS NULL
		AND c.IsHighVariance IN (0,1)
		AND c.PaymentGatewayStatusID != 1 -- not default Paypal






	--update paypal combinations
	UPDATE cth
		SET ConsumerCombinationID = p.ConsumerCombinationID
		, RequiresSecondaryID = 1
	FROM Staging.CTLoad_MIDIHolding cth
	INNER JOIN (
		SELECT ConsumerCombinationID, LocationCountry, MCCID, OriginatorID
		FROM Relational.ConsumerCombination
		WHERE PaymentGatewayStatusID = 1
	) P 
		ON cth.LocationCountry = P.LocationCountry 
		AND cth.MCCID = P.MCCID 
		AND cth.OriginatorID = P.OriginatorID
	WHERE cth.Narrative LIKE 'PAYPAL%'
		AND cth.ConsumerCombinationID IS NULL 

	UPDATE cch
		SET ConsumerCombinationID = p.ConsumerCombinationID
		, RequiresSecondaryID = 1
	FROM staging.creditcardload_midiholding cch
	INNER JOIN (
		SELECT ConsumerCombinationID, LocationCountry, MCCID, OriginatorID
		FROM Relational.ConsumerCombination
		WHERE PaymentGatewayStatusID = 1
	) P 
		ON cch.LocationCountry = P.LocationCountry 
		AND cch.MCCID = P.MCCID 
		AND cch.OriginatorReference = P.OriginatorID
	WHERE cch.Narrative LIKE 'PAYPAL%'
		AND cch.ConsumerCombinationID IS NULL 







	UPDATE cth
		SET SecondaryCombinationID = p.PaymentGatewayID
	FROM Staging.CTLoad_MIDIHolding cth
	INNER JOIN Relational.PaymentGatewaySecondaryDetail p 
		ON cth.ConsumerCombinationID = p.ConsumerCombinationID
		AND cth.MID = p.MID
		AND cth.Narrative = p.Narrative
	WHERE cth.SecondaryCombinationID IS NULL
		AND cth.RequiresSecondaryID = 1

	UPDATE cch
		SET SecondaryCombinationID = p.PaymentGatewayID
	FROM staging.creditcardload_midiholding cch
	INNER JOIN Relational.PaymentGatewaySecondaryDetail p 
		ON cch.ConsumerCombinationID = p.ConsumerCombinationID
		AND cch.MID = p.MID
		AND cch.Narrative = p.Narrative
	WHERE cch.SecondaryCombinationID IS NULL
		AND cch.RequiresSecondaryID = 1


	SELECT @PaypalCount = COUNT(1)
	FROM Staging.CTLoad_MIDIHolding
	WHERE RequiresSecondaryID = 1
	AND SecondaryCombinationID IS NULL

	IF @PaypalCount = 0
	BEGIN
		SELECT @PaypalCount = COUNT(1)
		FROM staging.creditcardload_midiholding
		WHERE RequiresSecondaryID = 1
		AND SecondaryCombinationID IS NULL
	END

	IF @PaypalCount > 0
	BEGIN

		--ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail DISABLE

		INSERT INTO Relational.PaymentGatewaySecondaryDetail (ConsumerCombinationID, MID, Narrative)
		SELECT ConsumerCombinationID, MID, Narrative
		FROM Staging.CTLoad_MIDIHolding
		WHERE RequiresSecondaryID = 1
			AND SecondaryCombinationID IS NULL

		UNION ALL

		SELECT ConsumerCombinationID, MID, Narrative
		FROM staging.creditcardload_midiholding
		WHERE RequiresSecondaryID = 1
			AND SecondaryCombinationID IS NULL

		--ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212 / 20201701 added fillfactor to index


		UPDATE cth
			SET SecondaryCombinationID = p.PaymentGatewayID
		FROM Staging.CTLoad_MIDIHolding cth
		INNER JOIN Relational.PaymentGatewaySecondaryDetail p 
			ON cth.ConsumerCombinationID = p.ConsumerCombinationID
			AND cth.MID = p.MID
			AND cth.Narrative = p.Narrative
		WHERE cth.SecondaryCombinationID IS NULL
			AND cth.RequiresSecondaryID = 1

		UPDATE cch
			SET SecondaryCombinationID = p.PaymentGatewayID
		FROM staging.creditcardload_midiholding cch
		INNER JOIN Relational.PaymentGatewaySecondaryDetail p 
			ON cch.ConsumerCombinationID = p.ConsumerCombinationID
			AND cch.MID = p.MID
			AND cch.Narrative = p.Narrative
		WHERE cch.SecondaryCombinationID IS NULL
			AND cch.RequiresSecondaryID = 1

	END

END


RETURN 0