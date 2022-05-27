-- =============================================
-- Author:		JEA
-- Create date: 30/09/2013
-- Description:	Enters the initial dates for CustomerActivationPeriod
-- =============================================
CREATE PROCEDURE [MI].[CustomerActivationPeriod_Initial_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients='Christopher.Morris@rewardinsight.com;',
	@subject = 'Warning 42',
	@body='MI.CustomerActivationPeriod_Initial_Fetch called unexpectedly',
	@body_format = 'TEXT', 
	@importance = 'HIGH', 
	@exclude_query_output = 1


    SELECT h.ID, h.FanID, h.StatusDate AS ActivationDate, h.IsRBS
	FROM MI.CustomerActivationHistory h
	WHERE ActivationStatusID = 1
	ORDER BY FanID, ActivationDate
	
END
