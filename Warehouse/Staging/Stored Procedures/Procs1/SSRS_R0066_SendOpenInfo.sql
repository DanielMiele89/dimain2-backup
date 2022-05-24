CREATE Procedure [Staging].[SSRS_R0066_SendOpenInfo]
As

Select	a.CampaignKey,
		CampaignName,
		SendDateTime,
		Sum(SentSuccessfully)	as SentSuccessfully,
		Sum(Opened)		as Opened,
		Sum(Case
				When Redemptions > 0 then 1
				Else 0
			End) as Redeemers,
		Sum(Redemptions) as Redemptions,
		Sum(Total_CashbackUsed) as CashbackUsed,
		ROW_NUMBER() OVER(ORDER BY SendDateTime) AS RowNo
From
(Select	a.CampaignKey,
		a.CampaignName,
		a.SendDateTime,
		a.FanID,
		a.SentSuccessfully,
		a.Opened,
		Sum(Case
				When TranID is not null then 1
				Else 0
			End) Redemptions,
		Sum(r.CashbackUsed) as Total_CashbackUsed
from
(select	ec.CampaignKey,
		ec.CampaignName,
		ec.SendDateTime,
		FanID,
		Max(Case
				When EmailEventCodeID in (910) then 1
				Else 0
			End) SentSuccessfully,
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
		ec.SendDateTime,
		ee.fanid
) as a
Left Outer join Warehouse.relational.Redemptions	as r
	on	a.FanID = r.FanID and
		r.RedeemDate >= SendDateTime and r.RedeemDate <  Dateadd(day,3,SendDateTime) and
		cancelled = 0
Group By a.CampaignName,a.CampaignKey,
		a.SendDateTime,
		a.FanID,
		a.SentSuccessfully,
		a.Opened
) as a
Group by CampaignName,a.CampaignKey,
		SendDateTime