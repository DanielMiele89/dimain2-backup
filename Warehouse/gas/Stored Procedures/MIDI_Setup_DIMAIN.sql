/*
Replaces "Setup" in the ConsumerTransactionHoldingLoad package
*/
create PROCEDURE [gas].[MIDI_Setup_DIMAIN]

AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE	@Time DATETIME,	@Msg VARCHAR(2048), @SSMS BIT = 1;
EXEC dbo.oo_TimerMessagev2 'Start gas.MIDI_Setup', @Time OUTPUT, @SSMS OUTPUT; 

-- Log package start
EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad', 'Started'


-- Set MainTableLoadOrMIDI Variable (this is used elsewhere, not here)

-- Disable ConsumerTransactionHolding Indexes
EXEC gas.CTLoad_ConsumerTransactionHolding_DisableIndexes;  EXEC dbo.oo_TimerMessagev2 'CTLoad_ConsumerTransactionHolding_DisableIndexes', @Time OUTPUT, @SSMS OUTPUT; 

-- Set Combinations in MIDI holding area
EXEC gas.CTLoad_CombinationsMIDIHolding_Set;  EXEC dbo.oo_TimerMessagev2 'CTLoad_CombinationsMIDIHolding_Set', @Time OUTPUT, @SSMS OUTPUT; 

-- Set Locations in MIDI holding area
EXEC gas.CTLoad_LocationIDsMIDIHolding_Set;  EXEC dbo.oo_TimerMessagev2 'CTLoad_LocationIDsMIDIHolding_Set', @Time OUTPUT, @SSMS OUTPUT; 


-- Load matched transactions data flow task
INSERT INTO Relational.ConsumerTransactionHolding WITH (TABLOCK) 
	(FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, BankID, 
	LocationID, CardholderPresentData, TranDate, CINID, Amount, IsRefund, 
	IsOnline, InputModeID, PostStatusID, PaymentTypeID)
SELECT 
	FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, BankID, 
	LocationID, CardholderPresentData, TranDate, CINID, Amount, IsRefund, 
	IsOnline, InputModeID, PostStatusID, PaymentTypeID
FROM Staging.CTLoad_MIDIHolding mh
WHERE ConsumerCombinationID IS NOT NULL
	AND LocationID IS NOT NULL
	AND NOT EXISTS (SELECT 1 FROM Relational.ConsumerTransactionHolding cth WHERE cth.FileID = mh.FileID AND cth.RowNum = mh.RowNum);
EXEC dbo.oo_TimerMessagev2 'Load matched transactions data flow task', @Time OUTPUT, @SSMS OUTPUT; 


-- Load Matched transactions CC data flow task
INSERT INTO Relational.ConsumerTransaction_CreditCardHolding WITH (TABLOCK)
	(FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, 
	CardholderPresentData, 
	TranDate, CINID, Amount, 
	IsOnline, 
	LocationID, FanID)
SELECT FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, 
	CardholderPresentData = CardholderPresentMC, 
	TranDate, CINID, Amount, 
	IsOnline = CASE WHEN CardholderPresentMC = '5' THEN 1 ELSE 0 END, 
	LocationID, FanID
FROM Staging.CreditCardLoad_MIDIHolding mh
WHERE ConsumerCombinationID IS NOT NULL 
	AND NOT EXISTS (SELECT 1 FROM Relational.ConsumerTransaction_CreditCardHolding h WHERE h.FileID = mh.FileID AND h.RowNum = mh.RowNum);
EXEC dbo.oo_TimerMessagev2 'Load Matched transactions CC data flow task', @Time OUTPUT, @SSMS OUTPUT;


-- Clear matched transactions from MIDI holding area
DELETE FROM Staging.CTLoad_MIDIHolding
WHERE ConsumerCombinationID IS NOT NULL
	AND LocationID IS NOT NULL

DELETE FROM Staging.CreditCardLoad_MIDIHolding
WHERE ConsumerCombinationID IS NOT NULL


RETURN 0