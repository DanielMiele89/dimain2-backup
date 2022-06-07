CREATE PROCEDURE [dbo].[Reports_Indexing_PersistData]

AS

--- Index Read/Write stats (all tables in current DB) ordered by Writes  (Query 67) (Overall Index Usage - Writes)

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- not yet used
IF OBJECT_ID('tempdb..#TableList') IS NOT NULL DROP TABLE #TableList;CREATE TABLE #TableList (DbSchemaTableName VARCHAR(100), Tablename VARCHAR(50));
INSERT INTO #TableList (DbSchemaTableName, Tablename) VALUES ('[SLC].[dbo].[Fan]', 'Fan');

-- not yet used
IF OBJECT_ID('tempdb..#NewIndexList') IS NOT NULL DROP TABLE #NewIndexList;CREATE TABLE #NewIndexList (Indexname VARCHAR(200));
INSERT INTO #NewIndexList (Indexname) VALUES ('[PK_IssuerCustomer]');



DECLARE @Script VARCHAR(8000)
SET @Script = 'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	INSERT INTO monitor.dbo.Reporting_IndexUsage (DBName, [RunDate], TableName, [IndexName], [New], [Writes], [Reads], [IndexType])
	SELECT 
		DBName = DB_NAME(),
		[RunDate] = GETDATE(),
		[ObjectName] = OBJECT_NAME(i.[object_id]), 	
		[IndexName] = ISNULL(i.[name],''heap''), 
		[New] = 0,
		[Writes] = ISNULL(s.user_updates,-1), 
		[Reads] = ISNULL(s.user_seeks + s.user_scans + s.user_lookups,-1),
		[IndexType] = CASE WHEN i.is_primary_key = 1 THEN ''PRIMARY KEY '' ELSE '''' END + i.type_desc + CASE WHEN i.is_primary_key = 0 AND i.is_unique = 1 THEN '', UNIQUE'' ELSE '''' END
	FROM sys.indexes AS i 
	LEFT JOIN sys.dm_db_index_usage_stats AS s  
		ON s.[object_id] = i.[object_id]
		AND s.index_id = i.index_id
		AND OBJECTPROPERTY(s.[object_id],''IsUserTable'') = 1
	WHERE i.[object_id] > 100
	ORDER BY OBJECT_NAME(i.[object_id]), i.Name;'

EXEC('USE [Archive_Light];' + @Script) 
EXEC('USE [nFI];' + @Script) 
EXEC('USE [Sandbox];' + @Script) 
EXEC('USE [SLC_Report];' + @Script) 
EXEC('USE [Warehouse];' + @Script) 

SELECT RunDate, DBName, TableName, IndexName, New, Writes, Reads, IndexType 
FROM monitor.dbo.Reporting_IndexUsage
--WHERE TableName IN ('Pan','Fan')
ORDER BY DBName, TableName, IndexName, Rundate DESC


RETURN 0














