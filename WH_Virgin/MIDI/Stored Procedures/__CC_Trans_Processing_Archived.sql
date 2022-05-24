CREATE PROCEDURE [MIDI].[__CC_Trans_Processing_Archived]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT 


-- Set CCFileID Variable	EXEC Staging.CreditCardLoad_MaxFileIDProcessed_Fetch
DECLARE @FileID INT
SELECT @FileID = MAX(FileID) FROM MIDI.CreditCardLoad_LastFileProcessed
SELECT @FileID = 23411 -- testing only


-- Load CreditCardLoad_InitialStage		EXEC AWSFile.CreditCardTransaction_Fetch 0 --> [Staging].[CreditCardLoad_InitialStage]
INSERT INTO [MIDI].[CreditCardLoad_InitialStage]
	(FileID, 
	RowNum, 
	OriginatorReference,
	LocationCountry,
	MID, 
	Narrative, 
	MCC, 
	Postcode, 
	CIN, 
	CardholderPresentMC, 
	Amount, 
	TranDateString, 
	TranDate, 
	FanID)
SELECT 
	FileID, 
	RowNum, 
	OriginatorReference = SUBSTRING(TransactionReferenceNumber,2,6),
	LocationCountry = LTRIM(RTRIM(SUBSTRING(MerchantDBACountry,1,2))),     
	MID = LTRIM(RTRIM(MerchantID)), 
	Narrative = REPLACE(LTRIM(RTRIM(MerchantDBAName)), '"', ''),
	MCC = MerchantSICClassCode, 
	Postcode = MerchantZip, 
	CIN = ISNULL(c.SourceUID, cth.CIN), 
	CardholderPresentMC = CASE WHEN CardholderPresentMC = '' THEN '9' ELSE CardholderPresentMC END, 
	Amount, 
	TranDateString = TranDate, 
	TranDate, 
	cth.FanID
FROM Archive_Light.dbo.CBP_Credit_TransactionHistory cth
LEFT JOIN Derived.Customer c 
	ON c.FanID = cth.FanID AND cth.CIN = ''
WHERE cth.IsValidTransaction = 1
	AND cth.FileID > @FileID --retrieve all transactions with fileid greater than the max already processed
	AND (cth.CIN != '' OR cth.FanID IS NOT NULL)
	AND cth.TranDate IS NOT NULL
-- (1028114 rows affected) / 00:00:50



-- Update Staging Fields CC		EXEC Staging.CreditCardLoad_ColumnValues_Set
INSERT INTO Derived.CINList(CIN)
SELECT DISTINCT i.CIN
FROM MIDI.CreditCardLoad_InitialStage i
WHERE NOT EXISTS (SELECT 1 FROM Derived.CINList c WHERE i.CIN = c.CIN)
-- (2 rows affected) / 00:00:01

UPDATE i SET CINID = c.CINID
FROM MIDI.CreditCardLoad_InitialStage i
INNER JOIN Derived.CINList c ON i.CIN = c.CIN
-- (1,028,114 rows affected) / 00:00:04


INSERT INTO Warehouse.Relational.CreditCardPostCode (LocationCountry, PostCode)
SELECT DISTINCT i.LocationCountry, i.PostCode
FROM MIDI.CreditCardLoad_InitialStage i
WHERE NOT EXISTS (SELECT 1 FROM Warehouse.Relational.CreditCardPostCode p 
	WHERE i.LocationCountry = p.LocationCountry AND i.PostCode = p.PostCode)
-- (0 rows affected) / 00:00:05

UPDATE i SET LocationID = p.LocationID
FROM MIDI.CreditCardLoad_InitialStage i
INNER JOIN Warehouse.Relational.CreditCardPostCode p 
	ON i.LocationCountry = p.LocationCountry and i.PostCode = p.PostCode
-- (1,028,114 rows affected) / 00:00:06


INSERT INTO Warehouse.Relational.MCCList (MCC, MCCGroup, MCCCategory, MCCDesc, SectorID)
SELECT DISTINCT MCC, '', '', '', 1
FROM MIDI.CreditCardLoad_InitialStage i
WHERE NOT EXISTS (SELECT 1 FROM Warehouse.Relational.MCCList m WHERE i.MCC = M.MCC)
-- 0 / 00:00:00

UPDATE i SET MCCID = m.MCCID
FROM MIDI.CreditCardLoad_InitialStage i
INNER JOIN Warehouse.Relational.MCCList m ON i.MCC = m.MCC
-- (1,028,114 rows affected) / 00:00:16




-- Set non-paypal combinations CC	EXEC Staging.CreditCardLoad_CombinationsNonPaypal_Set
UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
FROM MIDI.CreditCardLoad_InitialStage i
INNER JOIN Trans.ConsumerCombination c 
	ON i.MID = c.MID
	AND i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorReference = c.OriginatorID
	AND (c.IsHighVariance = 0 AND i.Narrative = c.Narrative)
WHERE c.PaymentGatewayStatusID <> 1 -- not default Paypal
-- (1028114 rows affected) / 00:00:16

UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID
FROM MIDI.CreditCardLoad_InitialStage i
INNER JOIN Trans.ConsumerCombination c 
	ON i.MID = c.MID
	AND i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorReference = c.OriginatorID
	AND (c.IsHighVariance = 1 AND i.Narrative LIKE c.Narrative)
WHERE c.PaymentGatewayStatusID <> 1 -- not default Paypal
	AND i.ConsumerCombinationID IS NULL
-- (51004 rows affected) / 00:00:05



-- Set Paypal Combinations CC	EXEC Staging.CreditCardLoad_CombinationsPaypal_Set
--DROP TABLE #PaypalCombosNonDefault
CREATE TABLE #PaypalCombosNonDefault (
	ConsumerCombinationID INT, 
	LocationCountry VARCHAR(3) NOT NULL
	, MCCID SMALLINT NOT NULL
	, OriginatorID VARCHAR(11) NOT NULL)
INSERT INTO #PaypalCombosNonDefault (ConsumerCombinationID, LocationCountry, MCCID, OriginatorID)
SELECT DISTINCT ConsumerCombinationID, LocationCountry, MCCID, OriginatorID
FROM Trans.ConsumerCombination
WHERE PaymentGatewayStatusID = 1

CREATE CLUSTERED INDEX IX_TMP_PaypalCombosNonDefault ON #PaypalCombosNonDefault (LocationCountry, MCCID, OriginatorID)
-- (25657 rows affected) / 00:00:01


CREATE TABLE #PaypalMIDNew(MID VARCHAR(50) PRIMARY KEY, TranCount INT NOT NULL)
INSERT INTO #PaypalMIDNew (MID, TranCount)
SELECT MID, COUNT(*)
FROM MIDI.CreditCardLoad_InitialStage -- ######################### corrected 
WHERE Narrative LIKE 'PAYPAL%'
	AND ConsumerCombinationID IS NULL
GROUP BY MID
HAVING COUNT(*) >= 10
-- (316 rows affected) / 00:00:01
	
INSERT INTO Trans.ConsumerCombination (BrandMIDID, BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, IsUKSpend, PaymentGatewayStatusID)
SELECT 142652, 943, '%', 'PAYPAL%', LocationCountry, MCCID, OriginatorReference, 1, CASE WHEN LocationCountry = 'GB' THEN 1 ELSE 0 END, 1
FROM MIDI.CreditCardLoad_InitialStage i
WHERE i.ConsumerCombinationID IS NULL
	AND i.Narrative LIKE 'PAYPAL%'
	AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE i.MID = pn.MID)
	AND NOT EXISTS (SELECT 1 FROM #PaypalCombosNonDefault c 
		WHERE  i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID)
-- (0 rows affected) / 00:00:01

UPDATE i
	SET ConsumerCombinationID = c.ConsumerCombinationID, RequiresSecondaryID = 1
FROM MIDI.CreditCardLoad_InitialStage i
INNER JOIN #PaypalCombosNonDefault c 
	ON  i.LocationCountry = c.LocationCountry
	AND i.MCCID = c.MCCID
	AND i.OriginatorReference = c.OriginatorID
WHERE i.ConsumerCombinationID IS NULL
	AND i.Narrative LIKE 'PAYPAL%'
	AND NOT EXISTS (SELECT 1 FROM #PaypalMIDNew pn WHERE i.MID = pn.MID)
-- (21,682 rows affected) / 00:00:02




-- Load Secondary IDs CC EXEC Staging.CreditCardLoad_PaypalSecondary_Fetch -> [Staging].[CTLoad_PaypalSecondaryID] REDUNDANT



-- Match Secondary IDs CC	EXEC Staging.CreditCardLoad_PaypalSecondaryIDs_Set

--insert new secondary combinations
INSERT INTO MIDI.PaymentGatewaySecondaryDetail (ConsumerCombinationID, MID, Narrative)
SELECT ConsumerCombinationID, MID, Narrative
FROM MIDI.CreditCardLoad_InitialStage s
WHERE s.RequiresSecondaryID = 1 
	AND NOT EXISTS (SELECT 1 FROM MIDI.PaymentGatewaySecondaryDetail p 
		WHERE s.ConsumerCombinationID = p.ConsumerCombinationID
		AND s.MID = p.MID
		AND s.Narrative = p.Narrative)
-- (277 rows affected) / 00:00:01

--set secondary combinations
UPDATE s SET SecondaryCombinationID = p.PaymentGatewayID
FROM MIDI.CreditCardLoad_InitialStage s
INNER JOIN MIDI.PaymentGatewaySecondaryDetail p 
	ON s.ConsumerCombinationID = p.ConsumerCombinationID
	AND s.MID = p.MID
	AND s.Narrative = p.Narrative
WHERE s.RequiresSecondaryID = 1
-- (21,682 rows affected) / 00:00:01




-- Distribute Transactions CC
INSERT INTO [MIDI].[ConsumerTransaction_CreditCardHolding] (
	FileID, RowNum, Amount, TranDate, ConsumerCombinationID, SecondaryCombinationID,
	LocationID, CINID, FanID,
	IsOnline,
	CardholderPresentData
)
SELECT 
	FileID, RowNum, Amount, TranDate, ConsumerCombinationID, SecondaryCombinationID,
	LocationID, CINID, FanID,
	IsOnline = CASE WHEN CardholderPresentMC = '5' THEN 1 ELSE 0 END, 
	CardholderPresentData = CardholderPresentMC 
FROM [MIDI].[CreditCardLoad_InitialStage]
WHERE ConsumerCombinationID IS NOT NULL 
-- (72,686 rows affected) / 00:00:02

INSERT INTO [MIDI].[CreditCardLoad_MIDIHolding] (
	FileID, RowNum, OriginatorReference, LocationCountry, MID, Narrative,
	MCC, PostCode, CIN, CardholderPresentMC, Amount, TranDateString,
	TranDate, ConsumerCombinationID, SecondaryCombinationID,
	RequiresSecondaryID, MCCID, LocationID, CINID, PaymentTypeID, FanID
)
SELECT 
	FileID, RowNum, OriginatorReference, LocationCountry, MID, Narrative,
	MCC, PostCode, CIN, CardholderPresentMC, Amount, TranDateString,
	TranDate, ConsumerCombinationID, SecondaryCombinationID,
	RequiresSecondaryID, MCCID, LocationID, CINID, PaymentTypeID, FanID
FROM [MIDI].[CreditCardLoad_InitialStage]
WHERE ConsumerCombinationID IS NULL 
-- (955,428 rows affected) / 00:00:08



-- Clear Holding Tables CC	EXEC Staging.CreditCardLoad_HoldingTable_Clear
TRUNCATE TABLE MIDI.CreditCardLoad_InitialStage




-- from setup
EXEC Monitor.ProcessLogger @ProcessName = 'MIDI', @Activity = 'ConsumerTransactionHoldingLoad - xxxx', @time = @time, @SSMS = NULL

--EXEC gas.CTLoad_MainTableLoad_Fetch
DECLARE @DayName VARCHAR(50) = UPPER(DATENAME(DW, GETDATE()))
SELECT CAST(CASE @DayName WHEN 'SATURDAY' THEN 1 WHEN 'SUNDAY' THEN 2 ELSE 0 END AS INT) AS MainTableLoadOrMIDI


--EXEC gas.CTLoad_ConsumerTransactionHolding_DisableIndexes

-- EXEC gas.CTLoad_CombinationsMIDIHolding_Set
--DECLARE @PaypalCount INT


--------------------------------------------------------------------------------------------------------------
-- CreditCardLoad_MIDIHolding


--update high and non-high variance non-paypal combinations
	UPDATE i
		SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM MIDI.creditcardload_midiholding i
	INNER JOIN Trans.ConsumerCombination c 
		ON i.MID = c.MID
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID
		AND (c.IsHighVariance = 0 AND i.Narrative = c.Narrative)
	WHERE c.PaymentGatewayStatusID != 1 -- not default Paypal
	-- (937932 rows affected) / 00:00:19

	UPDATE i
		SET ConsumerCombinationID = c.ConsumerCombinationID
	FROM MIDI.creditcardload_midiholding i
	INNER JOIN Trans.ConsumerCombination c 
		ON i.MID = c.MID
		AND i.LocationCountry = c.LocationCountry
		AND i.MCCID = c.MCCID
		AND i.OriginatorReference = c.OriginatorID
		AND (c.IsHighVariance = 1 AND i.Narrative LIKE c.Narrative)
	WHERE c.PaymentGatewayStatusID != 1 -- not default Paypal
		AND i.ConsumerCombinationID IS NULL
	-- 0 / 00:00:00




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
-- (5,117 rows affected) / 00:00:00

UPDATE cch
	SET SecondaryCombinationID = p.PaymentGatewayID
FROM MIDI.creditcardload_midiholding cch
INNER JOIN MIDI.PaymentGatewaySecondaryDetail p 
	ON cch.ConsumerCombinationID = p.ConsumerCombinationID
	AND cch.MID = p.MID
	AND cch.Narrative = p.Narrative
WHERE cch.SecondaryCombinationID IS NULL
	AND cch.RequiresSecondaryID = 1
-- (5,117 rows affected) / 00:00:00

INSERT INTO MIDI.PaymentGatewaySecondaryDetail (ConsumerCombinationID, MID, Narrative)
SELECT ConsumerCombinationID, MID, Narrative
FROM MIDI.creditcardload_midiholding
WHERE RequiresSecondaryID = 1
	AND SecondaryCombinationID IS NULL
-- 0 / 00:00:00

UPDATE cch
	SET SecondaryCombinationID = p.PaymentGatewayID
FROM MIDI.creditcardload_midiholding cch
INNER JOIN MIDI.PaymentGatewaySecondaryDetail p 
	ON cch.ConsumerCombinationID = p.ConsumerCombinationID
	AND cch.MID = p.MID
	AND cch.Narrative = p.Narrative
WHERE cch.SecondaryCombinationID IS NULL
	AND cch.RequiresSecondaryID = 1
-- 0 / 00:00:00

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
-- (943049 rows affected) / 00:00:12

DELETE FROM MIDI.CreditCardLoad_MIDIHolding
	WHERE ConsumerCombinationID IS NOT NULL




RETURN 0 


--SELECT FileID, count(*) from warehouse.relational.ConsumerTransaction_CreditCardHolding group by FileID

--SELECT FileID, count(*) from MIDI.ConsumerTransaction_CreditCardHolding group by FileID ORDER by FileID
--SELECT FileID, count(*) from warehouse.relational.ConsumerTransaction_CreditCard WHERE FILEID IN (23412,23426,23440,23454) group by FileID

--SELECT FileID, count(*) from warehouse.staging.CreditCardLoad_MIDIHolding group by FileID ORDER by FileID
--SELECT FileID, count(*) from MIDI.CreditCardLoad_MIDIHolding group by FileID ORDER by FileID


