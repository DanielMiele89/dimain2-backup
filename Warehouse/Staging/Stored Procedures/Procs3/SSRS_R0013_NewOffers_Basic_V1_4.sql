/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0013.

					This pulls off the data related to new offers so they
					can be passed on for checking, the data pulled includes the
					Ad Space weightings.

	Update:			08-07-2014 SB - Updated to deal with 2% non-core entries in table
					02/02/2016 SB - Added DisplaySuppressed field to see which offers which
									not be visible to the client when they log into the website
					24/05/2017 ZT - Added checks in comparison to PartnerDeals table and extended
									to nFI's

					
*/
CREATE Procedure [Staging].[SSRS_R0013_NewOffers_Basic_V1_4]
				 @StartDate Date, @EndDate Date
as


--declare @StartDate date = '2017-05-25', @EndDate date = '2018-05-25', @PublisherID int = 132
----------------------------------------------------------------------
-----------------------List of Non Basic Offers-----------------------
----------------------------------------------------------------------
--Offers with Minimum Spend or MID related rules
if object_id('tempdb..#BasicOffers') is not null drop table #BasicOffers
Select DISTINCT I.IronOfferID
Into #BasicOffers
from Warehouse.relational.IronOffer as i
inner join SLC_REPL.dbo.PartnerCommissionRule as pcr
	on i.IronOfferID = pcr.RequiredIronOfferID
Where	Status = 1 AND 
		(	pcr.RequiredMinimumBasketSize is not null or 
			pcr.RequiredMerchantID is not null or 
			pcr.RequiredChannel is not null
		) and
		Cast(i.StartDate as Date) Between @StartDate and @EndDate
----------------------------------------------------------------------
----------------Pull off a list of offers and rates-------------------
----------------------------------------------------------------------
if object_id('tempdb..#Offers') is not null drop table #Offers
Select a.*
Into #Offers
from 
(Select I.IronOfferID, 
		I.IronOfferName,
		i.StartDate,
		i.EndDate,
		Datediff(day,i.StartDate,i.EndDate)+1  as OfferPeriod,
		I.PartnerID,
		P.PartnerName,
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
inner join SLC_REPL.dbo.PartnerCommissionRule as pcr
	on	i.IronOfferID = pcr.RequiredIronOfferID
lEFT OUTER join #BasicOffers BO
	on	i.IronOfferID = BO.IronOfferID
Left Outer join (Select distinct OfferID from warehouse.relational.partneroffers_base) as PR
	on	I.IronOfferID = PR.OfferID
inner join warehouse.relational.partner as p
	on	i.PartnerID = P.PartnerID
Where	pr.OfferID is null and 
		IronOfferName not in ('Above the line') and
		i.IsTriggerOffer = 0 and
		Cast(i.StartDate as Date) Between @StartDate and @EndDate AND
		BO.IronOfferID IS NULL and i.IronOfferID > 750
Group by I.IronOfferID, 
		I.IronOfferName,
		i.StartDate,
		i.EndDate,
		I.PartnerID,
		P.PartnerName,
		i.Clubs
) as a

----------------------------------------------------------------------
--------------------------Find Weighting values-----------------------
----------------------------------------------------------------------
if object_id('tempdb..#OffersAS') is not null drop table #OffersAS
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
Into #OffersAS
from #Offers as o
inner join SLC_REPL.dbo.IronOfferAdSpace as a
	on o.IronOfferID = a.IronOfferID and a.AdSpaceID in (8,15,23)
Group by o.IronOfferID,o.IronOfferName,o.PartnerID,o.PartnerName,o.StartDate,
		 o.EndDate,o.OfferPeriod,o.CashbackRate,o.CommissionRate,o.Clubs
-----------------------------------------------------------------------------------
--------------------------------------Add Suppression Field------------------------
-----------------------------------------------------------------------------------
if object_id('tempdb..#PreCalc') is not null drop table #PreCalc
Select	o.*,
		i.DisplaySuppressed
Into #PreCalc
from #OffersAS as o
inner join SLC_REPL.dbo.IronOffer as i
	on o.IronOfferID = i.id


/******************************************************************		
		Calculate billing rate based on PartnerDeals table 
******************************************************************/

if object_id('tempdb..#CalculatedRate') is not null drop table #CalculatedRate
Select x.*
	, case 
		when p.FixedOverride = 1 then
			 x.cashbackrate + p.Override
		when p.FixedOverride = 0 THEN	
			(p.Override * x.CashbackRate) + x.CashbackRate
	else 0
	End as [CalculatedRate]
Into #CalculatedRate
From #PreCalc x
Left Join Warehouse.apw.PartnerAlternate pa
	on pa.PartnerID = x.partnerid
left Join Warehouse.Relational.nFI_Partner_Deals p
	on p.ClubID = 132
	and p.partnerid = coalesce(pa.AlternatePartnerID, x.partnerid)
	and p.EndDate is null

Select *
from #CalculatedRate