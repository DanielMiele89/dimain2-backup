
CREATE PROCEDURE [AWS].[GetFileCountForUpload]
	@ServerName VARCHAR(256)
AS
BEGIN
	SELECT COUNT(*)
	FROM AWS.FileUploadLog
	WHERE UploadedDate IS NULL
	AND ProcessRunID IS NULL
	AND ServerName = @ServerName;
END
