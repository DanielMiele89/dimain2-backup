
/******************************************************************************/
--Creation Date: 2018-11-07; Created By: Edmond Eilerts de Haan; Part of the Cloud Archive project. Used to log files for upload to AWS
CREATE PROCEDURE [AWS].[LogFilesForUpload]
	@FileList NVARCHAR(MAX),
	@UploadPath NVARCHAR(MAX),
	@ServerName SYSNAME
AS
BEGIN
	SET NOCOUNT ON;

	----Debug
	--insert into aws.TempLog (logdate, filelist, uploadpath, servername)
	--values (GETDATE(), @filelist, @uploadpath, @servername);
	--return;

	DECLARE @Command NVARCHAR(1000),
		@UploadPathLength INT;

	SET @UploadPathLength = LEN(@UploadPath);

	IF OBJECT_ID('tempdb..#AllFiles') IS NOT NULL DROP TABLE #AllFiles;
	CREATE TABLE #AllFiles ([FileName] NVARCHAR(256), [Destination] NVARCHAR(256), ID INT, UploadedDate DATETIME);

	IF CHARINDEX(CHAR(13)+CHAR(10), @FileList+CHAR(13)+CHAR(10)) = 1 SET @FileList = STUFF(@FileList, 1, 2, '');

	;WITH splitstring (FileNm, Remaining) AS
	(
		SELECT RTRIM(LTRIM(LEFT(@FileList, CHARINDEX(CHAR(13)+CHAR(10), @FileList+CHAR(13)+CHAR(10)) - 1))),
			STUFF(@FileList, 1, CHARINDEX(CHAR(13)+CHAR(10), @FileList+CHAR(13)+CHAR(10)) + 1, '')
		UNION ALL
		SELECT RTRIM(LTRIM(LEFT(Remaining, CHARINDEX(CHAR(13)+CHAR(10), Remaining) - 1))),
			STUFF(Remaining, 1, CHARINDEX(CHAR(13)+CHAR(10), Remaining) + 1, '')
		FROM splitstring
		WHERE LEN(Remaining) > 0
	)
	INSERT INTO #AllFiles (FileName)
	SELECT FileNm
	FROM splitstring
	WHERE LEFT(FileNm, @UploadPathLength) = @UploadPath
	OPTION (MAXRECURSION 0)

	--Tidy up the list
	DELETE FROM #AllFiles WHERE FileName IS NULL OR FileName = 'File Not Found';

	--Strip off the local path
	UPDATE #AllFiles SET [Destination] = RIGHT([FileName], LEN([FileName]) - @UploadPathLength);
	--Strip off the actual filename to leave just the relative destination folder
	UPDATE #AllFiles SET [Destination] = CASE CHARINDEX('\', REVERSE([Destination])) WHEN 0 THEN '' ELSE LEFT([Destination], LEN([Destination]) - CHARINDEX('\', REVERSE([Destination]))) END;
	--Swap \ for / to ready it for the upload command
	UPDATE #AllFiles SET [Destination] = REPLACE([Destination], '\', '/');

	--Record the files to be uploaded (if it hasn't already)
	INSERT INTO AWS.FileUploadLog (ServerName, FileName)
	SELECT @ServerName, FileName
	FROM #AllFiles f
	WHERE NOT EXISTS (SELECT NULL FROM AWS.FileUploadLog l WHERE l.FileName = f.FileName and l.ServerName = @ServerName);

	--Return the pertinent data back to the package
	SELECT l.ID, f.FileName, f.Destination, ISNULL(CONVERT(VARCHAR(23), l.UploadedDate, 121), '') as UploadedDate
	FROM #AllFiles f
	INNER JOIN AWS.FileUploadLog l on l.FileName = f.FileName;
END
