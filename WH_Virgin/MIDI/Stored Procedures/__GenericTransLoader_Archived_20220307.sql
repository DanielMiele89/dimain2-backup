
/*
CJM 20180829 Added a few columns to the columnstore index
RF	20190412 Contents of sProc commented out with copy saved in new sProc '[Staging].[PartitionSwitching_LoadCTtable_OLD_20190412]'
			 New contents is taken directly from [Staging].[PartitionSwitching_LoadCTtable_CJM]
CJM 20200210 removed LocationID throughout
*/
CREATE PROCEDURE [MIDI].[__GenericTransLoader_Archived_20220307]
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
IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [Name] = 'ConsumerTransaction_shadow')
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
SELECT PartitionID, [Rows], TranDate = DATEADD(MONTH,DATEDIFF(MONTH,0,TranDate),0),
	rn = ROW_NUMBER() OVER(ORDER BY PartitionID DESC)
INTO #CTHolding
FROM (
	SELECT 
		PartitionID = $PARTITION.PartitionByMonthFunction(Trandate), 
		TranDate = MIN(TranDate),
		[Rows] = COUNT(*)
	FROM [MIDI].[ConsumerTransactionHolding] 
	GROUP BY $PARTITION.PartitionByMonthFunction(Trandate)
) d

---------------------------------------------------------------------------
-- load the partitions to ConsumerTrans one at a time from the holding table, 
-- roughly biggest partition first
---------------------------------------------------------------------------
WHILE 1 = 1 BEGIN 
		
	SELECT @CurrentPartitionID = PartitionID, @CurrentPartitionStart = TranDate, @Rows = [Rows] 
	FROM #CTHolding WHERE rn = @CurrentRow 
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
	-- Switch live data to the shadow table for this partition
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE [Trans].[ConsumerTransaction] SWITCH PARTITION ' + @strPartitionID + ' TO [Trans].[ConsumerTransaction_shadow]') 


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

	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' Loaded partition ' + CAST(@CurrentPartitionID AS VARCHAR(2)) + ' [' + CAST(@Rows AS VARCHAR(10)) + ']'; SET @SSMS = 2; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	SET @CurrentRow = @CurrentRow + 1

END
SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Program finished'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


---------------------------------------------------------------------------
-- Update the process log table
---------------------------------------------------------------------------
UPDATE fp SET 
	RowsLoaded = x.RowsLoaded,
	LoadedDate = GETDATE() 
FROM [MIDI].GenericTrans_FilesProcessed fp
INNER JOIN (SELECT FileID, RowsLoaded = COUNT(*) FROM [MIDI].[ConsumerTransactionHolding] GROUP BY FileID) x ON x.FileID = fp.FileID



---------------------------------------------------------------------------
-- Insert new transactions to table for upload to AWS
---------------------------------------------------------------------------

INSERT INTO [MIDI].[ConsumerTransaction_ExportToAWS]
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
FROM [MIDI].[ConsumerTransactionHolding]

TRUNCATE TABLE [MIDI].[ConsumerTransactionHolding]



RETURN 0

