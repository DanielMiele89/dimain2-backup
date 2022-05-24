/*
Note: indexes on the shadow table must exactly match the partition table
Note: the check constraint is REQUIRED for partition switching
*/
CREATE PROCEDURE [Staging].[PartitionSwitching_LoadPartitionSwitch_20190412]
	(@PartitionID INT, @ThisPartitionStartDate DATE)
	WITH EXECUTE AS OWNER
AS

BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE 
		@strThisPartitionStartDate VARCHAR(8) = CONVERT(VARCHAR(8),@ThisPartitionStartDate,112),
		@strNextPartitionStartDate VARCHAR(8) = CONVERT(VARCHAR(8),DATEADD(MONTH,1,@ThisPartitionStartDate),112),
		@strPartitionID VARCHAR(3) = CAST(@PartitionID AS VARCHAR(3))

	DECLARE @Time1 DATETIME = GETDATE(), @msg NVARCHAR(4000)
	--DECLARE @Statement VARCHAR(8000) 


	--------------------------------------------------------------------------------------------------------------------------
	-- 1. Ensure the switch table is empty
	-- 2. Move rows from partition n to the pn switch table. Partition n is now empty, the data is in the switch table.
	-- 3. Disable constraints & indexes on pn switch table 
	--------------------------------------------------------------------------------------------------------------------------
	--SET @msg = 'Start PartitionSwitching, partition ' + @strPartitionID; EXEC Staging.oo_TimerMessage @msg, @Time1

	EXEC('TRUNCATE TABLE Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage')
	EXEC('ALTER TABLE Relational.ConsumerTransaction SWITCH PARTITION ' + @strPartitionID + ' TO Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage') 

	--EXEC Staging.oo_TimerMessage 'Disable constraints and indexes', @Time1

	EXEC('ALTER TABLE Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage NOCHECK CONSTRAINT ALL')
	EXEC('ALTER INDEX IX_ConsumerTransaction_MainCover ON Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage DISABLE')
	EXEC('ALTER INDEX IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery ON Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage DISABLE')
	-- 00:00:00

	EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad', 'Partition - Constraints and indexes disabled'
	--------------------------------------------------------------------------------------------------------------------------
	-- Load the pn switch table with new data (from #Temp65 for this prototype)
	--------------------------------------------------------------------------------------------------------------------------
	--SET @msg = 'Loading shadow table ' + @strPartitionID; EXEC Staging.oo_TimerMessage @msg, @Time1
	EXEC(
	'INSERT INTO Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage WITH (TABLOCKX) (
		[FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], 
		[TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID])
	SELECT [FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], 
		[TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID] 
	FROM [Relational].[ConsumerTransactionHolding] 
	WHERE [TranDate] >= ''' + @strThisPartitionStartDate + ''' AND [TranDate] < ''' + @strNextPartitionStartDate + '''')

	--SET @msg = 'Loaded shadow table ' + CAST(@PartitionID AS VARCHAR(3)) + '. Rows loaded = '+ CAST(@@ROWCOUNT AS VARCHAR(15)) ; EXEC Staging.oo_TimerMessage @msg, @Time1
	-- (50,000,000 rows affected) / 00:03:15 
	EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad', 'Partition - Loaded Shadow table'


	--------------------------------------------------------------------------------------------------------------------------
	-- Re-enable all constraints. Note that CheckTranDate has to be "trusted" i.e. entire table must be checked
	--------------------------------------------------------------------------------------------------------------------------
	--EXEC Staging.oo_TimerMessage 'Enable constraints etc', @Time1

	EXEC('ALTER TABLE Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage CHECK CONSTRAINT ALL')
	EXEC('ALTER TABLE Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage WITH CHECK CHECK CONSTRAINT CheckTranDate_p' + @strPartitionID) 
	--EXEC('ALTER INDEX PK_Relational_ConsumerTransaction_p' + @strPartitionID + '_Stage ON Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage REBUILD')
	EXEC('ALTER INDEX IX_ConsumerTransaction_MainCover ON Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage REBUILD')
	EXEC('ALTER INDEX IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery ON Relational.ConsumerTransaction_p' + @strPartitionID + '_Stage REBUILD')

	--EXEC Staging.oo_TimerMessage 'Constraints enabled', @Time1
	---- 00:01:05
	EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad', 'Partition - Constraints Emabled'

END