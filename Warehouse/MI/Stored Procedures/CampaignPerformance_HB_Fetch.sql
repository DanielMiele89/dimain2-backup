-- =============================================
-- Author:		<Adam Scott>
-- Create date: <25/03/2014>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[CampaignPerformance_HB_Fetch]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

		DECLARE @ThisMonthStart DATE, @MonthBeforeLastStart date

		SET @ThisMonthStart = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
		SET @MonthBeforeLastStart = DATEADD(MONTH, -2, @ThisMonthStart)

		SELECT	Reference,
		[Subject]
		, CASE
			WHEN EmailType = 'H' THEN 'Weekly Email with Hero Offer'
			WHEN EmailType = 'S' THEN 'Solus Email'
			WHEN EmailType = 'W' THEN 'Weekly Email'
		END AS CampaignDescription
		, CASE ClubID when 132 THEN 'Natwest' WHEN 138 THEN 'RBS' ELSE cast(ClubID AS VARCHAR(5)) END AS ClubID	
		, EmailName 
		, MAX(CAST(senddate as DATE)) as SentDate--EmailsSent,
		, SUM(EmailSentOK)	as E_EmailsSentOK
		, (SUM(EmailSentOK)-SUM(SB))-SUM(HB) as Delivered
		, (CAST((SUM(EmailSentOK)-SUM(SB))-SUM(HB) AS FLOAT) )/CAST(SUM(EmailSentOK) AS FLOAT) as Delivery_Pct
		, SUM(EmailOpened) as E_EmailsOpened
		, CAST(SUM(EmailOpened) AS FLOAT)/ CAST(SUM(EmailSentOK) AS FLOAT) AS EmailOpens_Pct
		, SUM(ClickLink) AS E_ClickLink
		, CAST(SUM(ClickLink) AS FLOAT)/CAST(SUM(EmailOpened) AS FLOAT) AS Clicks_Open_Pct
		, cud.Unsubscribed AS E_Unsubscribed
		, cud.Unsubscribed / CAST(SUM(EmailSentOK) AS INT) AS UnSub_PCt
		, SUM(HB) AS HardBounces --ADDED JEA 27/10/2014

		FROM
		(
			SELECT	ec.CampaignKey,ec.senddate,ec.CampaignName,Reference,[Subject],EmailType,EmailName,FanID,cls.ClubID,
					MAX(CASE WHEN ee.EmailEventCodeID = 901 OR ee.EmailEventCodeID = 910 THEN 1 ELSE 0 END) as EmailSentOK,
					MAX(CASE WHEN ee.EmailEventCodeID in (1301) THEN 1 ELSE 0 END) AS EmailOpened,
					MAX(CASE WHEN ee.EmailEventCodeID = 605 THEN 1 ELSE 0 END) AS ClickLink,
					MAX(CASE WHEN ee.EmailEventCodeID = 701 THEN 1 ELSE 0 END) AS SB, 
					MAX(CASE WHEN ee.EmailEventCodeID = 702 THEN 1 ELSE 0 END) AS HB
			FROM SLC_Report.dbo.EmailCampaign ec
				INNER JOIN SLC_Report.dbo.EmailEvent ee ON ec.CampaignKey = ee.campaignkey
				INNER JOIN warehouse.Relational.CampaignLionSendIDs cls ON ee.CampaignKey = cls.CampaignKey	
			WHERE ec.senddate  >= @MonthBeforeLastStart
			AND ec.SendDate  <  @ThisMonthStart
			GROUP BY ec.CampaignKey,ec.senddate,ec.CampaignName,FanID,Reference,[Subject],EmailType,EmailName,cls.ClubID
		) a
		LEFT OUTER JOIN 
		(
			SELECT CampaignKey
				,COUNT(*) AS Unsubscribed 
			FROM Warehouse.relational.Customer_UnsubscribeDates 
			GROUP BY CampaignKey
		) cud ON a.CampaignKey = cud.CampaignKey
		GROUP BY Reference
			,EmailType
			,EmailName
			,EmailType
			,[Subject]
			,ClubID
			,cud.Unsubscribed

END
