-- =============================================
-- Author:		JEA
-- Create date: 11/04/2014
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Week_ProcessAndSend]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	IF DATENAME(dw ,GETDATE()) = 'Monday'
    BEGIN
		EXEC MI.CBPDashboard_Week_Activations_Refresh
		EXEC MI.CBPDashboard_Week_SpendEarn_Refresh
		EXEC MI.CBPDashboard_Week_Redemptions_Refresh
		EXEC MI.CBPDashboard_Week_Offers_Refresh
		EXEC MI.CBPDashboard_Week_Emails_Refresh
		EXEC [DIMAIN].[msdb].[dbo].[sp_start_job] 'D39526E8-D56E-456C-9F60-68DC7AB62885'
	END
END