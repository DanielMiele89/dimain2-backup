/*
Logging, of a sort, of table/index usage, using index read/write system tables.
If an index isn't currently used, then the LastUpdate column will be either null 
(meaning it's not been used since the beginning of data capture, September 2018) or 
it will have a date from the last SQL Server service cycle when it was accessed, 
since these tables are cleared when the service is stopped.
This program only needs to run just before the service is stopped. 
In practice it's probably sufficient to run it on sunday evenings. 
It's quite lightweight, taking about a second to run.
*/
CREATE PROCEDURE [dbo].[WhenWasThisTableLastUsed]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


IF OBJECT_ID('tempdb..#TableData') IS NOT NULL DROP TABLE #TableData;
CREATE TABLE #TableData (
	[DB] VARCHAR(50) NOT NULL,
	[object_id] BIGINT NOT NULL,
	[index_id] BIGINT NOT NULL,
	[LastUpdate] DATETIME NOT NULL,
	[Table Name] VARCHAR(100) NOT NULL,
	[Table Rows] BIGINT NOT NULL,
	[Index Name] VARCHAR(100) NULL,
	[IndexType] VARCHAR(50) NOT NULL,
	[Writes] INT NOT NULL,
	[Reads] INT NOT NULL
	)


------------------------------------------------------------------------------------
--- Index Read/Write stats (all tables in Warehouse DB)   
------------------------------------------------------------------------------------
INSERT INTO #TableData
EXECUTE('USE Warehouse; SELECT 
	DB = ''Warehouse'',
	[object_id], 
	index_id,
	LastUpdate = GETDATE(),
	[Table Name], 		
	[Table Rows],
	[Index Name], 
	[IndexType],
	[Writes] = SUM([Writes]), 
	[Reads] = SUM([Reads])
FROM (
	SELECT 
		i.[object_id], 
		i.index_id,
		[Table Name] = OBJECT_SCHEMA_NAME(i.[object_id]) + ''.'' + OBJECT_NAME(i.[object_id]), 		
		p.[Table Rows],
		[Index Name] = i.name, 
		[IndexType] = i.[type_desc],
		[Writes] = ISNULL(s.user_updates,0), 
		[Reads] = ISNULL(s.user_seeks + s.user_scans + s.user_lookups,0)
	FROM sys.indexes AS i 
	left JOIN sys.dm_db_index_usage_stats AS s 
			ON i.[object_id] = s.[object_id]
			AND i.index_id = s.index_id
	OUTER APPLY (
		SELECT SUM(p.rows) AS [Table Rows] 
		FROM sys.partitions AS p 
		WHERE p.[object_id] = i.[object_id]
	) p
	WHERE i.[object_id] > 10000 AND p.[Table Rows] IS NOT NULL
) d
GROUP BY [object_id], index_id, [Table Name], [Table Rows], [Index Name], [IndexType] 
')  


------------------------------------------------------------------------------------
--- Index Read/Write stats (all tables in nFI DB)   
------------------------------------------------------------------------------------
INSERT INTO #TableData
EXECUTE('USE nFI; SELECT 
	DB = ''nFI'',
	[object_id], 
	index_id,
	LastUpdate = GETDATE(),
	[Table Name], 		
	[Table Rows],
	[Index Name], 
	[IndexType],
	[Writes] = SUM([Writes]), 
	[Reads] = SUM([Reads])
FROM (
	SELECT 
		i.[object_id], 
		i.index_id,
		[Table Name] = OBJECT_SCHEMA_NAME(i.[object_id]) + ''.'' + OBJECT_NAME(i.[object_id]), 		
		p.[Table Rows],
		[Index Name] = i.name, 
		[IndexType] = i.[type_desc],
		[Writes] = ISNULL(s.user_updates,0), 
		[Reads] = ISNULL(s.user_seeks + s.user_scans + s.user_lookups,0)
	FROM sys.indexes AS i 
	left JOIN sys.dm_db_index_usage_stats AS s 
			ON i.[object_id] = s.[object_id]
			AND i.index_id = s.index_id
	OUTER APPLY (
		SELECT SUM(p.rows) AS [Table Rows] 
		FROM sys.partitions AS p 
		WHERE p.[object_id] = i.[object_id]
	) p
	WHERE i.[object_id] > 10000 AND p.[Table Rows] IS NOT NULL
) d
GROUP BY [object_id], index_id, [Table Name], [Table Rows], [Index Name], [IndexType] 
')  


INSERT INTO dbo.TableUsageData ([DB], [object_id], [index_id], 
	[LastUpdate], 
	[Table Name], [Table Rows], [Index Name], [IndexType], [Writes], [Reads])
SELECT [DB], [object_id], [index_id], 
	[LastUpdate] = CASE WHEN [Writes] + [Reads] = 0 THEN NULL ELSE GETDATE() END, 
	[Table Name], [Table Rows], [Index Name], [IndexType], [Writes], [Reads] 
FROM #TableData tt
WHERE NOT EXISTS (
	SELECT 1 
	FROM dbo.TableUsageData tu 
	WHERE tu.DB = tt.DB
	AND tu.[object_id] = tt.[object_id]
	AND tu.index_id = tt.index_id)

UPDATE tu SET
	LastUpdate = tt.LastUpdate,
	Writes = CASE WHEN tt.Writes > tu.Writes THEN tt.Writes ELSE tu.Writes END,
	Reads = CASE WHEN tt.Reads > tu.Reads THEN tt.Reads ELSE tu.Reads END
FROM dbo.TableUsageData tu
INNER JOIN #TableData tt
	ON tu.DB = tt.DB
	AND tu.[object_id] = tt.[object_id]
	AND tu.index_id = tt.index_id
WHERE (tu.LastUpdate IS NULL OR tu.LastUpdate < tt.LastUpdate)
	AND (tt.Writes > 0 OR tt.Reads > 0)


RETURN 0
