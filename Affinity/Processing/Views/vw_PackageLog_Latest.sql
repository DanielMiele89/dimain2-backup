

CREATE VIEW [Processing].[vw_PackageLog_Latest]
AS
	SELECT TOP 100000 * FROM [Processing].vw_PackageLog vpl
	WHERE vpl.RunID = (SELECT MAX(RunID) FROM Processing.vw_PackageLog vpl1)
	ORDER BY vpl.RunStartDateTime


