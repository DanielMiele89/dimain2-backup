CREATE PROCEDURE [gas].[CTLoad_Module4_PartitionedTableLoad]

AS

SET NOCOUNT ON

	-------------------------------------------------------------------------------------------------------------------
	-- Load ConsumerTransactionForFile
	-------------------------------------------------------------------------------------------------------------------
	--INSERT INTO AWSFile.ConsumerTransactionForFile
	SELECT * FROM Relational.ConsumerTransactionHolding



	-------------------------------------------------------------------------------------------------------------------
	-- Partition Switching
	-------------------------------------------------------------------------------------------------------------------
	EXEC [Staging].[PartitionSwitching_LoadCTtable]



	-------------------------------------------------------------------------------------------------------------------
	-- CT Partition Completion Email
	-------------------------------------------------------------------------------------------------------------------
	EXEC msdb.dbo.sp_send_dbmail 
		@profile_name = 'Administrator', 
		@recipients='DIProcessCheckers@rewardinsight.com;DevDB@rewardinsight.com',
		@subject = 'ConsumerTransaction Partition Switching COMPLETE',
		@body='Notification email to confirm that the partition switching to ConsumerTransaction on DIMAIN has completed',
		@body_format = 'TEXT',  
		@exclude_query_output = 1



	-------------------------------------------------------------------------------------------------------------------
	-- Partition Switching CC
	-------------------------------------------------------------------------------------------------------------------
	EXEC [Staging].[PartitionSwitching_LoadCTtable_MyRewards]



	-------------------------------------------------------------------------------------------------------------------
	-- CT MyRewards Partition Completion Email
	-------------------------------------------------------------------------------------------------------------------
	EXEC msdb.dbo.sp_send_dbmail 
		@profile_name = 'Administrator', 
		@recipients='DIProcessCheckers@rewardinsight.com;DevDB@rewardinsight.com',
		@subject = 'ConsumerTransaction_MyRewards Partition Switching COMPLETE',
		@body='Notification email to confirm that the partition switching to ConsumerTransaction_MyRewards on DIMAIN has completed',
		@body_format = 'TEXT',  
		@exclude_query_output = 1


RETURN 0