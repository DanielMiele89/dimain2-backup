-- =============================================
-- Author:		JEA
-- Create date: 23/04/2014
-- Description:	Processes and sends the monthly dashboard report
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Month_ProcessAndSend]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	EXEC MI.CBPDashboard_Month_Activations_Refresh
	EXEC MI.CBPDashboard_Month_SpendEarn_Refresh
	EXEC MI.CBPDashboard_Month_Redemptions_Refresh
	EXEC MI.CBPDashboard_Month_Offers_Refresh
	EXEC MI.CBPDashboard_Month_Emails_Refresh
	EXEC [DIMAIN].[msdb].[dbo].[sp_start_job] '1E4945C8-0D03-4C48-8ED3-3533D8BC37EE'

END
