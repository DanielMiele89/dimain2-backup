/*
Note: indexes on the shadow table must exactly match the partition table
Note: the check constraint is REQUIRED for partition switching

Called by [Staging].[PartitionSwitching_LoadCTtable]
Calls Staging.PartitionSwitching_CreateShadowTable
*/
CREATE PROCEDURE [MIDI].[__PartitionSwitching_LoadPartitionSwitch_Archived]
	(@PartitionID INT, @ThisPartitionStartDate DATE, @Rows INT) 
	WITH EXECUTE AS OWNER
AS

BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE 
		@strThisPartitionStartDate VARCHAR(8) = CONVERT(VARCHAR(8),@ThisPartitionStartDate,112),
		@strNextPartitionStartDate VARCHAR(8) = CONVERT(VARCHAR(8),DATEADD(MONTH,1,@ThisPartitionStartDate),112),
		@strPartitionID VARCHAR(3) = CAST(@PartitionID AS VARCHAR(3))

	DECLARE @NewFilegroupSuffix VARCHAR(6) = LEFT(@strThisPartitionStartDate,6)


	--------------------------------------------------------------------------------------------------------------------------
	-- Change the date check constraint on the shadow table to match this partition
	--------------------------------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [Name] = 'ConsumerTransaction_shadow')
	BEGIN -- check if the table has any content 
		DECLARE @RowCount INT; 
		SELECT @RowCount = COUNT(*) FROM Trans.ConsumerTransaction_shadow; 
		IF @RowCount > 0 BEGIN -- Log it, raise an error and return

			RETURN -1
		END
	END

	ALTER TABLE [Trans].[ConsumerTransaction_shadow] DROP CONSTRAINT [CheckTranDate_shadow]
	EXEC('ALTER TABLE [Trans].[ConsumerTransaction_shadow] ADD CONSTRAINT CheckTranDate_shadow CHECK (TranDate >= ''' + @strThisPartitionStartDate + ''' AND TranDate < ''' + @strNextPartitionStartDate + ''')')
	ALTER TABLE [Trans].[ConsumerTransaction_shadow] CHECK CONSTRAINT [CheckTranDate_shadow]


	--------------------------------------------------------------------------------------------------------------------------
	-- Disable constraints & indexes on the shadow table - csx_stuff is READONLY, everything else is for perf.
	-- should this be AFTER the switch step???
	--------------------------------------------------------------------------------------------------------------------------
	ALTER TABLE Trans.ConsumerTransaction_shadow NOCHECK CONSTRAINT ALL
	ALTER INDEX csx_ConsumerTrans_shadow ON Trans.ConsumerTransaction_shadow DISABLE 
	IF @Rows > 1000 BEGIN -- if the rowcount exceeds a threshold, disable the indexes
		ALTER INDEX ix_ConsumerTrans_shadow_ConsumerCombinationID ON Trans.ConsumerTransaction_shadow DISABLE
		ALTER INDEX ix_ConsumerTrans_shadow_CINID ON Trans.ConsumerTransaction_shadow DISABLE
	END


	--------------------------------------------------------------------------------------------------------------------------
	-- Switch live data to the shadow table for the partition of interest
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE Trans.ConsumerTransaction SWITCH PARTITION ' + @strPartitionID + ' TO Trans.ConsumerTransaction_shadow') 


	--------------------------------------------------------------------------------------------------------------------------
	-- Load the switch table with new data from the transaction holding table 
	--------------------------------------------------------------------------------------------------------------------------
	INSERT INTO Trans.ConsumerTransaction_shadow WITH (TABLOCKX) (
		[FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], 
		[TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID])
	SELECT [FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], 
		[TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID] 
	FROM [MIDI].[ConsumerTransactionHolding] 
	WHERE [TranDate] >= @strThisPartitionStartDate AND [TranDate] <  @strNextPartitionStartDate 


	--------------------------------------------------------------------------------------------------------------------------
	-- Re-enable all constraints and indexes. Note that CheckTranDate has to be "trusted" i.e. entire shadow table must be checked.
	--------------------------------------------------------------------------------------------------------------------------
	ALTER TABLE Trans.ConsumerTransaction_shadow CHECK CONSTRAINT ALL
	ALTER TABLE Trans.ConsumerTransaction_shadow WITH CHECK CHECK CONSTRAINT CheckTranDate_shadow 
	ALTER INDEX csx_ConsumerTrans_shadow ON Trans.ConsumerTransaction_shadow REBUILD
	IF @Rows > 1000 BEGIN -- if the rowcount exceeds a threshold, rebuild the disabled indexes
		ALTER INDEX ix_ConsumerTrans_shadow_ConsumerCombinationID ON Trans.ConsumerTransaction_shadow REBUILD WITH (DATA_COMPRESSION = PAGE)
		ALTER INDEX ix_ConsumerTrans_shadow_CINID ON Trans.ConsumerTransaction_shadow REBUILD WITH (DATA_COMPRESSION = PAGE)
	END


	--------------------------------------------------------------------------------------------------------------------------
	-- switch shadow table contents back to main table
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE Trans.ConsumerTransaction_shadow SWITCH TO Trans.ConsumerTransaction PARTITION ' + @strPartitionID)


	--------------------------------------------------------------------------------------------------------------------------
	-- Truncate the shadow table, we're finished with the contents 
	--------------------------------------------------------------------------------------------------------------------------
	TRUNCATE TABLE Trans.ConsumerTransaction_p_Stage


END


RETURN 0

