-- =============================================
-- Author:		JEA
-- Create date: 23/10/2014
-- Description:	Enters the initial values for CustomerActiveStatus
-- =============================================
CREATE PROCEDURE [MI].[CustomerActiveStatus_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients='Christopher.Morris@rewardinsight.com;',
	@subject = 'Warning 42',
	@body='MI.CustomerActiveStatus_Fetch called unexpectedly',
	@body_format = 'TEXT', 
	@importance = 'HIGH', 
	@exclude_query_output = 1

    SELECT h.FanID, MIN(h.StatusDate) AS ActivationDate, h.IsRBS
	FROM MI.CustomerActivationHistory h
	WHERE ActivationStatusID = 1
	GROUP BY h.FanID, h.IsRBS
	--ORDER BY FanID, ActivationDate ChrisM 20180625
	
END