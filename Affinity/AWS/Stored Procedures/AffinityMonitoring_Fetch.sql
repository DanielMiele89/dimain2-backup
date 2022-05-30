﻿

CREATE PROCEDURE [AWS].[AffinityMonitoring_Fetch]
AS
BEGIN
		SELECT
		ID
		, RunID
		, OverallID
		, PackageID
		, SourceID
		, SourceName
		, RunStartDateTime
		, RunEndDateTime
		, FileDate
		, RowCnt
		, [DD HH:MM:SS]
		, SecondsDuration
		, SourceTypeID
		, SourceType
		, isEntryPoint
		, REPLACE(ErrorDetails, CHAR(10), ' ') ErrorDetails
		, traceHasError
		, sourceHasError
	FROM Processing.vw_PackageLog


END