CREATE PROC [WHB].[_PartitionMaintenance_Transactions_AddNew]
AS
BEGIN
	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	DECLARE @DBName VARCHAR(100) = 'Finance'
		, @FileScheme VARCHAR(100) = 'FG_Transactions_[YEAR]'
		, @FileLocation VARCHAR(100) = 'D:\MSSQL\Data'
		, @PartitionSchemeName VARCHAR(100) = 'PS_Month'
		, @PartitionFunctionName VARCHAR(100) = 'PFn_Transactions_ByMonth'

	DECLARE @MaxPartitionDate DATETIME

	SELECT 
		@MaxPartitionDate = CONVERT(DATETIME,MAX(prv.[Value]),112)
	FROM sys.partition_range_values prv  
	JOIN sys.partition_functions pf    
		ON pf.function_id = prv.function_id  
	WHERE pf.[Name] = 'PFn_Transactions_ByMonth'

	WHILE @MaxPartitionDate < DATEADD(DAY,1,EOMONTH(GETDATE())) 
	BEGIN
		DECLARE @NewMonth DATE = DATEADD(MONTH,1,@MaxPartitionDate)
		DECLARE @NewYear VARCHAR(4) = YEAR(@NewMonth)
		DECLARE @FGName VARCHAR(100) = REPLACE(@FileScheme, '[YEAR]', @NewYear)

		IF @NewYear > YEAR(@MaxPartitionDate) 
		BEGIN -- Create next year's filegroup in November, if it doesn't already exist
			EXEC('ALTER DATABASE '+@DBName+' ADD FILEGROUP '+@FGName);
			EXEC('ALTER DATABASE '+@DBName+' ADD FILE (
				NAME = '+@DBName+'_'+@NewYear+', 
				FILENAME = '''+@FileLocation+'\'+@FGName+'.ndf'', 
				SIZE=10GB, 
				FILEGROWTH=10%) 
				TO FILEGROUP '+@FGName+'');
		END 
		EXEC('ALTER PARTITION SCHEME '+@PartitionSchemeName+' NEXT USED ' + @FGName);
		EXEC('ALTER PARTITION FUNCTION '+@PartitionFunctionName+'() SPLIT RANGE ('''+ @NewMonth + ''')');

		SELECT 
			@MaxPartitionDate = CONVERT(DATETIME,MAX(prv.[Value]),112)
		FROM sys.partition_range_values prv  
		JOIN sys.partition_functions pf    
			ON pf.function_id = prv.function_id  
		WHERE pf.[Name] = 'PFn_Transactions_ByMonth'

	END

	----------------------------------------------------------------------
	-- Reload PartitionInfo table
	----------------------------------------------------------------------
	EXEC WHB._PartitionMaintenance_PartitionInfo_Reload

	----------------------------------------------------------------------
	-- DEBUG: Check Partitions
	----------------------------------------------------------------------
	-- -- Check the results
	-- SELECT
	-- 	PartitionID = prv.boundary_id,
	-- 	PreviousBoundaryValue = LAG(prv.Value) OVER (PARTITION BY ps.name ORDER BY ps.name, boundary_id),
	-- 	ThisBoundaryValue = prv.value,
	-- 	[FileGroup] = fg.name
	-- FROM sys.partition_schemes ps
	-- INNER JOIN sys.destination_data_spaces dds
	-- 	ON dds.partition_scheme_id = ps.data_space_id
	-- INNER JOIN sys.filegroups fg
	-- 	ON dds.data_space_id = fg.data_space_id
	-- INNER JOIN sys.partition_functions f
	-- 	ON f.function_id = ps.function_id
	-- INNER JOIN sys.partition_range_values prv
	-- 	ON f.function_id = prv.function_id
	-- 	AND dds.destination_id = prv.boundary_id
	-- WHERE ps.name = 'PS_Month'
	-- ORDER BY prv.boundary_id DESC

		
	
END
