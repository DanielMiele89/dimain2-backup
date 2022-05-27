CREATE Procedure [Prototype].[LionSendTracking] @LionSendID Int
as
Begin

	Declare @EmailSendDate Date = (Select Max(EmailSendDate) From Staging.R_0183_LionSendVolumesCheck Where LionSendID = @LionSendID)

	If Object_ID('tempdb..#LionSend_Customers') Is Not Null Drop Table #LionSend_Customers
	Select Distinct
		   @LionSendID as LionSendID
		 , @EmailSendDate as EmailSendDate
		 , cu.CompositeID
		 , cu.FanID
		 , cu.ClubID
		 , Case When CustomerSegment Like '%v%' Then 1 Else 0 End as IsLoyalty
	Into #LionSend_Customers
	From Lion.NominatedLionSendComponent nlsc
	Inner join Relational.Customer cu
		on nlsc.CompositeID = cu.CompositeID
	Inner join Relational.Customer_RBSGSegments rbsg
		on cu.FanID = rbsg.FanID
		and rbsg.EndDate Is Null
	Where LionSendID = @LionSendID
	And Not Exists (Select 1
					From Prototype.LionSend_Customers lsc
					Where nlsc.CompositeID = lsc.CompositeID
					And nlsc.LionSendID = lsc.LionSendID)

	If Object_ID('tempdb..#LionSend_Offers') Is Not Null Drop Table #LionSend_Offers
	Select nle.LionSendID
		 , @EmailSendDate as EmailSendDate
		 , nle.CompositeID
		 , cu.FanID
		 , nle.TypeID
		 , nle.ItemID
		 , nle.ItemRank
	Into #LionSend_Offers
	From Lion.NominatedLionSendComponent nle
	Inner join Relational.Customer cu
		on nle.CompositeID = cu.CompositeID
	Where LionSendID = @LionSendID
	Union
	Select nlb.LionSendID
		 , @EmailSendDate as EmailSendDate
		 , nlb.CompositeID
		 , cu.FanID
		 , nlb.TypeID
		 , nlb.ItemID
		 , nlb.ItemRank
	From Lion.NominatedLionSendComponent_RedemptionOffers nlb
	Inner join Relational.Customer cu
		on nlb.CompositeID = cu.CompositeID
	Where LionSendID = @LionSendID

	Create Clustered Index CIX_LionSendOffers On #LionSend_Offers (LionSendID, CompositeID)

	Delete lsot
	From #LionSend_Offers lsot
	Where Exists (Select 1
				  From Prototype.LionSend_Offers lso
				  Where lsot.CompositeID = lso.CompositeID
				  And lsot.LionSendID = lso.LionSendID)

				  
	DROP INDEX [CSX_LionSendOffers_All] ON [Prototype].[LionSend_Offers]
	DROP INDEX [CSX_LionSendCustomers_All] ON [Prototype].[LionSend_Customers]
	Alter Index IX_LionSendCustomers_LionCampaignClubLoyaltyFan On [Prototype].[LionSend_Customers] Disable

	-- Initial population of tables

	Insert into [Prototype].[LionSend_Customers] (LionSendID
												, EmailSendDate
												, CompositeID
												, FanID
												, ClubID
												, IsLoyalty)
	Select LionSendID
		 , EmailSendDate
		 , CompositeID
		 , FanID
		 , ClubID
		 , IsLoyalty
	From #LionSend_Customers


	Insert into [Prototype].[LionSend_Offers] (LionSendID
											 , EmailSendDate
											 , CompositeID
											 , FanID
											 , TypeID
											 , ItemID
											 , OfferSlot)
	Select LionSendID
		 , EmailSendDate
		 , CompositeID
		 , FanID
		 , TypeID
		 , ItemID
		 , ItemRank
	From #LionSend_Offers

	Alter Index IX_LionSendCustomers_LionCampaignClubLoyaltyFan On [Prototype].[LionSend_Customers] Rebuild

	-- update campaign key info

	If Object_ID('tempdb..#EmailCampaign') Is Not Null Drop Table #EmailCampaign
	Select ec.CampaignKey
		 , CampaignName
		 , SendDate
		 , Case
			When CampaignName Like '%NWC%' Or CampaignName Like '%NatWest%' Then 132
			When CampaignName Like '%NWP%' Or CampaignName Like '%NatWest%' Then 132
			When CampaignName Like '%RBSC%' Or CampaignName Like '%RBS%' Then 138
			When CampaignName Like '%RBSP%' Or CampaignName Like '%RBS%' Then 138
		   End as ClubID
		 , Case
			When CampaignName Like '%NWC%' Or CampaignName Like '%Core%' Then 0
			When CampaignName Like '%NWP%' Or CampaignName Like '%Private%' Then 1
			When CampaignName Like '%RBSC%' Or CampaignName Like '%Core%' Then 0
			When CampaignName Like '%RBSP%' Or CampaignName Like '%Private%' Then 1
		   End as IsLoyalty
		 , Case When PatIndex('%LSID%', CampaignName) > 0 Then Substring(CampaignName, PatIndex('%LSID%', CampaignName) + 4, 3) Else Null End as LionSendID
	Into #EmailCampaign
	From Warehouse.Relational.EmailCampaign ec
	Where CampaignName Like '%newsletter%'


	Update ls
	Set ls.CampaignKey = ec.CampaignKey
	From [Prototype].[LionSend_Customers] ls
	Inner join #EmailCampaign ec
		on ls.LionSendID = ec.LionSendID
		and ls.IsLoyalty = ec.IsLoyalty
		and ls.ClubID = ec.ClubID
	Where ls.CampaignKey Is Null
	

	-- update sent & opened
	
	If Object_ID('tempdb..#EmailNotSent') Is Not Null Drop Table #EmailNotSent
	Select lsc.CampaignKey
		 , lsc.FanID
	Into #EmailNotSent
	From [Prototype].[LionSend_Customers] lsc
	Where lsc.EmailSent = 0

	Create Clustered Index CIX_EmailNotSent_FanID On #EmailNotSent (CampaignKey, FanID)
	

	If Object_ID('tempdb..#EmailSent') Is Not Null Drop Table #EmailSent
	Select Distinct
		   ee.CampaignKey
		 , ee.FanID
	Into #EmailSent
	From #EmailNotSent ens
	Inner join Warehouse.Relational.EmailEvent ee
		on ens.FanID = ee.FanID
		and ens.CampaignKey = ee.CampaignKey

	Update lsc
	Set EmailSent = 1
	From Warehouse.Prototype.LionSend_Customers lsc
	Inner join #EmailSent es
		on lsc.CampaignKey = es.CampaignKey
		and lsc.FanID = es.FanID
	Where EmailSent = 0
	
	If Object_ID('tempdb..#EmailNotOpened') Is Not Null Drop Table #EmailNotOpened
	Select lsc.CampaignKey
		 , lsc.FanID
	Into #EmailNotOpened
	From [Prototype].[LionSend_Customers] lsc
	Where lsc.EmailOpened = 0

	Create Clustered Index CIX_EmailNotOpened_CampaignKeyFanID On #EmailNotOpened (CampaignKey, FanID)


	If Object_ID('tempdb..#EmailOpens') Is Not Null Drop Table #EmailOpens
	Select ee.CampaignKey
		 , ee.FanID
		 , Min(EventDate) as EventDate
	Into #EmailOpens
	From #EmailNotOpened eno
	Inner join Warehouse.Relational.EmailEvent ee
		on eno.CampaignKey = ee.CampaignKey
		and eno.FanID = ee.FanID
	Where ee.EmailEventCodeID = 1301
	Group by ee.CampaignKey
		   , ee.FanID

	Update lsc
	Set EmailOpened = 1
	  , EmailOpenedDate = EventDate
	From Warehouse.Prototype.LionSend_Customers lsc
	Inner join #EmailOpens eo
		on lsc.CampaignKey = eo.CampaignKey
		and lsc.FanID = eo.FanID
	Where EmailOpened = 0
		

	CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_LionSendOffers_All] ON [Prototype].[LionSend_Offers] ([LionSendID], [EmailSendDate], [CompositeID], [FanID], [TypeID], [ItemID], [OfferSlot])
	CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_LionSendCustomers_All] ON [Prototype].[LionSend_Customers] ([LionSendID], [EmailSendDate], [CampaignKey], [CompositeID], [FanID], [ClubID], [IsLoyalty], [EmailSent], [EmailOpened], [EmailOpenedDate])




	-- highlighting new offers

	--If Object_ID('tempdb..#LionSend_PreviousOffers') Is Not Null Drop Table #LionSend_PreviousOffers
	--Select Distinct
	--	   TypeID
	--	 , ItemID
	--Into #LionSend_PreviousOffers
	--From [Prototype].[LionSend_Offers]
	--Where LionSendID < 550


	--If Object_ID('tempdb..#OfferPrioritisation') Is Not Null Drop Table #OfferPrioritisation
	--Select op.PartnerID
	--	 , op.IronOfferID
	--	 , Case
	--			When op.EmailDate = iof.StartDate Then 1
	--			Else 0
	--	   End as NewOffer
	--Into #OfferPrioritisation
	--From Selections.OfferPrioritisation op
	--Inner join Relational.IronOffer iof
	--	on op.IronOfferID = iof.IronOfferID
	--Where EmailDate = '2018-11-08'

	--If Object_ID('tempdb..#LionSend_CurrentOffers') Is Not Null Drop Table #LionSend_CurrentOffers
	--Select Distinct
	--	   TypeID
	--	 , ItemID
	--Into #LionSend_CurrentOffers
	--From [Prototype].[LionSend_Offers]
	--Where LionSendID = 551

	--Select op.PartnerID
	--	 , op.IronOfferID
	--	 , op.NewOffer
	--	 , lsp.ItemID
	--	 , lsc.ItemID
	--	 , Case
	--			When op.NewOffer = 1 And lsc.ItemID Is Null Then 1
	--			Else 0
	--	   End as  NewOfferMissing
	--	 , Case
	--			When op.NewOffer = 0 And lsc.ItemID Is Null And lsp.ItemID Is Not Null Then 1
	--			Else 0
	--	   End as ExistingOfferMissing_InPrevious
	--	 , Case
	--			When op.NewOffer = 0 And lsc.ItemID Is Null And lsp.ItemID Is Null Then 1
	--			Else 0
	--	   End as ExistingOfferMissing_NotInPrevious
	--From #OfferPrioritisation op
	--Left join #LionSend_PreviousOffers lsp
	--	on op.IronOfferID = lsp.ItemID
	--	and lsp.TypeID = 1
	--Left join #LionSend_CurrentOffers lsc
	--	on op.IronOfferID = lsc.ItemID
	--	and lsc.TypeID = 1
	--Order by ExistingOfferMissing_NotInPrevious
	--	   , ExistingOfferMissing_InPrevious
	--	   , NewOfferMissing

End