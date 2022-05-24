CREATE VIEW [Monitor].[vw_PackageLog_Latest]
AS
	SELECT TOP 100 PERCENT * 
	FROM 
	(
		SELECT *, DENSE_RANK() OVER (PARTITION BY [vpl].[PackageID] ORDER BY [vpl].[RunID] DESC) rw
		FROM [Monitor].vw_PackageLog vpl
	) x
	WHERE rw = 1
	ORDER BY [x].[RunID] Desc, [x].[ID]
