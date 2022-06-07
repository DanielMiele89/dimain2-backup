/****** Script for SelectTopNRows command from SSMS  ******/

CREATE PROCEDURE [dbo].[ListHugeUnusedTables]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- List tables (and indexes) which are unused since monitoring started and the table contains at least
-- a hundred million rows
SELECT [ID], [DB], [object_id], [index_id], [LastUpdate], [Table Name], [Index Name], [IndexType], [Table Rows], x.SpaceGB,
	[TotalSpaceGB] = SUM(x.SpaceGB) OVER(PARTITION BY [DB], [object_id])
FROM [Monitor].[dbo].[TableUsageData] o
CROSS APPLY (
	SELECT SpaceGB = CAST(ROUND(((SUM(a.total_pages) * 8) / (1024.00*1024)), 2) AS NUMERIC(36, 2)) 
	FROM warehouse.sys.partitions p 
	INNER JOIN warehouse.sys.allocation_units a ON p.partition_id = a.container_id
	WHERE o.object_id = p.OBJECT_ID AND o.index_id = p.index_id
) x
WHERE [Table Rows] > 100000000 
	AND NOT EXISTS (SELECT 1 FROM [Monitor].[dbo].[TableUsageData] i WHERE i.object_id = o.object_id AND i.LastUpdate IS NOT NULL)
ORDER BY [TotalSpaceGB] desc, [DB], [Table Name], [index_id]


RETURN 0


