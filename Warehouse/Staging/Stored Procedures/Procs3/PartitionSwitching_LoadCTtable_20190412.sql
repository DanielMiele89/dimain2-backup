
/*
CJM 20180829 Added a few columns to the columnstore index
*/
CREATE PROCEDURE [Staging].[PartitionSwitching_LoadCTtable_20190412]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable', 'Program Started'

	DECLARE 
		@Time1 DATETIME = GETDATE(), 
		@msg NVARCHAR(4000), 
		@Statement VARCHAR(8000),
		@RowsAffected INT 
	EXEC Staging.oo_TimerMessage 'Start', @Time1

	IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'csx_Stuff' AND OBJECT_NAME([object_id]) = 'ConsumerTransaction') 
		DROP INDEX [csx_Stuff] ON [Relational].[ConsumerTransaction]

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable', 'Columnstore index dropped'

	-- Measure the CT holding table
	IF OBJECT_ID('tempdb..#CTHolding') IS NOT NULL DROP TABLE #CTHolding;
	SELECT PartitionID, [Rows], TranDate = DATEADD(MONTH,DATEDIFF(MONTH,0,TranDate),0),
		rn = ROW_NUMBER() OVER(ORDER BY PartitionID DESC)
	INTO #CTHolding
	FROM (
		SELECT 
			PartitionID = $PARTITION.PartitionByMonthFunction (Trandate), 
			TranDate = MIN(TranDate),
			[Rows] = COUNT(*)
		FROM [Relational].[ConsumerTransactionHolding] 
		GROUP BY $PARTITION.PartitionByMonthFunction(Trandate)
	) d
	ORDER BY PartitionID DESC

	DECLARE 
		@CurrentPartitionID INT, @LastPartitionID INT,
		@LastPartitionRowcount INT,
		@CurrentPartitionStart DATE, @LastPartitionStart DATE

	SELECT @CurrentPartitionID = PartitionID, @CurrentPartitionStart = TranDate FROM #CTHolding WHERE rn = 1
	SELECT @LastPartitionID = PartitionID, @LastPartitionRowcount = [Rows], @LastPartitionStart = TranDate FROM #CTHolding WHERE rn = 2

	--SET @msg = 'Finished checking data. ' + 
	--	'CT holding top date: ' + CAST(@CurrentPartitionStart AS NVARCHAR(20)) + ', ' + 
	--	'CT holding top partition: ' + CAST(@CurrentPartitionID AS NVARCHAR(5)) + ', ' + 
	--	'Rows in holding top-1 partition: ' + CAST(@LastPartitionRowcount AS NVARCHAR(5))
	--EXEC Staging.oo_TimerMessage @msg, @Time1
	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable', 'Partition - Holding Temp Table Loaded'


	-----------------------------------------------------------------------------------------------------------------
	-- If the "last" partition has enough rows, then load them by switching (leave switched out afterwards)
	-----------------------------------------------------------------------------------------------------------------
	IF @LastPartitionRowcount > 50000 
	EXEC [Staging].[PartitionSwitching_LoadPartitionSwitch] @LastPartitionID, @LastPartitionStart


	-----------------------------------------------------------------------------------------------------------------
	-- Load the current partition (leave switched out afterwards)
	-----------------------------------------------------------------------------------------------------------------
	EXEC [Staging].[PartitionSwitching_LoadPartitionSwitch] @CurrentPartitionID, @CurrentPartitionStart


	-----------------------------------------------------------------------------------------------------------------
	-- Load the remaining rows as conventional inserts directly into CT table
	-----------------------------------------------------------------------------------------------------------------
	DECLARE 
		@strLastPartitionStart VARCHAR(8),
		@strLastPartitionID VARCHAR(3) = CAST(@LastPartitionID AS VARCHAR(3)),
		@strCurrentPartitionID VARCHAR(3) = CAST(@CurrentPartitionID AS VARCHAR(3))


	IF @LastPartitionRowcount > 50000 
		SET @strLastPartitionStart = CONVERT(VARCHAR(8),@LastPartitionStart,112)
	ELSE
		SET @strLastPartitionStart = CONVERT(VARCHAR(8),@CurrentPartitionStart,112)

	--BEGIN TRAN -- TESTING ONLY ################################################
	EXEC('
		INSERT INTO Relational.ConsumerTransaction WITH (TABLOCKX) (
			[FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], 
			[TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID])
		SELECT [FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], 
			[TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID] 
		FROM [Relational].[ConsumerTransactionHolding] 
		WHERE [TranDate] < ''' + @strLastPartitionStart + ''' ')

	--SET @msg = 'Finished loading nonswitched data prior to ' + @strLastPartitionStart + '. Rows loaded = '+ CAST(@@ROWCOUNT AS VARCHAR(15))  
	--EXEC Staging.oo_TimerMessage @msg, @Time1
	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable', 'Partition - Loaded Non-switched data'
	--ROLLBACK TRAN -- TESTING ONLY ################################################  


	-----------------------------------------------------------------------------------------------------------------
	-- Switch partitions back in (this empties the shadow tables)
	-----------------------------------------------------------------------------------------------------------------
	-- Last partition
	IF @LastPartitionRowcount > 50000 
	EXEC('ALTER TABLE Relational.ConsumerTransaction_p' + @strLastPartitionID + '_Stage SWITCH TO Relational.ConsumerTransaction PARTITION ' + @strLastPartitionID)

	-- Current partition
	EXEC('ALTER TABLE Relational.ConsumerTransaction_p' + @strCurrentPartitionID + '_Stage SWITCH TO Relational.ConsumerTransaction PARTITION ' + @strCurrentPartitionID)


	-----------------------------------------------------------------------------------------------------------------
	-- Clear down Relational.ConsumerTransactionHolding
	-- switched off 20180504 ChrisM
	-----------------------------------------------------------------------------------------------------------------
	-- TRUNCATE TABLE [Relational].[ConsumerTransactionHolding]

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable', 'Creating columnstore index'

	CREATE NONCLUSTERED COLUMNSTORE INDEX [csx_Stuff] ON [Relational].[ConsumerTransaction]
	(
		   [TranDate],
		   [CINID],
		   [ConsumerCombinationID],
		   [BankID],
		   [LocationID],
		   [Amount],
		   [IsRefund],
		   [IsOnline],
			cardholderpresentdata, fileid, rownum -- new columns should give this index a wider audience CJM 20180829
	)WITH (DROP_EXISTING = OFF)

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable', 'Created columnstore index'

END