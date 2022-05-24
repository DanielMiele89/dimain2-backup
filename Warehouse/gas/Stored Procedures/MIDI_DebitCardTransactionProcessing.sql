/*
Replaces "Debit Card Transaction Processing LOOP" in the ConsumerTransactionHoldingLoad package
*/
CREATE PROCEDURE [gas].[MIDI_DebitCardTransactionProcessing]

AS 

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE	@Time DATETIME,	@Msg VARCHAR(2048), @SSMS BIT = 1,
	@LastFileIDProcessed INT, @LastFileIDStaged INT, @RowsProcessed INT
							
EXEC dbo.oo_TimerMessagev2 'Start gas.MIDI_DebitCardTransactionProcessing', @Time OUTPUT, @SSMS OUTPUT 


--EXEC gas.CTLoad_LastFileIDProcessed_Fetch
SELECT @LastFileIDProcessed = FileID FROM Staging.CTLoad_LastFileProcessed

--EXEC gas.CTLoad_FilesToProcess_Fetch
-- DIMAIN can't see DIMAIN_TR
IF OBJECT_ID('tempdb..#Looper') IS NOT NULL DROP TABLE #Looper;
CREATE TABLE #Looper (ID INT, InDate DATETIME)
INSERT INTO #Looper (ID, InDate)
	EXEC('SELECT ID, InDate
		FROM DIMAIN_TR.SLC_REPL.dbo.NobleFiles
		WHERE FileType = ''TRANS''
			AND ID > ' + @LastFileIDProcessed + '
			AND ID != 27429
		ORDER BY ID')

SELECT @LastFileIDStaged = MIN(ID) FROM #Looper
WHILE 1 = 1 BEGIN
	IF @LastFileIDStaged IS NULL BREAK

INSERT INTO Staging.CTLoad_InitialStage WITH (TABLOCK)
	(FileID, RowNum, BankIDString, 
	MID, Narrative, LocationAddress, LocationCountry, 
	MCC, CardholderPresentData, TranDate, PaymentCardID, 
	Amount, OriginatorID, PostStatus, CardInputMode, PaymentTypeID, 
	IsOnline, IsRefund)
SELECT --TOP(1000000) 
	FileID,
	RowNum,
	BankID,
	MID = CASE 
		WHEN MerchantID LIKE 'VCR%[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]%' THEN CAST(LTRIM(RTRIM(vcr.MID)) AS VARCHAR(50)) + '%'
		ELSE CAST(LTRIM(RTRIM(MerchantID)) AS VARCHAR(50)) END,	
	Narrative = CAST(LTRIM(RTRIM(LocationName)) AS VARCHAR(22)),
	LocationAddress = CAST(LTRIM(RTRIM(LocationAddress)) AS VARCHAR(18)),
	LocationCountry = CAST(LTRIM(RTRIM(LocationCountry)) AS VARCHAR(3)), 
	MCC,
	CardholderPresentData,
	TranDate = CASE WHEN TranDate IN ('0001-01-01','00010101') THEN '20010101' ELSE TranDate END,
	PaymentCardID,
	Amount,
	OriginatorID,
	PostStatus,
	CardInputMode,
	CAST(1 AS TINYINT) AS PaymentTypeID,
	IsOnline = CASE WHEN CardholderPresentData = 5 THEN 1 ELSE 0 END,
	IsRefund = CASE WHEN Amount < 0 THEN 1 ELSE 0 END
FROM Archive_Light.dbo.NobleTransactionHistory_MIDI nth 
CROSS APPLY (SELECT MID = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(nth.MerchantID, '0', ''), '1', ''), '2', ''), '3', ''), '4', ''), '5', ''), '6', ''), '7', ''), '8', ''), '9', '')) vcr
WHERE FileID = @LastFileIDStaged
ORDER BY FileID, RowNum;

	SET @RowsProcessed = @@ROWCOUNT;
	SET @Msg = 'Collected FileID ' + CAST(@LastFileIDStaged AS VARCHAR(10)) + ' rows = ' + CAST(@RowsProcessed AS VARCHAR(10))
	EXEC dbo.oo_TimerMessagev2 @Msg, @Time OUTPUT, @SSMS OUTPUT 


	EXEC gas.CTLoad_SetInitialColumnValues;  EXEC dbo.oo_TimerMessagev2 'CTLoad_SetInitialColumnValues', @Time OUTPUT, @SSMS OUTPUT 

	EXEC gas.CTLoad_CombinationsNonPaypal_Set;  EXEC dbo.oo_TimerMessagev2 'CTLoad_CombinationsNonPaypal_Set', @Time OUTPUT, @SSMS OUTPUT 

	EXEC gas.CTLoad_CombinationsPaypal_Set;  EXEC dbo.oo_TimerMessagev2 'CTLoad_CombinationsPaypal_Set', @Time OUTPUT, @SSMS OUTPUT 

	-- Load CTLoad_PaypalSecondaryID
	INSERT INTO Staging.CTLoad_PaypalSecondaryID WITH (TABLOCK)
		(FileID, RowNum, MID, Narrative, ConsumerCombinationID)
	SELECT FileID, RowNum, MID, Narrative, ConsumerCombinationID
	FROM Staging.CTLoad_InitialStage
	WHERE RequiresSecondaryID = 1
	EXEC dbo.oo_TimerMessagev2 'Load CTLoad_PaypalSecondaryID', @Time OUTPUT, @SSMS OUTPUT 

	EXEC gas.CTLoad_PaypalSecondaryIDs_Set;  EXEC dbo.oo_TimerMessagev2 'CTLoad_PaypalSecondaryIDs_Set', @Time OUTPUT, @SSMS OUTPUT 

	EXEC gas.CTLoad_LocationIDs_Set;  EXEC dbo.oo_TimerMessagev2 'CTLoad_LocationIDs_Set', @Time OUTPUT, @SSMS OUTPUT 


	--EXEC gas.CTLoad_DistributeTransactions;  
	--Unresolved
    INSERT INTO [Staging].[CTLoad_MIDIHolding] 
		(FileID, RowNum, BankID, MID, Narrative, LocationAddress, LocationCountry, CardholderPresentData, 
		TranDate, CINID, Amount, IsOnline, IsRefund, OriginatorID, MCCID, PostStatusID, LocationID, 
		ConsumerCombinationID, SecondaryCombinationID, InputModeID, PaymentTypeID)
	SELECT 
		FileID, RowNum, BankID, MID, Narrative, LocationAddress, LocationCountry, CardholderPresentData, 
		TranDate, CINID, Amount, IsOnline, IsRefund, OriginatorID, MCCID, PostStatusID, LocationID, 
		ConsumerCombinationID, SecondaryCombinationID, InputModeID, PaymentTypeID
	FROM [Staging].[CTLoad_InitialStage]
	WHERE CINID IS NOT NULL
		AND (ConsumerCombinationID IS NULL OR LocationID IS NULL)
	
	--	Ready
	INSERT INTO [Relational].[ConsumerTransactionHolding] 
		(FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, BankID, LocationID, CardholderPresentData, 
		TranDate, CINID, Amount, IsRefund, IsOnline, InputModeID, PostStatusID, PaymentTypeID)
    SELECT 
		FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, BankID, LocationID, CardholderPresentData, 
		TranDate, CINID, Amount, IsRefund, IsOnline, InputModeID, PostStatusID, PaymentTypeID
	FROM [Staging].[CTLoad_InitialStage]
	WHERE CINID IS NOT NULL
		AND ConsumerCombinationID IS NOT NULL
		AND LocationID IS NOT NULL	
	EXEC dbo.oo_TimerMessagev2 'CTLoad_DistributeTransactions', @Time OUTPUT, @SSMS OUTPUT 


	EXEC gas.CTLoad_QAStats_Set;  EXEC dbo.oo_TimerMessagev2 'CTLoad_QAStats_Set', @Time OUTPUT, @SSMS OUTPUT 

	EXEC gas.CTLoad_StagingTables_Clear

	SET @Msg = 'Processed FileID ' + CAST(@LastFileIDStaged AS VARCHAR(10))
	EXEC dbo.oo_TimerMessagev2 @Msg, @Time OUTPUT, @SSMS OUTPUT 

	-- Get the next FileID, exit the loop if there isn't one
	SELECT @LastFileIDStaged = MIN(ID) FROM #Looper WHERE ID > @LastFileIDStaged
END


RETURN 0