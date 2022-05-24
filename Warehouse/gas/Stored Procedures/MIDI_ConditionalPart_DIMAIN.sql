/*
Replaces the conditional processing section in the ConsumerTransactionHoldingLoad package
*/
create PROCEDURE [gas].[MIDI_ConditionalPart_DIMAIN]

AS 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE	@Time DATETIME,	@Msg VARCHAR(2048), @SSMS BIT = 1
EXEC dbo.oo_TimerMessagev2 'Start gas.MIDI_ConditionalPart', @Time OUTPUT, @SSMS OUTPUT

-- Reset last file processed
EXEC gas.CTLoad_LastFileProcessed_Set

-- Set MainTableLoadOrMIDI Variable (this is used elsewhere, not here)
DECLARE @DayName VARCHAR(10) = UPPER(DATENAME(DW, GETDATE()));
SELECT @DayName = CASE WHEN @DayName IN ('SATURDAY','SUNDAY') THEN @DayName ELSE 'WEEKDAY' END


-- ConsumerTransaction Load
IF @DayName = 'SATURDAY' BEGIN

	-- Load ConsumerTransactionForFile data flow task
	INSERT INTO AWSFile.ConsumerTransactionForFile
		(FileID, RowNum, ConsumerCombinationID, CardholderPresentData, TranDate, 
		CINID, Amount, IsRefund, IsOnline, InputModeID, PaymentTypeID)
	SELECT 
		FileID, RowNum, ConsumerCombinationID, CardholderPresentData, TranDate, 
		CINID, Amount, IsRefund, IsOnline, InputModeID, PaymentTypeID 
	FROM Relational.ConsumerTransactionHolding
	EXEC dbo.oo_TimerMessagev2 'Load ConsumerTransactionForFile data flow task', @Time OUTPUT, @SSMS OUTPUT

	-- Partition switching
	EXEC [Staging].[PartitionSwitching_LoadCTtable];  EXEC dbo.oo_TimerMessagev2 'Partition switching', @Time OUTPUT, @SSMS OUTPUT

	-- CT Partition Completion Email
	EXEC msdb.dbo.sp_send_dbmail 
        @profile_name = 'Administrator', 
		@recipients='DIProcessCheckers@rewardinsight.com;DevDB@rewardinsight.com',
        @subject = 'ConsumerTransaction Partition Switching COMPLETE',
        @body='Notification email to confirm that the partition switching to ConsumerTransaction on DIMAIN2 has completed',
        @body_format = 'TEXT',  
        @exclude_query_output = 1

	-- Partition Switching CC
	EXEC [Staging].[PartitionSwitching_LoadCTtable_MyRewards]
	EXEC dbo.oo_TimerMessagev2 'Partition switching CC', @Time OUTPUT, @SSMS OUTPUT

	-- CT MyRewards Partition Completion Email
	EXEC msdb.dbo.sp_send_dbmail 
        @profile_name = 'Administrator', 
		@recipients='DIProcessCheckers@rewardinsight.com;DevDB@rewardinsight.com',
        @subject = 'ConsumerTransaction_MyRewards Partition Switching COMPLETE',
        @body='Notification email to confirm that the partition switching to ConsumerTransaction_MyRewards on DIMAIN2 has completed',
        @body_format = 'TEXT',  
        @exclude_query_output = 1

END


-- MIDI Module
IF @DayName = 'SUNDAY' BEGIN
	-- Clear Brand Suggestions
	EXEC gas.CTLoad_BrandSuggestions_Clear;  EXEC dbo.oo_TimerMessagev2 'CTLoad_BrandSuggestions_Clear', @Time OUTPUT, @SSMS OUTPUT


	-- Load CTLoad_MIDINewCombo data flow task
	INSERT INTO Staging.CTLoad_MIDINewCombo_v2 WITH (TABLOCK)
		(MID, Narrative, LocationCountry, MCCID, OriginatorID, AcquirerID, IsCreditOrigin)
	SELECT 
		MID, Narrative, LocationCountry, MCCID, d.OriginatorID, AcquirerID, IsCreditOrigin
	FROM (
		SELECT MID, Narrative, LocationCountry, MCCID, OriginatorID, CAST(0 AS BIT) AS IsCreditOrigin
		FROM staging.CTLoad_MIDIHolding WITH (NOLOCK)
		WHERE ConsumerCombinationID IS NULL
		UNION ALL -- CJM added ALL
		SELECT MID, Narrative, LocationCountry, MCCID, OriginatorReference AS OriginatorID, CAST(1 AS BIT) AS IsCreditOrigin
		FROM Staging.CreditCardLoad_MIDIHolding WITH (NOLOCK)
		WHERE ConsumerCombinationID IS NULL
	) d
	CROSS APPLY (SELECT OriginatorID = LTRIM(RTRIM(CAST(TRY_CAST(OriginatorID AS INT) AS VARCHAR(12))))) q
	CROSS APPLY (
		SELECT AcquirerID = CASE
			WHEN IsCreditOrigin = 1 THEN 7 -- unknown
			WHEN UPPER(LocationCountry) <> 'GB' THEN 9
			WHEN LEN(RTRIM(q.OriginatorID)) <> 6 THEN 7 -- unknown
			WHEN q.OriginatorID IS NULL THEN 7
			WHEN LEN(q.OriginatorID) <> 6 THEN 7
			WHEN LEFT(q.OriginatorID,4) = '4929' AND LEN(MID) >= 7 
				AND TRY_CAST(MID AS BIGINT) = TRY_CAST(RIGHT(MID, 7) AS BIGINT) THEN 1 -- barclaycard business
			WHEN q.OriginatorID IN ('467858', '474510', '491678', '491677', '406418', '454706', '477902', '474509')
				AND TRY_CAST(MID AS BIGINT) = TRY_CAST(RIGHT(MID, 8) AS BIGINT) THEN 2 -- worldpay
			WHEN q.OriginatorID = '408532' THEN 3 -- cardnet with no MID check
			WHEN q.OriginatorID IN ('424192', '425518', '424191')
				AND TRY_CAST(MID AS BIGINT) = TRY_CAST(RIGHT(MID, 15) AS BIGINT)
				AND LEFT(MID,4) = '5404' THEN 3 -- cardnet
			WHEN q.OriginatorID = '483050'
				AND TRY_CAST(MID AS BIGINT) = TRY_CAST(RIGHT(MID, 8) AS BIGINT)
				AND RIGHT(MID,1) = '1' THEN 4 -- Global Payments
			WHEN q.OriginatorID = '446365'
				AND TRY_CAST(MID AS BIGINT) = TRY_CAST(RIGHT(MID, 10) AS BIGINT) THEN 5 -- Elavon
			WHEN q.OriginatorID IN ('255', '256') THEN 6 -- odd
			WHEN q.OriginatorID = '417776' THEN 10 -- Interpay
			WHEN q.OriginatorID IN ('407370', '424469', '424500', '431319', '431320', '431321','431323','431326','431327','431328',
				'431329','431330','438218','446366','450306','450744','455358','459519','467989','467990','477127','479262','498750','499876','499886')
				THEN 9 -- foreign	
			ELSE 7 END
	) x
	EXEC dbo.oo_TimerMessagev2 'Load CTLoad_MIDINewCombo data flow task', @Time OUTPUT, @SSMS OUTPUT


	-- Suggest Brands
	EXEC gas.CTLoad_MIDINewCombo_SuggestBrands_V3;  EXEC dbo.oo_TimerMessagev2 'CTLoad_MIDINewCombo_SuggestBrands_V3', @Time OUTPUT, @SSMS OUTPUT

END


-- Enable ConsumerTransactionHolding Indexes
EXEC gas.CTLoad_ConsumerTransactionHolding_EnableIndexes;  EXEC dbo.oo_TimerMessagev2 'CTLoad_ConsumerTransactionHolding_EnableIndexes', @Time OUTPUT, @SSMS OUTPUT

-- Log Package Complete
EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad', 'Complete'

-- Process Completion email
EXEC msdb.dbo.sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients='DIProcessCheckers@rewardinsight.com;DevDB@rewardinsight.com',
	@subject = 'MID Identification process COMPLETE',
	@body='Notification email to confirm that the MID Identification process on DIMAIN2 has completed',
	@body_format = 'TEXT',  
	@exclude_query_output = 1


RETURN 0