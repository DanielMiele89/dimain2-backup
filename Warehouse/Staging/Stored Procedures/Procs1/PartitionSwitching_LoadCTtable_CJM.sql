
/*
CJM 20180829 Added a few columns to the columnstore index
RF	20190412 Contents of sProc commented out with copy saved in new sProc '[Staging].[PartitionSwitching_LoadCTtable_OLD_20190412]'
			 New contents is taken directly from [Staging].[PartitionSwitching_LoadCTtable_CJM]
*/
CREATE PROCEDURE [Staging].[PartitionSwitching_LoadCTtable_CJM]
	WITH EXECUTE AS OWNER
AS
--BEGIN

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable', 'Program Started'

DECLARE 
	@Time1 DATETIME = GETDATE(), 
	@msg VARCHAR(4000), 
	@Statement VARCHAR(8000),
	@RowsAffected INT 


-----------------------------------------------------------------------------------------------------------------
-- Calibrate the CT holding table
-----------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#CTHolding') IS NOT NULL DROP TABLE #CTHolding;
SELECT 
	d.PartitionID, 
	x.[filegroup_name],
	x.data_compression_desc, 
	d.[Rows], 
	TranDate = DATEADD(MONTH,DATEDIFF(MONTH,0,TranDate),0),
	rn = ROW_NUMBER() OVER(ORDER BY PartitionID DESC)
INTO #CTHolding
FROM (
	SELECT 
		PartitionID = $PARTITION.PartitionByMonthFunction(Trandate), 
		TranDate = MIN(TranDate),
		[Rows] = COUNT(*)
	FROM [Relational].[ConsumerTransactionHolding] 
	GROUP BY $PARTITION.PartitionByMonthFunction(Trandate)
) d
OUTER APPLY (
	SELECT [filegroup_name], data_compression_desc FROM dbo.il_GetFilegroupName('ConsumerTransaction', d.PartitionID) WHERE index_name = 'PK_Relational_ConsumerTransaction_Partitioned'
) x
ORDER BY d.PartitionID DESC

EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable', 'Calibrated the CT holding table'

-- select * from #CTHolding


-----------------------------------------------------------------------------------------------------------------
-- Load the partitions one at a time from the holding table #MR_holding
-----------------------------------------------------------------------------------------------------------------
EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable', 'Partitions loading'

DECLARE 
	@CurrentRow INT = 1, 
	@strPartitionID VARCHAR(3),
	@CurrentPartitionStart DATE, 
	@strThisPartitionStartDate VARCHAR(8),
	@strNextPartitionStartDate VARCHAR(8),
	@StrFilegroupSuffix VARCHAR(6),
	@filegroup_name VARCHAR(100),
	@data_compression_desc VARCHAR(200),
	@ShadowTable VARCHAR(200),
	@TimeNow DATETIME

WHILE 1 = 1 BEGIN
		
	SET @TimeNow = GETDATE() -- reset the timer

	SELECT 
		@strPartitionID = CAST(PartitionID AS VARCHAR(3)),
		@filegroup_name = [filegroup_name],
		@data_compression_desc = CASE WHEN PartitionID > 100 THEN 'PAGE' ELSE data_compression_desc END,
		@CurrentPartitionStart = TranDate, 
		@RowsAffected = [Rows] 
	FROM #CTHolding 
	WHERE rn = @CurrentRow 
	IF @@ROWCOUNT = 0 BREAK

	SELECT 
		@strThisPartitionStartDate = CONVERT(VARCHAR(8),@CurrentPartitionStart,112),
		@strNextPartitionStartDate = CONVERT(VARCHAR(8),DATEADD(MONTH,1,@CurrentPartitionStart),112)


	--------------------------------------------------------------------------------------------------------------------------
	-- Create the shadow table, drop it first if necessary
	--------------------------------------------------------------------------------------------------------------------------
	SET @ShadowTable = 'Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage'

	IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [Name] = 'ConsumerTransaction_p' + @strPartitionID + '_Stage')
	BEGIN
		-- check if the table has any content before dropping
		DECLARE @SQLString nvarchar(500) = N'SELECT @SourceRowCount = COUNT(*) FROM ' + @ShadowTable; 
		DECLARE @ParmDefinition nvarchar(500) = N'@SourceRowCount varchar(30) OUTPUT';   
		DECLARE @RowCount INT; 

		EXECUTE sp_executesql @SQLString, @ParmDefinition, @SourceRowCount = @RowCount OUTPUT; PRINT @RowCount; 
		IF @RowCount > 0 BEGIN
			-- Log it, raise an error and return

			RETURN -1
		END

		EXEC('DROP TABLE ' + @ShadowTable) -- CJM 20190608
	END
	
	EXEC Staging.PartitionSwitching_CreateShadowTable_CJM @strPartitionID, @strThisPartitionStartDate, @strNextPartitionStartDate, @filegroup_name, @data_compression_desc




	--------------------------------------------------------------------------------------------------------------------------
	-- Disable constraints & indexes on the shadow table - csx_stuff is READONLY, everything else is for perf.
	-- should this be AFTER the switch step???
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE ' + @ShadowTable + ' NOCHECK CONSTRAINT ALL')
	EXEC('ALTER INDEX csx_Stuff ON ' + @ShadowTable + ' DISABLE') -- new cjm
	IF @RowsAffected > 1000 BEGIN -- if the rowcount exceeds a threshold, disable the indexes
		EXEC('ALTER INDEX IX_ConsumerTransaction_MainCover ON ' + @ShadowTable + ' DISABLE')
		EXEC('ALTER INDEX IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery ON ' + @ShadowTable + ' DISABLE')
	END


	--------------------------------------------------------------------------------------------------------------------------
	-- Switch live data to the shadow table for the partition of interest
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE Relational.ConsumerTransaction SWITCH PARTITION ' + @strPartitionID + ' TO ' + @ShadowTable) 


	--------------------------------------------------------------------------------------------------------------------------
	-- Load the switch table with new data from the transaction holding table 
	--------------------------------------------------------------------------------------------------------------------------
	EXEC(
		'INSERT INTO ' + @ShadowTable + ' WITH (TABLOCKX) (
			[FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], 
			[TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID], [Currency])
		SELECT [FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], 
			[TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID], [Currency] = ''GBP''
		FROM [Relational].[ConsumerTransactionHolding] 
		WHERE [TranDate] >= ''' + @strThisPartitionStartDate + ''' AND [TranDate] < ''' + @strNextPartitionStartDate + '''')


	--------------------------------------------------------------------------------------------------------------------------
	-- Re-enable all constraints and indexes. Note that CheckTranDate has to be "trusted" i.e. entire shadow table must be checked.
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE ' + @ShadowTable + ' CHECK CONSTRAINT ALL')
	EXEC('ALTER TABLE ' + @ShadowTable + ' WITH CHECK CHECK CONSTRAINT CheckTranDate_p' + @strPartitionID) 
	EXEC('ALTER INDEX csx_Stuff ON ' + @ShadowTable + ' REBUILD')
	IF @RowsAffected > 1000 BEGIN -- if the rowcount exceeds a threshold, rebuild the disabled indexes
		EXEC('ALTER INDEX IX_ConsumerTransaction_MainCover ON ' + @ShadowTable + ' REBUILD WITH (DATA_COMPRESSION = PAGE)')
		EXEC('ALTER INDEX IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery ON ' + @ShadowTable + ' REBUILD WITH (DATA_COMPRESSION = PAGE)')
	END


	--------------------------------------------------------------------------------------------------------------------------
	-- switch shadow table contents back to main table
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE ' + @ShadowTable + ' SWITCH TO Relational.ConsumerTransaction PARTITION ' + @strPartitionID)

	SET @msg = 'Loaded partition ' + @strPartitionID + ' [' + CAST(@RowsAffected AS VARCHAR(10)) + '] in ' + CAST(CAST(GETDATE() - @TimeNow AS TIME(0)) AS VARCHAR(8)) + ' ' + CASE WHEN @RowsAffected > 50000 THEN 'Indexes disabled' ELSE '' END
	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_CJM', @msg


	--------------------------------------------------------------------------------------------------------------------------
	-- drop the shadow table, we're finished with it 
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('DROP TABLE ' + @ShadowTable)

	SET @CurrentRow = @CurrentRow + 1

END

EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable', 'All partitions loaded'

--END


RETURN 0


