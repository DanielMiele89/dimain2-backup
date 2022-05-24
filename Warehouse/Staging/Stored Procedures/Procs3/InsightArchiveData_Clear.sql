-- =============================================
-- Author:		JEA>
-- Create date: 18/10/2014
-- Description:	Clears archive change log table
-- =============================================
CREATE PROCEDURE [Staging].[InsightArchiveData_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients='Christopher.Morris@rewardinsight.com;',
	@subject = 'Warning 42',
	@body='Staging.InsightArchiveData_Clear called unexpectedly',
	@body_format = 'TEXT', 
	@importance = 'HIGH', 
	@exclude_query_output = 1

    TRUNCATE TABLE Staging.InsightArchiveData;

END