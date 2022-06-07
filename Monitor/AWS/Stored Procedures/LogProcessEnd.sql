

CREATE PROCEDURE [AWS].[LogProcessEnd]
	@ProcessID INT
AS
BEGIN
	UPDATE AWS.FileUploadProcessRun SET EndTime = GETDATE() WHERE ID = @ProcessID;
END
