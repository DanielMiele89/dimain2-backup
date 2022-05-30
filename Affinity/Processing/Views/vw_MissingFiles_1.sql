
CREATE VIEW [Processing].[vw_MissingFiles]
AS
	WITH FileTypes
	AS
	(
		SELECT * FROM (
			VALUES
			('CRTRN', 'Credit')
			, ('TRANS', 'Debit')
		) x(FileType, FileTypeName)
	),
	FileChecks
	AS
	(
		select
			ft.FileType
			, ft.FileTypeName
			, COUNT(nf.ID) isAvailable
			, ROW_NUMBER() OVER ( ORDER BY ft.FileType) as id
		from FileTypes ft
		LEFT JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[NobleFiles] nf
			ON ft.FileType = nf.FileType
			AND CAST(InDate AS DATE) = CAST(GETDATE() AS DATE)
		GROUP BY ft.FileType, ft.FileTypeName
	),
	Subj
	AS
	(
		SELECT
			FileType
			, isAvailable
			, id
			, CAST(CASE WHEN isAvailable = 0 THEN FileTypeName ELSE '' END AS VARCHAR(500)) AS FilesMissing
		FROM FileChecks
		WHERE ID = 1

		UNION ALL

		SELECT
			f.FileType
			, f.isAvailable
			, f.id
			, CAST(FilesMissing + CASE WHEN f.isAvailable = 0 THEN CASE WHEN LEN(FilesMissing) > 0 THEN ', ' + f.FileTypeName ELSE f.FileTypeName END ELSE '' END AS VARCHAR(500)) AS FilesMissing
		FROM Subj s
		JOIN FileChecks f
			ON s.ID+1 = f.ID
	)
	SELECT
		*
	FROM Subj

