

CREATE VIEW [Processing].[vw_PackageLog_Tableau]
AS
	WITH SourceIDs
	AS
	(
		SELECT
			*
		FROM
		(
			VALUES 
				('B11EC040-FD84-4D51-8B23-24C7FE9E2D56', 'Customers')
				, ('D2D6463A-A986-4CED-9C51-6197FF769511', 'MIDI Debit')
				, ('A9E00B05-1BA7-4DE3-9F32-FBF1FD1D0F59', 'MIDI Credit')
				, ('9F33AC09-C495-45A6-844C-269B91ACA6A2', 'RBS Debit')
				, ('70FF6006-438A-4901-8F88-5579D58FF569', 'RBS Credit')
				, ('E9A0D8F1-75D8-4C0F-AC29-BA57B3DD1E05', 'nFI')
				, ('CB42B744-7B2F-4948-A273-0BF0DA3A8A41', 'Merchant Details')
				, ('64CC2746-A4D8-4C15-8000-DF304F6066B7', 'MTID Mapping')
		)x(KeepID, DisplayName)
	)
	SELECT
		ID
	  , RunID
	  , MIN(RunID) OVER (PARTITION BY CAST(DATEADD(HH, Processing.getTimeDiff(), pl.RunStartDateTime) AS DATE)) AS OverallID
	  , PackageID
	  , SourceID
	  , SourceName
	  , COALESCE(DisplayName, dbo.SpaceBeforeCap(REPLACE(SourceName, 'PKG_', ''))) AS DisplayName
	  , CAST(DATEADD(HH, Processing.getTimeDiff(), pl.RunStartDateTime) AS DATE) AS RunDate
	  , RunStartDateTime
	  , RunEndDateTime
	  , DATEADD(DAY, 1, CAST(CAST(DATEADD(HH, Processing.getTimeDiff(), pl.RunStartDateTime) AS DATE) AS DATETIME) + CAST(TIMEFROMPARTS(3, 0, 0, 0, 3) AS DATETIME))  AS SLA3
	  , DATEADD(DAY, 1, CAST(CAST(DATEADD(HH, Processing.getTimeDiff(), pl.RunStartDateTime) AS DATE) AS DATETIME) + CAST(TIMEFROMPARTS(8, 0, 0, 0, 3) AS DATETIME))  AS SLA8
	  , COALESCE(rw.scriptRowCnt, RowCnt)		AS RowCnt
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
	FROM Processing.Package_Log pl
	JOIN Processing.Package_SourceType pst
		ON pl.SourceTypeID = pst.SourceTypeID
	LEFT JOIN SourceIDs s
		ON pl.SourceID = s.KeepID
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
	) d (diff)
	WHERE s.KeepID IS NOT NULL
		OR pl.SourceID = pl.PackageID
	



