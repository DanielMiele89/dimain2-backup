

CREATE PROCEDURE [MIDI].[__Setup_CC_Archived]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT 

EXEC Monitor.ProcessLogger @ProcessName = 'MIDI', @Activity = 'ConsumerTransactionHoldingLoad - Starting', @time = @time, @SSMS = NULL

--EXEC gas.CTLoad_MainTableLoad_Fetch
DECLARE @DayName VARCHAR(50) = UPPER(DATENAME(DW, GETDATE()))
SELECT CAST(CASE @DayName WHEN 'SATURDAY' THEN 1 WHEN 'SUNDAY' THEN 2 ELSE 0 END AS INT) AS MainTableLoadOrMIDI


--EXEC gas.CTLoad_ConsumerTransactionHolding_DisableIndexes

-- EXEC gas.CTLoad_CombinationsMIDIHolding_Set
--DECLARE @PaypalCount INT


--------------------------------------------------------------------------------------------------------------
-- CreditCardLoad_MIDIHolding


--update high and non-high variance non-paypal combinations
UPDATE cch
SET ConsumerCombinationID = c.ConsumerCombinationID
FROM MIDI.CreditCardLoad_MIDIHolding cch
INNER JOIN Trans.ConsumerCombination c 
	ON cch.MID = c.MID
	AND cch.Narrative = c.Narrative
	AND cch.LocationCountry = c.LocationCountry
	AND cch.MCCID = c.MCCID
	AND cch.OriginatorReference = c.OriginatorID
WHERE cch.ConsumerCombinationID IS NULL
	AND c.IsHighVariance IN (0,1)
	AND c.PaymentGatewayStatusID != 1 -- not default Paypal


--update paypal combinations
UPDATE cch
	SET ConsumerCombinationID = p.ConsumerCombinationID
	, RequiresSecondaryID = 1
FROM MIDI.creditcardload_midiholding cch
INNER JOIN (
	SELECT ConsumerCombinationID, LocationCountry, MCCID, OriginatorID
	FROM Trans.ConsumerCombination
	WHERE PaymentGatewayStatusID = 1
) P 
	ON cch.LocationCountry = P.LocationCountry 
	AND cch.MCCID = P.MCCID 
	AND cch.OriginatorReference = P.OriginatorID
WHERE cch.Narrative LIKE 'PAYPAL%'
	AND cch.ConsumerCombinationID IS NULL 


UPDATE cch
	SET SecondaryCombinationID = p.PaymentGatewayID
FROM MIDI.creditcardload_midiholding cch
INNER JOIN MIDI.PaymentGatewaySecondaryDetail p 
	ON cch.ConsumerCombinationID = p.ConsumerCombinationID
	AND cch.MID = p.MID
	AND cch.Narrative = p.Narrative
WHERE cch.SecondaryCombinationID IS NULL
	AND cch.RequiresSecondaryID = 1


INSERT INTO MIDI.PaymentGatewaySecondaryDetail (ConsumerCombinationID, MID, Narrative)
SELECT ConsumerCombinationID, MID, Narrative
FROM MIDI.creditcardload_midiholding
WHERE RequiresSecondaryID = 1
	AND SecondaryCombinationID IS NULL

UPDATE cch
	SET SecondaryCombinationID = p.PaymentGatewayID
FROM MIDI.creditcardload_midiholding cch
INNER JOIN MIDI.PaymentGatewaySecondaryDetail p 
	ON cch.ConsumerCombinationID = p.ConsumerCombinationID
	AND cch.MID = p.MID
	AND cch.Narrative = p.Narrative
WHERE cch.SecondaryCombinationID IS NULL
	AND cch.RequiresSecondaryID = 1


-- EXEC Staging.CreditCardLoad_MIDIHolding_Matched_Fetch -->> Relational.ConsumerTransactionCreditCardHolding
INSERT INTO MIDI.ConsumerTransaction_CreditCardHolding (
	FileID, RowNum, Amount, TranDate, ConsumerCombinationID, SecondaryCombinationID, LocationID, CINID, FanID, 
	IsOnline, 
	CardholderPresentData)
SELECT 
	FileID, RowNum, Amount, TranDate, ConsumerCombinationID, SecondaryCombinationID, LocationID, CINID, FanID, 
	IsOnline = CASE WHEN CardholderPresentMC = 5 THEN 1 ELSE 0 END, 
	CardholderPresentData = CardholderPresentMC
FROM MIDI.CreditCardLoad_MIDIHolding
WHERE ConsumerCombinationID IS NOT NULL


DELETE FROM MIDI.CreditCardLoad_MIDIHolding
	WHERE ConsumerCombinationID IS NOT NULL




RETURN 0 


