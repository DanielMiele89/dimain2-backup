

CREATE PROCEDURE [Staging].[SSRS_R0016_PreSFDUploadDataAssessment]

AS
BEGIN
	SET NOCOUNT ON

	Declare @Date Date = (Select Min(EmailDate) From Selections.ROCShopperSegment_PreSelection_ALS Where EmailDate > GetDate())

	/*******************************************************************************************************************************************
		1. Customer Counts
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			1.1. Create joined table of both earn & burn Nominated Lion Send Customers
		***********************************************************************************************************************/

			If Object_ID('tempdb..#NominatedLionSendCustomers') Is Not Null Drop Table #NominatedLionSendCustomers
			Select Distinct
				   LionSendID
				 , Convert(Date, Date) as UploadDate
				 , CompositeID
			Into #NominatedLionSendCustomers
			From Lion.NominatedLionSendComponent nlsc

			Insert Into #NominatedLionSendCustomers
			Select Distinct
				   LionSendID
				 , Convert(Date, Date) as UploadDate
				 , CompositeID
			From Lion.NominatedLionSendComponent_RedemptionOffers nlscr
			Where Not Exists (Select 1
							  From #NominatedLionSendCustomers nlsc
							  Where nlscr.CompositeID = nlsc.CompositeID
							  And nlscr.LionSendID = nlsc.LionSendID)
		   
			Create Clustered Index CIX_NominatedLionSendCustomers_LionSendOfferTypeComposite On #NominatedLionSendCustomers (LionSendID, CompositeID)
	

		/***********************************************************************************************************************
			1.2. Fetch counts of customers on both earn & burn
		***********************************************************************************************************************/

			If Object_ID('tempdb..#EarnCustomerCounts') Is Not Null Drop Table #EarnCustomerCounts
			Select LionSendID
				 , Count(Distinct CompositeID) as EarnOfferCustomerCount
			Into #EarnCustomerCounts
			From Lion.NominatedLionSendComponent nlsc
			Group by LionSendID

			If Object_ID('tempdb..#BurnCustomerCounts') Is Not Null Drop Table #BurnCustomerCounts
			Select LionSendID
				 , Count(Distinct CompositeID) as BurnOfferCustomerCount
			Into #BurnCustomerCounts
			From Lion.NominatedLionSendComponent nlsc
			Group by LionSendID
	

		/***********************************************************************************************************************
			1.3. Get counts for whole selected base and join with previous counts
		***********************************************************************************************************************/

			If Object_ID('tempdb..#CustomerStats') Is Not Null Drop Table #CustomerStats
			Select nlsc.LionSendID
				 , UploadDate
				 , Count(nlsc.CompositeID) as TotalCustomerCount
				 , EarnOfferCustomerCount
				 , BurnOfferCustomerCount
				 , Count(Case When cu.CurrentlyActive = 1 Then nlsc.CompositeID Else Null End) as Currently_Activated
				 , Count(Case When cu.CurrentlyActive = 1 And MarketableByEmail = 1 Then nlsc.CompositeID Else Null End) as Currently_MarketableByEmail
				 , Count(Case When cu.CurrentlyActive = 0 Then nlsc.CompositeID Else Null End) as Deactivated
			Into #CustomerStats
			From #NominatedLionSendCustomers nlsc
			Left join Relational.Customer cu
				  on nlsc.CompositeID = cu.CompositeID
			Left join #EarnCustomerCounts eo
				on nlsc.LionSendID = eo.LionSendID
			Left join #BurnCustomerCounts bo
				on nlsc.LionSendID = bo.LionSendID
			Group by nlsc.LionSendID
				   , UploadDate
				   , EarnOfferCustomerCount
				   , BurnOfferCustomerCount
		   

	/*******************************************************************************************************************************************
		2. Offer Slots
	*******************************************************************************************************************************************/
	
		/***********************************************************************************************************************
			2.1. Fetch LionSendID for earn offers where not all customers has 7 slots filled
		***********************************************************************************************************************/

			If Object_ID('tempdb..#EarnOfferSlots') Is Not Null Drop Table #EarnOfferSlots
			Select Distinct LionSendID
			Into #EarnOfferSlots
			From (Select LionSendID
		  			   , CompositeID
				  From Lion.NominatedLionSendComponent
				  Group by LionSendID
		  			   , CompositeID
				  Having Count(*) != 7) eos
	

		/***********************************************************************************************************************
			2.2. Fetch LionSendID for burn offers where not all customers has 5 slots filled
		***********************************************************************************************************************/
	
			If Object_ID('tempdb..#BurnOfferSlots') Is Not Null Drop Table #BurnOfferSlots
			Select Distinct LionSendID
			Into #BurnOfferSlots
			From (Select LionSendID
		  			   , CompositeID
				  From Lion.NominatedLionSendComponent_RedemptionOffers
				  Group by LionSendID
		  			   , CompositeID
				  Having Count(*) != 5) eos
		   

	/*******************************************************************************************************************************************
		3. Offer Counts
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			3.1. Fetch list of offers from the PartnerCommissionRule table
		***********************************************************************************************************************/

			If Object_ID('tempdb..#PartnerCommissionRule') Is Not Null Drop Table #PartnerCommissionRule
			Select RequiredIronOfferID
				 , Max(Case When Status = 1 And TypeID = 1 Then CommissionRate End) as CashbackRate
				 , Convert(Numeric(32,2), Max(Case When Status = 1 And TypeID = 2 Then CommissionRate End)) as CommissionRate
			Into #PartnerCommissionRule
			From SLC_Report..PartnerCommissionRule pcr
			Where RequiredIronOfferID Is Not Null
			And DeletionDate Is Not Null
			Group by RequiredIronOfferID

			Create Clustered Index CIX_PartnerCommissionRule_IoronOfferID On #PartnerCommissionRule (RequiredIronOfferID)


		/***********************************************************************************************************************
			3.2. Fetch distinct list of earn offers
		***********************************************************************************************************************/

			If Object_ID('tempdb..#NominatedLionSendEarnOffers') Is Not Null Drop Table #NominatedLionSendEarnOffers
			Select Distinct
				   LionSendID
				 , ItemID
			Into #NominatedLionSendEarnOffers
			From Lion.NominatedLionSendComponent

			Create Clustered Index CIX_NominatedLionSendEarnOffers_ItemID On #NominatedLionSendEarnOffers (ItemID)
	

		/***********************************************************************************************************************
			3.3. Fetch distinct list of burn offers
		***********************************************************************************************************************/

			If Object_ID('tempdb..#NominatedLionSendBurnOffers') Is Not Null Drop Table #NominatedLionSendBurnOffers
			Select Distinct
				   LionSendID
				 , ItemID
			Into #NominatedLionSendBurnOffers
			From Lion.NominatedLionSendComponent_RedemptionOffers

			Create Clustered Index CIX_NominatedLionSendBurnOffers_ItemID On #NominatedLionSendBurnOffers (ItemID)
	

		/***********************************************************************************************************************
			3.4. Fetch count of total offers across earn & burn
		***********************************************************************************************************************/
	
			If Object_ID('tempdb..#NominatedLionSendOffers') Is Not Null Drop Table #NominatedLionSendOffers
			Select LionSendID
				 , Count(1) as TotalOffers
			Into #NominatedLionSendOffers
			From (Select LionSendID
		  			   , 'Earn' as OfferType
		  			   , ItemID
				  From #NominatedLionSendEarnOffers
				  Union all
				  Select LionSendID
		  			   , 'Burn' as OfferType
		  			   , ItemID
				  From #NominatedLionSendBurnOffers) nls
			Group by LionSendID
	

		/***********************************************************************************************************************
			3.5. Fetch offers counts for earn offers
		***********************************************************************************************************************/
	
			If Object_ID('tempdb..#EarnOfferCounts') Is Not Null Drop Table #EarnOfferCounts
			Select LionSendID
				 , Count(ItemID) as EarnOffers
				 , Count(Case When Convert(Date, iof.StartDate) < @Date And (Convert(Date, iof.EndDate) Is Null Or iof.EndDate > @Date) Then ItemID Else NULL End) as EarnOffers_CurrentlyLive
				 , Count(Case When Convert(Date, iof.StartDate) = @Date And (Convert(Date, iof.EndDate) Is Null Or iof.EndDate > @Date) Then ItemID Else NULL End) as EarnOffers_AboutToGoLive
				 , Count(Case When iof.EndDate <= @Date Then ItemID Else NULL End) as EarnOffers_ExpiredByEmailSendDate
				 , Count(Case When Convert(Date, iof.StartDate) > @Date Then ItemID Else NULL End) as EarnOffers_NotLiveOnEmailSendDate
				 , Count(Case When pcr.CashbackRate Is Not Null Then ItemID Else NULL End) as EarnOffers_WithCashBackRates
				 , Count(Case When pcr.CommissionRate Is Not Null Then ItemID Else NULL End) as EarnOffers_WithCommissionRates
			Into #EarnOfferCounts
			From #NominatedLionSendEarnOffers eo
			Inner join Warehouse.Relational.IronOffer iof
				on eo.ItemID = iof.IronOfferID
				and iof.IsTriggerOffer = 0
			Left join #PartnerCommissionRule pcr
				on eo.ItemID = pcr.RequiredIronOfferID
			Group by LionSendID
	

		/***********************************************************************************************************************
			3.4. Fetch offers counts for burn offers
		***********************************************************************************************************************/
	
			If Object_ID('tempdb..#BurnOfferCounts') Is Not Null Drop Table #BurnOfferCounts
			Select LionSendID
				 , Count(Distinct bo.ItemID) as RedemptionOffers
				 , Count(Distinct Case When RedeemType = 'Trade Up' Then bo.ItemID Else Null End) as TradeUpRedemptionOffers
				 , Count(Distinct Case When Status = 1 Then bo.ItemID Else Null End) as RedemptionOffers_CurrentlyLive
				 , Count(Distinct Case When Status = 0 Then bo.ItemID Else Null End) as RedemptionOffers_NotLive
			Into #BurnOfferCounts
			From #NominatedLionSendBurnOffers bo
			Inner join Relational.RedemptionItem ri
				on bo.ItemID = ri.RedeemID
			Group by LionSendID
		   

	/*******************************************************************************************************************************************
		4. Output for report
	*******************************************************************************************************************************************/


		Select cs.LionSendID
			 , @Date as EmailSendDate
			 , cs.UploadDate
			 , cs.TotalCustomerCount
			 , cs.EarnOfferCustomerCount
			 , cs.BurnOfferCustomerCount
			 , cs.Currently_Activated
			 , cs.Currently_MarketableByEmail
			 , cs.Deactivated
			 , Case When eos.LionSendID Is Null Then 'All Customers have 7 Slots' Else 'Not all Customers have 7 Slots' End as EarnOfferSlots
			 , Case When bos.LionSendID Is Null Then 'All Customers have 5 Slots' Else 'Not all Customers have 5 Slots' End as BurnOfferSlots
			 , aoc.TotalOffers
			 , eoc.EarnOffers
			 , eoc.EarnOffers_CurrentlyLive
			 , eoc.EarnOffers_AboutToGoLive
			 , eoc.EarnOffers_ExpiredByEmailSendDate
			 , eoc.EarnOffers_NotLiveOnEmailSendDate
			 , eoc.EarnOffers_WithCashBackRates
			 , eoc.EarnOffers_WithCommissionRates
			 , boc.RedemptionOffers
			 , boc.TradeUpRedemptionOffers
			 , boc.RedemptionOffers_CurrentlyLive
			 , boc.RedemptionOffers_NotLive
		From #CustomerStats cs
		Left join #EarnOfferSlots eos
			on cs.LionSendID = eos.LionSendID
		Left join #BurnOfferSlots bos
			on cs.LionSendID = bos.LionSendID
		Left join #NominatedLionSendOffers aoc
			on cs.LionSendID = aoc.LionSendID
		Left join #EarnOfferCounts eoc
			on cs.LionSendID = eoc.LionSendID
		Left join #BurnOfferCounts boc
			on cs.LionSendID = boc.LionSendID

End