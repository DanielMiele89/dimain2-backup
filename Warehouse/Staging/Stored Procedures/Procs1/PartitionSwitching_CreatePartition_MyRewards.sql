CREATE PROCEDURE [Staging].[PartitionSwitching_CreatePartition_MyRewards] 
	WITH EXECUTE AS OWNER
AS

SET NOCOUNT ON

-- This program is now redundant, partition maint is pperformed in PartitionSwitching_LoadCTtable_MyRewards
RETURN 0

/*******************************************************************************
This script is to perform regular (monthly) partition maintenance
The tasks it performs are...
	1) Create a new filegroup for the month after next
	2) Add a data file to the filegroup
	3) Add the new filegroup to the partition scheme as NEXTUSED
	4) Split the partitioning function
	5) Create the new shadow table
*******************************************************************************/

-- Which database are we changing and where the extra files will live
DECLARE @databasename NVARCHAR(256) = DB_NAME(); 
DECLARE @databasepath NVARCHAR(256) = CASE 
	WHEN @@SERVERNAME = 'DIMAIN' AND @databasename = 'Warehouse' THEN N'D:\MSSQL\DATA'
	WHEN @@SERVERNAME = 'DIDEVTEST' AND @databasename = 'Warehouse' THEN N'D:\SQL\Data\MSSQL11.MSSQLSERVER\MSSQL\DATA'
	WHEN @@SERVERNAME = 'DIDEVTEST' AND @databasename = 'Warehouse_Dev' THEN N'D:\SQL\Data\MSSQL11.MSSQLSERVER\MSSQL\DATA'
	ELSE NULL END;

-- Initial size and growth of the new database file
DECLARE 
	@FileSize NVARCHAR(8) = '10GB',
	@FileGrowth NVARCHAR(8) = '2GB';

DECLARE 
	@SplitFunction NVARCHAR(MAX),
	@AddFileGroups NVARCHAR(MAX),
	@AddFiles NVARCHAR(MAX),
	@AlterScheme NVARCHAR(MAX);

DECLARE 
	@EmailSubject VARCHAR(256),
	@EmailBody VARCHAR(2048);

-------------------------------------------------------------------
-- Run on the first day of this month to create structures for next month
 DECLARE @FirstOfNextMonth DATETIME = DATEADD(MONTH,1+DATEDIFF(MONTH,0,GETDATE()),0) -- first day of next month LIVE
--DECLARE @FirstOfNextMonth DATETIME = '20181101' -- testing

DECLARE 	 
	@NewPartition VARCHAR(3) = CAST(DATEDIFF(MONTH,'20110501',@FirstOfNextMonth) AS VARCHAR(3)), 
	@NewFileGroup VARCHAR(16) = 'fgCTransR' + CONVERT(VARCHAR(6),@FirstOfNextMonth,112),
	@TrandateStart VARCHAR(8) = CONVERT(VARCHAR(8),@FirstOfNextMonth,112),
	@TranDateEnd VARCHAR(8) = CONVERT(VARCHAR(8),DATEADD(MONTH,1,@FirstOfNextMonth),112)

-- If there isn't yet a partition for the month parameter then $PARTITION
-- will return the highest partition number
DECLARE @NewPartitionCheck VARCHAR(3) = $PARTITION.PartitionByMonthFunction_CTR(@TrandateStart)+1

DECLARE 
	@FileGroupExists BIT, 
	@ShadowTableExists BIT,
	@Partition_Number_Mismatch BIT 
SELECT @FileGroupExists = 1 FROM sys.filegroups WHERE [Name] = @NewFileGroup -- 1 if exists, NULL if it doesn't
SELECT @ShadowTableExists = 1 FROM SYS.TABLES WHERE [Name] = 'ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage' -- 1 if exists, NULL if it doesn't
--SELECT @Partition_Number_Mismatch = CASE WHEN @NewPartition = @NewPartitionCheck THEN NULL ELSE 1 END

SELECT
	NewPartition = @NewPartition, NewPartitionCheck = @NewPartitionCheck,
	NewFileGroup = @NewFileGroup, @FileGroupExists, 
	ShadowTable = 'ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage', @ShadowTableExists, 
	@Partition_Number_Mismatch

-------------------------------------------------------------------

IF --@Partition_Number_Mismatch IS NULL AND 
	@FileGroupExists IS NULL
BEGIN

	PRINT 'Creating filegroup'

	-- 1) Create a new filegroup
	SET @AddFileGroups = 'ALTER DATABASE ' + @databasename + ' ADD FILEGROUP ' + @NewFileGroup + ';';
	--PRINT @AddFileGroups;
	EXEC sp_executesql @AddFileGroups;


	-- 2) Add a data file to the filegroup
	SET @AddFiles = 'ALTER DATABASE ' + @databasename + ' ADD FILE (NAME = ' + @NewFileGroup + ', FILENAME = ''' + @databasepath + '\' + @databasename + '_' + @NewFileGroup + '.ndf'', SIZE=' + @FileSize + ', FILEGROWTH=' + @FileGrowth + ') TO FILEGROUP ' + @NewFileGroup + '; ';
	--PRINT @AddFiles;
	EXEC sp_executesql @AddFiles;


	-- 3) Add the filegroup to the partition scheme as NEXT USED
	SET @AlterScheme = 'ALTER PARTITION SCHEME PartitionByMonthScheme_CTR NEXT USED ' + @NewFileGroup + ';'
	--PRINT @AlterScheme;
	EXEC sp_executesql @AlterScheme;


	-- 4) Split the partitioning function
	SET @SplitFunction = 'ALTER PARTITION FUNCTION PartitionByMonthFunction_CTR() SPLIT RANGE (N''' + CONVERT(NVARCHAR, @TrandateStart, 126) + ''');';
	--PRINT @SplitFunction;
	EXEC sp_executesql @SplitFunction;

END

IF --@Partition_Number_Mismatch IS NULL AND 
	@ShadowTableExists IS NULL
BEGIN 

	PRINT 'Creating shadow table'

	-- 5) Create the shadow table in the new filegroup
	EXEC ('
		CREATE TABLE [Relational].[ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage] (
			[FileID] [int] NOT NULL,
			[RowNum] [int] NOT NULL,
			[ConsumerCombinationID] [int] NOT NULL,
			[CardholderPresentData] [tinyint] NOT NULL,
			[TranDate] [date] NOT NULL,
			[CINID] [int] NOT NULL,
			[Amount] [money] NOT NULL,
			[IsOnline] [bit] NOT NULL,
			[PaymentTypeID] [tinyint] NOT NULL,
		 CONSTRAINT [PK_ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage] 
		 PRIMARY KEY NONCLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (FILLFACTOR = 85) ON [' + @NewFileGroup + ']
		) ON [' + @NewFileGroup + ']
	')

	EXEC('ALTER TABLE [Relational].[ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage] WITH CHECK ADD CONSTRAINT CheckTranDate_R_p' + @NewPartition + ' CHECK (TranDate >= ''' + @TrandateStart + ''' AND TranDate < ''' + @TrandateEnd + ''')')
	EXEC('ALTER TABLE [Relational].[ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage] CHECK CONSTRAINT [CheckTranDate_R_p' + @NewPartition + ']')
	EXEC('CREATE CLUSTERED INDEX [cx_CT] ON [Relational].[ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage] ([TranDate] ASC,[CINID] ASC,[ConsumerCombinationID] ASC) WITH (FILLFACTOR = 85)')
	EXEC('CREATE      INDEX [ix_Stuff01] ON [Relational].[ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage] ([TranDate] ASC,[ConsumerCombinationID] ASC) INCLUDE ([Amount],[IsOnline],[CINID]) WITH (FILLFACTOR = 85)')

END


------------------------------------------------------------------------------------------------
-- Collect the names of the indexes on the shadow table
------------------------------------------------------------------------------------------------
DECLARE @IndexNames VARCHAR(4000) = ''

SELECT @IndexNames = @IndexNames + i.[name] + CHAR(10)
FROM sys.tables t
INNER JOIN sys.indexes i 
	ON i.object_id = t.object_id
WHERE t.[name] = 'ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage'
ORDER BY i.[name]


IF @FileGroupExists = 1 OR @ShadowTableExists = 1
BEGIN
	------------------------------------------------------------------------------------------------
	--Prepare an email listing issues
	------------------------------------------------------------------------------------------------
	SET @EmailSubject = '[' + @@SERVERNAME + '] Warning: Warehouse MyRewards Partitioning';
	SET @EmailBody = 'There were issues with the monthly partitioning update process. ' + CHAR(10) + CHAR(10)
		+ CASE 
			WHEN @FileGroupExists = 1       THEN '    The filegroup ' + @NewFileGroup + ' already exists.'
			ELSE '    The filegroup ' + @NewFileGroup + ' was created.' END + CHAR(10) + CHAR(10) 
		+ CASE WHEN @ShadowTableExists = 1     THEN '    The corresponding shadow table [Relational].[ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage] already exists.' ELSE '' END
		+ CASE WHEN @ShadowTableExists IS NULL THEN '    The corresponding shadow table [Relational].[ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage] was created.' ELSE '' END

	SET @EmailBody = @EmailBody + CHAR(10) 
			+ '    The ' + CASE WHEN @ShadowTableExists IS NULL THEN 'new' ELSE '' END + ' shadow table has these indexes:' + CHAR(10)
			+ @IndexNames;

	PRINT @EmailBody

END
ELSE
BEGIN
	------------------------------------------------------------------------------------------------
	--Prepare an email saying it's done
	------------------------------------------------------------------------------------------------
	SET @EmailSubject = '[' + @@SERVERNAME + '] Success: Warehouse MyRewards Partitioning updated';
	SET @EmailBody = 'The Warehouse Partitioning scheme has been successfully updated.

		The new filegroup is called ' + @NewFileGroup + '.
		The Partitioning function has been split at ' + CONVERT(NVARCHAR, @TrandateStart, 126) + '.

		The corresponding shadow table [Relational].[ConsumerTransaction_MyRewards_p' + @NewPartition + '_Stage] was created.
		The new shadow table has these indexes:' + CHAR(10)
		+ @IndexNames;

	PRINT @EmailBody

END


------------------------------------------------------------------------------------------------
--Send the email
------------------------------------------------------------------------------------------------
EXEC msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	--@recipients = 'dev@rewardinsight.com;ed.allison@rewardinsight.com',
	@recipients = 'Christopher.Morris@rewardinsight.com',
	@subject = @EmailSubject,
	@body = @EmailBody,
	@body_format = 'TEXT',
	@exclude_query_output = 1;


 RETURN 0