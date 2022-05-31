


CREATE PROCEDURE Segmentation.OfferSetUp (@OfferStartDate date)
As
Begin

--Declare @StartDate Date = '2018-11-08'


/********************************************************************************************
	Name: Segmentation.OfferSetUp
	Desc: To set up the new nFI offers in the relevant tables ready for segmentation
	Auth: Zoe Taylor

	Change History
			Initials Date
				Change Info
	
*********************************************************************************************/


		Declare @StartDate date = @OfferStartDate
		/******************************************************************		
				Find all new offers to be added 
		******************************************************************/

		IF OBJECT_ID('tempdb..#NewOffers') IS NOT NULL DROP TABLE #NewOffers
		Select	ID as IronOfferID,
				io.PartnerID,
				Io.ClubID,
				Case
					When io.IronofferName like '%Retain%' then 6
					When io.IronofferName like '%Grow%' then 5
					When io.IronofferName like '%Win%Prime%' then 4
					When io.IronofferName like '%WinBack%' then 3
					When io.IronofferName like '%Acquire%' then 7
					When io.IronofferName like '%Lapsed%' then 8
					When io.IronofferName like '%Shopper%' then 9
					When io.IronofferName like '%Launch%' then 0
					When io.IronofferName like '%Universal%' then 0
					Else 0
				End as ShopperSegmentTypeID,
				1 as LiveOffer,
				Case
					When io.IronofferName Like '%Welcome%' then 1
					Else 0
				End as WelcomeOffer
		Into	#NewOffers
		From nfi.relational.ironoffer as io
		Where StartDate = @StartDate AND
				io.IsAppliedToAllMembers = 0
		Order by ClubID,PartnerID



		/******************************************************************		
				Find all those that are on Primary partner records
		******************************************************************/

		IF OBJECT_ID('tempdb..#SSTO') IS NOT NULL DROP TABLE #SSTO
		Select	n.IronOfferID,
				n.ShopperSegmentTypeID,
				n.LiveOffer,
				n.WelcomeOffer,
				n.ClubID,n.PartnerID
		Into #SSTO
		from warehouse.iron.PrimaryRetailerIdentification as b
		inner join #NewOffers as n
			on	b.PartnerID = n.PartnerID
		Where PrimaryPartnerID is null
		Order by n.ClubID,n.PartnerID,IroNOfferID

		/******************************************************************		
				Insert any missing rows 
		******************************************************************/
		Insert into [Segmentation].[ROC_Shopper_Segment_To_Offers]
		Select	s.IronOfferID,
				s.ShopperSegmentTypeID,
				s.LiveOffer,
				s.WelcomeOffer
		From #SSTO s
		left outer join nfi.[Segmentation].[ROC_Shopper_Segment_To_Offers] o
			on o.IronOfferID = s.ironofferid 
		where o.IronOfferID is NULL and
				(s.ShopperSegmentTypeID > 1 or s.WelcomeOffer = 1) -- Must be a shopper segment or welcome offer

		/******************************************************************		
					Validate Settings - Amend if needed			 
		******************************************************************/
		
		Select * From #SSTO as s
		Inner join  nfi.[Segmentation].[ROC_Shopper_Segment_To_Offers] as a
			on s.ironofferid = a.IronOfferID
		Where s.welcomeoffer <> a.WelcomeOffer or s.ShopperSegmentTypeID <> a.ShopperSegmentTypeID

		--Update nfi.[Segmentation].[ROC_Shopper_Segment_To_Offers]
		--Set WelcomeOffer = 1
		--Where IronOfferID in (14007,14021)




		/******************************************************************		
				Check Secondary records 
		******************************************************************/

		Insert into [Selections].[Roc_Offers_Primary_to_Secondary]
		Select	c.IronOfferID,
				n.IronOfferID as IronOffer2nd
		from warehouse.iron.PrimaryRetailerIdentification as b
		inner join #NewOffers as n
			on b.PartnerID = n.PartnerID
		inner join #SSTO as c
			on	b.PrimaryPartnerID = c.PartnerID and
				n.ShopperSegmentTypeID = c.ShopperSegmentTypeID and
				n.WelcomeOffer = c.WelcomeOffer and
				n.ClubID = c.ClubID
		Left Outer join [Selections].[Roc_Offers_Primary_to_Secondary] as a
			on c.ironofferid = a.IronOfferID
		Where	PrimaryPartnerID is not null and
				a.ironofferid is null
		Order by n.ClubID,n.PartnerID,n.IroNOfferID

		/******************************************************************		
				get launch offers
		******************************************************************/
		Insert into [Segmentation].[ROC_Shopper_Segment_To_Offers]
		Select o.IronOfferID, o.ShopperSegmentTypeID, o.LiveOffer, o.WelcomeOffer
		from #NewOffers o
		inner join  nFI.Relational.IronOffer io
			on io.ID = o.IronOfferID
		left outer join [Segmentation].[ROC_Shopper_Segment_To_Offers] x
			on x.IronOfferID = o.IronOfferID
		where io.IronOfferName like 'launch%'
		and o.ShopperSegmentTypeID = 0
		and x.IronOfferID is null



		/******************************************************************		
				Check Secondary records 
		******************************************************************/

		Select  IronOffer2nd,i.StartDate
		From nfi.Selections.Roc_Offers_Primary_to_Secondary as a
		inner join nfi.relational.IronOffer as i
			on a.IronOffer2nd = i.id
		Group by  IronOffer2nd,i.StartDate
			Having  Count(*) > 1




		/******************************************************************		
				Add welcome offers
		******************************************************************/
		Insert into [Warehouse].[Iron].[WelcomeOffer] 
		Select n.IronOfferID, n.ClubID
		from #NewOffers n
		left join [Warehouse].[Iron].[WelcomeOffer]  wo
			on wo.IronOfferID = n.IronOfferID
			and wo.ClubID = n.ClubID
		Where WelcomeOffer = 1
		and wo.IronOfferID is null


End