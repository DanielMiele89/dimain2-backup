Create PROCEDURE [dbo].[PartitionTruncate_ConsumerTrans]
AS
BEGIN

declare @month date = DATEADD(YEAR, -5, GETDATE());
declare @partition_number int;
select @partition_number = $PARTITION.PartitionByMonthFunction(@month)

DECLARE @MinRange INT
	, @MaxRange INT

SELECT @minrange = min(partition_number), @maxrange = max(partition_number)
FROM sys.partitions
WHERE object_id = OBJECT_ID('relational.consumertransaction') and partition_number <= @partition_number

TRUNCATE TABLE Trans.ConsumerTransaction
	WITH (PARTITIONs (@MinRange TO @MaxRange));
END;