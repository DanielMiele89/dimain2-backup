/*
Replaces "Debit Card Transaction Processing LOOP" in the ConsumerTransactionHoldingLoad package
*/
create PROCEDURE [gas].[MIDI_DebitCardTransactionProcessing_DIMAIN]

AS 

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE	@Time DATETIME,	@Msg VARCHAR(2048), @SSMS BIT = 1,
	@LastFileIDProcessed INT, @LastFileIDStaged INT, @RowsProcessed INT
							
EXEC dbo.oo_TimerMessagev2 'Start gas.MIDI_DebitCardTransactionProcessing', @Time OUTPUT, @SSMS OUTPUT 


--EXEC gas.CTLoad_LastFileIDProcessed_Fetch
SELECT @LastFileIDProcessed = FileID FROM Staging.CTLoad_LastFileProcessed

--EXEC gas.CTLoad_FilesToProcess_Fetch
IF OBJECT_ID('tempdb..#Looper') IS NOT NULL DROP TABLE #Looper;
SELECT ID, InDate
INTO #Looper
FROM SLC_REPL.dbo.NobleFiles
WHERE FileType = 'TRANS'
	AND ID > @LastFileIDProcessed
	AND ID != 27429
ORDER BY ID

SELECT @LastFileIDStaged = MIN(ID) FROM #Looper
WHILE 1 = 1 BEGIN
	IF @LastFileIDStaged IS NULL BREAK

	INSERT INTO Staging.CTLoad_InitialStage WITH (TABLOCK)
		(FileID, RowNum, BankIDString, 
		MID, Narrative, LocationAddress, LocationCountry, 
		MCC, CardholderPresentData, TranDate, PaymentCardID, 
		Amount, OriginatorID, PostStatus, CardInputMode, PaymentTypeID)
	SELECT FileID
		, RowNum
		, BankID
		, CAST(MerchantID AS VARCHAR(50)) AS MID
		, CAST(LocationName AS VARCHAR(22)) AS Narrative
		, CAST(LocationAddress AS VARCHAR(18)) AS LocationAddress
		, CAST(LocationCountry AS VARCHAR(3)) AS LocationCountry
		, MCC
		, CardholderPresentData
		, TranDate
		, PaymentCardID
		, Amount
		, OriginatorID
		, PostStatus
		, CardInputMode
		, CAST(1 AS TINYINT) AS PaymentTypeID
	FROM Archive_Light.dbo.NobleTransactionHistory_MIDI nth 
	WHERE FileID = @LastFileIDStaged
		AND NOT EXISTS (SELECT 1
			FROM Warehouse.Staging.CTLoad_InitialStage ct
			WHERE nth.FileID = ct.FileID
				AND nth.RowNum = ct.RowNum) 
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

	EXEC gas.CTLoad_DistributeTransactions;  EXEC dbo.oo_TimerMessagev2 'CTLoad_DistributeTransactions', @Time OUTPUT, @SSMS OUTPUT 

	EXEC gas.CTLoad_QAStats_Set;  EXEC dbo.oo_TimerMessagev2 'CTLoad_QAStats_Set', @Time OUTPUT, @SSMS OUTPUT 

	EXEC gas.CTLoad_StagingTables_Clear

	SET @Msg = 'Processed FileID ' + CAST(@LastFileIDStaged AS VARCHAR(10))
	EXEC dbo.oo_TimerMessagev2 @Msg, @Time OUTPUT, @SSMS OUTPUT 

	-- Get the next FileID, exit the loop if there isn't one
	SELECT @LastFileIDStaged = MIN(ID) FROM #Looper WHERE ID > @LastFileIDStaged
END


RETURN 0