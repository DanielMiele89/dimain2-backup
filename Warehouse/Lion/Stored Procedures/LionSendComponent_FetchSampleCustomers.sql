
/*
	
	Author:		Rory

	Date:		23rd September 2016

	Purpose:	Generate Sample Data for upload INTO SFD for a specific ClubID and LionSendID
	

*/

CREATE PROCEDURE [Lion].[LionSendComponent_FetchSampleCustomers] (@LionSendID INT
															   , @LionSendIDSample INT)
AS
BEGIN

	/*******************************************************************************************************************************************
		1. Fetch customer Brand / Loyalty data
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
		SELECT cu.CLubID
			 , CASE
					WHEN rbsg.CustomerSegment LIKE '%v%' THEN 1
					ELSE 0
			   END AS IsLoyalty
			 , cu.CompositeID
		INTO #Customers
		FROM [Relational].[Customer] cu
		INNER JOIN [Relational].[Customer_RBSGSegments] rbsg
			ON cu.FanID = rbsg.FanID
			AND rbsg.EndDate IS NULL
		WHERE cu.MarketableByEmail = 1

		CREATE CLUSTERED INDEX CIX_All ON #Customers (CompositeID, CLubID, IsLoyalty)


	/*******************************************************************************************************************************************
		2. Join together all earn and burn offers from Nominated Lion Send tables
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CustomerSampleInput') IS NOT NULL DROP TABLE #CustomerSampleInput
		SELECT cu.ClubID
			 , cu.IsLoyalty
			 , nlsc.CompositeID
			 , nlsc.TypeID
			 , nlsc.ItemRank
			 , nlsc.ItemID
			 , nlsc.Date
		INTO #CustomerSampleInput
		FROM [Lion].[NominatedLionSendComponent] nlsc
		INNER JOIN #Customers cu
			ON nlsc.CompositeId = cu.CompositeID
			AND nlsc.LionSendID = @LionSendID
		UNION ALL
		SELECT cu.ClubID
			 , cu.IsLoyalty
			 , nlscr.CompositeID
			 , nlscr.TypeID
			 , nlscr.ItemRank
			 , nlscr.ItemID
			 , nlscr.Date
		FROM [Lion].[NominatedLionSendComponent_RedemptionOffers] nlscr
		INNER JOIN #Customers cu
			ON nlscr.CompositeId = cu.CompositeID
			AND nlscr.LionSendID = @LionSendID

		CREATE CLUSTERED INDEX CIX_TypeClubLoyaltyItemComposite ON #CustomerSampleInput (TypeID, ClubID, IsLoyalty, ItemID, CompositeID)


	/*******************************************************************************************************************************************
		3. Aggregate offer counts per club / loyalty / offer type
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#OffersPre') IS NOT NULL DROP TABLE #OffersPre
		SELECT DISTINCT
			   ClubID
			 , IsLoyalty
			 , TypeID
			 , ItemID
		INTO #OffersPre
		FROM #CustomerSampleInput csi

		IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
		SELECT ClubID
			 , IsLoyalty
			 , TypeID
			 , ItemID
			 , CASE
					WHEN iof.StartDate > GETDATE() THEN 1
					ELSE 0
			   END AS NewOffer
			 , 0 AS Sample
		INTO #Offers
		FROM #OffersPre op
		LEFT JOIN [Relational].[IronOffer] iof
			ON op.ItemID = iof.IronOfferID
			AND op.TypeID = 1


	/*******************************************************************************************************************************************
		4. Select at least one customer per club / loyalty covering all offers
	*******************************************************************************************************************************************/
		
			DECLARE @ClubID INT
				  , @IsLoyalty BIT
				  , @TypeID INT
				  , @ItemID INT
				  , @CompositeID BIGINT


		/***********************************************************************************************************************
			4.1. Create table for sample insert
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Sample') IS NOT NULL DROP TABLE #Sample
			CREATE TABLE #Sample (ClubID INT
								, IsLoyalty BIT
								, CompositeID BIGINT
								, TypeID INT
								, ItemRank INT
								, ItemID INT
								, Date DATETIME)


		/***********************************************************************************************************************
			4.2. Loop through #Offers to select offer with the lowest count of customers per club / loyalty where Sample = 0,
				 select one customer that is assigned that offer and add their entires to the sample table.
				 At the end of each loop update #Offers to set Sample = 1 for all new offers inserted.
		***********************************************************************************************************************/

			WHILE (SELECT ISNULL(COUNT(*), 0) FROM #Offers WHERE Sample = 0) > 0
				BEGIN
				
					SELECT @CompositeID = CompositeID
					FROM (SELECT TOP 1 CompositeID
						  FROM #CustomerSampleInput ovs
						  INNER JOIN #Offers o
						  	  ON ovs.TypeID = o.TypeID
						  	  AND ovs.ClubID = o.ClubID
						  	  AND ovs.IsLoyalty = o.IsLoyalty
							  AND ovs.ItemID = o.ItemID
							  AND o.Sample = 0
						  GROUP BY CompositeID
						  ORDER BY COUNT(CASE WHEN NewOffer = 1 THEN 1 ELSE NULL END) DESC, COUNT(1) DESC) o

					INSERT INTO #Sample
					SELECT ovs.ClubID
						 , ovs.IsLoyalty
						 , ovs.CompositeID
						 , ovs.TypeID
						 , ovs.ItemRank
						 , ovs.ItemID
						 , ovs.Date
					FROM #CustomerSampleInput ovs
					WHERE ovs.CompositeId = @CompositeID

					UPDATE o
					SET Sample = 1
					FROM #Offers o
					INNER JOIN #Sample s
						ON o.ClubID = s.ClubID
						AND o.IsLoyalty = s.IsLoyalty
						AND o.TypeID = s.TypeID
						AND o.ItemID = s.ItemID

				END


	/*******************************************************************************************************************************************
		5. Insert data to NominatedLionSendComponent & NominatedLionSendComponent_RedemptionOffers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#NominatedLionSendComponent') IS NOT NULL DROP TABLE #NominatedLionSendComponent
		SELECT DISTINCT
			   @LionSendIDSample AS LionSendID
			 , s.CompositeId
			 , s.TypeID
			 , s.ItemRank
			 , s.ItemID
			 , s.Date
		INTO #NominatedLionSendComponent
		FROM #Sample s
		WHERE s.TypeID = 1
		
		IF OBJECT_ID('tempdb..#NominatedLionSendComponent_RedemptionOffers') IS NOT NULL DROP TABLE #NominatedLionSendComponent_RedemptionOffers
		SELECT DISTINCT
			   @LionSendIDSample AS LionSendID
			 , s.CompositeId
			 , s.TypeID
			 , s.ItemRank
			 , s.ItemID
			 , s.Date
		INTO #NominatedLionSendComponent_RedemptionOffers
		FROM #Sample s
		WHERE s.TypeID = 3

		--ALTER INDEX [IUX_LSIDOfferCompRank] ON [Lion].[NominatedLionSendComponent] DISABLE
		--ALTER INDEX [IUX_LSIDOfferTypeCompRank] ON [Lion].[NominatedLionSendComponent_RedemptionOffers] DISABLE
		
		
		INSERT INTO [Lion].[NominatedLionSendComponent]
		SELECT *
		FROM #NominatedLionSendComponent

		INSERT INTO [Lion].[NominatedLionSendComponent_RedemptionOffers]
		SELECT *
		FROM #NominatedLionSendComponent_RedemptionOffers

		--ALTER INDEX [IUX_LSIDOfferCompRank] ON [Lion].[NominatedLionSendComponent] REBUILD
		--ALTER INDEX [IUX_LSIDOfferTypeCompRank] ON [Lion].[NominatedLionSendComponent_RedemptionOffers] REBUILD
		

END


	--IF OBJECT_ID('tempdb..#OffersLive') IS NOT NULL DROP TABLE #OffersLive
	--Select op.PartnerID
	--	 , 1 as TypeID
	--	 , op.IronOfferID as ItemID
	--INTO #OffersLive
	--From Selections.OfferPrioritisation op
	--INNER JOIN Relational.IronOffer iof
	--	on op.IronOfferID = iof.IronOfferID
	--WHERE EmailDate = '2018-12-13'

	--Union

	--Select PartnerID
	--	 , 3 as TypeID
	--	 , RedeemID as TypeID
	--From Staging.RedemptionItem
	--WHERE RedeemType = 'Trade Up'
	--And Status = 1


	-- --highlighting new offers

	--IF OBJECT_ID('tempdb..#LionSend_PreviousOffers') IS NOT NULL DROP TABLE #LionSend_PreviousOffers
	--Select Distinct
	--	   TypeID
	--	 , ItemID
	--INTO #LionSend_PreviousOffers
	--From [Prototype].[LionSend_Offers]


	--IF OBJECT_ID('tempdb..#OffersInLionSend') IS NOT NULL DROP TABLE #OffersInLionSend
	--Select Min(LionSendID) as LionSendID
	--	 , TypeID
	--	 , ItemID
	--INTO #OffersInLionSend
	--From [Lion].[NominatedLionSendComponent]
	--GROUP BY TypeID
	--	   , ItemID

	--Union
	
	--Select Min(LionSendID) as LionSendID
	--	 , TypeID
	--	 , ItemID
	--From [Lion].[NominatedLionSendComponent_RedemptionOffers]
	--GROUP BY TypeID
	--	   , ItemID

	--Select *
	--From #OffersInLionSend


	--Select ol.PartnerID
	--	 , ol.TypeID
	--	 , ol.ItemID
	--	 , iof.IronOfferName
	--	 , Convert(Date, iof.StartDate) as StartDate
	--	 , Convert(Date, iof.EndDate) as EndDate
	--	 , CASE WHEN po.ItemID Is Not Null THEN 1 ELSE 0 End as InPreviousLionSend
	--	 , CASE WHEN oils.ItemID Is Not Null THEN 1 ELSE 0 End as InCurrentLionSend
	--From #OffersLive ol
	--Left join #LionSend_PreviousOffers po
	--	on ol.TypeID = po.TypeID
	--	and ol.ItemID = po.ItemID
	--Left join #OffersInLionSend oils
	--	on ol.TypeID = oils.TypeID
	--	and ol.ItemID = oils.ItemID
	--Left join Relational.IronOffer iof
	--	on ol.ItemID = iof.IronOfferID
	--WHERE ol.TypeID = 1
	--And CASE WHEN po.ItemID Is Not Null THEN 1 ELSE 0 End = 0
	--Or CASE WHEN oils.ItemID Is Not Null THEN 1 ELSE 0 End = 0
	--ORDER BY iof.StartDate

	--Select op.PartnerID
	--	 , op.IronOfferID
	--	 , op.NewOffer
	--	 , lsp.ItemID
	--	 , lsc.ItemID
	--	 , CASE
	--			WHEN op.NewOffer = 1 And lsc.ItemID IS NULL THEN 1
	--			ELSE 0
	--	   End as  NewOfferMissing
	--	 , CASE
	--			WHEN op.NewOffer = 0 And lsc.ItemID IS NULL And lsp.ItemID Is Not Null THEN 1
	--			ELSE 0
	--	   End as ExistingOfferMissing_InPrevious
	--	 , CASE
	--			WHEN op.NewOffer = 0 And lsc.ItemID IS NULL And lsp.ItemID IS NULL THEN 1
	--			ELSE 0
	--	   End as ExistingOfferMissing_NotInPrevious
	--From #OfferPrioritisation op
	--Left join #LionSend_PreviousOffers lsp
	--	on op.IronOfferID = lsp.ItemID
	--	and lsp.TypeID = 1
	--Left join #LionSend_CurrentOffers lsc
	--	on op.IronOfferID = lsc.ItemID
	--	and lsc.TypeID = 1
	--ORDER BY ExistingOfferMissing_NotInPrevious
	--	   , ExistingOfferMissing_InPrevious
	--	   , NewOfferMissing