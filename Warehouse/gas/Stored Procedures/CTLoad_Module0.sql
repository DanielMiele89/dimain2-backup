


CREATE procedure [gas].[CTLoad_Module0] 

AS 

SET NOCOUNT ON

-------------------------------------------------------------------------------------------------------------------
--Log package start			
-------------------------------------------------------------------------------------------------------------------
EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad', 'Started'



-------------------------------------------------------------------------------------------------------------------
--Disable CTHolding indexes	gas.CTLoad_ConsumerTransactionHolding_DisableIndexes		
-------------------------------------------------------------------------------------------------------------------
ALTER INDEX IX_ConsumerTransactionHolding_MainCover ON Relational.ConsumerTransactionHolding DISABLE
ALTER INDEX IX_Relational_ConsumerTransactionHolding_CINIDTranDateIncl_ForMissingTranQuery ON Relational.ConsumerTransactionHolding DISABLE



-------------------------------------------------------------------------------------------------------------------
-- Set Combinations in MIDI holding area	gas.CTLoad_CombinationsMIDIHolding_Set		
-- Staging.CTLoad_MIDIHolding is populated by Distribute transactions	Data flow task in Module 2
-- staging.creditcardload_MIDIholding is populated by Distribute Transactions CC dataflow task in Module 3
-- Loads to Relational.ConsumerTransactionHolding
-------------------------------------------------------------------------------------------------------------------
EXEC [gas].[CTLoad_Module1_Combinations]




-------------------------------------------------------------------------------------------------------------------
-- Get new data from Archive_Light.dbo.NobleTransactionHistory_MIDI
-- into Relational.ConsumerTransactionHolding if it can be tagged
-- into Staging.CTLoad_MIDIHolding if it cannot be tagged
-------------------------------------------------------------------------------------------------------------------
DECLARE @FileID INT

SELECT FileID = ID
INTO #FilesToProcess 
FROM SLC_Report.dbo.NobleFiles --WHERE FileType IN ('TRANS', 'CRTRN')
WHERE FileType = 'TRANS'
	AND ID > (SELECT FileID FROM Staging.CTLoad_LastFileProcessed)

SELECT @FileID = MIN(FileID) FROM #FilesToProcess
WHILE @FileID IS NOT NULL BEGIN

	EXEC [gas].[CTLoad_Module2_CTLoad] @FileID 

	SELECT @FileID = MIN(FileID) FROM #FilesToProcess WHERE FileID > @FileID

	IF @@ROWCOUNT = 0 BREAK

END



------------------------------------------------------------------------------------------------------------------- 
-- Get new data from Archive_Light.dbo.CBP_Credit_TransactionHistory
-- into relational.consumertransaction_creditcardholding if it can be tagged
-- into staging.CreditCardLoad_MIDIHolding if it cannot be tagged
-- doesn't touch ConsumerTransactionHolding
------------------------------------------------------------------------------------------------------------------- 
EXEC [gas].[CTLoad_Module3_CreditCardLoad]



------------------------------------------------------------------------------------------------------------------- 
-- Reset last file processed	gas.CTLoad_LastFileProcessed_Set		
-------------------------------------------------------------------------------------------------------------------
DECLARE @LatestFile INT


SELECT @LatestFile = MAX(FileID) FROM Relational.ConsumerTransactionHolding WITH (NOLOCK)

IF @LatestFile IS NULL
	SELECT @LatestFile = MAX(FileID) FROM Relational.ConsumerTransaction WITH (NOLOCK)

UPDATE Staging.CTLoad_LastFileProcessed SET FileID = @LatestFile, ProcessDate = GETDATE()



SELECT @LatestFile = MAX(FileID) FROM Relational.ConsumerTransaction_CreditCardHolding WITH (NOLOCK)

IF @LatestFile IS NULL
	SELECT @LatestFile = MAX(FileID) FROM Relational.ConsumerTransaction_CreditCard

UPDATE Staging.CreditCardLoad_LastFileProcessed SET FileID = @LatestFile



-------------------------------------------------------------------------------------------------------------------
--Set MainTableLoadOrMIDI Variable			
-------------------------------------------------------------------------------------------------------------------
DECLARE @DayName VARCHAR(50) = UPPER(DATENAME(DW, GETDATE()))
DECLARE @MaintableloadOrMIDI INT = CAST(CASE @DayName WHEN 'SATURDAY' THEN 1 WHEN 'SUNDAY' THEN 2 ELSE 0 END AS INT) 

IF @MaintableloadOrMIDI = 0 BEGIN 
	-- do nothing
	SELECT 0
END


IF @MaintableloadOrMIDI = 1 BEGIN 

	------------------------------------------------------------------------------------------------------------------- 
	-- Load to partitioned tables, saturday
	------------------------------------------------------------------------------------------------------------------- 
	EXEC [gas].[CTLoad_Module4_PartitionedTableLoad]
	
END


IF @MaintableloadOrMIDI = 2 BEGIN 

	------------------------------------------------------------------------------------------------------------------- 
	-- MIDI module, sunday
	------------------------------------------------------------------------------------------------------------------- 
	EXEC [gas].[CTLoad_Module5_MIDI]

END 



------------------------------------------------------------------------------------------------------------------- 
-- Enable CTholding indexes	gas.CTLoad_ConsumerTransactionHolding_EnableIndexes		
------------------------------------------------------------------------------------------------------------------- 
ALTER INDEX IX_ConsumerTransactionHolding_MainCover ON Relational.ConsumerTransactionHolding REBUILD
ALTER INDEX IX_Relational_ConsumerTransactionHolding_CINIDTranDateIncl_ForMissingTranQuery ON Relational.ConsumerTransactionHolding REBUILD



------------------------------------------------------------------------------------------------------------------- 
-- Log package complete
------------------------------------------------------------------------------------------------------------------- 
EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad', 'Complete'



------------------------------------------------------------------------------------------------------------------- 
-- Process Completion Email
------------------------------------------------------------------------------------------------------------------- 
DECLARE @txtBody VARCHAR(200) = 'Notification email to confirm that the MID Identification process on ' + @@SERVERNAME + ' has completed'
EXEC msdb.dbo.sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients = 'DIProcessCheckers@rewardinsight.com;DevDB@rewardinsight.com',
	@subject = 'MID Identification process COMPLETE',
	@body = @txtBody,
	@body_format = 'TEXT',  
	@exclude_query_output = 1

RETURN 0

