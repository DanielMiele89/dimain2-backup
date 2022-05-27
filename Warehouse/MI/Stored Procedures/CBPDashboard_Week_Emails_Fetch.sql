-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Refreshes email information for weekly CBP dashboard
-- =============================================
CREATE PROCEDURE MI.CBPDashboard_Week_Emails_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT Dispatched, Opened, Clicked, Bounced, Unsubscribed
	FROM MI.CBPDashboard_Week_Emails

END
