CREATE VIEW [Monitor].[vw_PackageLog_LatestRunID]
AS
	SELECT
		[Monitor].[Package_Log].[PackageID]
		, [Monitor].[Package_Log].[SourceID]
		, MAX([Monitor].[Package_Log].[RunID]) AS LatestRunID
		, MAX([Monitor].[Package_Log].[RunStartDateTime]) LatestRunStartDateTime
	FROM Monitor.Package_Log
	GROUP BY [Monitor].[Package_Log].[PackageID], [Monitor].[Package_Log].[SourceID]

