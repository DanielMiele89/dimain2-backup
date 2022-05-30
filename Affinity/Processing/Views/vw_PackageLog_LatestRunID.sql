CREATE VIEW [Processing].[vw_PackageLog_LatestRunID]
AS
	SELECT
		PackageID
		, SourceID
		, MAX(RunID) AS LatestRunID
		, MAX(RunStartDateTime) LatestRunStartDateTime
	FROM Processing.Package_Log
	GROUP BY PackageID, SourceID

