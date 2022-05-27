Create Procedure Staging.SSRS_R0049_CaffeNero_BirthdayEmails @StartDate Date,@EndDate Date
 as
--Declare @StartDate date, @EndDate date
--Set @StartDate = 'Sep 01, 2014'
--Set @EndDate = 'Sep 05, 2014'

Select	CampaignKey,
		CampaignName,
		SendDate,
		Sum(Case
				When Delivered = 1 and Bounced = 0 then 1
				Else 0
			End) as Delivered,
		Sum(Opened) as Opened,
		Cast(Sum(Opened) as real)/
		Sum(Case
				When Delivered = 1 and Bounced = 0 then 1
				Else 0
			End) as [Open%]
From 
(select	ec.CampaignKey,
		ec.CampaignName,
		ec.SendDate,
		FanID,
		Max(Case
				When EmailEventCodeID in (910) then 1
				Else 0
			End) Delivered,
		Max(Case
				When EmailEventCodeID in (702) then 1
				Else 0
			End) Bounced,
		Max(Case
				When EmailEventCodeID in (605,1301,301) then 1
				Else 0
			End) Opened

from warehouse.relational.emailcampaign as ec
left Outer join warehouse.relational.emailevent as ee
	on ec.CampaignKey = ee.CampaignKey
Where   CampaignName like 'Caffe Nero Birthday%' and
		Cast(ec.SendDate as date) Between @StartDate and @EndDate
Group By ec.CampaignKey,
		ec.CampaignName,
		ec.SendDate,
		ee.fanid
) as a
Group By CampaignKey,
		CampaignName,
		SendDate
Order by	SendDate,
			CampaignName