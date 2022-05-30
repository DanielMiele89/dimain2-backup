CREATE PROCEDURE Processing.Email_CheckForMissingFiles
AS
BEGIN

	DECLARE @Subject VARCHAR(500)

	SELECT 
		@Subject = 'Affinity - ' + NULLIF(FilesMissing, '') + ' Missing' 
	FROM Processing.vw_MissingFiles
	WHERE ID = (SELECT MAX(ID) FROM Processing.vw_MissingFiles)

	IF @Subject IS NOT NULL
	BEGIN
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Administrator'
									, @recipients = 'diprocesscheckers@rewardinsight.com; hayden.reid@rewardinsight.com'
									, @Subject = @Subject
	END
END





