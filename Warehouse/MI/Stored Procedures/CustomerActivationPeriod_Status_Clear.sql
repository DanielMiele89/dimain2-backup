-- =============================================
-- Author:		JEA
-- Create date: 30/09/2013
-- Description:	Clears down the MI.CustomerActivationPeriod
-- and MI.CustomerActiveStatus tables
-- =============================================
CREATE PROCEDURE [MI].[CustomerActivationPeriod_Status_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients='Christopher.Morris@rewardinsight.com;',
	@subject = 'Warning 42',
	@body='MI.CustomerActivationPeriod_Status_Clear called unexpectedly',
	@body_format = 'TEXT', 
	@importance = 'HIGH', 
	@exclude_query_output = 1

	TRUNCATE TABLE Staging.CustomerActivationPeriod
	TRUNCATE TABLE MI.CustomerActiveStatus
	TRUNCATE TABLE MI.CustomersInactive

END
