CREATE VIEW [dbo].[vwTestSplitOwnership]

AS
SELECT 
	[Item],
	[Owner]
FROM TestSplitOwnership
WHERE [Owner] <> 'C'

UNION ALL

SELECT 
	t.[Item],
	A.[Owner]
FROM TestSplitOwnership t
CROSS JOIN (
	SELECT DISTINCT [Owner]
	FROM   TestSplitOwnership
	WHERE  [Owner] <> 'C'
) AS A
WHERE t.[Owner] = 'C';
