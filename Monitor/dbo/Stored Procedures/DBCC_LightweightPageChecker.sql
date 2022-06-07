CREATE PROCEDURE DBCC_LightweightPageChecker
/*
https://www.sqlservercentral.com/articles/a-faster-dbcc-checkdb
-- I. Stirk. ian_stirk@yahoo.com LightweightPageChecker utility...

Let me tell you all why I wrote this utility. I had a 5 terrabyte database, where the weekend DBCC 
CHECKDB typically took 10 hours to complete, and when there were problems it would sometimes take 
48 hours to complete before it gave me any indication of errors. During this time I decided it might be nice 
to get a head start on what the underlying problems were, and how serious (heap/clustered index
problems are much more troublesome). Using this utility, while the associated DBCC CHECKDB was
running on another box, allowed me to identify the severity of the error very quickly, and plan/implement 
corrective action.
*/
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

-- Ensure buffer pool is empty.
DBCC DROPCLEANBUFFERS

DECLARE @CheckIndexesSQL NVARCHAR(MAX)
DECLARE @StartOffset INT
DECLARE @Length INT


-- Get details of all heaps, clustered indexes and non-clustered indexes to check.
IF OBJECT_ID('tempdb..#IndexDetails') IS NOT NULL DROP TABLE #IndexDetails;
SELECT Bunch, CheckIndexesSQL = 'SELECT COUNT_BIG(*) AS ' 
		+ LEFT('[Table: ' + RIGHT(SPACE(5) + CAST(Bunch AS varchar(5)),5) + '  ' + SchemaName + '.' + TableName + '. Index: ' + ISNULL(IndexName, 'HEAP'),110) + '. ' 
		+ 'IndexId: ' + CAST(indid AS VARCHAR(3)) + '] ' 
		+ 'FROM ' 
		+ QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName) 
		+ ' WITH (INDEX(' + CAST(indid AS VARCHAR(3)) + '));'
INTO #IndexDetails
FROM (
	SELECT Bunch = CAST(ROW_NUMBER() OVER(ORDER BY s.name, t.name, i.index_id) AS INT), 
		[SchemaName] = s.[Name],
		[TableName] = t.[Name],
		indid = i.index_id,
		[IndexName] = i.[Name],
		i.has_filter,
		[Filter] = i.filter_definition
	FROM sys.indexes i
	INNER JOIN sys.tables t ON t.object_id = i.object_id
	INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
	WHERE t.type_desc = N'USER_TABLE'
		AND i.has_filter = 0
		AND is_disabled = 0
) d
ORDER BY Bunch -- Do heaps and clustered indexes first


DECLARE @Bunch INT = 1

IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;
	CREATE TABLE #Results (ID INT IDENTITY (1,1), [Rows] BIGINT, CheckIndexesSQL VARCHAR(8000));

DECLARE @ErrorMessage NVARCHAR(4000), @MaxID INT

WHILE 1 = 1 BEGIN

	SET @CheckIndexesSQL = ''


	-- Build SQL to read each page in each index (including clustered index).
	SELECT @CheckIndexesSQL = CheckIndexesSQL
	FROM #IndexDetails
	WHERE Bunch = @Bunch

	IF @@ROWCOUNT = 0 BREAK

	-- Print out every 100th row 
	IF @Bunch%100 = 0 PRINT @CheckIndexesSQL

	-- Do work.
	BEGIN TRY
		INSERT INTO #Results ([Rows]) 
			EXECUTE sp_executesql @CheckIndexesSQL

		SELECT @MaxID = MAX(ID) FROM #Results

		UPDATE #Results SET CheckIndexesSQL = @CheckIndexesSQL WHERE ID = @MaxID
	END TRY
	BEGIN CATCH
		SET @ErrorMessage = ERROR_MESSAGE()
		PRINT @ErrorMessage
		PRINT @CheckIndexesSQL

	END CATCH

	SET @Bunch = @Bunch + 1

END

SELECT * FROM #Results order by ID desc


RETURN 0

