-- =============================================
-- Author:		<Adam Scott>
-- Create date: <25/03/2014>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[CampainPerformance_fetch]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here


DECLARE   @ThisMonthStart DATE
		, @ThisMonthEnd DATE


		--First day of the lag date month
		SET @ThisMonthEnd = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101)
		
		--First day of the previous (i.e. completed) month
		SET @ThisMonthStart = DATEADD(MONTH, -1, @ThisMonthEnd)
		--last day of that month
		SET @ThisMonthEnd = DATEADD(DAY, -1, @ThisMonthEnd)








Select	Reference,
		[Subject],
		Case
			When EmailType = 'H' then 'Weekly Email with Hero Offer'
			When EmailType = 'S' then 'Solus Email'
			When EmailType = 'W' then 'Weekly Email'
		End as CampaignDescription,
		case ClubID when 132 then 'Natwest' when 138 then 'RBS' else cast(ClubID as Varchar(5)) end as ClubID,	
		EmailName ,Max(Cast(senddate as DATE)) as SentDate,--EmailsSent,
		Sum(EmailSentOK)	as E_EmailsSentOK,
		(Sum(EmailSentOK)-SUM(SB))-SUM(HB) as Delivered,
		(Cast((Sum(EmailSentOK)-SUM(SB))-SUM(HB) as float) )/Cast(Sum(EmailSentOK) as float) as Delivery_Pct,
		Sum(EmailOpened)	as E_EmailsOpened,
		Cast(Sum(EmailOpened) as float)/ CAST(Sum(EmailSentOK) as float) as EmailOpens_Pct,
		Sum(ClickLink)		as E_ClickLink,
		CAST(Sum(ClickLink) as float)/Cast(Sum(EmailOpened) as float) as Clicks_Open_Pct,
		cud.Unsubscribed as E_Unsubscribed,
		cud.Unsubscribed / cast(Sum(EmailSentOK) as int) as UnSub_PCt

from
(select	ec.CampaignKey,ec.senddate,ec.CampaignName,Reference,[Subject],EmailType,EmailName,FanID,cls.ClubID,
		max(Case When ee.EmailEventCodeID = 901 OR ee.EmailEventCodeID = 910 then 1 else 0 end) as EmailSentOK,
		Max(Case When ee.EmailEventCodeID in (1301) then 1 else 0 end) as EmailOpened,
		Max(Case When ee.EmailEventCodeID = 605 then 1 else 0 end) as ClickLink,
		Max(Case When ee.EmailEventCodeID = 701 then 1 else 0 end) as SB, 
		Max(Case When ee.EmailEventCodeID = 702 then 1 else 0 end) as HB
from SLC_Report.dbo.EmailCampaign as ec
inner join SLC_Report.dbo.EmailEvent as ee
	on ec.CampaignKey = ee.campaignkey
inner join warehouse.Relational.CampaignLionSendIDs as cls
	on ee.CampaignKey = cls.CampaignKey	
Where	ec.senddate  >= dateadd(day,-(datepart(day,@ThisMonthEnd)-1),@ThisMonthEnd) and
		ec.SendDate  <  dateadd(day,1,@ThisMonthEnd) 
Group by ec.CampaignKey,ec.senddate,ec.CampaignName,FanID,Reference,[Subject],EmailType,EmailName,cls.ClubID
) as a
Left Outer join 
(Select CampaignKey,Count(*) as Unsubscribed from Warehouse.relational.Customer_UnsubscribeDates Group by CampaignKey) as cud
	on a.CampaignKey = cud.CampaignKey
Group by Reference,EmailType,EmailName,EmailType,[Subject],ClubID,cud.Unsubscribed
END