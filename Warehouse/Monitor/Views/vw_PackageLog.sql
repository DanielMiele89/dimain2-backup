
CREATE VIEW [Monitor].[vw_PackageLog]
AS

	SELECT
		ID
	  , RunID
	  , PackageID
	  , SourceID
	  , SourceName
	  , RunStartDateTime
	  , RunEndDateTime
	  , COALESCE(rx.childRowCnt, rw.scriptRowCnt, RowCnt)		AS RowCnt
	  , CONVERT(VARCHAR(12), d.diff / 60 / 60 / 24) + ' '
		+ RIGHT('0' + CONVERT(VARCHAR(12), d.diff / 60 / 60 % 24), 2) + ':'
		+ RIGHT('0' + CONVERT(VARCHAR(2), d.diff / 60 % 60), 2) + ':'
		+ RIGHT('0' + CONVERT(VARCHAR(2), d.diff % 60), 2) + '' AS [DD HH:MM:SS]
	  , d.diff													AS SecondsDuration
	  , pl.SourceTypeID
	  , pst.SourceType
	  , STUFF(
		(
			SELECT
				' | ' + ErrorDetails
			FROM Monitor.Package_Errors pe
			WHERE pe.RunID = pl.RunID
				AND pe.PackageID = pl.PackageID
				AND pe.SourceID = pl.SourceID
			FOR XML PATH ('')
		)
		, 1, 3, '')												AS ErrorDetails
	  , COALESCE(rx.childIsErr, pl.isError)						AS traceHasError
	  , pl.isError AS sourceHasError
	FROM Monitor.Package_Log pl
	JOIN Monitor.Package_SourceType pst
		ON pl.SourceTypeID = pst.SourceTypeID
	OUTER APPLY (
		SELECT
			RowCnt
		FROM Monitor.Package_Log plx
		WHERE pl.ID = plx.ID - 1
			AND plx.SourceName LIKE 'Script - Set RowCount%'
	) rw (scriptRowCnt)
	OUTER APPLY (
		SELECT
			SUM(RowCnt)
		  , CAST(MAX(CAST(plx.isError AS INT)) AS BIT)
		FROM Monitor.Package_Log plx
		WHERE plx.SourceTypeID > pl.SourceTypeID
			AND plx.RunStartDateTime BETWEEN pl.RunStartDateTime AND pl.RunEndDateTime
			AND plx.RunID = pl.RunID
	) rx (childRowCnt, childIsErr)
	CROSS APPLY (
		SELECT
			DATEDIFF(SECOND, RunStartDateTime, RunEndDateTime)
	) d (diff)
	WHERE pl.SourceName NOT LIKE 'Script - Set RowCount%'