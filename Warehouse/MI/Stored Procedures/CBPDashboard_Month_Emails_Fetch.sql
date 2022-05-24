-- =============================================
-- Author:		JEA
-- Create date: 23/04/2014
-- Description:	Refreshes email information for monthly CBP dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Month_Emails_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT Dispatched, Opened, Clicked, Bounced, Unsubscribed
	FROM MI.CBPDashboard_Month_Emails

END