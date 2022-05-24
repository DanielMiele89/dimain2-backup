/*
Removes rows from Trans.ConsumerTransaction which have a trandate 
older than the beginning of the current month, five years ago. This takes about 10 seconds 
per partition.
*/
Create PROCEDURE [dbo].[ConsumerTransactionNibbler] AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

DECLARE @msg varchar(8000), @time1 datetime = GETDATE(), @SSMS BIT = 1;
EXEC master.dbo.oo_TimerMessageV2 'Started ConsumerTransaction nibbler', @time1 OUTPUT, @SSMS OUTPUT


-- If today is October 2021 then discard data which is September 2016 or earlier
DECLARE 
	@MinTranDate DATE = DATEADD(MONTH, DATEDIFF(MONTH,0,GETDATE())-60, 0),
	@Counter SMALLINT = 1;
--SELECT @MinTranDate 

IF OBJECT_ID('tempdb..#Partitions') IS NOT NULL DROP TABLE #Partitions;
;WITH PartitionData AS (
	SELECT
		PartitionID = pstats.partition_number,
		PartitionRowCount = pstats.row_count,
		PartitionFilegroupName = ds.name,
		ThisPartitionStartDate = CAST(ISNULL(prv.value,'2010-01-01 00:00:00.000') AS DATE),
		NextPartitionStartDate = CAST(LEAD(prv.value) OVER(PARTITION BY pstats.object_id ORDER BY pstats.object_id, pstats.partition_number) AS DATE) 
	FROM sys.dm_db_partition_stats AS pstats
	INNER JOIN sys.destination_data_spaces AS dds 
		ON pstats.partition_number = dds.destination_id
	INNER JOIN sys.data_spaces AS ds 
		ON dds.data_space_id = ds.data_space_id
	INNER JOIN sys.partition_schemes AS ps 
		ON dds.partition_scheme_id = ps.data_space_id
	INNER JOIN sys.partition_functions AS pf 
		ON ps.function_id = pf.function_id
	INNER JOIN sys.indexes AS i 
		ON pstats.object_id = i.object_id AND pstats.index_id = i.index_id AND dds.partition_scheme_id = i.data_space_id AND i.type <= 1 /* Heap or Clustered Index */
	LEFT JOIN sys.partition_range_values AS prv 
		ON pf.function_id = prv.function_id AND pstats.partition_number = (CASE pf.boundary_value_on_right WHEN 0 THEN prv.boundary_id ELSE (prv.boundary_id+1) END)
	WHERE pstats.object_id = OBJECT_ID('trans.consumertransaction')
)
SELECT * INTO #Partitions 
FROM PartitionData 
WHERE ThisPartitionStartDate < @MinTranDate 
	AND PartitionRowCount > 0
ORDER BY PartitionID ;
EXEC master.dbo.oo_TimerMessageV2 'Collected partition data', @time1 OUTPUT, @SSMS OUTPUT

--select * from #Partitions

DECLARE @strPartitionID VARCHAR(3), @ThisPartitionStartDate VARCHAR(8), @NextPartitionStartDate VARCHAR(8), @NewFilegroupSuffix VARCHAR(6), @SQL VARCHAR(8000), @PartitionFilegroupName VARCHAR(200);
SELECT @Counter = MIN(PartitionID) FROM #Partitions
WHILE 1 = 1 BEGIN
	SELECT 
		@strPartitionID = PartitionID, 
		@ThisPartitionStartDate = CONVERT(VARCHAR(8),ThisPartitionStartDate,112), 
		@NextPartitionStartDate = CONVERT(VARCHAR(8),NextPartitionStartDate,112),
		@NewFilegroupSuffix = RIGHT(PartitionFilegroupName,6),
		@PartitionFilegroupName = PartitionFilegroupName
	FROM #Partitions WHERE PartitionID = @Counter;
	IF @@ROWCOUNT = 0 BREAK;

	SET @msg = 'Processing partition ' + @strPartitionID + ', date ' + @ThisPartitionStartDate;
	EXEC master.dbo.oo_TimerMessageV2 @msg, @time1 OUTPUT, @SSMS OUTPUT;

	-- Create a switch table
	EXEC Staging.PartitionSwitching_CreateShadowTable @strPartitionID, @ThisPartitionStartDate, @NextPartitionStartDate, @NewFilegroupSuffix;

	-- Disable the columnstore index on the switch table
	EXEC('ALTER TABLE Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage NOCHECK CONSTRAINT ALL');
	IF @@SERVERNAME <> 'DIMAIN2' BEGIN
		EXEC('DROP INDEX csx_Stuff ON Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage');
	END

	-- Switch live data to the shadow table for the current partition
	EXEC('ALTER TABLE Trans.ConsumerTransaction SWITCH PARTITION ' + @strPartitionID + ' TO Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage'); 

	-- Remove the data from the shadow table
	EXEC('TRUNCATE TABLETrans.ConsumerTransaction_p' + @strPartitionID + '_Stage')
	EXEC master.dbo.oo_TimerMessageV2 'Truncated partition data', @time1 OUTPUT, @SSMS OUTPUT;


	-- Re-enable all constraints and indexes. Note that CheckTranDate has to be "trusted" i.e. entire shadow table must be checked.
	EXEC('ALTER TABLE Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage CHECK CONSTRAINT ALL');
	EXEC('ALTER TABLE Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage WITH CHECK CHECK CONSTRAINT CheckTranDate_p' + @strPartitionID); 
	IF @@SERVERNAME <> 'DIMAIN2' BEGIN
		EXEC('CREATE NONCLUSTERED COLUMNSTORE INDEX [csx_Stuff] ON Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage
			([TranDate], [CINID], [ConsumerCombinationID], [BankID], [LocationID], [Amount], [IsRefund], [IsOnline], [CardholderPresentData], [FileID], [RowNum])');
	END
	EXEC master.dbo.oo_TimerMessageV2 'Rebuilt shadow table indexes', @time1 OUTPUT, @SSMS OUTPUT;
	
	-- switch shadow table contents back to main table
	EXEC('ALTER TABLE Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage SWITCH TO Trans.ConsumerTransaction PARTITION ' + @strPartitionID);

	-- drop the shadow table, we're finished with it 
	EXEC('DROP TABLE Trans.ConsumerTransaction_p' + @strPartitionID + '_Stage');

	-- Resize the partition's filegroup to recover disk space
	IF @strPartitionID <> 46 EXEC('DBCC SHRINKFILE (' + @PartitionFilegroupName + ', 5)'); 
	EXEC master.dbo.oo_TimerMessageV2 'Resized partition filegroup', @time1 OUTPUT, @SSMS OUTPUT;

	SET @Counter = @Counter + 1;

END


RETURN 0