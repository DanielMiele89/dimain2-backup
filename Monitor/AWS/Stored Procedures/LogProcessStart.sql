
CREATE PROCEDURE [AWS].[LogProcessStart]
	@ServerName SYSNAME
AS
BEGIN
	DECLARE @IDStore TABLE (ID INT);

	--Log that this server has a new process running
	INSERT INTO AWS.FileUploadProcessRun (ServerName, StartTime)
	OUTPUT inserted.ID INTO @IDStore
	VALUES (@ServerName, GETDATE());

	--Return the value to the package
	SELECT ID FROM @IDStore;
END
