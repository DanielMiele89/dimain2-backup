CREATE VIEW [Monitor].[vw_PackageLog_LatestRunID]
AS
	SELECT
		PackageID
		, SourceID
		, MAX(RunID) AS LatestRunID
		, MAX(RunStartDateTime) LatestRunStartDateTime
	FROM Monitor.Package_Log
	GROUP BY PackageID, SourceID