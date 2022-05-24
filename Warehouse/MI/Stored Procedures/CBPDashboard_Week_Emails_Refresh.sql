-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Refreshes email information for weekly CBP dashboard
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Week_Emails_Refresh]
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @ThisWeekStart DATE, @ThisWeekEnd DATETIME

	SET @ThisWeekEnd = DATEADD(MINUTE, -1, CAST(CAST(GETDATE() AS DATE) AS DATETIME))
	SET @ThisWeekStart = DATEADD(DAY, -7, CAST(GETDATE() AS DATE))

	DELETE FROM MI.CBPDashboard_Week_Emails

	INSERT INTO MI.CBPDashboard_Week_Emails(Dispatched, Opened, Clicked, Bounced, Unsubscribed)

	SELECT ISNULL(SUM(a.Dispatched),0) AS Dispatched
			, ISNULL(SUM(a.Opened),0) AS Opened
			, ISNULL(SUM(a.Clicked),0) AS Clicked
			, ISNULL(SUM(a.Bounced),0) AS Bounced
			, ISNULL(SUM(u.Unsubscribed),0) AS Unsubscribed
	FROM
	(
		SELECT a.CampaignKey
			, SUM(a.Dispatched) AS Dispatched
			, SUM(a.Opened) AS Opened
			, SUM(a.Clicked) AS Clicked
			, SUM(a.SB + a.HB) AS Bounced
		FROM
			(
			SELECT	ec.CampaignKey,
					MAX(CASE WHEN ee.EmailEventCodeID = 901 OR ee.EmailEventCodeID = 910 THEN 1 ELSE 0 END) AS Dispatched,
					MAX(CASE WHEN ee.EmailEventCodeID in (1301) THEN 1 ELSE 0 END) AS Opened,
					MAX(CASE WHEN ee.EmailEventCodeID = 605 THEN 1 ELSE 0 END) AS Clicked,
					MAX(CASE WHEN ee.EmailEventCodeID = 701 THEN 1 ELSE 0 END) AS SB, 
					MAX(CASE WHEN ee.EmailEventCodeID = 702 THEN 1 ELSE 0 END) AS HB
			FROM SLC_Report.dbo.EmailCampaign as ec
			INNER JOIN SLC_Report.dbo.EmailEvent as ee
				ON ec.CampaignKey = ee.campaignkey
			INNER JOIN warehouse.Relational.CampaignLionSendIDs as cls
				ON ee.CampaignKey = cls.CampaignKey	
			WHERE ec.senddate  BETWEEN @ThisWeekStart AND @ThisWeekEnd
			GROUP BY ec.CampaignKey,ec.senddate,ec.CampaignName,FanID,Reference,[Subject],EmailType,EmailName,cls.ClubID
			) as a
			GROUP BY a.CampaignKey
		) a
		LEFT OUTER JOIN 
			(SELECT CampaignKey,Count(*) AS Unsubscribed 
				FROM Warehouse.relational.Customer_UnsubscribeDates 
				GROUP BY CampaignKey
			) u
				ON a.CampaignKey = u.CampaignKey

END