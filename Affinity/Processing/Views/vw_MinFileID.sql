


	CREATE VIEW [Processing].[vw_MinFileID] 
	AS
	SELECT MIN(FileID) AS FileID, 'FI' FileType
	FROM Processing.RowNum_Log rnl
	WHERE rnl.FileID > 0
	UNION ALL
	SELECT MIN(RowNum) AS FileID, 'nFI' FileType
	FROM Processing.RowNum_Log rnl
	WHERE rnl.FileID = -1

