﻿/*
Note: indexes on the shadow table must exactly match the partition table
Note: the check constraint is REQUIRED for partition switching

Called by [Staging].[PartitionSwitching_LoadCTtable]
Calls Staging.PartitionSwitching_CreateShadowTable
*/
CREATE PROCEDURE [MIDI].[__PartitionSwitching_LoadPartitionSwitch_BAK_Archived]
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
	-- Create the shadow table, drop it first if necessary
	--------------------------------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [SYS].[TABLES].[Name] = 'ConsumerTransaction_p' + @strPartitionID + '_Stage')
	BEGIN
		-- check if the table has any content before dropping
		DECLARE @SQLString nvarchar(500) = N'SELECT @SourceRowCount = COUNT(*) FROM Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage'; 
		DECLARE @ParmDefinition nvarchar(500) = N'@SourceRowCount varchar(30) OUTPUT';   
		DECLARE @RowCount INT; 

		EXECUTE sp_executesql @SQLString, @ParmDefinition, @SourceRowCount = @RowCount OUTPUT; PRINT @RowCount; 
		IF @RowCount > 0 BEGIN
			-- Log it, raise an error and return

			RETURN -1
		END

		EXEC('DROP TABLE Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage') -- CJM 20190608
	END
	
	EXEC MIDI.PartitionSwitching_CreateShadowTable @strPartitionID, @strThisPartitionStartDate, @strNextPartitionStartDate, @NewFilegroupSuffix


	--------------------------------------------------------------------------------------------------------------------------
	-- Disable constraints & indexes on the shadow table - csx_stuff is READONLY, everything else is for perf.
	-- should this be AFTER the switch step???
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage NOCHECK CONSTRAINT ALL')
	EXEC('ALTER INDEX csx_Stuff ON Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage DISABLE') -- new cjm
	IF @Rows > 1000 BEGIN -- if the rowcount exceeds a threshold, disable the indexes
		EXEC('ALTER INDEX IX_ConsumerTransaction_MainCover ON Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage DISABLE')
		EXEC('ALTER INDEX IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery ON Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage DISABLE')
	END


	--------------------------------------------------------------------------------------------------------------------------
	-- Switch live data to the shadow table for the partition of interest
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE Trans.ConsumerTransaction SWITCH PARTITION ' + @strPartitionID + ' TO Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage') 


	--------------------------------------------------------------------------------------------------------------------------
	-- Load the switch table with new data from the transaction holding table 
	--------------------------------------------------------------------------------------------------------------------------
	EXEC(
		'INSERT INTO Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage WITH (TABLOCKX) (
			[FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], 
			[TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID])
		SELECT [FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], 
			[TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID] 
		FROM [MIDI].[ConsumerTransactionHolding] 
		WHERE [TranDate] >= ''' + @strThisPartitionStartDate + ''' AND [TranDate] < ''' + @strNextPartitionStartDate + '''')


	--------------------------------------------------------------------------------------------------------------------------
	-- Re-enable all constraints and indexes. Note that CheckTranDate has to be "trusted" i.e. entire shadow table must be checked.
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage CHECK CONSTRAINT ALL')
	EXEC('ALTER TABLE Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage WITH CHECK CHECK CONSTRAINT CheckTranDate_p' + @strPartitionID) 
	EXEC('ALTER INDEX csx_Stuff ON Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage REBUILD')
	IF @Rows > 1000 BEGIN -- if the rowcount exceeds a threshold, rebuild the disabled indexes
		EXEC('ALTER INDEX IX_ConsumerTransaction_MainCover ON Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage REBUILD WITH (DATA_COMPRESSION = PAGE)')
		EXEC('ALTER INDEX IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery ON Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage REBUILD WITH (DATA_COMPRESSION = PAGE)')
	END


	--------------------------------------------------------------------------------------------------------------------------
	-- switch shadow table contents back to main table
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage SWITCH TO Trans.ConsumerTransaction PARTITION ' + @strPartitionID)


	--------------------------------------------------------------------------------------------------------------------------
	-- drop the shadow table, we're finished with it 
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('DROP TABLE Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage')


END


RETURN 0

