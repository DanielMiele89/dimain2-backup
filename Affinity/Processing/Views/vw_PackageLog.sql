



CREATE VIEW [Processing].[vw_PackageLog]
AS

	SELECT
		ID
	  , RunID
	  , MIN(RunID) OVER (PARTITION BY CAST(DATEADD(HH, Processing.getTimeDiff(), pl.RunStartDateTime) AS DATE)) AS OverallID
	  , PackageID
	  , SourceID
	  , SourceName
	  , RunStartDateTime
	  , RunEndDateTime
	  , d.FileDate
	  , COALESCE(rx.childRowCnt, rw.scriptRowCnt, RowCnt)		AS RowCnt
	  , CONVERT(VARCHAR(12), d.diff / 60 / 60 / 24) + ' '
		+ RIGHT('0' + CONVERT(VARCHAR(12), d.diff / 60 / 60 % 24), 2) + ':'
		+ RIGHT('0' + CONVERT(VARCHAR(2), d.diff / 60 % 60), 2) + ':'
		+ RIGHT('0' + CONVERT(VARCHAR(2), d.diff % 60), 2) + '' AS [DD HH:MM:SS]
	  , d.diff													AS SecondsDuration
	  , pl.SourceTypeID
	  , pst.SourceType
	  , CASE WHEN SourceID = pl.PackageID THEN 1 ELSE 0 END AS isEntryPoint
	  , CAST(STUFF(
		(
			SELECT
				' | ' + ErrorDetails
			FROM Processing.Package_Errors pe
			WHERE pe.RunID = pl.RunID
				AND pe.PackageID = pl.PackageID
				AND pe.SourceID = pl.SourceID
			FOR XML PATH ('')
		)
		, 1, 3, '')	AS VARCHAR(MAX))											AS ErrorDetails
	  , COALESCE(rx.childIsErr, pl.isError)						AS traceHasError
	  , pl.isError AS sourceHasError
	  , sla.SLABreach1Time
	  , CASE WHEN sla.SLABreach1Time < pl.RunEndDateTime OR sla.SLABreach1Time IS NULL THEN 1 ELSE 0 END AS isSLA1Breached
	  , sla.SLABreach2Time
	  , CASE WHEN sla.SLABreach2Time < pl.RunEndDateTime OR sla.SLABreach2Time IS NULL THEN 1 ELSE 0 END AS isSLA2Breached
	FROM Processing.Package_Log pl
	JOIN Processing.Package_SourceType pst
		ON pl.SourceTypeID = pst.SourceTypeID
	OUTER APPLY (
		SELECT
			RowCnt
		FROM Processing.Package_Log plx
		WHERE pl.ID = plx.ID - 1
			AND plx.SourceName LIKE 'Script - Set RowCount%'
	) rw (scriptRowCnt)
	OUTER APPLY (
		SELECT
			SUM(RowCnt)
		  , CAST(MAX(CAST(plx.isError AS INT)) AS BIT)
		FROM Processing.Package_Log plx
		WHERE plx.SourceTypeID > pl.SourceTypeID
			AND plx.RunStartDateTime BETWEEN pl.RunStartDateTime AND pl.RunEndDateTime
			AND plx.RunID = pl.RunID
	) rx (childRowCnt, childIsErr)
	CROSS APPLY (
		SELECT
			DATEDIFF(SECOND, RunStartDateTime, RunEndDateTime)
			, CAST(DATEADD(HH, Processing.getTimeDiff(), pl.RunStartDateTime) AS DATE)
	) d (diff, FileDate)
	OUTER APPLY (
		SELECT DISTINCT
			DATEADD(HH, Processing.getSLATimeDiff(1)+ -Processing.getTimeDiff(), CAST(x.FileDate AS DATETIME)) AS SLABreach1Time
			, DATEADD(HH, Processing.getSLATimeDiff(2)+ -Processing.getTimeDiff(), CAST(x.FileDate AS DATETIME)) AS SLABreach2Time
		FROM Processing.Package_Log plx
		CROSS APPLY (
			SELECT CAST(DATEADD(HH, Processing.getTimeDiff(), plx.RunStartDateTime) AS DATE)
		) x(FileDate)
		WHERE plx.SourceID = '7A1A20EA-0FBC-439A-A366-19A4D06E1C94' 
			AND d.FileDate = x.FileDate
	) sla
	WHERE pl.SourceName NOT LIKE 'Script - Set RowCount%'
		AND pl.isArchived = 0




