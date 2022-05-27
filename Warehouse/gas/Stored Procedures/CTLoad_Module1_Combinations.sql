/*
Tags Staging.CTLoad_MIDIHolding and CreditCardLoad_MIDIHolding and puts fully tagged rows into the holding tables. Rows which are not fully tagged continue through the cycle.

First 'Not Paypal' is tagged with ConsumerCombinationID.
Then 'Paypal' is tagged with ConsumerCombinationID and SecondaryCombinationID, including putting new SecondaryCombinations into PaymentGatewaySecondaryDetail.

New Locations are loaded into Relational.Location, CTLoad_MIDIHolding is tagged with LocationID.

Matched transactions are loaded from Staging.CTLoad_MIDIHolding into Relational.ConsumerTransactionHolding.
Matched transactions are loaded from Staging.CreditCardLoad_MIDIHolding into Relational.ConsumerTransaction_CreditcardHolding.

Matched transactions are deleted from Staging.CTLoad_MIDIHolding.
Matched transactions are deleted from Staging.CreditCardLoad_MIDIHolding.

*/
CREATE PROCEDURE [gas].[CTLoad_Module1_Combinations]

AS

SET NOCOUNT ON


-------------------------------------------------------------------------------------------------------------------
-- Set Combinations in MIDI holding area	gas.CTLoad_CombinationsMIDIHolding_Set		
-- Staging.CTLoad_MIDIHolding is populated by Distribute transactions	Data flow task in Module 2
-- staging.creditcardload_MIDIholding is populated by Distribute Transactions CC dataflow task in Module 1
-------------------------------------------------------------------------------------------------------------------
DECLARE @PaypalCount INT

--update non-high variance non-paypal combinations
--update high variance non-paypal combinations
UPDATE i SET ConsumerCombinationID = x.NewConsumerCombinationID
FROM Staging.CTLoad_MIDIHolding i
CROSS APPLY (
	SELECT TOP(1) NewConsumerCombinationID = CASE 
		WHEN i.Narrative = c.Narrative AND c.IsHighVariance = 0 THEN c.ConsumerCombinationID
		WHEN i.Narrative LIKE c.Narrative AND c.IsHighVariance = 1 THEN c.ConsumerCombinationID
		ELSE i.ConsumerCombinationID END	
	FROM Relational.ConsumerCombination c 
	WHERE c.PaymentGatewayStatusID != 1 -- not default Paypal
		AND i.MID = c.MID
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorID = c.OriginatorID
) x
WHERE i.ConsumerCombinationID IS NULL


--update non-high variance non-paypal combinations
--update high variance non-paypal combinations
UPDATE i SET ConsumerCombinationID = x.NewConsumerCombinationID
FROM staging.CreditCardLoad_MIDIHolding i
CROSS APPLY (
	SELECT TOP(1) NewConsumerCombinationID = CASE 
		WHEN i.Narrative = c.Narrative AND c.IsHighVariance = 0 THEN c.ConsumerCombinationID
		WHEN i.Narrative LIKE c.Narrative AND c.IsHighVariance = 1 THEN c.ConsumerCombinationID
		ELSE i.ConsumerCombinationID END
	FROM Relational.ConsumerCombination c 
		WHERE c.PaymentGatewayStatusID != 1 -- not default Paypal
		AND	i.MID = c.MID
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID
) x
WHERE i.ConsumerCombinationID IS NULL



--update paypal combinations
CREATE TABLE #PaypalCombos(ConsumerCombinationID INT PRIMARY KEY
	, LocationCountry VARCHAR(3) NOT NULL
	, MCCID SMALLINT NOT NULL
	, OriginatorID VARCHAR(11) NOT NULL)

INSERT INTO #PaypalCombos (ConsumerCombinationID, LocationCountry, MCCID, OriginatorID)
SELECT ConsumerCombinationID, LocationCountry, MCCID, OriginatorID
FROM Relational.ConsumerCombination
WHERE PaymentGatewayStatusID = 1

CREATE INDEX IX_TMP_PaypalConsCom ON #PaypalCombos (LocationCountry, MCCID, OriginatorID)


UPDATE m SET ConsumerCombinationID = p.ConsumerCombinationID
	, RequiresSecondaryID = 1
FROM Staging.CTLoad_MIDIHolding m
INNER JOIN #PaypalCombos P 
	ON M.LocationCountry = P.LocationCountry 
	AND M.MCCID = P.MCCID 
	AND M.OriginatorID = P.OriginatorID
WHERE M.Narrative LIKE 'PAYPAL%'
	AND M.ConsumerCombinationID IS NULL 

UPDATE m SET SecondaryCombinationID = p.PaymentGatewayID
FROM Staging.CTLoad_MIDIHolding m
INNER JOIN Relational.PaymentGatewaySecondaryDetail p 
	ON m.ConsumerCombinationID = p.ConsumerCombinationID
	AND m.MID = p.MID
	AND m.Narrative = p.Narrative
WHERE m.SecondaryCombinationID IS NULL
	AND m.RequiresSecondaryID = 1


UPDATE m SET ConsumerCombinationID = p.ConsumerCombinationID
	, RequiresSecondaryID = 1
FROM staging.creditcardload_midiholding M
INNER JOIN #PaypalCombos P 
	ON M.LocationCountry = P.LocationCountry 
	AND M.MCCID = P.MCCID 
	AND M.OriginatorReference = P.OriginatorID
WHERE M.Narrative LIKE 'PAYPAL%'
	AND M.ConsumerCombinationID IS NULL 

UPDATE m SET SecondaryCombinationID = p.PaymentGatewayID
FROM staging.creditcardload_midiholding m
INNER JOIN Relational.PaymentGatewaySecondaryDetail p 
	ON m.ConsumerCombinationID = p.ConsumerCombinationID
	AND m.MID = p.MID
	AND m.Narrative = p.Narrative
WHERE m.SecondaryCombinationID IS NULL
AND m.RequiresSecondaryID = 1



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

IF @PaypalCount > 0 BEGIN
	-- capture combos which have not yet been encountered

	ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail DISABLE

	INSERT INTO Relational.PaymentGatewaySecondaryDetail (ConsumerCombinationID, MID, Narrative) -- 28,719,654 rows
		
	SELECT ConsumerCombinationID, MID, Narrative
	FROM Staging.CTLoad_MIDIHolding
	WHERE RequiresSecondaryID = 1
	AND SecondaryCombinationID IS NULL

	UNION -- ###

	SELECT ConsumerCombinationID, MID, Narrative
	FROM staging.creditcardload_midiholding
	WHERE RequiresSecondaryID = 1
	AND SecondaryCombinationID IS NULL

	ALTER INDEX IX_Relational_PaymentGatewaySecondaryDetail ON Relational.PaymentGatewaySecondaryDetail REBUILD

	-- get these new combos into the two staging tables
	UPDATE m
	SET SecondaryCombinationID = p.PaymentGatewayID
	FROM Staging.CTLoad_MIDIHolding m
	INNER JOIN Relational.PaymentGatewaySecondaryDetail p ON m.ConsumerCombinationID = p.ConsumerCombinationID
		AND m.MID = p.MID
		AND m.Narrative = p.Narrative
	WHERE m.SecondaryCombinationID IS NULL
		AND m.RequiresSecondaryID = 1

	UPDATE m
	SET SecondaryCombinationID = p.PaymentGatewayID
	FROM staging.creditcardload_midiholding m
	INNER JOIN Relational.PaymentGatewaySecondaryDetail p ON m.ConsumerCombinationID = p.ConsumerCombinationID
		AND m.MID = p.MID
		AND m.Narrative = p.Narrative
	WHERE m.SecondaryCombinationID IS NULL
		AND m.RequiresSecondaryID = 1


END



-------------------------------------------------------------------------------------------------------------------
--Set Locations in MIDI holding area	gas.CTLoad_LocationIDsMIDIHolding_Set		
-------------------------------------------------------------------------------------------------------------------
--DISABLE INDEX PRIOR TO INSERT
ALTER INDEX IX_Relational_Location_Cover ON Relational.Location DISABLE

--INSERT NEW LOCATIONS
INSERT INTO Relational.Location (ConsumerCombinationID, LocationAddress, IsNonLocational)
SELECT DISTINCT ConsumerCombinationID, LocationAddress, 0
FROM Staging.CTLoad_MIDIHolding
WHERE ConsumerCombinationID IS NOT NULL
	AND LocationID IS NULL

--ENABLE INDEX FOLLOWING INSERT
ALTER INDEX IX_Relational_Location_Cover ON Relational.Location REBUILD


--SET NEW LOCATIONS
UPDATE i
SET LocationID = L.LocationID
FROM Staging.CTLoad_MIDIHolding i
INNER JOIN Relational.Location l 
	ON  i.ConsumerCombinationID = l.ConsumerCombinationID
	AND i.LocationAddress = l.LocationAddress
WHERE l.IsNonLocational = 0
AND i.LocationID IS NULL



-------------------------------------------------------------------------------------------------------------------
-- Load matched transactions	Data flow task	Staging.CTLoad_MIDIHolding	Relational.ConsumerTransactionHolding
-- using gas.CombinationsMIDIHolding_Fetch 
-------------------------------------------------------------------------------------------------------------------
INSERT INTO Relational.ConsumerTransactionHolding (
FileID, RowNum, BankID, 
	--MID, Narrative, LocationAddress, LocationCountry, 
	CardholderPresentData, TranDate
, CINID, Amount, IsOnline, IsRefund, 
--OriginatorID, MCCID, 
PostStatusID, LocationID
, ConsumerCombinationID, SecondaryCombinationID, InputModeID, PaymentTypeID
)
SELECT FileID, RowNum, BankID, 
	--MID, Narrative, LocationAddress, LocationCountry, 
	CardholderPresentData, TranDate
, CINID, Amount, IsOnline, IsRefund, 
--OriginatorID, MCCID, 
PostStatusID, LocationID
, ConsumerCombinationID, SecondaryCombinationID, InputModeID, PaymentTypeID
FROM Staging.CTLoad_MIDIHolding
WHERE ConsumerCombinationID IS NOT NULL
AND LocationID IS NOT NULL
 


-------------------------------------------------------------------------------------------------------------------
-- Load matched transactions CC	Data flow task	Staging.CTLoad_MIDIHolding	Relational.ConsumerTransaction_CreditcardHolding
-- using Staging.CreditCardLoad_MIDIHolding_Matched_Fetch 
-------------------------------------------------------------------------------------------------------------------
INSERT INTO Relational.ConsumerTransaction_CreditcardHolding (
	[FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [CardholderPresentData], [TranDate], [CINID], [Amount], [IsOnline], [LocationID], [FanID]
)
SELECT 
	FileID, 
	RowNum, 
	ConsumerCombinationID, 
	SecondaryCombinationID,
	CardholderPresentData = 0,
	TranDate, 
	CINID, 
	Amount, 
	IsOnline = 0, 
	LocationID, 
	FanID 
	--OriginatorReference, 
	--LocationCountry, 
	--MID, 
	--Narrative, 
	--CardholderPresentMC, 
	--RequiresSecondaryID, 
	--MCCID, 
	--PaymentTypeID, 
FROM Staging.CreditCardLoad_MIDIHolding
WHERE ConsumerCombinationID IS NOT NULL



-------------------------------------------------------------------------------------------------------------------
--Clear matched transactions from MIDI holding area	gas.CTLoad_MIDIHoldingCombinations_Clear		
-------------------------------------------------------------------------------------------------------------------
DELETE FROM Staging.CTLoad_MIDIHolding
WHERE ConsumerCombinationID IS NOT NULL
AND LocationID IS NOT NULL

DELETE FROM Staging.CreditCardLoad_MIDIHolding -- MyRewards
WHERE ConsumerCombinationID IS NOT NULL



RETURN 0