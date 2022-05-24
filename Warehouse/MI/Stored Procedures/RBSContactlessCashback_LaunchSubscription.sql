-- =============================================
-- Author:		JEA
-- Create date: 19/10/2014
-- Description:	Retrieves contactless cashback
-- =============================================
CREATE PROCEDURE MI.RBSContactlessCashback_LaunchSubscription
	WITH EXECUTE AS OWNER 

AS
BEGIN

	SET NOCOUNT ON;

    exec msdb.dbo.sp_start_job '55449A1A-A293-4188-8CA0-CCB66773BCC4'

END
