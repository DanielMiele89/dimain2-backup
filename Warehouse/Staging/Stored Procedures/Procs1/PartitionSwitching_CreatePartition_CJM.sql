CREATE PROCEDURE [Staging].[PartitionSwitching_CreatePartition_CJM] 
	WITH EXECUTE AS OWNER
AS
-- THIS IS THE MODIFIED VERSION FOR 5TH OCTOBER 2018
SET NOCOUNT ON

/*****************************************************************************************
NOTE: this script sets up the following month - so, if today is the first of October, then 
next month (November) will be created.

The tasks it performs are...
	1) Create a new filegroup for next month (if today is Jan 1st, then create Feb filegroup)
	2) Add a data file to the new filegroup
	3) Add the new filegroup to the partition scheme as NEXTUSED
	4) Split the partitioning function
	5) Create a shadow table on this new partition

	The date constraint of the newly-created table partition will be 'the first of next 
	month to infinity' and this date range won't be closed off until the next partition 
	is created. Of course this won't match the corresponding shadow table which is constrained 
	to just one month (next month). There's no harm in creating the shadow table for 
	next month up front but attempting to use it for partition switching will fail with an 
	error that the constraints don't match.
*****************************************************************************************/

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


	--DECLARE @NextMonthStart DATETIME = DATEADD(MM, DATEDIFF(MM, 0, GETDATE()) + 2, 0); -- test version - comment out
DECLARE @NextMonthStart DATETIME = DATEADD(MM, DATEDIFF(MM, 0, GETDATE()) + 1, 0); -- Live version 
DECLARE @NewFilegroupSuffix VARCHAR(6) = LEFT(CONVERT(varchar, @NextMonthStart, 112), 6);

DECLARE 
	@SplitFunction NVARCHAR(MAX),
	@AddFileGroups NVARCHAR(MAX),
	@AddFiles NVARCHAR(MAX),
	@AlterScheme NVARCHAR(MAX);

DECLARE 
	@EmailSubject VARCHAR(256),
	@EmailBody VARCHAR(2048);

DECLARE
	@NewPartition VARCHAR(3) = CAST(DATEDIFF(MONTH,'20120501',@NextMonthStart) AS VARCHAR(3)), 
	@ThisPartitionStartDate VARCHAR(8) = CONVERT(VARCHAR(8), @NextMonthStart, 112), 
	@NextPartitionStartDate VARCHAR(8) = CONVERT(VARCHAR(8), DATEADD(MONTH, 1, @NextMonthStart), 112) 

DECLARE @FileGroupExists BIT
SELECT @FileGroupExists = 1 FROM sys.filegroups WHERE name = 'fgCTrans' + @NewFilegroupSuffix -- 1 if exists, NULL if it doesn't


IF @FileGroupExists IS NULL BEGIN 

	PRINT 'Creating filegroup'

	-- 1) Create a new filegroup
	SET @AddFileGroups = 'ALTER DATABASE ' + @databasename + ' ADD FILEGROUP fgCTrans' + @NewFilegroupSuffix + ';';
	--PRINT @AddFileGroups;
	EXEC sp_executesql @AddFileGroups;


	-- 2) Add a data file to the new filegroup
	SET @AddFiles = 'ALTER DATABASE ' + @databasename + ' ADD FILE (NAME = fgCTrans' + @NewFilegroupSuffix + ', FILENAME = ''' + @databasepath + '\' + @databasename + '_fgCTrans' + @NewFilegroupSuffix + '.ndf'', SIZE=' + @FileSize + ', FILEGROWTH=' + @FileGrowth + ') TO FILEGROUP fgCTrans' + @NewFilegroupSuffix + '; ';
	--PRINT @AddFiles;
	EXEC sp_executesql @AddFiles;


	-- 3) Add the new filegroup to the partition scheme as NEXTUSED
	SET @AlterScheme = 'ALTER PARTITION SCHEME PartitionByMonthScheme NEXT USED fgCTrans' + @NewFilegroupSuffix + ';'
	--PRINT @AlterScheme;
	EXEC sp_executesql @AlterScheme;


	-- 4) Split the partitioning function
	SET @SplitFunction = 'ALTER PARTITION FUNCTION PartitionByMonthFunction() SPLIT RANGE (N''' + CONVERT(NVARCHAR, @NextMonthStart, 126) + ''');';
	--PRINT @SplitFunction;
	EXEC sp_executesql @SplitFunction;

END


IF @FileGroupExists = 1 BEGIN
	------------------------------------------------------------------------------------------------
	--Prepare an email listing issues
	------------------------------------------------------------------------------------------------
	SET @EmailSubject = '[' + @@SERVERNAME + '] Warning: Warehouse Partitioning';
	SET @EmailBody = 'There were issues with the monthly partitioning update process. 
	
	    The filegroup fgCTrans' + @NewFilegroupSuffix + ' already exists.'; 

	PRINT @EmailBody

END
ELSE BEGIN
	------------------------------------------------------------------------------------------------
	--Prepare an email saying it's done
	------------------------------------------------------------------------------------------------
	SET @EmailSubject = '[' + @@SERVERNAME + '] Success: Warehouse Partitioning updated';
	SET @EmailBody = 'The Warehouse Partitioning scheme has been successfully updated.

		The new filegroup is called fgCTrans' + @NewFilegroupSuffix + '.
		The Partitioning function has been split at ' + CONVERT(NVARCHAR, @NextMonthStart, 126) + '.';

	PRINT @EmailBody

END


------------------------------------------------------------------------------------------------
--Send the email
------------------------------------------------------------------------------------------------
EXEC msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients = 'dev@rewardinsight.com;diprocesscheckers@rewardinsight.com;',
	--@recipients = 'dev@rewardinsight.com',
	@subject = @EmailSubject,
	@body = @EmailBody,
	@body_format = 'TEXT',
	@exclude_query_output = 1;


RETURN 0
