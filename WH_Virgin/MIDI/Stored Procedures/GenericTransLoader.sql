
/*
CJM 20180829 Added a few columns to the columnstore index
RF	20190412 Contents of sProc commented out with copy saved in new sProc '[Staging].[PartitionSwitching_LoadCTtable_OLD_20190412]'
			 New contents is taken directly from [Staging].[PartitionSwitching_LoadCTtable_CJM]
CJM 20200210 removed LocationID throughout
*/
CREATE PROCEDURE [MIDI].[GenericTransLoader]
	WITH EXECUTE AS OWNER
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT
DECLARE 
	@CurrentRow INT = 1,
	@CurrentPartitionID INT,
	@CurrentPartitionStart DATE,
	@msg NVARCHAR(4000),
	@Rows INT
DECLARE 
	@strThisPartitionStartDate VARCHAR(8),
	@strNextPartitionStartDate VARCHAR(8),
	@strPartitionID VARCHAR(3)
	
DECLARE
	@IdentitySeed BIGINT


--------------------------------------------------------------------------------------------------------------------------
-- If there's no data to process, drop out
--------------------------------------------------------------------------------------------------------------------------
SELECT @RowsAffected = COUNT(*) FROM [MIDI].[ConsumerTransactionHolding] 
IF @RowsAffected = 0 BEGIN
	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - No rows to process'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	RETURN 0
END

SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Program started'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


--------------------------------------------------------------------------------------------------------------------------
-- If the shadow table has data, drop out
--------------------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [SYS].[TABLES].[Name] = 'ConsumerTransaction_shadow')
BEGIN -- check if the table has any content 
	DECLARE @RowCount INT; 
	SELECT @RowCount = COUNT(*) FROM [Trans].[ConsumerTransaction_shadow] 
	IF @RowCount > 0 BEGIN -- Log it, raise an error and return
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - ERROR: shadow table contains data'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
		RETURN -1
	END
END


---------------------------------------------------------------------------
-- Create a new partition if necessary. Use the same filegroup for the new partition
---------------------------------------------------------------------------
DECLARE @MaxPartitionDate DATETIME
SELECT @MaxPartitionDate = CONVERT(DATETIME,MAX(prv.[Value]),120) 
FROM sys.partition_range_values prv
INNER JOIN sys.partition_functions pf 
	ON pf.function_id = prv.function_id
WHERE pf.[Name] = 'PartitionByMonthFunction'

IF @MaxPartitionDate < DATEADD(DAY,1,EOMONTH(GETDATE())) BEGIN

	ALTER PARTITION SCHEME PartitionByMonthScheme NEXT USED fg_ConsumerTrans;

	DECLARE @SplitFunction NVARCHAR(MAX) = N'ALTER PARTITION FUNCTION PartitionByMonthFunction() SPLIT RANGE (N''' + CONVERT(NVARCHAR, DATEADD(MONTH,1,@MaxPartitionDate), 126) + ''');';
	EXEC sp_executesql @SplitFunction;

	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' Created new partition ' + ' [' + CONVERT(NVARCHAR, DATEADD(MONTH,1,@MaxPartitionDate), 126) + ']'; SET @SSMS = 2; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

END


---------------------------------------------------------------------------
-- Measure the CT holding table
---------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#CTHolding') IS NOT NULL DROP TABLE #CTHolding;
SELECT [d].[PartitionID], [d].[Rows], TranDate = DATEADD(MONTH,DATEDIFF(MONTH,0,[d].[TranDate]),0),
	rn = ROW_NUMBER() OVER(ORDER BY [d].[PartitionID])
INTO #CTHolding
FROM (
	SELECT 
		PartitionID = $PARTITION.PartitionByMonthFunction([MIDI].[ConsumerTransactionHolding].[TranDate]), 
		TranDate = MIN([MIDI].[ConsumerTransactionHolding].[TranDate]),
		[Rows] = COUNT(*)
	FROM [MIDI].[ConsumerTransactionHolding]
	GROUP BY $PARTITION.PartitionByMonthFunction([MIDI].[ConsumerTransactionHolding].[TranDate])
) d

---------------------------------------------------------------------------
-- load the partitions to ConsumerTrans one at a time from the holding table, 
-- roughly biggest partition first
---------------------------------------------------------------------------
WHILE 1 = 1 BEGIN 
		
	SELECT @CurrentPartitionID = #CTHolding.[PartitionID], @CurrentPartitionStart = #CTHolding.[TranDate], @Rows = #CTHolding.[Rows] 
	FROM #CTHolding WHERE #CTHolding.[rn] = @CurrentRow 
	IF @@ROWCOUNT = 0 BREAK

	SELECT	@strThisPartitionStartDate = CONVERT(VARCHAR(8),@CurrentPartitionStart,112)
		,	@strNextPartitionStartDate = CONVERT(VARCHAR(8),DATEADD(MONTH,1,@CurrentPartitionStart),112)
		,	@strPartitionID = CAST(@CurrentPartitionID AS VARCHAR(3))
		
	IF @CurrentPartitionStart < '2019-01-01'
		BEGIN
			SELECT	@strThisPartitionStartDate = '20180101'	--	RF Added 2021-03-08 to include transasctions not covered by Partition
				,	@strNextPartitionStartDate = '20190101'	--	RF Added 2021-03-08 to include transasctions not covered by Partition
		END

	--------------------------------------------------------------------------------------------------------------------------
	-- Modify the check constraint on Trandate to match this partition number
	--------------------------------------------------------------------------------------------------------------------------

	ALTER TABLE [Trans].[ConsumerTransaction_shadow] DROP CONSTRAINT [CheckTranDate_shadow]
	EXEC('ALTER TABLE [Trans].[ConsumerTransaction_shadow] ADD CONSTRAINT CheckTranDate_shadow CHECK (TranDate >= ''' + @strThisPartitionStartDate + ''' AND TranDate < ''' + @strNextPartitionStartDate + ''')')
	ALTER TABLE [Trans].[ConsumerTransaction_shadow] CHECK CONSTRAINT [CheckTranDate_shadow]


	--------------------------------------------------------------------------------------------------------------------------
	-- Disable constraints & indexes on the shadow table - csx_stuff is READONLY, everything else is for perf.
	--------------------------------------------------------------------------------------------------------------------------

	ALTER TABLE [Trans].[ConsumerTransaction_shadow] NOCHECK CONSTRAINT ALL
	ALTER INDEX csx_ConsumerTrans_shadow ON [Trans].[ConsumerTransaction_shadow] DISABLE 
	IF @Rows > 10000 BEGIN -- Only if the rowcount exceeds a threshold, disable the indexes
		ALTER INDEX ix_ConsumerTrans_shadow_ConsumerCombinationID ON [Trans].[ConsumerTransaction_shadow] DISABLE
		ALTER INDEX ix_ConsumerTrans_shadow_CINID ON [Trans].[ConsumerTransaction_shadow] DISABLE
	END
	
	--------------------------------------------------------------------------------------------------------------------------
	-- Store the Max ID found from the Trans table, later used to reseed to ID column of the Sahdow table
	-- This is done so the ID columns between the Trans table & Shadow table remain in line
	--------------------------------------------------------------------------------------------------------------------------
			
	SELECT @IdentitySeed = COALESCE(MAX([Trans].[ConsumerTransaction].[ID]), 0) + 1
	FROM [Trans].[ConsumerTransaction]

	--------------------------------------------------------------------------------------------------------------------------
	-- Switch live data to the shadow table for this partition
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE [Trans].[ConsumerTransaction] SWITCH PARTITION ' + @strPartitionID + ' TO [Trans].[ConsumerTransaction_shadow]') 
	
	--------------------------------------------------------------------------------------------------------------------------
	-- Reseed the shadow table to have the same idenity valu as the transaction table
	--------------------------------------------------------------------------------------------------------------------------

	DBCC CHECKIDENT ('[Trans].[ConsumerTransaction]', RESEED, @IdentitySeed)
	DBCC CHECKIDENT ('[Trans].[ConsumerTransaction_shadow]', RESEED, @IdentitySeed)

	--------------------------------------------------------------------------------------------------------------------------
	-- Load the switch table with new data from the transaction holding table 
	-- This has to be dynamic SQL to avoid an error message relating to the readonly columnstore index
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('
		INSERT INTO [Trans].[ConsumerTransaction_shadow] WITH (TABLOCKX) (	[FileID]
																		,	[RowNum]
																		,	[ConsumerCombinationID]
																		,	[SecondaryCombinationID]
																		,	[BankID]
																		,	[CardholderPresentData]
																		,	[TranDate]
																		,	[CINID]
																		,	[Amount]
																		,	[IsRefund]
																		,	[IsOnline]
																		,	[InputModeID]
																		,	[PaymentTypeID])
		SELECT	[FileID]
			,	[RowNum]
			,	[ConsumerCombinationID]
			,	[SecondaryCombinationID]
			,	[BankID]
			,	[CardholderPresentData]
			,	[TranDate]
			,	[CINID]
			,	[Amount]
			,	[IsRefund]
			,	[IsOnline]
			,	[InputModeID]
			,	[PaymentTypeID]
		FROM [MIDI].[ConsumerTransactionHolding] cth
		WHERE NOT EXISTS (	SELECT 1
							FROM [Trans].[ConsumerTransaction_shadow] ct
							WHERE cth.FileID = ct.FileID
							AND cth.RowNum = ct.RowNum)
		AND [TranDate] >= ''' + @strThisPartitionStartDate + ''' AND [TranDate] < ''' + @strNextPartitionStartDate + '''
		ORDER BY	[FileID]
				,	[RowNum]
	')

	--SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' loaded shadow table'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


	--------------------------------------------------------------------------------------------------------------------------
	-- Re-enable all constraints and indexes. Note that CheckTranDate has to be "trusted" i.e. entire shadow table must be checked.
	--------------------------------------------------------------------------------------------------------------------------
	ALTER TABLE [Trans].[ConsumerTransaction_shadow] CHECK CONSTRAINT ALL
	ALTER TABLE [Trans].[ConsumerTransaction_shadow] WITH CHECK CHECK CONSTRAINT CheckTranDate_shadow 
	ALTER INDEX csx_ConsumerTrans_shadow ON [Trans].[ConsumerTransaction_shadow] REBUILD
	IF @Rows > 10000 BEGIN -- Only if the rowcount exceeds a threshold, rebuild the disabled indexes
		ALTER INDEX ix_ConsumerTrans_shadow_ConsumerCombinationID ON [Trans].[ConsumerTransaction_shadow] REBUILD WITH (DATA_COMPRESSION = PAGE)
		ALTER INDEX ix_ConsumerTrans_shadow_CINID ON [Trans].[ConsumerTransaction_shadow] REBUILD WITH (DATA_COMPRESSION = PAGE)
	END

	--SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' rebuilt indexes'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


	--------------------------------------------------------------------------------------------------------------------------
	-- switch shadow table contents back to main table
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE [Trans].[ConsumerTransaction_shadow] SWITCH TO [Trans].[ConsumerTransaction] PARTITION ' + @strPartitionID)


	--------------------------------------------------------------------------------------------------------------------------
	-- Truncate the shadow table, we're finished with the contents
	-- This has to be dynamic SQL to avoid an intermittent error message relating to the readonly columnstore index 
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('DROP INDEX csx_ConsumerTrans_shadow ON [Trans].[ConsumerTransaction_shadow]') 
	EXEC('TRUNCATE TABLE [Trans].[ConsumerTransaction_shadow]')
	EXEC('CREATE NONCLUSTERED COLUMNSTORE INDEX [csx_ConsumerTrans_shadow] ON [Trans].[ConsumerTransaction_shadow]
		([TranDate], [CINID], [ConsumerCombinationID], [BankID], [Amount], [IsRefund], [IsOnline], [CardholderPresentData], [FileID], [RowNum]) 
		WITH (DROP_EXISTING = OFF) ON [fg_ConsumerTrans]')

	--------------------------------------------------------------------------------------------------------------------------
	-- Store the Max ID found from the Trans table, later used to reseed to ID column of the Sahdow table
	-- This is done so the ID columns between the Trans table & Shadow table remain in line
	-- Switch live data to the shadow table for this partition
	--------------------------------------------------------------------------------------------------------------------------
			
	SELECT @IdentitySeed = MAX([Trans].[ConsumerTransaction].[ID])
	FROM [Trans].[ConsumerTransaction]

	DBCC CHECKIDENT ('[Trans].[ConsumerTransaction]', RESEED, @IdentitySeed)
	DBCC CHECKIDENT ('[Trans].[ConsumerTransaction_shadow]', RESEED, 0);

	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' Loaded partition ' + CAST(@CurrentPartitionID AS VARCHAR(2)) + ' [' + CAST(@Rows AS VARCHAR(10)) + ']'; SET @SSMS = 2; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT



	SET @CurrentRow = @CurrentRow + 1

END
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Program finished'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


---------------------------------------------------------------------------
-- Update the process log table
---------------------------------------------------------------------------
UPDATE fp SET 
	[fp].[RowsLoaded] = x.RowsLoaded,
	[fp].[LoadedDate] = GETDATE() 
FROM [MIDI].GenericTrans_FilesProcessed fp
INNER JOIN (SELECT [MIDI].[ConsumerTransactionHolding].[FileID], RowsLoaded = COUNT(*) FROM [MIDI].[ConsumerTransactionHolding] GROUP BY [MIDI].[ConsumerTransactionHolding].[FileID]) x ON x.FileID = fp.FileID



---------------------------------------------------------------------------
-- Insert new transactions to table for upload to AWS
---------------------------------------------------------------------------

INSERT INTO [MIDI].[ConsumerTransaction_ExportToAWS]
SELECT	[MIDI].[ConsumerTransactionHolding].[FileID]
	,	[MIDI].[ConsumerTransactionHolding].[RowNum]
	,	[MIDI].[ConsumerTransactionHolding].[ConsumerCombinationID]
	,	[MIDI].[ConsumerTransactionHolding].[SecondaryCombinationID]
	,	[MIDI].[ConsumerTransactionHolding].[BankID]
	,	[MIDI].[ConsumerTransactionHolding].[CardholderPresentData]
	,	[MIDI].[ConsumerTransactionHolding].[TranDate]
	,	[MIDI].[ConsumerTransactionHolding].[CINID]
	,	[MIDI].[ConsumerTransactionHolding].[Amount]
	,	[MIDI].[ConsumerTransactionHolding].[IsRefund]
	,	[MIDI].[ConsumerTransactionHolding].[IsOnline]
	,	[MIDI].[ConsumerTransactionHolding].[InputModeID]
	,	[MIDI].[ConsumerTransactionHolding].[PaymentTypeID]
FROM [MIDI].[ConsumerTransactionHolding]

TRUNCATE TABLE [MIDI].[ConsumerTransactionHolding]



RETURN 0

