-- =============================================
-- Author:		JEA
-- Create date: 30/09/2013
-- Description:	Retrieves close dates for CustomerActivationPeriod
-- =============================================
CREATE PROCEDURE [MI].[CustomerActivationPeriod_Inactive_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients='Christopher.Morris@rewardinsight.com;',
	@subject = 'Warning 42',
	@body='MI.CustomerActivationPeriod_Inactive_Fetch called unexpectedly',
	@body_format = 'TEXT', 
	@importance = 'HIGH', 
	@exclude_query_output = 1

    SELECT h.FanID, h.StatusDate AS ActivationDate, ActivationStatusID
	FROM MI.CustomerActivationHistory h
	INNER JOIN Relational.Customer c ON h.FanID = c.FanID
	WHERE ActivationStatusID > 1
	ORDER BY FanID, ActivationDate
	
END