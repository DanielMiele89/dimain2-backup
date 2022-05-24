﻿
CREATE PROCEDURE [Staging].[SSRS_R0140_CurrentLiveOffers_SignedOff_Display]

as
begin


	declare @date date = GETDATE()

	select
		  io.clubs [Club]
		, p.partnername [Partner]
		, h.ClientServicesRef 
		, io.ironofferid [IronOfferID]
		, io.IronOfferName [IronOfferName]
		, io.startdate [StartDate]
		, io.enddate [EndDate]
		, io.Topcashbackrate [TopCashBackRate]
		, io.Campaigntype [CampaignType]
		, case 
				when pn.ironofferid is not null then 1 
				else 0 
		  end as [NonCoreBaseOffer]
		, case 
				when po.offerid is not null then 1 
				else 0 
		  end as [CoreBaseOffer]
		, case 
				when po.offerid is null and pn.ironofferid is null then 'Shopper Segments'
				when pn.IronOfferID is not null and po.offerid is null then 'Non-Core Base Offer'
				when po.offerid is not null then 'Base Offer'
		  end as [Category]
		, Case
				When DENSE_RANK() Over (Order by io.Campaigntype, p.partnername) % 2  = 1 Then '#4b196e'
				Else '#dc0f50'
		  End as PartnerColour
		, Case
				When DENSE_RANK() Over (Order by io.Campaigntype, p.partnername, Coalesce(h.ClientServicesRef, '')) % 2  = 1 Then '#bcbcbc'
				Else '#9d9d9d'
		  End as ClientServicesRefColour
	from relational.ironoffer io
	inner join relational.partner p 
		on p.partnerid = io.partnerid
	left outer join Relational.IronOffer_Campaign_HTM h
		on h.IronOfferID = io.IronOfferID
	left outer join relational.Partner_NonCoreBaseOffer pn
		on pn.ironofferid = io.ironofferid
	left outer join (select distinct offerid
						from relational.PartnerOffers_Base) po
		on po.offerid = io.IronOfferID
	where io.startdate <= @date
	And (	io.enddate > @date
		 or io.enddate is null)
	and io.issignedoff = 1
--	and p.CurrentlyActive = 1
	and io.IsDefaultCollateral = 0
	and io.IsAboveTheLine = 0
	and p.BrandID is not null
	Order by  p.partnername
			, h.ClientServicesRef
			, io.ironofferid

END