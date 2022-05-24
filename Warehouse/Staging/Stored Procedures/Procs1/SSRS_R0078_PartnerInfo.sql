CREATE Procedure [Staging].[SSRS_R0078_PartnerInfo]
as
--------------------------------------------------------------------------------------
-----------------------Get an initial list of Merchants on CBP------------------------
--------------------------------------------------------------------------------------
if object_id('tempdb..#Part') is not null drop table #Part
select	p.PartnerName,
		p.PartnerID,
		Case	
			When p.PartnerID = 4447 then 'RBS Funded'
			When Core = 'Y' then 'Core'
			Else 'Non-Core'
		End as MerchantType
Into #Part
from Relational.partner as p
inner join Relational.Partner_CBPDates as d
	on p.PartnerID = d.PartnerID
left outer join Relational.Master_Retailer_Table as mrt
	on p.PartnerID = mrt.PartnerID
Where d.Scheme_EndDate is null or d.Scheme_Enddate >= Cast(getdate() as date)
--------------------------------------------------------------------------------------
----------------------------------------Find Base Offers------------------------------
--------------------------------------------------------------------------------------
if object_id('tempdb..#OffersBase') is not null drop table #OffersBase
Select Distinct p.PartnerID,p.PartnerName,p.MerchantType,i.IronOfferID
Into #OffersBase
from #Part as p
inner join Relational.PartnerOffers_Base as b
	on p.PartnerID = b.PartnerID
inner join Relational.IronOffer as i
	on b.OfferID = i.IronOfferID
Where i.EndDate is null or i.EndDate >= Cast(getdate() as date)
Union All
Select Distinct p.PartnerID,p.PartnerName,p.MerchantType,IronOfferID
from #Part as p
inner join Relational.Partner_BaseOffer as b
	on p.PartnerID = b.PartnerID
inner join Relational.IronOffer as i
	on b.OfferID = i.IronOfferID
Where i.EndDate is null or i.EndDate >= Cast(getdate() as date)
Union All
Select Distinct p.PartnerID,p.PartnerName,p.MerchantType,n.IronOfferID
from #Part as p
inner join Relational.Partner_NonCoreBaseOffer as n
	on p.PartnerID = n.PartnerID
inner join Relational.IronOffer as i
	on n.IronOfferID = i.IronOfferID
Where i.EndDate is null or i.EndDate >= Cast(getdate() as date)
--------------------------------------------------------------------------------------
-----------------Find Client Services Ref for Base Where possible---------------------
--------------------------------------------------------------------------------------
if object_id('tempdb..#ob2') is not null drop table #ob2
Select ob.*,ClientServicesRef
into #ob2
from #OffersBase as ob
Left outer join Relational.IronOffer_Campaign_HTM as c
	on ob.IronOfferID = c.IronOfferID

--------------------------------------------------------------------------------------
-------------------CONCATENATE Base Offers and ClientServices Refs -------------------
--------------------------------------------------------------------------------------
--Select * from #OffersBase
if object_id('tempdb..#BOs') is not null drop table #BOs

SELECT DISTINCT PartnerID,PartnerName,MerchantType,
  BaseOffer = STUFF((SELECT ', ' + Cast(IronOfferID as varchar)
                FROM #ob2 t
               where d.PartnerID = t.PartnerID
                FOR XML PATH (''))
                , 1, 1, '') ,
	ClientServicesRef = STUFF((SELECT ', ' + Cast(ClientServicesRef as varchar)
                FROM #ob2 t
                where d.PartnerID = t.PartnerID
                FOR XML PATH (''))
                , 1, 1, '') 
Into #BOs
FROM #ob2 d

-----------------------------------------------------------------------------------------------------------------
-----------------Find Partner Trigger Campaigns that are shop at Merchant and Scheduled Weekly-------------------
-----------------------------------------------------------------------------------------------------------------
Select	p.PartnerID, 
		Cast(pt.CampaignID as varchar) + ' ('+cast(DaysWorthTransactions as varchar)+ ' days)' as PartnerTrigger_CampaignIDs
Into #PTs
from #Part AS P
inner join warehouse.relational.partner as pa
	on p.PartnerID = pa.PartnerID
INNER JOIN [Relational].[PartnerTrigger_Campaigns] as pt
	on p.PartnerID = pt.PartnerID
inner join warehouse.[Relational].[PartnerTrigger_Brands] as ptb
	on	pa.BrandID = ptb.BrandID and
		pt.CampaignID = ptb.CampaignID
Left Outer join warehouse.[Relational].[PartnerTrigger_Brands] as ptb2
	on	pa.BrandID <> ptb2.BrandID and
		pt.CampaignID = ptb2.CampaignID
Where WeeklyExecute = 1
-----------------------------------------------------------------------------------------------------------------
--------------Concatenate Partner Trigger Campaigns that are shop at Merchant and Scheduled Weekly---------------
-----------------------------------------------------------------------------------------------------------------


if object_id('tempdb..#PTsX') is not null drop table #PTsX

SELECT DISTINCT PartnerID,
  PartnerTrigger_CampaignIDs = STUFF((SELECT ', ' + Cast(PartnerTrigger_CampaignIDs as varchar)
                FROM #PTs t
               where d.PartnerID = t.PartnerID
                FOR XML PATH (''))
                , 1, 1, '')
Into #PTsX
FROM #PTs d



Select	p.PartnerName,
		p.PartnerID,
		Case
			When b.PartnerID is null then 'STO'
			Else p.MerchantType
		End as MerchantType,
		BaseOffer,
		ClientServicesRef,
		pt.PartnerTrigger_CampaignIDs
from #Part as p
left outer join #BOs as b
	on p.PartnerID = b.PartnerID
Left Outer join #PTsX as pt
	on p.PartnerID = pt.PartnerID

Order by PartnerName

