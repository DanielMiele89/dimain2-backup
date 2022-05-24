-- =============================================
-- Author:		JEA
-- Create date: 01/07/2015
-- Description:	Clears CBP daily tables prior to population
-- =============================================
CREATE PROCEDURE [MI].[CBPDailyFile_Tables_Clear] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE MI.CBP_DailyMIReport
	TRUNCATE TABLE MI.CBP_CustomerSpend

	exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients='Christopher.Morris@rewardinsight.com;',
	@subject = 'Warning 42',
	@body='MI.CBPDailyFile_Tables_Clear called unexpectedly',
	@body_format = 'TEXT', 
	@importance = 'HIGH', 
	@exclude_query_output = 1

END