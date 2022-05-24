/*
Replaces "Credit Card Transaction Processing" in the ConsumerTransactionHoldingLoad package
*/
CREATE PROCEDURE [gas].[MIDI_CreditCardTransactionProcessing]

AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE	@Time DATETIME,	@Msg VARCHAR(2048), @SSMS BIT = 1,
	@LastFileIDProcessed INT, @LastFileIDStaged INT, @RowsProcessed INT;
EXEC dbo.oo_TimerMessagev2 'Start gas.MIDI_CreditCardTransactionProcessing', @Time OUTPUT, @SSMS OUTPUT; 

-- Set CCFileID Variable
SELECT @LastFileIDProcessed = MAX(FileID) FROM staging.CreditCardLoad_LastFileProcessed;


-- Load CreditCardLoad_InitialStage data flow task
-- Retrieve all transactions with FileID greater than the max already processed
INSERT INTO Staging.CreditCardLoad_InitialStage WITH (TABLOCK)
	(FileID, RowNum, 
	OriginatorReference, 
	LocationCountry, 
	MID, 
	Narrative, 
	MCC, 
	PostCode, 
	CIN, CardholderPresentMC, 
	Amount, 
	TranDateString,
	TranDate,
	FanID)
SELECT FileID, RowNum, 
	OriginatorReference = SUBSTRING(TransactionReferenceNumber,2,6), 
	LocationCountry = SUBSTRING(MerchantDBACountry,1,2), 
	MerchantID AS MID, 
	MerchantDBAName AS Narrative, 
	MerchantSICClassCode AS MCC, 
	MerchantZip AS PostCode, 
	CIN, CardholderPresentMC, 
	Amount, 
	TranDate AS TranDateString, 
	TranDate,
	FanID
FROM Archive_Light.dbo.CBP_Credit_TransactionHistory 
WHERE IsValidTransaction = 1
	AND FileID > @LastFileIDProcessed 
	AND (CIN != '' OR FanID IS NOT NULL)
	AND ISDATE(TranDate) = 1 
ORDER BY FileID, RowNum;
EXEC dbo.oo_TimerMessagev2 'Load CreditCardLoad_InitialStage', @Time OUTPUT, @SSMS OUTPUT 

-- Update Staging Fields CC
EXEC Staging.CreditCardLoad_ColumnValues_Set;  EXEC dbo.oo_TimerMessagev2 'CreditCardLoad_ColumnValues_Set', @Time OUTPUT, @SSMS OUTPUT 

-- Set non-paypal combinations CC
EXEC Staging.CreditCardLoad_CombinationsNonPaypal_Set;  EXEC dbo.oo_TimerMessagev2 'CreditCardLoad_CombinationsNonPaypal_Set', @Time OUTPUT, @SSMS OUTPUT

-- Set Paypal Combinations CC
EXEC Staging.CreditCardLoad_CombinationsPaypal_Set;  EXEC dbo.oo_TimerMessagev2 'CreditCardLoad_CombinationsPaypal_Set', @Time OUTPUT, @SSMS OUTPUT

-- Load Secondary IDs CC data flow task
INSERT INTO Staging.CTLoad_PaypalSecondaryID WITH (TABLOCK)
	(FileID, RowNum, MID, Narrative, ConsumerCombinationID)
SELECT FileID, RowNum, MID, Narrative, ConsumerCombinationID
FROM Staging.CreditCardLoad_InitialStage
WHERE RequiresSecondaryID = 1
EXEC dbo.oo_TimerMessagev2 'Load Secondary IDs CC data flow task', @Time OUTPUT, @SSMS OUTPUT

-- Match Secondary IDs CC
EXEC Staging.CreditCardLoad_PaypalSecondaryIDs_Set;  EXEC dbo.oo_TimerMessagev2 'CreditCardLoad_PaypalSecondaryIDs_Set', @Time OUTPUT, @SSMS OUTPUT

-- Distribute Transactions CC data flow task
INSERT INTO Relational.ConsumerTransaction_CreditCardHolding WITH (TABLOCK)
	(FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, 
	CardHolderPresentData, 
	TranDate, CINID, Amount, 
	IsOnline, 
	LocationID, FanID)
SELECT 
	FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, 
	CardHolderPresentData = CardholderPresentMC, 
	TranDate, CINID, Amount, 
	IsOnline = CASE WHEN CardholderPresentMC = '5' THEN 1 ELSE 0 END, 
	LocationID, FanID 
FROM Staging.CreditCardLoad_InitialStage
WHERE ConsumerCombinationID IS NOT NULL;
EXEC dbo.oo_TimerMessagev2 'Distribute Transactions CC data flow task', @Time OUTPUT, @SSMS OUTPUT

INSERT INTO Staging.CreditCardLoad_MIDIHolding WITH (TABLOCK)
	(FileID, RowNum, OriginatorReference, 
	LocationCountry, MID, Narrative, MCC, PostCode, CIN, 
	CardholderPresentMC, Amount, TranDateString, TranDate,
	ConsumerCombinationID, SecondaryCombinationID, RequiresSecondaryID,
	MCCID, LocationID, CINID, PaymentTypeID, FanID)
SELECT 
	FileID, RowNum, OriginatorReference, 
	LocationCountry, MID, Narrative, MCC, PostCode, CIN, 
	CardholderPresentMC, Amount, TranDateString, TranDate,
	ConsumerCombinationID, SecondaryCombinationID, RequiresSecondaryID,
	MCCID, LocationID, CINID, PaymentTypeID, FanID
FROM Staging.CreditCardLoad_InitialStage s
WHERE ConsumerCombinationID IS NULL
	AND NOT EXISTS (SELECT 1 FROM Staging.CreditCardLoad_MIDIHolding h WHERE h.FileID = s.FileID AND h.RowNum = s.RowNum)
EXEC dbo.oo_TimerMessagev2 'CreditCardLoad_MIDIHolding', @Time OUTPUT, @SSMS OUTPUT

-- Log it
INSERT INTO Staging.CardTransaction_QA(FileID, FileCount, MatchedCount, UnmatchedCount, NoCINCount, PositiveCount)
SELECT FileID
	, COUNT(1) AS FileCount
	, SUM(CASE WHEN ConsumerCombinationID IS NULL THEN 0 ELSE 1 END) AS MatchedCount
	, SUM(CASE WHEN ConsumerCombinationID IS NULL THEN 1 ELSE 0 END) AS UnmatchedCount
	, SUM(CASE WHEN CINID IS NULL THEN 0 ELSE 1 END) AS NoCINCount
	, -1 AS PositiveCount
FROM Staging.CreditCardLoad_InitialStage
GROUP BY FileID


-- Clear Holding Tables CC
TRUNCATE TABLE Staging.CreditCardLoad_InitialStage


RETURN 0