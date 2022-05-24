

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
SET [MIDI].[CreditCardLoad_MIDIHolding].[ConsumerCombinationID] = c.ConsumerCombinationID
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
	SET [MIDI].[creditcardload_midiholding].[ConsumerCombinationID] = p.ConsumerCombinationID
	, [MIDI].[creditcardload_midiholding].[RequiresSecondaryID] = 1
FROM MIDI.creditcardload_midiholding cch
INNER JOIN (
	SELECT [Trans].[ConsumerCombination].[ConsumerCombinationID], [Trans].[ConsumerCombination].[LocationCountry], [Trans].[ConsumerCombination].[MCCID], [Trans].[ConsumerCombination].[OriginatorID]
	FROM Trans.ConsumerCombination
	WHERE [Trans].[ConsumerCombination].[PaymentGatewayStatusID] = 1
) P 
	ON cch.LocationCountry = P.LocationCountry 
	AND cch.MCCID = P.MCCID 
	AND cch.OriginatorReference = P.OriginatorID
WHERE cch.Narrative LIKE 'PAYPAL%'
	AND cch.ConsumerCombinationID IS NULL 


UPDATE cch
	SET [MIDI].[creditcardload_midiholding].[SecondaryCombinationID] = p.PaymentGatewayID
FROM MIDI.creditcardload_midiholding cch
INNER JOIN MIDI.PaymentGatewaySecondaryDetail p 
	ON cch.ConsumerCombinationID = p.ConsumerCombinationID
	AND cch.MID = p.MID
	AND cch.Narrative = p.Narrative
WHERE cch.SecondaryCombinationID IS NULL
	AND cch.RequiresSecondaryID = 1


INSERT INTO MIDI.PaymentGatewaySecondaryDetail ([MIDI].[PaymentGatewaySecondaryDetail].[ConsumerCombinationID], [MIDI].[PaymentGatewaySecondaryDetail].[MID], [MIDI].[PaymentGatewaySecondaryDetail].[Narrative])
SELECT [MIDI].[creditcardload_midiholding].[ConsumerCombinationID], [MIDI].[creditcardload_midiholding].[MID], [MIDI].[creditcardload_midiholding].[Narrative]
FROM MIDI.creditcardload_midiholding
WHERE [MIDI].[creditcardload_midiholding].[RequiresSecondaryID] = 1
	AND [MIDI].[creditcardload_midiholding].[SecondaryCombinationID] IS NULL

UPDATE cch
	SET [MIDI].[creditcardload_midiholding].[SecondaryCombinationID] = p.PaymentGatewayID
FROM MIDI.creditcardload_midiholding cch
INNER JOIN MIDI.PaymentGatewaySecondaryDetail p 
	ON cch.ConsumerCombinationID = p.ConsumerCombinationID
	AND cch.MID = p.MID
	AND cch.Narrative = p.Narrative
WHERE cch.SecondaryCombinationID IS NULL
	AND cch.RequiresSecondaryID = 1


-- EXEC Staging.CreditCardLoad_MIDIHolding_Matched_Fetch -->> Relational.ConsumerTransactionCreditCardHolding
INSERT INTO MIDI.ConsumerTransaction_CreditCardHolding (
	[MIDI].[ConsumerTransaction_CreditCardHolding].[FileID], [MIDI].[ConsumerTransaction_CreditCardHolding].[RowNum], [MIDI].[ConsumerTransaction_CreditCardHolding].[Amount], [MIDI].[ConsumerTransaction_CreditCardHolding].[TranDate], [MIDI].[ConsumerTransaction_CreditCardHolding].[ConsumerCombinationID], [MIDI].[ConsumerTransaction_CreditCardHolding].[SecondaryCombinationID], [MIDI].[ConsumerTransaction_CreditCardHolding].[LocationID], [MIDI].[ConsumerTransaction_CreditCardHolding].[CINID], [MIDI].[ConsumerTransaction_CreditCardHolding].[FanID], 
	[MIDI].[ConsumerTransaction_CreditCardHolding].[IsOnline], 
	[MIDI].[ConsumerTransaction_CreditCardHolding].[CardholderPresentData])
SELECT 
	[MIDI].[CreditCardLoad_MIDIHolding].[FileID], [MIDI].[CreditCardLoad_MIDIHolding].[RowNum], [MIDI].[CreditCardLoad_MIDIHolding].[Amount], [MIDI].[CreditCardLoad_MIDIHolding].[TranDate], [MIDI].[CreditCardLoad_MIDIHolding].[ConsumerCombinationID], [MIDI].[CreditCardLoad_MIDIHolding].[SecondaryCombinationID], [MIDI].[CreditCardLoad_MIDIHolding].[LocationID], [MIDI].[CreditCardLoad_MIDIHolding].[CINID], [MIDI].[CreditCardLoad_MIDIHolding].[FanID], 
	IsOnline = CASE WHEN [MIDI].[CreditCardLoad_MIDIHolding].[CardholderPresentMC] = 5 THEN 1 ELSE 0 END, 
	CardholderPresentData = [MIDI].[CreditCardLoad_MIDIHolding].[CardholderPresentMC]
FROM MIDI.CreditCardLoad_MIDIHolding
WHERE [MIDI].[CreditCardLoad_MIDIHolding].[ConsumerCombinationID] IS NOT NULL


DELETE FROM MIDI.CreditCardLoad_MIDIHolding
	WHERE [MIDI].[CreditCardLoad_MIDIHolding].[ConsumerCombinationID] IS NOT NULL




RETURN 0 


