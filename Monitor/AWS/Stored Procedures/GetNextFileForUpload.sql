
CREATE PROCEDURE [AWS].[GetNextFileForUpload]
	@ServerName VARCHAR(256),
	@ProcessID INT,
	@UploadPath NVARCHAR(256)
AS
BEGIN
	DECLARE @ThisID INT,
		@ThisFileName NVARCHAR(256),
		@ThisDestination NVARCHAR(256);

	--Wrapped in a tran to ensure only 1 process picks up each file, this may cause locks but not for long!
	BEGIN TRAN

	SELECT TOP 1 @ThisID = ID, @ThisFileName = FileName
	FROM AWS.FileUploadLog
	WHERE ServerName = @ServerName
	AND UploadedDate IS NULL
	AND ProcessRunID IS NULL;

	IF @ThisID IS NULL
	BEGIN
		--No files, so quit out
		ROLLBACK TRAN

		SELECT 0 as ID, '' as FileName, '' as Destination;

		RETURN
	END

	UPDATE AWS.FileUploadLog SET ProcessRunID = @ProcessID WHERE ID = @ThisID;

	COMMIT TRAN

	DECLARE @UploadPathLength INT;

	SET @UploadPathLength = LEN(@UploadPath);

	--Strip off the local path
	SET @ThisDestination = RIGHT(@ThisFileName, LEN(@ThisFileName) - @UploadPathLength);
	--Strip off the actual filename to leave just the relative destination folder
	SET @ThisDestination = CASE CHARINDEX('\', REVERSE(@ThisDestination)) WHEN 0 THEN '' ELSE LEFT(@ThisDestination, LEN(@ThisDestination) - CHARINDEX('\', REVERSE(@ThisDestination))) END;
	--Swap \ for / to ready it for the upload command
	SET @ThisDestination = REPLACE(@ThisDestination, '\', '/');

	--Return the data to the Package
	SELECT @ThisID as ID, @ThisFileName as FileName, @ThisDestination as Destination;
END
