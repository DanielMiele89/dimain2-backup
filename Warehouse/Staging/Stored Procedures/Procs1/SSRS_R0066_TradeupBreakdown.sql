CREATE Procedure [Staging].[SSRS_R0066_TradeupBreakdown]
As

Select	a.CampaignKey,
		a.CampaignName,
		a.SendDatetime,
		r.RedeemType,r.PartnerID,r.PartnerName,
		Count(*) As redemptions,
		Sum(CashbackUsed) as CashbackUsed,
		Sum(r.TradeUp_Value) as TradeUpValue

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
		ee.EventDate < Dateadd(day,3,SendDateTime)
Group By ec.CampaignKey,
		ec.CampaignName,
		ec.SendDatetime,
		ee.fanid
) as a
Left Outer join Warehouse.relational.Redemptions	as r
	on	a.FanID = r.FanID and
		r.RedeemDate >= SendDateTime and r.RedeemDate <  Dateadd(day,3,SendDateTime) and
		cancelled = 0
Where RedeemType = 'Trade Up'
Group by a.CampaignName,a.CampaignKey,
		a.SendDateTime,
		r.RedeemType,r.PartnerID,r.PartnerName