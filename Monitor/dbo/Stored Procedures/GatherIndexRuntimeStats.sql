CREATE PROCEDURE [dbo].[GatherIndexRuntimeStats]
AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE 
	@DatabaseID INT = DB_ID('SLC_REPL')

If Object_ID('tempdb..#TableList') Is Not Null Drop Table #TableList 
SELECT * INTO #TableList FROM (
VALUES 
	(OBJECT_ID('SLC_REPL.dbo.Trans'), 'SLC_REPL.dbo.Trans'),
	(OBJECT_ID('SLC_REPL.dbo.Fan'), 'SLC_REPL.dbo.Fan'),
	(OBJECT_ID('SLC_REPL.dbo.Match'), 'SLC_REPL.dbo.Match'),
	(OBJECT_ID('SLC_REPL.dbo.IronOfferMember'), 'SLC_REPL.dbo.IronOfferMember')
) d (ObjectID, TableName)  

-- Selected tables
INSERT INTO monitor.dbo.IndexRuntimeStats ([ReadDate], [TableName], [IndexName], fill_factor, [avg_fragmentation_in_percent], page_count)
SELECT 
	[ReadDate] = GETDATE(),
	OBJECT_NAME(i.object_id, @DatabaseID), 
	i.[Name], 
	i.fill_factor,
	ips.[avg_fragmentation_in_percent],
	ips.page_count
FROM SLC_REPL.sys.indexes i
OUTER APPLY (
	SELECT page_count, [avg_fragmentation_in_percent] = CAST(avg_fragmentation_in_percent AS DECIMAL(5,3)) 
	FROM sys.dm_db_index_physical_stats(@DatabaseID, i.object_id, i.index_id, NULL, N'LIMITED')
	WHERE i.is_disabled = 0
) ips
WHERE EXISTS (SELECT 1 FROM #TableList tl WHERE tl.ObjectID = i.object_id)

RETURN 0
