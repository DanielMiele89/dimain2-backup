
CREATE Procedure [Staging].[SSRS_R0021_SMSCampaignAnalysis]
				 @StartDate date
As
--Declare @SMSCampaignID int

--Set @SMSCampaignID = 5
--------------------------------------------------------------------------
--------------------Collect basic Campaign Information--------------------
--------------------------------------------------------------------------
if object_id('tempdb..#t1') is not null drop table #t1
select	c.SMSCampaignID,
		Acc.ClubID,
		SendDateTime, 
		Dateadd(second,-1,Dateadd(day,3,SendDateTime)) as MidDate,
		Dateadd(second,-1,Dateadd(day,7,SendDateTime)) as EndDate,
		Count(Distinct mem.FanID) as CustomerCount
Into #t1
from Warehouse.relational.SMSCampaign as c
inner join warehouse.relational.EmailCampaign as ec
	on c.CampaignKey = ec.CampaignKey
inner join warehouse.relational.SMSCampaignMembers as mem
	on c.SMSCampaignID = mem.SMSCampaignID
Inner join Relational.Customer as Acc
	on mem.FanID = Acc.FanID
Where ec.SendDate >= @StartDate
Group by c.SMSCampaignID,
		SendDateTime, 
		Acc.ClubID
--------------------------------------------------------------------------
--------Find redemption information at a customer level-------------------
--------------------------------------------------------------------------
if object_id('tempdb..#t2') is not null drop table #t2
Select	SMSCampaignID,
		RedeemType,
		RedeemTime,
		Count(FanID) as RedeemerCount,
		Sum(Redemptions) as Redemptions,
		Sum(CashbackUsed) as CashbackUsed,
		Coalesce(SUm(Tradeupvalue),0) as TradeUpValueuv
Into #t2
From
(Select	mem.SMSCampaignID,
		r.FanID,
		r.RedeemType,
		Case
			When RedeemDate <= SendDatetime then 'Pre Send'
			When RedeemDate <= MidDate then 'First Three Days'
			When RedeemDate <= EndDate then 'Seven Days'
		End as Redeemtime,
		Count(Distinct r.TranID) as Redemptions,
		Sum(r.CashbackUsed) as CashbackUsed,
		Sum(r.TradeUp_Value) as Tradeupvalue
from Relational.SMSCampaignMembers as mem
inner join Relational.Redemptions as r
	on mem.FanID = r.FanID
inner join #t1 as t
	on mem.SMSCampaignID = t.SMSCampaignID
Where r.Cancelled = 0 and r.RedeemDate <= EndDate
Group By mem.SMSCampaignID,
	   r.FanID,
	   r.RedeemType,
	   Case
			When RedeemDate <= SendDatetime then 'Pre Send'
			When RedeemDate <= MidDate then 'First Three Days'
			When RedeemDate <= EndDate then 'Seven Days'
		End
) as a
Group by SMSCampaignID,
		RedeemType,
		RedeemTime
---------------------------------------------------------------------------------
------------------------------------Output Data----------------------------------
---------------------------------------------------------------------------------
Select	#t1.ClubID,
		#t1.SendDateTime,
		#t1.MidDate,
		#t1.EndDate,
		#t1.CustomerCount,
		#t2.*
from #t1 
inner join #t2
	on #t1.SMSCampaignID = #t2.SMSCampaignID
