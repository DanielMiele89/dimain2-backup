
-- =============================================
-- Author:		JEA
-- Create date: 29/01/2018
-- Description:	Snapshot Monitor
-- Altered CJM 20180622
-- =============================================
CREATE PROCEDURE [dbo].[SnapshotHealthCheck_Check]
	
AS

BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @Err VARCHAR(4000), @Return INT = 0

	BEGIN TRY

		EXEC('INSERT INTO dbo.SnapshotHealthCheck(IsError, ErrorMessage)
		SELECT TOP 1 0, '''' FROM SLC_Snapshot.dbo.Club')

	END TRY

	BEGIN CATCH

		SET @Err = ERROR_MESSAGE()
		SET @Return = -1

		INSERT INTO dbo.SnapshotHealthCheck(IsError, ErrorMessage)
		VALUES(1, @Err)

		EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = 'Administrator', 
			@recipients='diprocesscheckers@rewardinsight.com;Christopher.Morris@rewardinsight.com',
			@subject = 'Snapshot Inaccessible - DIMAIN',
			@body= @Err,
			@body_format = 'TEXT',  
			@exclude_query_output = 1

	END CATCH

END

RETURN @Return
