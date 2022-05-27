/*

	Author:			Stuart Barnley


	Date:			29th June 2017


	Purpose:		To display RBSG open offers and whether they currently have membes assigned. This is used to help 
					work out which offers need memberships running

*/

CREATE Procedure Staging.[SSRS_R_0162_OpensRBSGOffers] (@EmailDate date,@NeedsMembers int)
With Execute as Owner
as

Declare	@Date Date = @EmailDate, --*******************Date that selections need to be pulled for (and emails is due to be sent)
		@Today Date = getdate(), --**********Used to stored todays date for queries lower down
		@NM int = @NeedsMembers

------------------------------------------------------------------------------------------------------
-----------------------------Put dates in table so code can be used later-----------------------------
------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Dates') is not null drop table #Dates
	
Select	@Date as EmailDate,
		@Today as Today 
into #Dates	

------------------------------------------------------------------------------------------------------
----------Create a list of Natwest Offers that are or will be live by the date entered above----------
------------------------------------------------------------------------------------------------------

Declare @t1 date = (Select EmailDate From #Dates)

if object_id('tempdb..#Offers') is not null drop table #Offers

Select *
into #Offers
From warehouse.relational.IronOffer as i
Where	StartDate <= @t1 and
		(	EndDate is null or
			EndDate > @t1
		) 

Create Clustered Index cix_Offers_IronOfferID 
										on #Offers (IronOfferID)

------------------------------------------------------------------------------------------------------
-----------------------Filter down the list to offers that should need assessment---------------------
------------------------------------------------------------------------------------------------------
Declare @today_Local date = (Select Today From #Dates)

if object_id('tempdb..#CSR_Offers_Filtered') is not null drop table #CSR_Offers_Filtered

Select	Coalesce(ClientServicesRef,'Unknown') as ClientServicesRef,
		p.PartnerID,
		p.PartnerName,
		o.IronOfferID,
		o.IronOfferName,
		o.StartDate,
		o.EndDate
Into #CSR_Offers_Filtered
From #Offers as o
Left Outer join warehouse.relational.PartnerOffers_Base as b --***check if offer is a core base offer
	on	o.IronOfferID = b.OfferID
inner join warehouse.relational.partner as p
	on	o.PartnerID = p.PartnerID and
		BrandID is not null
Left Outer join warehouse.relational.IronOffer_Campaign_HTM as a --*** Collect Clietn Services ref
	on o.IronOfferID = a.IronOfferID
Where b.OfferID is null and  --*** remove core base offers
		IsAboveTheLine = 0 and --*** remove offers that were created for ATL advertising
		IsDefaultCollateral = 0 and --*** remove offers created to add contents by default to other partner offers
		o.PartnerID not in (3962,3963,3724) and --*** remove offers for TUI & NCP whose offers were never closed
		Not (Issignedoff = 0 and o.startdate <= @today_Local) and --*** remove any offers from the past that are still not signed off
		Not (ClientServicesRef is null and o.StartDate <= @today_Local) --*** remove offers from the past that have no CLietn Services Reference
Order by 1

Create Clustered index cix_CSR_Offers_Filtered_IronOfferID 
											on #CSR_Offers_Filtered (IronOfferID)

------------------------------------------------------------------------------------------------------
---------------------Pull together list of offers and the latest start and end dates------------------
------------------------------------------------------------------------------------------------------

if object_id('tempdb..#OfferMembers') is not null drop table #OfferMembers

Select	c.ClientServicesRef,
		c.PartnerID,
		c.PartnerName,
		Max(i.StartDate) as LatestBatch_StartDate,
		Max(i.EndDate) as LatestBatch_EndDate
Into #OfferMembers
From #CSR_Offers_Filtered as c
left Outer join slc_report.dbo.ironoffermember as i
	on c.IronOfferID = i.IronOfferID
Group by c.ClientServicesRef,c.PartnerID,c.PartnerName

------------------------------------------------------------------------------------------------------
----------------------------------Display list of offers with S & E Dates-----------------------------
------------------------------------------------------------------------------------------------------


Select *,
		Case
			When LatestBatch_EndDate < @Date then 1 
			Else 0
		End as NeedsMembers
from #OfferMembers
Where @NM = 1 or LatestBatch_EndDate < @Date
Order by 2