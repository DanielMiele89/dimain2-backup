


	CREATE VIEW [Processing].[vw_MaxFileID] 
	AS
	SELECT MAX(FileID) AS FileID, 'FI' FileType, CAST(CASE WHEN nf.FileType = 'CRTRN' THEN 1 WHEN nf.FileType = 'TRANS' THEN 0 END AS BIT) AS isCredit
	FROM Processing.RowNum_Log rnl
	JOIN (
		SELECT TOP 30 * FROM SLC_REPL..NobleFiles nf
		ORDER BY 1 DESC
	) nf
		ON rnl.FileID = nf.ID
	WHERE rnl.FileID > 0
	GROUP BY nf.FileType
	UNION ALL
	SELECT MAX(RowNum) AS FileID, 'nFI' FileType, NULL AS isCredit
	FROM Processing.RowNum_Log rnl
	WHERE rnl.FileID = -1

