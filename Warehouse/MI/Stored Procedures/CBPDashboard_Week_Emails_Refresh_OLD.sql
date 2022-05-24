-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Refreshes email information for weekly CBP dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Week_Emails_Refresh_OLD]
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @ThisWeekStart DATE, @ThisWeekEnd DATE
		, @Dispatched INT, @Bounced INT, @Opened INT, @Clicked INT, @Unsubscribed INT

	SET @ThisWeekEnd = DATEADD(DAY, -1, GETDATE())
	SET @ThisWeekStart = DATEADD(DAY, -6, @ThisWeekEnd)

    CREATE TABLE #EmailCampaigns(CampaignKey NVARCHAR(8) PRIMARY KEY)
	CREATE TABLE #EmailEvents(ID INT PRIMARY KEY IDENTITY
		, CampaignKey NVARCHAR(8) NOT NULL
		, FanID INT NOT NULL
		, EmailEventCodeID INT NOT NULL
		)

	--Store campaigns sent in the last week
	INSERT INTO #EmailCampaigns(CampaignKey)
	SELECT CampaignKey
	FROM Relational.EmailCampaign
	WHERE SendDate BETWEEN @ThisWeekStart AND @ThisWeekEnd

	--Store target event occurrences per customer per campaign (i.e. the event can only occur once per customer per campaign)
	INSERT INTO #EmailEvents(CampaignKey, FanID, EmailEventCodeID)
	SELECT DISTINCT ec.CampaignKey, ee.FanID, ee.EmailEventCodeID
	FROM Relational.EmailEvent ee
	INNER JOIN #EmailCampaigns ec ON ee.CampaignKey = ec.CampaignKey
	WHERE ee.EmailEventCodeID IN (605,901,1301)
	UNION
	SELECT DISTINCT ec.CampaignKey, ee.FanID, 701
	FROM Relational.EmailEvent ee
	INNER JOIN #EmailCampaigns ec ON ee.CampaignKey = ec.CampaignKey
	WHERE ee.EmailEventCodeID IN (701,702)
	UNION
	SELECT ISNULL(CampaignKey, 'A'), FanID, 0
	FROM Relational.Customer_UnsubscribeDates
	WHERE EventDate
	BETWEEN @ThisWeekStart AND @ThisWeekEnd

	SELECT @Dispatched = COUNT(1)
	FROM #EmailEvents
	WHERE EmailEventCodeID = 901 --sent

	SELECT @Opened = COUNT(1)
	FROM #EmailEvents
	WHERE EmailEventCodeID = 1301 --opened

	SELECT @Clicked = COUNT(1)
	FROM #EmailEvents
	WHERE EmailEventCodeID = 605 --clicked

	SELECT @Bounced = COUNT(1)
	FROM #EmailEvents
	WHERE EmailEventCodeID = 701 --bounced

	SELECT @Unsubscribed = COUNT(1)
	FROM #EmailEvents
	WHERE EmailEventCodeID = 0 --unsubscribed

	DELETE FROM MI.CBPDashboard_Week_Emails

	INSERT INTO MI.CBPDashboard_Week_Emails(Dispatched, Opened, Clicked, Bounced, Unsubscribed)
	VALUES(@Dispatched, @Opened, @Clicked, @Bounced, @Unsubscribed)

END
