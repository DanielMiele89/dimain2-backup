-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Inserts an action into the process log
-- =============================================
CREATE PROCEDURE [MI].[ProcessLog_Insert]
	(
		@ProcessName VARCHAR(50)
		, @ActionName VARCHAR(200)
		, @IsError BIT = 0
	)
AS
BEGIN
	
	SET NOCOUNT ON;

   INSERT INTO MI.ProcessLog(ProcessName, ActionName, IsError)
   VALUES(@ProcessName, @ActionName, @IsError)

END