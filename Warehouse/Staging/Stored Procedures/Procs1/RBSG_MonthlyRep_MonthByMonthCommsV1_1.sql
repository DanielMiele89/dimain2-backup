Create Procedure [Staging].[RBSG_MonthlyRep_MonthByMonthCommsV1_1] (@StartDate Date, @EndDate Date)
as
--declare @StartDate date, @EndDate date
--Set @StartDate = 'Dec 01, 2013'
--set @EndDate = 'Dec 31, 2013'
if object_id('tempdb..#MonthlyEmailCounts') is not null drop table #MonthlyEmailCounts
Select	SendDate,
		SUM(EmailsSent) as Total_EmailsSent,
		Count(FanID)	as Unique_CustomerCount,
		Sum(Opened)		as Opens,
		Cast(Sum(Opened)as float)/ cast(SUM(EmailsSent) as float) as Opens_Pct,
		sum(LinkClicked) as Links_Clicked,
		Cast(sum(LinkClicked) as float) / Cast(Sum(Opened)as float) as LinkClicked_Pct,
		Sum(Unsubscribes)as Unsubscribes,
		Cast(Sum(Unsubscribes) as float) /CAST(SUM(EmailsSent) as float) as Unsubscribe_Pct
into	#MonthlyEmailCounts
from
(Select	cast(datename(month,senddate) + ' 01, ' + cast(YEAR(senddate) as varchar(4)) as DATe) as SendDate,
		FanID,
		Sum(EmailSentOK) as EmailsSent,
		(Sum(EmailSentOK)-SUM(SB))-SUM(HB) as Delivered,
		Sum(EmailOpened) as Opened,
		Sum(ClickLink) as LinkClicked,
		Sum(Unsubscribed) as Unsubscribes
from
(select	ec.CampaignKey,ec.senddate,ec.CampaignName,Reference,EmailType,EmailName,FanID,
		max(Case When ee.EmailEventCodeID in (901,910) then 1 else 0 end) as EmailSentOK,
		Max(Case When ee.EmailEventCodeID = 1301 then 1 else 0 end) as EmailOpened,
		Max(Case When ee.EmailEventCodeID = 605 then 1 else 0 end) as ClickLink,
		Max(Case When ee.EmailEventCodeID in (301,303) then 1 else 0 end) as Unsubscribed ,
		Max(Case When ee.EmailEventCodeID = 701 then 1 else 0 end) as SB, 
		Max(Case When ee.EmailEventCodeID = 702 then 1 else 0 end) as HB
from SLC_Report.dbo.EmailCampaign as ec
inner join SLC_Report.dbo.EmailEvent as ee
	on ec.CampaignKey = ee.campaignkey
inner join warehouse.Relational.CampaignLionSendIDs as cls
	on ee.CampaignKey = cls.CampaignKey	
Where	ec.senddate  >= @StartDate and
		ec.SendDate  <  dateadd(day,1,@EndDate)
Group by ec.CampaignKey,ec.senddate,ec.CampaignName,FanID,Reference,EmailType,EmailName
) as a
Group by cast(datename(month,senddate) + ' 01, ' + cast(YEAR(senddate) as varchar(4)) as DATe),
		FanID
) as a
Group by SendDate

-----------------------------------------------------------------------------------------------------
--------------------Get unique list of offers promoted per month ------------------------------------
-----------------------------------------------------------------------------------------------------
if object_id('tempdb..#OfferPromotions') is not null drop table #OfferPromotions
Select	SendDate,
		Count(ClientServicesRef) as OffersPromoted,
		Sum(Case
				When AboveBase > 0 then 1
				Else 0
			End) as AboveBaseOffers,
		Sum(Case
				When AboveBase = 0 then 1
				Else 0
			End) as BaseOffers
Into	#OfferPromotions
from	

(select m.SendDate, 
		Case
			When i.ClientServicesRef IS not null then i.ClientServicesRef
			Else --Base.ClientServicesRef
					'XB-'+cast(base.PartnerID as CHAR(4)) + '-'+ cast(datepart(Year,base.StartDate) as CHAR(4))+ '-'+cast(datepart(month,base.StartDate) as CHAR(2))
		End as ClientServicesRef,
		Max(Case
				When i.AboveBase IS not null then i.AboveBase
				Else 0
			End) as AboveBase
 from #MonthlyEmailCounts as m
inner join SLC_Report.dbo.EmailCampaign as ec
	on ec.SendDate >= m.SendDate and ec.SendDate < dateadd(month,1,m.SendDate)
inner join warehouse.Relational.CampaignLionSendIDs as cls
	on ec.CampaignKey = cls.CampaignKey
inner join SLC_Report.lion.LionSendComponent as lsc
	on cls.LionSendID = lsc.LionSendID
Left Outer join warehouse.relational.IronOffer_Campaign_HTM as i	
	on lsc.ItemID = i.Ironofferid
inner join Warehouse.relational.IronOffer as Base
--Left Outer join (select pbo.OfferID, 'XB-'+cast(pbo.PartnerID as CHAR(4)) + '-'+ cast(datepart(Year,pbo.StartDate) as CHAR(4))+ '-'+cast(datepart(month,pbo.StartDate) as CHAR(2)) as ClientServicesRef
	--			 from warehouse.relational.Partner_BaseOffer as pbo)	
		--		 as Base
	on lsc.ItemID = Base.IronOfferID
	
Group by m.SendDate, 
		Case
			When i.ClientServicesRef IS not null then i.ClientServicesRef
			Else --Base.ClientServicesRef
				'XB-'+cast(base.PartnerID as CHAR(4)) + '-'+ cast(datepart(Year,base.StartDate) as CHAR(4))+ '-'+cast(datepart(month,base.StartDate) as CHAR(2))
		End
Union all
select m.SendDate, 
		i.ClientServicesRef,
		Max(i.AboveBase)as AboveBase
 from #MonthlyEmailCounts as m
inner join SLC_Report.dbo.EmailCampaign as ec
	on ec.SendDate >= m.SendDate and ec.SendDate < dateadd(month,1,m.SendDate)
inner join warehouse.relational.CampaignLionSendIDs as cls
	on ec.CampaignKey = cls.CampaignKey
Left Outer join warehouse.Relational.IronOffer_Campaign_HTM as i
	on i.IronOfferid between cls.HardCoded_OfferFrom and cls.HardCoded_OfferTo
Group by m.SendDate, 
		i.ClientServicesRef
Having Max(i.AboveBase) >= 0
) as a
Group by SendDate

--select * from #OfferPromotions
-----------------------------------------------------------------------------------------------------
------------------------Create Averages for Offer Promotions-----------------------------------------
-----------------------------------------------------------------------------------------------------
if object_id('tempdb..#OfferPromotions_RT') is not null drop table #OfferPromotions_RT
Select OP1.*, 
		AVG(op2.OffersPromoted)		as Avg_OffersPromoted,
		AVG(op2.AboveBaseOffers)	as Avg_AboveBaseOffers,
		AVG(op2.BaseOffers)			as Avg_BaseOffers
into	#OfferPromotions_RT
from #OfferPromotions as OP1
inner join #OfferPromotions as OP2
	on OP1.SendDate >= OP2.SendDate
Group by op1.SendDate,op1.OffersPromoted,op1.AboveBaseOffers,op1.BaseOffers
-----------------------------------------------------------------------------------------------------
------------------------Create Final Emails and Offers Data-----------------------------------------
-----------------------------------------------------------------------------------------------------
if object_id('Warehouse.staging.RBSG_MonthlyReport_MonthByMonthComms') is not null drop table Warehouse.staging.RBSG_MonthlyReport_MonthByMonthComms
Select	m1.*,
		AVG(m2.Total_EmailsSent) as Avg_EmailsSent,
		AVG(m2.Unique_CustomerCount) as Avg_CustomerCount,
		AVG(m2.Opens) as Avg_Opens,
		Cast(AVG(m2.Opens) as float) / CAST(AVG(m2.Total_EmailsSent) as float) as Avg_Open_Pct,
		AVG(m2.Links_Clicked) as Avg_Links_Clicked,
		CAST(AVG(m2.Links_Clicked) as float) / Cast(AVG(m2.Opens) as float) as Avg_Links_Pct,
		AVG(m2.Unsubscribes) as Avg_Unsubscribes,
		Cast(AVG(m2.Unsubscribes) as float)/AVG(m2.Total_EmailsSent) as Avg_Unsubscribes_Pct,
		Case
			When m1.SendDate = Dateadd(Month,-1,Dateadd(day,1,@EndDate)) then 'TM'
			When m1.SendDate = Dateadd(Month,-2,Dateadd(day,1,@EndDate)) then 'LM'
			Else 'O'
		End as WhichMonth,
		Op.OffersPromoted,
		Op.AboveBaseOffers,
		Op.BaseOffers,
		OP.Avg_OffersPromoted,
		OP.Avg_AboveBaseOffers,
		Op.Avg_BaseOffers
Into Warehouse.staging.RBSG_MonthlyReport_MonthByMonthComms
from #MonthlyEmailCounts as m1
inner join #MonthlyEmailCounts m2
	on m1.SendDate >= m2.SendDate
Inner join #OfferPromotions_RT as OP
	on m1.SendDate = op.SendDate
Group by M1.SendDate,M1.Total_EmailsSent,M1.Unique_CustomerCount,M1.Opens,M1.Opens_Pct,M1.Links_Clicked,M1.LinkClicked_Pct,M1.Unsubscribes,
		 M1.Unsubscribe_Pct,Op.OffersPromoted,Op.AboveBaseOffers,Op.BaseOffers,OP.Avg_OffersPromoted,OP.Avg_AboveBaseOffers,Op.Avg_BaseOffers