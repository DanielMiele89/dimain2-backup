CREATE Procedure [Staging].[SSRS_R0066_RedemptionSplit]
As
Select	a.CampaignKey,
		a.CampaignName,
		a.SendDatetime,
		r.RedeemType,
		Count(*) as Redemptions,
		Sum(CashbackUsed) as CashbackUsed
from
(select	ec.CampaignKey,
		ec.CampaignName,
		ec.SendDatetime,
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
Where   CampaignName like '%CBP_Redemption%' and
		--Cast(ec.SendDate as date) Between @StartDate and @EndDate and
		ee.EventDate < Dateadd(day,3,SendDateTime)
Group By ec.CampaignKey,
		ec.CampaignName,
		ec.SendDatetime,
		ee.fanid
) as a
Inner join Warehouse.relational.Redemptions	as r
	on	a.FanID = r.FanID and
		r.RedeemDate >= SendDatetime and r.RedeemDate <  Dateadd(day,3,SendDateTime) and
		cancelled = 0
inner join Warehouse.Relational.Customer as c
	on	a.FanID = c.FanID
Group By a.CampaignName,a.CampaignKey,
		a.SendDatetime,
		r.RedeemType
		
Order by	SendDatetime,CampaignName,RedeemType
		