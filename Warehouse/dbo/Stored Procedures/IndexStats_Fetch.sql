CREATE PROCEDURE [dbo].[IndexStats_Fetch]
--WITH EXECUTE AS OWNER	
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- CJM 20161118

    DECLARE @TableID Int

	SELECT @TableID = MIN(TableID) FROM Staging.CardTransactionTableMonitor

	SELECT * INTO #IndexStats 
	FROM sys.dm_db_index_physical_stats(DB_ID(), @TableID, null, null, null)

	SELECT @TableID = MIN(TableID) FROM Staging.CardTransactionTableMonitor WHERE TableID > @TableID

	WHILE @TableID IS NOT NULL
	BEGIN

		INSERT INTO #IndexStats
		SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), @TableID, null, null, null)
		
		SELECT @TableID = MIN(TableID) FROM Staging.CardTransactionTableMonitor WHERE TableID > @TableID

	END


	SELECT s.name AS SchemaName
		  , t.name AS TableName
		  , i.name AS IndexName
		  , p.index_type_desc AS IndexType
		  , p.avg_fragmentation_in_percent AS FragmentationPercent
		  , u.user_seeks
		  , u.user_scans
		  , u.user_lookups
		  , u.last_user_seek
		  , u.last_user_scan
	FROM #IndexStats p
	INNER JOIN Staging.CardTransactionTableMonitor m ON p.object_id = m.TableID
	INNER JOIN sys.tables t ON m.TableID= t.object_id
	INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
	INNER JOIN sys.indexes i ON p.object_id = i.object_id and p.index_id = i.index_id
	INNER JOIN sys.dm_db_index_usage_stats u on u.database_id = DB_ID() 
		  and u.object_id = i.object_id and u.index_id = i.index_id

	ORDER BY s.name, t.name, p.index_type_desc, i.name
	            
	DROP TABLE #IndexStats

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[IndexStats_Fetch] TO [DB5\reportinguser]
    AS [dbo];


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[IndexStats_Fetch] TO [Ed]
    AS [dbo];

