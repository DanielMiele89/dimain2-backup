
	
	
	
CREATE PROCEDURE [Selections].[ROCShopperSegment_OfferSetup] @StartDate date
WITH EXECUTE AS OWNER
AS
BEGIN

	--Declare @StartDate Date = GETDATE()
	
		/******************************************************************		
				Untick live offers 
		******************************************************************/
		
			Update a
			Set LiveOffer = 0
			From Selections.ROCShopperSegment_AllOffers as a
			inner join [Relational].IronOffer as i
				on a.IronOfferID = i.ID
			Where i.EndDate < @StartDate and
				LiveOffer = 1

		/******************************************************************		
				Get the new offers to add to the table 
		******************************************************************/

			-- ** Populate temp table for later use
			IF OBJECT_ID('tempdb..#OffersToAdd') IS NOT NULL DROP TABLE #OffersToAdd
			Select
				 io.ID IronOfferID
				, PartnerID
				, ClubID
				, 1 LiveOffer
				, Case 
						When IronOfferName like '%Acquire%' Then 7
					--	When IronOfferName like '%Low Interest%' Then 7
						When IronOfferName like '%Lapsed%' Then 8
					--	When IronOfferName like '%Winback%' Then 8
						When IronOfferName like '%Shopper%' Then 9
					--	When IronOfferName like '%Retain%' Then 9
					--	When IronOfferName like '%Grow%' Then 9
						Else NULL 
					End as ShopperSegmentTypeID
				, Case 
					When IronOfferName like '%Welcome%' Then 2
					When IronOfferName like '%Launch%' Then 3
					When IronOfferName like '%Universal%' Then 4
					When IronOfferName like '%Base%' Then 5
					Else 1
				End as OfferType
				, GETDATE() DateAdded
			Into #OffersToAdd
			From NFI.Relational.IronOffer io
			Left Outer Join Selections.ROCShopperSegment_AllOffers ao
				on ao.IronOfferID = io.ID
			Where StartDate < @StartDate
				and Enddate > @StartDate
				and IsSignedOff = 1
				and ao.IronOfferID is NULL -- Only retrieve new rows
				   

			-- ** Insert entries into main table
			Insert into Selections.ROCShopperSegment_AllOffers
			Select IronOfferID
				, LiveOffer
				, ShopperSegmentTypeID
				, OfferType
				, DateAdded 
			from #OffersToAdd

	/******************************************************************		
			Calulate if SecondaryPartnerRecord 
	******************************************************************/

		--Calculate secondary offers
		IF OBJECT_ID('tempdb..#SecondaryOffers') IS NOT NULL DROP TABLE #SecondaryOffers
		Select oa.IronOfferID [PrimaryOfferID]
			, oa2.*	
		Into #SecondaryOffers
		from #OffersToAdd oa
		Left join Warehouse.iron.PrimaryRetailerIdentification pri 
			on pri.PrimaryPartnerID = oa.PartnerID
		Left join #OffersToAdd oa2
			on oa2.PartnerID = pri.PartnerID
			and oa2.OfferType = oa.OfferType 
			and oa2.ShopperSegmentTypeID = oa.ShopperSegmentTypeID
			and oa.ClubID = oa2.ClubID
		Where oa2.IronOfferID is not null
	

		-- Insert into main Mapping table
		Insert Into nFI.Selections.Roc_Offers_Primary_to_Secondary
		Select s.PrimaryOfferID as IronOfferID
			, s.IronOfferID as IronOffer2nd
		from #SecondaryOffers s
		Left join nFI.Selections.Roc_Offers_Primary_to_Secondary ps
			on ps.IronOfferID = s.PrimaryOfferID
			and ps.IronOffer2nd = s.IronOfferID
		Where ps.IronOfferID is null 
		Order by PrimaryOfferID


	/******************************************************************		
			Calculate Welcome vs Launch vs Universal 
	******************************************************************/
	
		Insert into Selections.ROCShopperSegment_WelcomeVsOther
		Select w.IronOfferID IronOfferID_Welcome
			, l.IronOfferID IronOfferID_Launch
			, b.IronOfferID IronOfferID_Universal
		From (
			--** Welcome Offers
			Select IronOfferID, ClubID, PartnerID
			From #OffersToAdd 
			Where OfferType = 2 
			) w
		Left Join (
			-- ** Launch Offers
			Select IronOfferID, ClubID, PartnerID
			From #OffersToAdd 
			Where OfferType = 3
			) l 
		on l.ClubID = w.ClubID
		and l.PartnerID = w.PartnerID
		Left Join (
			-- ** Universal/Base Offers
			Select IronOfferID, ClubID, PartnerID
			From #OffersToAdd 
			Where OfferType in (4,5)
			) b 
		on b.ClubID = w.ClubID
		and b.PartnerID = w.PartnerID
		Left join Selections.ROCShopperSegment_WelcomeVsOther wo
			on wo.IronOfferID_Welcome = w.IronOfferID
			and wo.IronOfferID_Launch = l.IronOfferID
			and wo.IronOfferID_Universal = b.IronOfferID
		Where 1=1
			and (wo.IronOfferID_Welcome <> w.IronOfferID
			and wo.IronOfferID_Launch <> l.IronOfferID
			and wo.IronOfferID_Universal <> b.IronOfferID)
			and (l.IronOfferID IS NOT NULL or b.IronOfferID IS NOT NULL)			

			
	/******************************************************************		
			Insert All Welcome Offers 
	******************************************************************/
	
		Insert Into Warehouse.Iron.WelcomeOffer
		Select oa.IronOfferID, oa.ClubID
		from #OffersToAdd oa
		Inner join Warehouse.Iron.WelcomeOffer w
			on w.IronOfferID = oa.IronOfferID
		Where OfferType = 2
			and w.IronOfferID is NULL


END


