CREATE PROCEDURE [Staging].[PartitionSwitching_CreatePartition_OLD] 
	WITH EXECUTE AS OWNER
AS

SET NOCOUNT ON

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

-- Which month we are adding
DECLARE @NextMonthStart DATETIME = DATEADD(MM, DATEDIFF(MM, 0, GETDATE()) + 1, 0) -- Live version - retain
--DECLARE @NextMonthStart DATETIME = DATEADD(MM, DATEDIFF(MM, 0, GETDATE()) + 2, 0) -- TESTING ONLY - REMOVE
DECLARE @NewMonthName VARCHAR(6) = LEFT(CONVERT(varchar, @NextMonthStart, 112), 6);;

DECLARE 
	@SplitFunction NVARCHAR(MAX),
	@AddFileGroups NVARCHAR(MAX),
	@AddFiles NVARCHAR(MAX),
	@AlterScheme NVARCHAR(MAX);

DECLARE 
	@EmailSubject VARCHAR(256),
	@EmailBody VARCHAR(2048);

DECLARE
	@NewPartition VARCHAR(3) = $PARTITION.PartitionByMonthFunction(@NextMonthStart),
	@ThisPartitionStartDate VARCHAR(8) = CONVERT(VARCHAR(8), @NextMonthStart, 112), 
	@NextPartitionStartDate VARCHAR(8) = CONVERT(VARCHAR(8), DATEADD(MONTH, 1, @NextMonthStart), 112) 

DECLARE 
	@FileGroupExists BIT, 
	@ShadowTableExists BIT 
SELECT @FileGroupExists = 1 FROM sys.filegroups WHERE name = 'fgCTrans' + @NewMonthName -- 1 if exists, NULL if it doesn't
SELECT @ShadowTableExists = 1 FROM SYS.TABLES WHERE NAME = 'ConsumerTransaction_p' + @NewPartition + '_Stage' -- 1 if exists, NULL if it doesn't


IF @FileGroupExists IS NULL
BEGIN 

	PRINT 'Creating filegroup'

	-- 1) Create a new filegroup
	SET @AddFileGroups = 'ALTER DATABASE ' + @databasename + ' ADD FILEGROUP fgCTrans' + @NewMonthName + ';';
	--PRINT @AddFileGroups;
	EXEC sp_executesql @AddFileGroups;


	-- 2) Add a data file to the filegroup
	SET @AddFiles = 'ALTER DATABASE ' + @databasename + ' ADD FILE (NAME = fgCTrans' + @NewMonthName + ', FILENAME = ''' + @databasepath + '\' + @databasename + '_fgCTrans' + @NewMonthName + '.ndf'', SIZE=' + @FileSize + ', FILEGROWTH=' + @FileGrowth + ') TO FILEGROUP fgCTrans' + @NewMonthName + '; ';
	--PRINT @AddFiles;
	EXEC sp_executesql @AddFiles;


	-- 3) Add the filegroup to the partition scheme as NEXTUSED
	SET @AlterScheme = 'ALTER PARTITION SCHEME PartitionByMonthScheme NEXT USED fgCTrans' + @NewMonthName + ';'
	--PRINT @AlterScheme;
	EXEC sp_executesql @AlterScheme;


	-- 4) Split the partitioning function
	SET @SplitFunction = 'ALTER PARTITION FUNCTION PartitionByMonthFunction() SPLIT RANGE (N''' + CONVERT(NVARCHAR, @NextMonthStart, 126) + ''');';
	--PRINT @SplitFunction;
	EXEC sp_executesql @SplitFunction;

END

IF @ShadowTableExists IS NULL
BEGIN 

	PRINT 'Creating shadow table'

	-- 5) Create the shadow table in the new filegroup
	EXEC ('
		CREATE TABLE [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage](
			[FileID] [int] NOT NULL,
			[RowNum] [int] NOT NULL,
			[ConsumerCombinationID] [int] NOT NULL,
			[SecondaryCombinationID] [int] NULL,
			[BankID] [tinyint] NOT NULL,
			[LocationID] [int] NOT NULL,
			[CardholderPresentData] [tinyint] NOT NULL,
			[TranDate] [date] NOT NULL,
			[CINID] [int] NOT NULL,
			[Amount] [money] NOT NULL,
			[IsRefund] [bit] NOT NULL,
			[IsOnline] [bit] NOT NULL,
			[InputModeID] [tinyint] NOT NULL,
			[PostStatusID] [tinyint] NOT NULL,
			[PaymentTypeID] [tinyint] NOT NULL,
		 CONSTRAINT [PK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage] PRIMARY KEY CLUSTERED 
		(
			[FileID] ASC,
			[RowNum] ASC,
			[TranDate] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
		) ON [fgCTrans' + @NewMonthName + ']
	')

	EXEC('ALTER TABLE [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage] ADD CONSTRAINT CheckTranDate_p' + @NewPartition + ' CHECK (TranDate >= ''' + @ThisPartitionStartDate + ''' AND TranDate < ''' + @NextPartitionStartDate + ''')')

	EXEC('ALTER TABLE [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage] ADD  CONSTRAINT [DF_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_PaymentTypeID]  DEFAULT ((1)) FOR [PaymentTypeID]')

	EXEC('ALTER TABLE [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage] WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_CardInputMode] FOREIGN KEY([InputModeID])
		REFERENCES [Relational].[CardInputMode] ([InputModeID])')

	EXEC('ALTER TABLE [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage] CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_CardInputMode]')

	EXEC('ALTER TABLE [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage] WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_Combination] FOREIGN KEY([ConsumerCombinationID])
		REFERENCES [Relational].[ConsumerCombination] ([ConsumerCombinationID])')

	EXEC('ALTER TABLE [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage] CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_Combination]')

	EXEC('ALTER TABLE [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage] WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_PostStatus] FOREIGN KEY([PostStatusID])
		REFERENCES [Relational].[PostStatus] ([PostStatusID])')

	EXEC('ALTER TABLE [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage] CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_PostStatus]')

	EXEC('CREATE NONCLUSTERED INDEX [IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery] ON [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage]
		([CINID] ASC,[TranDate] ASC) INCLUDE ([FileID],[RowNum],[ConsumerCombinationID],[LocationID],[Amount])')

	EXEC('CREATE NONCLUSTERED INDEX [IX_ConsumerTransaction_MainCover] ON [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage]
		([ConsumerCombinationID] ASC,[TranDate] ASC,[CINID] ASC,[IsOnline] ASC,[IsRefund] ASC,[BankID] ASC,[CardholderPresentData] ASC) INCLUDE ([Amount])')

END


------------------------------------------------------------------------------------------------
-- Collect the names of the indexes on the shadow table
------------------------------------------------------------------------------------------------
DECLARE @IndexNames VARCHAR(4000) = ''

SELECT @IndexNames = @IndexNames + i.[name] + CHAR(10)
FROM sys.tables t
INNER JOIN sys.indexes i 
	ON i.object_id = t.object_id
WHERE t.[name] = 'ConsumerTransaction_p' + @NewPartition + '_Stage'
ORDER BY i.[name]


IF @FileGroupExists = 1 OR @ShadowTableExists = 1
BEGIN
	------------------------------------------------------------------------------------------------
	--Prepare an email listing issues
	------------------------------------------------------------------------------------------------
	SET @EmailSubject = '[' + @@SERVERNAME + '] Warning: Warehouse Partitioning';
	SET @EmailBody = 'There were issues with the monthly partitioning update process. ' + CHAR(10) + CHAR(10)
		+ CASE 
			WHEN @FileGroupExists = 1       THEN '    The filegroup fgCTrans' + @NewMonthName + ' already exists.'
			ELSE '    The filegroup fgCTrans' + @NewMonthName + ' was created.' END + CHAR(10) + CHAR(10) 
		+ CASE WHEN @ShadowTableExists = 1     THEN '    The corresponding shadow table [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage] already exists.' ELSE '' END
		+ CASE WHEN @ShadowTableExists IS NULL THEN '    The corresponding shadow table [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage] was created.' ELSE '' END

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
	SET @EmailSubject = '[' + @@SERVERNAME + '] Success: Warehouse Partitioning updated';
	SET @EmailBody = 'The Warehouse Partitioning scheme has been successfully updated.

		The new filegroup is called fgCTrans' + @NewMonthName + '.
		The Partitioning function has been split at ' + CONVERT(NVARCHAR, @NextMonthStart, 126) + '.

		The corresponding shadow table [Relational].[ConsumerTransaction_p' + @NewPartition + '_Stage] was created.
		The new shadow table has these indexes:' + CHAR(10)
		+ @IndexNames;

	PRINT @EmailBody

END


------------------------------------------------------------------------------------------------
--Send the email
------------------------------------------------------------------------------------------------
EXEC msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients = 'dev@rewardinsight.com;ed.allison@rewardinsight.com;',
	--@recipients = 'dev@rewardinsight.com',
	@subject = @EmailSubject,
	@body = @EmailBody,
	@body_format = 'TEXT',
	@exclude_query_output = 1;


 RETURN 0