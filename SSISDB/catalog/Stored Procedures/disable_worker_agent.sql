﻿
CREATE PROCEDURE [catalog].[disable_worker_agent]
    @WorkerAgentId	UNIQUEIDENTIFIER

WITH EXECUTE AS 'AllSchemaOwner'
AS
BEGIN
	SET NOCOUNT ON
		
	
	IF @WorkerAgentId IS NULL
	BEGIN
		RAISERROR(27100, 16, 1, N'@WorkerAgentId')
		RETURN 1
	END
	
	IF @WorkerAgentId = '11111111-1111-1111-1111-111111111111'
	BEGIN
		RAISERROR(27101, 16, 1, '11111111-1111-1111-1111-111111111111') WITH NOWAIT
		RETURN 1
	END
	
	UPDATE [internal].[worker_agents] SET [IsEnabled]=0 WHERE WorkerAgentId=@WorkerAgentId 
	
	IF @@ROWCOUNT = 0
	BEGIN
		DECLARE @strWorkerAgentId NVARCHAR(50)
		SET @strWorkerAgentId = CONVERT(NVARCHAR(50), @WorkerAgentId)
		RAISERROR(27243, 16, 1, @strWorkerAgentId) WITH NOWAIT
		RETURN 1
	END
	
	RETURN 0
END

GO
GRANT EXECUTE
    ON OBJECT::[catalog].[disable_worker_agent] TO [ssis_admin]
    AS [dbo];

