/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0013.

					This pulls off the data related to new offers so they
					can be passed on for checking, the data pulled includes the
					Ad Space weightings.

					This section is for offers with conditions (Spend or MID)

	Update:			N/A
					
*/
CREATE Procedure [Staging].[SSRS_R0013_NewOffers_WithConditions_v1_2]
				 @StartDate Date, @EndDate Date
as
----------------------------------------------------------------------
-----------------------List of Non Basic Offers-----------------------
----------------------------------------------------------------------
if object_id('tempdb..#BasicOffers') is not null drop table #BasicOffers
Select Distinct I.IronOfferID
Into #BasicOffers
from Warehouse.relational.IronOffer as i
inner join SLC_Report.dbo.PartnerCommissionRule as pcr
	on i.IronOfferID = pcr.RequiredIronOfferID
Where Status = 1 and 
		(	pcr.RequiredMinimumBasketSize is not null or 
			pcr.RequiredMerchantID is not null or 
			pcr.RequiredChannel is not null
			) and
		Cast(i.StartDate as Date) Between @StartDate and @EndDate
----------------------------------------------------------------------
----------------Pull off a list of offers and rates-------------------
----------------------------------------------------------------------
if object_id('tempdb..#Offers') is not null drop table #Offers
Select a.*,
		Case
			When pcr.CommissionType = 'Invoiced Offline' and pcr.commissionrate = a.commissionrate then 'Yes'
			When pcr.CommissionType = 'Percent' and 
			a.CashbackRate* (pcr.CommissionRate/pcr.CurrentRate) between a.CommissionRate - 0.001 and a.CommissionRate + 0.001 then 'Yes'
			Else 'No'
		End as CommissionRatesCheck
Into #Offers
 from 
(Select I.IronOfferID, 
		I.IronOfferName,
		i.StartDate,
		i.EndDate,
		Datediff(day,i.StartDate,i.EndDate)+1  as OfferPeriod,
		I.PartnerID,
		P.PartnerName,
		PCR.RequiredMerchantID,
		PCR.RequiredMinimumBasketSize,
		PCR.RequiredChannel,
		Max(Case
				When TypeID = 1 and Status = 1 then pcr.CommissionRate
				Else NULL
			End) as CashbackRate,
		Max(Case
				When TypeID = 2 and Status = 1 then pcr.CommissionRate
				Else NULL
			End) as CommissionRate,
		I.Clubs
from warehouse.relational.ironoffer as I
inner join SLC_Report.dbo.PartnerCommissionRule as pcr
	on	i.IronOfferID = pcr.RequiredIronOfferID
inner join #BasicOffers BO
	on	i.IronOfferID = BO.IronOfferID
Left Outer join (Select distinct OfferID from warehouse.relational.partneroffers_base) as PR
	on	I.IronOfferID = PR.OfferID
inner join warehouse.relational.partner as p
	on	i.PartnerID = P.PartnerID
Where	pr.OfferID is null and IronOfferName not in ('Above the line') and
		i.IsTriggerOffer = 0 and i.StartDate >= 'Aug 08, 2013' and
		--(pcr.RequiredMerchantID is not null or pcr.RequiredMinimumBasketSize is not null) and
		Cast(i.StartDate as date) Between @StartDate and @EndDate and PCR.Status = 1

Group by I.IronOfferID, 
		I.IronOfferName,
		i.StartDate,
		i.EndDate,
		I.PartnerID,
		P.PartnerName,
		i.Clubs,
		PCR.RequiredMerchantID,
		PCR.RequiredMinimumBasketSize,
		PCR.RequiredChannel

) as a
Left outer join Warehouse.[Relational].[PartnerCommissionRates_PostLaunch] pcr
	on a.Partnerid = pcr.Partnerid
----------------------------------------------------------------------
--------------------------Find Weighting values-----------------------
----------------------------------------------------------------------
Select o.*,
		Max(Case	
				When a.AdSpaceID = 8 then a.[Weight] 
				Else -1
			End) as [Hero_Retail_Banner_8],
		Max(Case	
				When a.AdSpaceID = 15 then a.[Weight] 
				Else -1
			End) as [Retail_Recommendation_Item_15],
		Max(Case	
				When a.AdSpaceID = 23 then a.[Weight] 
				Else -1
			End) as [Regular_Offer_23]
from #Offers as o
inner join slc_report.dbo.IronOfferAdSpace as a
	on o.IronOfferID = a.IronOfferID and a.AdSpaceID in (8,15,23)
Group by o.IronOfferID,o.IronOfferName,o.PartnerID,o.PartnerName,o.StartDate,
		 o.EndDate,o.OfferPeriod,o.CommissionRatesCheck,o.CashbackRate,o.CommissionRate,o.Clubs,
		 RequiredMerchantID,RequiredMinimumBasketSize,RequiredChannel