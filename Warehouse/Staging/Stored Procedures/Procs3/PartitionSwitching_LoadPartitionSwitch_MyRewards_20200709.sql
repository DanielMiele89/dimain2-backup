/*
Note: indexes on the shadow table must exactly match the partition table
Note: the check constraint is REQUIRED for partition switching
Note: the shadow table is switched back to the partition in the calling program
*/
CREATE PROCEDURE [Staging].[PartitionSwitching_LoadPartitionSwitch_MyRewards_20200709]
	(@PartitionID INT, @ThisPartitionStartDate DATE)
	WITH EXECUTE AS OWNER
AS

BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadPartitionSwitch_MyRewards', 'Sub Started'

	DECLARE 
		@strThisPartitionStartDate VARCHAR(8) = CONVERT(VARCHAR(8),@ThisPartitionStartDate,112),
		@strNextPartitionStartDate VARCHAR(8) = CONVERT(VARCHAR(8),DATEADD(MONTH,1,@ThisPartitionStartDate),112),
		@strPartitionID VARCHAR(3) = CAST(@PartitionID AS VARCHAR(3))

	DECLARE @Time1 DATETIME = GETDATE(), @msg NVARCHAR(4000), @RowsAffected INT

	--------------------------------------------------------------------------------------------------------------------------
	-- 1. Ensure the switch table is empty
	-- 2. Move rows from partition n to the pn switch table. Partition n is now empty, the data is in the switch table.
	-- 3. Disable constraints & indexes on pn switch table 
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('TRUNCATE TABLE Relational.ConsumerTransaction_MyRewards_p' + @strPartitionID + '_Stage')
	EXEC('ALTER TABLE Relational.ConsumerTransaction_MyRewards SWITCH PARTITION ' + @strPartitionID + ' TO Relational.ConsumerTransaction_MyRewards_p' + @strPartitionID + '_Stage') 

	EXEC('ALTER TABLE Relational.ConsumerTransaction_MyRewards_p' + @strPartitionID + '_Stage NOCHECK CONSTRAINT ALL')
	EXEC('ALTER INDEX [ix_Stuff01] ON Relational.ConsumerTransaction_MyRewards_p' + @strPartitionID + '_Stage DISABLE')

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadPartitionSwitch_MyRewards', 'Partition - Constraints and indexes disabled'


	--------------------------------------------------------------------------------------------------------------------------
	-- Load the pn switch table with new data (from #Temp65 for this prototype)
	--------------------------------------------------------------------------------------------------------------------------

	DECLARE @STMT VARCHAR(8000) = 
		'INSERT INTO Relational.ConsumerTransaction_MyRewards_p' + @strPartitionID + '_Stage WITH (TABLOCKX) (
			[FileID],[RowNum],[ConsumerCombinationID],[CardholderPresentData],[TranDate],[CINID],[Amount],[IsOnline],[PaymentTypeID])
		SELECT 
			[FileID],[RowNum],[ConsumerCombinationID],[CardholderPresentData],[TranDate],cth.[CINID],[Amount],[IsOnline],[PaymentTypeID]=1
		FROM [Relational].[ConsumerTransactionHolding] cth
		INNER JOIN Relational.CINList c 
			ON c.CINID = cth.CINID
		INNER JOIN Relational.Customer cu 
			ON C.CIN = CU.SourceUID
		WHERE NOT EXISTS (SELECT 1 FROM MI.CINDuplicate d WHERE cu.FanID = d.FanID)
			AND [TranDate] >= ''' + @strThisPartitionStartDate + ''' AND [TranDate] < ''' + @strNextPartitionStartDate + '''' --PAYMENT TYPE 0 FOR DEBIT JEA 08/05/2018
																																--CORRECTED TO 1 FOR DEBIT JEA 24/09/2018
	
	--PRINT @STMT
	
	EXEC(@STMT)

	SET @RowsAffected = @@ROWCOUNT
	SET @msg = 'Switch-loaded ' + CAST(@RowsAffected AS VARCHAR(10)) + ' rows of data from ConsumerTransactionHolding' 
	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadPartitionSwitch_MyRewards', @msg


	--------------------------------------------------------------------------------------------------------------------------
	-- Re-enable all constraints. Note that CheckTranDate has to be "trusted" i.e. entire table must be checked
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE Relational.ConsumerTransaction_MyRewards_p' + @strPartitionID + '_Stage CHECK CONSTRAINT ALL')
	EXEC('ALTER TABLE Relational.ConsumerTransaction_MyRewards_p' + @strPartitionID + '_Stage WITH CHECK CHECK CONSTRAINT CheckTranDate_R_p' + @strPartitionID) 

	EXEC('ALTER INDEX      [cx_CT] ON Relational.ConsumerTransaction_MyRewards_p' + @strPartitionID + '_Stage REBUILD')
	EXEC('ALTER INDEX [ix_Stuff01] ON Relational.ConsumerTransaction_MyRewards_p' + @strPartitionID + '_Stage REBUILD')

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadPartitionSwitch_MyRewards', 'Sub Finished'

END