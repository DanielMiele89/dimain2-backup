CREATE VIEW [dbo].[vwTestSplitOwnership_2]
WITH SCHEMABINDING
AS
SELECT 
	t.Item, 
	[Owner] = ISNULL(x.[Owner], t.[Owner]) 
FROM dbo.TestSplitOwnership t
OUTER APPLY (
	SELECT DISTINCT [Owner] 
	FROM dbo.TestSplitOwnership i
	WHERE t.[Owner] = 'C' 
		AND i.Item <> t.Item
		AND i.[Owner] <> 'C'
) x