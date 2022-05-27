
/* Update:		28-02-2014 SB - Amended to change to Left Outer Join for Unsubscribes
*/
Create Procedure [Staging].[RBSG_MonthlyRep_InMonthCommsV1_2] (@EndDate date)
as
--declare @StartDate date--, @EndDate date
--set @EndDate = 'Feb 28, 2014'

if object_id('Warehouse.staging.RBSG_MonthlyReport_InMonthComms') is not null drop table Warehouse.staging.RBSG_MonthlyReport_InMonthComms
Select	Reference,
		[Subject],
		Case
			When EmailType = 'H' then 'Weekly Email with Hero Offer'
			When EmailType = 'S' then 'Solus Email'
			When EmailType = 'W' then 'Weekly Email'
		End as CampaignDescription,
		ClubID,	
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
		--SUM(Unsubscribed)	as E_Unsubscribed,
		--Cast(SUM(Unsubscribed) as float) / cast(Sum(EmailSentOK) as int) as UnSub_PCt
Into Warehouse.staging.RBSG_MonthlyReport_InMonthComms
from
(select	ec.CampaignKey,ec.senddate,ec.CampaignName,Reference,[Subject],EmailType,EmailName,FanID,cls.ClubID,
		max(Case When ee.EmailEventCodeID in (901,910) then 1 else 0 end) as EmailSentOK,
		Max(Case When ee.EmailEventCodeID in (1301) then 1 else 0 end) as EmailOpened,
		Max(Case When ee.EmailEventCodeID = 605 then 1 else 0 end) as ClickLink,
		--Max(Case When ee.EmailEventCodeID = 301 then 1 else 0 end) as Unsubscribed ,
		Max(Case When ee.EmailEventCodeID = 701 then 1 else 0 end) as SB, 
		Max(Case When ee.EmailEventCodeID = 702 then 1 else 0 end) as HB
from SLC_Report.dbo.EmailCampaign as ec
inner join SLC_Report.dbo.EmailEvent as ee
	on ec.CampaignKey = ee.campaignkey
inner join warehouse.Relational.CampaignLionSendIDs as cls
	on ee.CampaignKey = cls.CampaignKey	
Where	ec.senddate  >= dateadd(day,-(datepart(day,@EndDate)-1),@EndDate) and
		ec.SendDate  <  dateadd(day,1,@EndDate) 
Group by ec.CampaignKey,ec.senddate,ec.CampaignName,FanID,Reference,[Subject],EmailType,EmailName,cls.ClubID
) as a
Left Outer join 
(Select CampaignKey,Count(*) as Unsubscribed from Warehouse.relational.Customer_UnsubscribeDates Group by CampaignKey) as cud
	on a.CampaignKey = cud.CampaignKey
Group by Reference,EmailType,EmailName,EmailType,[Subject],ClubID,cud.Unsubscribed