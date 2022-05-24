-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Inserts an action into the process log
-- =============================================
create PROCEDURE monitor.[ProcessLog_Insert]
	(
		@ProcessName VARCHAR(50)
		, @ActionName VARCHAR(200)
		, @IsError BIT = 0
	)
AS
	
SET NOCOUNT ON;

INSERT INTO monitor.ProcessLog 
	(ProcessName, ActionName, IsError)
VALUES (@ProcessName, @ActionName, @IsError)


RETURN 0