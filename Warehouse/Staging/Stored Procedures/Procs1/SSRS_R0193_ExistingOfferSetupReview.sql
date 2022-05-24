/*
	
	Author:		Rory

	Date:		22nd November 2018

	Purpose:	To review the offer setup, namely cashback & spend stretch rules
				for existing offers
				
*/


CREATE Procedure [Staging].[SSRS_R0193_ExistingOfferSetupReview] @ReportDate Date
															  , @ErrorsAndUpdates Bit
															  , @OfferAge Int
As
Begin

	/*******************************************************************************************************************************************
		1. Declare @Date parameter
	*******************************************************************************************************************************************/

		Declare @Date Date = @ReportDate

		--Declare @Date Date = '2018-11-23'
		--	  , @ErrorsAndUpdates Bit = 1
		--	  , @OfferAge Bit = 0


	/*******************************************************************************************************************************************
		2. Create temp table holding all Offers currently live from the SLC_REPL..IronOffer table
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			6.1. Populate initial #IronOffer table
		***********************************************************************************************************************/

			If Object_ID('tempdb..#IronOffer_Temp') Is Not Null Drop Table #IronOffer_Temp
			Select *
			Into #IronOffer_Temp
			From SLC_REPL..IronOffer
			Where (@Date Between StartDate and EndDate
			Or EndDate Is Null)
			Or StartDate > GetDate()

			Delete iof
			From #IronOffer_Temp iof
			Where iof.Name In ('Above the line', 'Default Offer', 'SPARE')
			Or iof.IsTriggerOffer = 1
			Or iof.IsAboveTheLine = 1
			Or iof.IsDefaultCollateral = 1
			Or Name Like 'Spare%'
			Or Name in ('suppressed', 'Test', '1% All Members Offer')
			Or PartnerID = 4642
			Or ID in (315,515,528,539,554,564,575,584,586,589,590,594,610,
					  614,615,1117,1590,1746,1748,1756,1758,1760,1761,1764,
					  1768,1772,1776,1778,1782,1786,1788,1790,1791,1793,1847,
					  8827,8851,8858,9919,9921,9927,9928,10491,10492,10493,
					  10494,10495,10496,10497,10861,11645,11646,11835,11836,
					  12039,13885,13461,13462,18295,18296,18297,18298,18300,
					  18299,16535,18466,19637)
			Or Exists (Select 1
					   From Relational.PartnerOffers_Base pob
					   Where iof.ID = pob.OfferID)
				   

		/***********************************************************************************************************************
			6.2. Fetch Club details
		***********************************************************************************************************************/

			If Object_ID('tempdb..#IronOfferClub') Is Not Null Drop Table #IronOfferClub
			Select *
			Into #IronOfferClub
			From SLC_REPL..IronOfferClub

			Create Clustered Index CIX_IronOfferClub_IronOfferID on #IronOfferClub (IronOfferID)


		/***********************************************************************************************************************
			6.3. Add Club details to #IronOffer
		***********************************************************************************************************************/
	
			If Object_ID('tempdb..#IronOffer') Is Not Null Drop Table #IronOffer
			Select Distinct
				   iof.*
				 , ioc.ClubID
				 , cl.Name as ClubName
				 , pa.Name as PartnerName
			Into #IronOffer
			From #IronOffer_Temp iof
			Inner join #IronOfferClub ioc
				on iof.ID = ioc.IronOfferID
			Inner join SLC_Report..Club cl
				on ioc.ClubID = cl.ID
			Inner join SLC_Report..Partner pa
				on iof.PartnerID = pa.ID

			Create Clustered Index CIX_IronOffer_IronOfferID on #IronOffer (ID)


	/*******************************************************************************************************************************************
		3. Create temp table holding all Partner Commision rules for currently live offers from the SLC_REPL..PartnerCommissionRule table
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#PartnerCommissionRule_Temp1') Is Not Null Drop Table #PartnerCommissionRule_Temp1
		Select pcr.*
		Into #PartnerCommissionRule_Temp1
		From SLC_REPL..PartnerCommissionRule pcr
		Inner join #IronOffer iof
			on pcr.RequiredIronOfferID = iof.ID

		Delete
		From #PartnerCommissionRule_Temp1
		Where Status = 0

		Create Clustered Index CIX_PartnerCommissionRule_IronOfferID on #PartnerCommissionRule_Temp1 (RequiredIronOfferID)


	/*******************************************************************************************************************************************
		4. Create a temp table holding all primary & secondary partner links
		   For some partners, the primary partner was designated but the secondary partner was the first to run offers, to allow complete
		   joins these PartnerIDs have been swapped in the #PrimaryRetailerIdentification table
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#PrimaryRetailerIdentification') Is Not Null Drop Table #PrimaryRetailerIdentification
		Select Case
					When PartnerID = 4557 Then 4578	--	Barrhead Travel
					When PartnerID = 4578 Then 4557	--	Barrhead Travel
			
					When PartnerID = 4585 Then 4614	--	Butlins
					When PartnerID = 4614 Then 4585	--	Butlins
			
					When PartnerID = 4723 Then 4671	--	Chef & Brewer
					When PartnerID = 4671 Then 4723	--	Chef & Brewer
			
--					When PartnerID = 3432 Then 4640	--	Hungry Horse
--					When PartnerID = 4640 Then 3432	--	Hungry Horse
					Else PartnerID
			   End as PartnerID
			 , Case
					When PrimaryPartnerID = 4557 Then 4578	--	Barrhead Travel
					When PrimaryPartnerID = 4578 Then 4557	--	Barrhead Travel
			
					When PrimaryPartnerID = 4585 Then 4614	--	Butlins
					When PrimaryPartnerID = 4614 Then 4585	--	Butlins
			
					When PrimaryPartnerID = 4723 Then 4671	--	Chef & Brewer
					When PrimaryPartnerID = 4671 Then 4723	--	Chef & Brewer
			
--					When PrimaryPartnerID = 3432 Then 4640	--	Hungry Horse
--					When PrimaryPartnerID = 4640 Then 3432	--	Hungry Horse
					Else PrimaryPartnerID
			   End as PrimaryPartnerID
		Into #PrimaryRetailerIdentification
		From iron.PrimaryRetailerIdentification

		Create Clustered Index CIX_PrimaryRetailerIdentification_PriPartPart On #PrimaryRetailerIdentification (PrimaryPartnerID, PartnerID)


	/*******************************************************************************************************************************************
		5. Fetch all Partners that have an associated offer imported from a brief
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#Partners') Is Not Null Drop Table #Partners
		Select Distinct
			   pa.ID as PartnerID
			 , pa.Name as PartnerName
		Into #Partners
		From Selections.AllPublisher_CampaignDetails cd
		Inner join #IronOffer iof
			on cd.IronOfferID = iof.ID
		Inner join SLC_Report..Partner pa
			on iof.PartnerID = pa.ID

		Create Clustered Index CIX_Partners_PartnerID On #Partners (PartnerID)


	/*******************************************************************************************************************************************
		6. Fetch all entries from the nFI_Partner_Deals table
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			6.1. Populating primary partner records, coalescing the end date with a future date where null
		***********************************************************************************************************************/

			If Object_ID('tempdb..#nFI_Partner_Deals') Is Not Null Drop Table #nFI_Partner_Deals
			Select ClubID
				 , PartnerID
				 , StartDate
				 , Coalesce(EndDate, '9999-01-01') as EndDate
				 , Convert(Float, Override * 100) as Override_PCR
				 , FixedOverride
			Into #nFI_Partner_Deals
			From Relational.nFI_Partner_Deals

			Create Clustered Index CIX_nFIPartnerDeals_PartnerID On #nFI_Partner_Deals (PartnerID)


		/***********************************************************************************************************************
			6.2. Populating secondary partner records
		***********************************************************************************************************************/

			Insert into #nFI_Partner_Deals	
			Select Distinct
				   pd1.ClubID
				 , pri.PartnerID
				 , pd1.StartDate
				 , pd1.EndDate
				 , pd1.Override_PCR
				 , pd1.FixedOverride
			From #nFI_Partner_Deals pd1
			Inner join #PrimaryRetailerIdentification pri
				on pd1.PartnerID = pri.PrimaryPartnerID
			Where Not Exists (Select 1
							  From #nFI_Partner_Deals pd2
							  Where pri.PartnerID = pd2.PartnerID
							  And pd1.ClubID = pd2.ClubID
							  And pd1.StartDate = pd2.StartDate)


		/***********************************************************************************************************************
			6.3. Populating second ClubID for NatWest & RBS
		***********************************************************************************************************************/

			Insert into #nFI_Partner_Deals	
			Select Distinct
				   Case
						When pd1.ClubID = 132 Then 138
						When pd1.ClubID = 138 Then 132
						Else pd1.ClubID
				   End as ClubID
				 , pd1.PartnerID
				 , pd1.StartDate
				 , pd1.EndDate
				 , pd1.Override_PCR
				 , pd1.FixedOverride
			From #nFI_Partner_Deals pd1
			Where Not Exists (Select 1
							  From #nFI_Partner_Deals pd2
							  Where pd1.PartnerID = pd2.PartnerID
							  And pd1.StartDate = pd2.StartDate
							  And Case
									When pd1.ClubID = 132 Then 138
									When pd1.ClubID = 138 Then 132
									Else pd1.ClubID
								  End = pd2.ClubID)


	/*******************************************************************************************************************************************
		7. Fetch all entries from the Selections.AllPublisher_CampaignDetails table within the date range
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			7.1. Populate initial table
		***********************************************************************************************************************/

			If Object_ID('tempdb..#AllPublisher_CampaignDetails') Is Not Null Drop Table #AllPublisher_CampaignDetails
			Select Distinct 
				   cd.ClubID
				 , cl.Name as ClubName
				 , cd.PartnerName as PrimaryPartnerName
				 , pa.ID as PartnerID
				 , pa.Name as PartnerName
				 , pd.FixedOverride
				 , pd.Override_PCR
				 , cd.ClientServicesRef
				 , cd.CampaignStartDate
				 , cd.Override as Override_Brief
				 , cd.IronOfferID
				 , iof.Name as IronOfferName
				 , iof.StartDate
				 , iof.EndDate
				 , cd.OfferRate as OfferRate_Brief
				 , cd.SpendStretchAmount as SpendStretchAmount_Brief
				 , cd.AboveSpendStretchRate as AboveSpendStretchRate_Brief
				 , cd.OfferBillingRate as OfferBillingRate_Brief
				 , cd.AboveSpendStrechBillingRate as AboveSpendStrechBillingRate_Brief
			Into #AllPublisher_CampaignDetails
			From Selections.AllPublisher_CampaignDetails cd
			Inner join #IronOffer iof
				on cd.IronOfferID = iof.ID
			Left join SLC_Report..Club cl
				on cd.ClubID = cl.ID
			Left join SLC_Report..Partner pa
				on iof.PartnerID = pa.ID
			Left join #nFI_Partner_Deals pd
				on cd.ClubID = pd.ClubID
				and pa.ID = pd.PartnerID
				and iof.StartDate Between pd.StartDate And pd.EndDate

				
		/***********************************************************************************************************************
			7.2. Populating second ClubID for NatWest & RBS
		***********************************************************************************************************************/

			Insert into #AllPublisher_CampaignDetails	
			Select Distinct
				   Case
						When cd1.ClubID = 132 Then 138
						When cd1.ClubID = 138 Then 132
						Else cd1.ClubID
				   End as ClubID
				 , Case
						When cd1.ClubName = 'NatWest MyRewards' Then 'RBS MyRewards'
						When cd1.ClubName = 'RBS MyRewards' Then 'NatWest MyRewards'
						Else cd1.ClubName
				   End as ClubName
				 , cd1.PrimaryPartnerName
				 , cd1.PartnerID
				 , cd1.PartnerName
				 , cd1.FixedOverride
				 , cd1.Override_PCR
				 , cd1.ClientServicesRef
				 , cd1.CampaignStartDate
				 , cd1.Override_Brief
				 , cd1.IronOfferID
				 , cd1.IronOfferName
				 , cd1.StartDate
				 , cd1.EndDate
				 , cd1.OfferRate_Brief
				 , cd1.SpendStretchAmount_Brief
				 , cd1.AboveSpendStretchRate_Brief
				 , cd1.OfferBillingRate_Brief
				 , cd1.AboveSpendStrechBillingRate_Brief
			From #AllPublisher_CampaignDetails cd1
			Where Not Exists (Select 1
							  From #AllPublisher_CampaignDetails cd2
							  Where cd1.IronOfferID = cd2.IronOfferID
							  And Case
									When cd1.ClubID = 132 Then 138
									When cd1.ClubID = 138 Then 132
									Else cd1.ClubID
								  End = cd2.ClubID)

							  
	/*******************************************************************************************************************************************
		8. Clean the #PartnerCommissionRule_Temp1 table to get down to the actual rules set up
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			8.1. Populate initial table
		***********************************************************************************************************************/

			If Object_ID('tempdb..#PartnerCommissionRule_Temp2') Is Not Null Drop Table #PartnerCommissionRule_Temp2
			Select iofc.ClubID
				 , cl.Name as ClubName
				 , iof.PartnerID
				 , pa.Name as PartnerName
				 , iof.ID as IronOfferID
				 , iof.Name as IronOfferName
				 , iof.StartDate
				 , iof.EndDate
				 , Datediff(day, iof.StartDate, iof.EndDate) + 1 as OfferPeriodDays
				 , Max(Case
							When pcr.TypeID = 1 And pcr.Status = 1 Then pcr.CommissionRate
							Else Null
						End) as CashbackRate
				 , Max(Case
							When pcr.TypeID = 2 And pcr.Status = 1 Then pcr.CommissionRate
							Else Null
						End) as CommissionRate
				 , pcr.RequiredMerchantID
				 , Convert(Float, pcr.RequiredMinimumBasketSize) as RequiredMinimumBasketSize
				 , pcr.RequiredChannel
				 , pcr.RequiredRetailOutletID
			Into #PartnerCommissionRule_Temp2
			From #IronOffer iof
			Inner join SLC_Report..Partner pa
				on iof.PartnerID = pa.ID
			Inner join #IronOfferClub iofc
				on iof.ID = iofc.IronOfferID
			Inner join SLC_Report..Club cl
				on iofc.ClubID = cl.ID
			Inner join #PartnerCommissionRule_Temp1 pcr
				on iof.ID = pcr.RequiredIronOfferID
			Group by iofc.ClubID
				   , cl.Name
				   , iof.PartnerID
				   , pa.Name
				   , iof.ID
				   , iof.Name
				   , iof.StartDate
				   , iof.EndDate
				   , Datediff(day, iof.StartDate, iof.EndDate) + 1
				   , pcr.RequiredMerchantID
				   , pcr.RequiredMinimumBasketSize
				   , pcr.RequiredChannel
				   , pcr.RequiredRetailOutletID


		/***********************************************************************************************************************
			8.2. Take the previous table and split out rows into offers with or without spend stretch rules
		***********************************************************************************************************************/

			If Object_ID('tempdb..#NoSpendStretch') Is Not Null Drop Table #NoSpendStretch
			Select ClubID
				 , ClubName
				 , PartnerID
				 , PartnerName
				 , IronOfferID
				 , IronOfferName
				 , StartDate
				 , EndDate
				 , OfferPeriodDays
				 , CashbackRate as CashbackRate_PCR
				 , CommissionRate as CommissionRate_PCR
				 , RequiredMerchantID as RequiredMerchantID_PCR
				 , RequiredMinimumBasketSize as RequiredMinimumBasketSize_PCR
				 , RequiredChannel as RequiredChannel_PCR
				 , RequiredRetailOutletID as RequiredRetailOutletID_PCR
			Into #NoSpendStretch
			From #PartnerCommissionRule_Temp2
			Where RequiredMinimumBasketSize Is Null

			If Object_ID('tempdb..#SpendStretch') Is Not Null Drop Table #SpendStretch
			Select ClubID
				 , ClubName
				 , PartnerID
				 , PartnerName
				 , IronOfferID
				 , IronOfferName
				 , StartDate
				 , EndDate
				 , OfferPeriodDays
				 , CashbackRate as AboveSpendStretchCashbackRate_PCR
				 , CommissionRate as AboveSpendStretchBillingRate_PCR
				 , RequiredMerchantID as RequiredMerchantID_PCR
				 , RequiredMinimumBasketSize as RequiredMinimumBasketSize_PCR
				 , RequiredChannel as RequiredChannel_PCR
				 , RequiredRetailOutletID as RequiredRetailOutletID_PCR
			Into #SpendStretch
			From #PartnerCommissionRule_Temp2
			Where RequiredMinimumBasketSize Is Not Null

		/***********************************************************************************************************************
			8.3. Join spend strech & non spend stretch 
		***********************************************************************************************************************/

			If Object_ID('tempdb..#PartnerCommissionRule') Is Not Null Drop Table #PartnerCommissionRule
			Select Coalesce(nss.ClubID, ss.ClubID) as ClubID
				 , Coalesce(nss.ClubName, ss.ClubName) as ClubName

				 , Coalesce(nss.PartnerID, ss.PartnerID) as PartnerID
				 , Coalesce(nss.PartnerName, ss.PartnerName) as PartnerName
				 , Coalesce(nss.IronOfferID, ss.IronOfferID) as IronOfferID
				 , Coalesce(nss.IronOfferName, ss.IronOfferName) as IronOfferName
				 , Coalesce(nss.StartDate, ss.StartDate) as StartDate
				 , Coalesce(nss.EndDate, ss.EndDate) as EndDate
				 , Coalesce(nss.OfferPeriodDays, ss.OfferPeriodDays) as OfferPeriodDays

				 , Coalesce(nss.CashbackRate_PCR, 0) as OfferRate_PCR
				 , Coalesce(nss.CommissionRate_PCR, 0) as OfferBillingRate_PCR
				 , Coalesce(ss.AboveSpendStretchCashbackRate_PCR, 0) as AboveSpendStretchRate_PCR
				 , Coalesce(ss.AboveSpendStretchBillingRate_PCR, 0) as AboveSpendStrechBillingRate_PCR

				 , Coalesce(nss.RequiredMerchantID_PCR, ss.RequiredMerchantID_PCR) as RequiredMerchantID_PCR
				 , Coalesce(nss.RequiredMinimumBasketSize_PCR, ss.RequiredMinimumBasketSize_PCR, 0) as SpendStretchAmount_PCR
				 , Coalesce(nss.RequiredChannel_PCR, ss.RequiredChannel_PCR) as RequiredChannel_PCR
				 , Coalesce(nss.RequiredRetailOutletID_PCR, ss.RequiredRetailOutletID_PCR) as RequiredRetailOutletID_PCR
			Into #PartnerCommissionRule
			From #NoSpendStretch nss
			Full outer join #SpendStretch ss
				on nss.IronOfferID = ss.IronOfferID
				and nss.ClubID = ss.ClubID
							  



	/*******************************************************************************************************************************************
		9. Compare the three sources the data has been pulled from to check for discrepancies and compare against SLC_Report..IronOffer to
		   find either new offers or highlight offers that have been updated
	*******************************************************************************************************************************************/
	
		
--	If Object_ID('tempdb..#Update_IronOffer') Is Not Null Drop Table #Update_IronOffer
--	Select *
--	Into #Update_IronOffer
--	From SLC_Report..IronOffer

--	Update #AllPublisher_CampaignDetails
--	Set OfferRate_Brief = 4
--	Where IronOfferID = 15343
--
--	Delete
--	From #PartnerCommissionRule
--	Where IronOfferID = 12797
--
--
--	Update #Update_IronOffer
--	Set StartDate = '2018-04-22'
--	Where ID = 14617



		If Object_ID('tempdb..#PartnerCommissionRule_Validation') Is Not Null Drop Table #PartnerCommissionRule_Validation
		Select Distinct
			   iof.ClubID
			 , iof.ClubName
	 
			 , iof.PartnerID
			 , Case
					When iof.PartnerName = Coalesce(pa.Name, iof.PartnerName) Then iof.PartnerName
					Else ' Was: ' + pa.Name + ' '  + CHAR(13) + 'Is: ' + iof.PartnerName
			   End as PartnerName
	 
			 , Coalesce(htm.ClientServicesRef, cd.ClientServicesRef, 'N/A') as ClientServicesRef

			 , iof.ID as IronOfferID
			 , Case
					When iof.Name = Coalesce(iof_slcr.Name, iof.Name) Then iof.Name
					Else ' Was: ' + iof_slcr.Name + ' ' + CHAR(13) + 'Is: ' + iof.Name
			   End as IronOfferName

			 , Case
					When iof.StartDate = Coalesce(iof_slcr.StartDate, iof.StartDate) Then Convert(VarChar(20), Convert(Date, iof.StartDate))
					Else ' Was: ' + Convert(VarChar(20), Convert(Date, iof_slcr.StartDate)) + ' '  + CHAR(13) + 'Is: ' + Convert(VarChar(20), Convert(Date, iof.StartDate))
			   End as StartDate
			 , Case
					When iof.EndDate = Coalesce(iof_slcr.EndDate, iof.EndDate) Then Convert(VarChar(20), Convert(Date, iof.EndDate))
					Else ' Was: ' + Convert(VarChar(20), Convert(Date, iof_slcr.EndDate)) + ' '  + CHAR(13) + 'Is: ' + Convert(VarChar(20), Convert(Date, iof.EndDate))
			   End as EndDate
	
			 , Case
					When Convert(VarChar(500), pcr.RequiredMerchantID_PCR) Is Null Then 'All MIDS'
					Else Convert(VarChar(500), pcr.RequiredMerchantID_PCR)
			   End as MerchantID
			 , Case
					When Convert(VarChar(500), pcr.RequiredRetailOutletID_PCR) Is Null Then 'All Outlets'
					Else Convert(VarChar(500), pcr.RequiredRetailOutletID_PCR)
			   End as RetailOutlet
			 , Case
					When pcr.RequiredChannel_PCR = 1 Then 'Online'
					When pcr.RequiredChannel_PCR = 2 Then 'Offline'
					Else 'All Channels'
			   End as Channel
			 , Case
					When cd.IronOfferID Is Null Then 'Brief not imported, '
					Else ''
			   End
			 + Case
					When pcr.IronOfferID Is Null Then 'No cashback rules, '
					Else ''
			   End
			+ Case
					When pd.PartnerID Is Null Then 'Missing from Partner Deals, '
					Else ''
			  End
			 + Case
	 				When cd.Override_Brief != cd.Override_PCR Then 'Override, '
	 				Else ''
			   End
			 + Case
	 				When cd.OfferRate_Brief != pcr.OfferRate_PCR Then 'Offer Rate, '
	 				Else ''
			   End
			 + Case
	 				When cd.OfferBillingRate_Brief != pcr.OfferBillingRate_PCR Then 'Offer Billing Rate, '
	 				Else ''
			   End
			 + Case
	 				When cd.SpendStretchAmount_Brief != pcr.SpendStretchAmount_PCR Then 'Spend Stretch Amount, '
	 				Else ''
			   End
			 + Case
	 				When cd.AboveSpendStretchRate_Brief != pcr.AboveSpendStretchRate_PCR Then 'Above Spend Stretch Rate, '
	 				Else ''
			   End
			 + Case
					When cd.AboveSpendStrechBillingRate_Brief != pcr.AboveSpendStrechBillingRate_PCR Then 'Above Spend Strech Billing Rate, '
					Else ''
			   End
			 + ', ' as Error
			 , Case
					When pd.PartnerID Is Null Then 'Missing from Partner Deals'
					Else ''
			   End as Error_PartnerDeals

			 , Case When iof.Name = Coalesce(iof_slcr.Name, iof.Name) Then 0 Else 1 End
			 + Case When iof.StartDate = Coalesce(iof_slcr.StartDate, iof.StartDate) Then 0 Else 1 End
			 + Case When iof.EndDate = Coalesce(iof_slcr.EndDate, iof.EndDate) Then 0 Else 1 End
			 + Case When iof.Name = Coalesce(iof_slcr.Name, iof.Name) Then 0 Else 1 End
			 + Case When iof.PartnerName = Coalesce(pa.Name, iof.PartnerName) Then 0 Else 1 End as Updates

			 , Case When cd.IronOfferID Is Not Null Then 0 Else 1 End
			 + Case When pcr.IronOfferID Is Not Null Then 0 Else 1 End
			 + Case When pd.PartnerID Is Not Null Then 0 Else 1 End
			 + Case When cd.Override_Brief = cd.Override_PCR Then 0 Else 1 End
			 + Case When cd.OfferRate_Brief = pcr.OfferRate_PCR Then 0 Else 1 End
			 + Case When cd.OfferBillingRate_Brief = pcr.OfferBillingRate_PCR Then 0 Else 1 End
			 + Case When cd.SpendStretchAmount_Brief = pcr.SpendStretchAmount_PCR Then 0 Else 1 End
			 + Case When cd.AboveSpendStretchRate_Brief = pcr.AboveSpendStretchRate_PCR Then 0 Else 1 End
			 + Case When cd.AboveSpendStrechBillingRate_Brief = pcr.AboveSpendStrechBillingRate_PCR Then 0 Else 1 End as Errors
	 
			 , Case
					When cd.Override_Brief = cd.Override_PCR Then Coalesce(Convert(VarChar(10), cd.Override_Brief), Convert(VarChar(10), cd.Override_PCR), Convert(VarChar(10), pd.Override_PCR), 'N/A')			
					Else ' Brief: ' + Coalesce(Convert(VarChar(10), cd.Override_Brief), 'N/A') + ' ' + CHAR(13) + 'PCR: ' + Coalesce(Convert(VarChar(10), cd.Override_PCR), Convert(VarChar(10), pd.Override_PCR), 'N/A')
			   End as Override
	   	 
			 , Case
					When cd.OfferRate_Brief = pcr.OfferRate_PCR Then Coalesce(Convert(VarChar(10), cd.OfferRate_Brief), Convert(VarChar(10), pcr.OfferRate_PCR))
					Else ' Brief: ' + Coalesce(Convert(VarChar(10), cd.OfferRate_Brief), 'N/A') + ' ' + CHAR(13) + 'PCR: ' + Coalesce(Convert(VarChar(10), pcr.OfferRate_PCR), 'N/A')
			   End as OfferRate
	 
			 , Case
					When cd.OfferBillingRate_Brief = pcr.OfferBillingRate_PCR Then Convert(VarChar(10), cd.OfferBillingRate_Brief)
					Else ' Brief: ' + Coalesce(Convert(VarChar(10), cd.OfferBillingRate_Brief), 'N/A') + ' ' + CHAR(13) + 'PCR: ' + Coalesce(Convert(VarChar(10), pcr.OfferBillingRate_PCR), 'N/A')
			   End as OfferBillingRate

	 
			 , Case
					When cd.SpendStretchAmount_Brief = pcr.SpendStretchAmount_PCR Then Convert(VarChar(10), cd.SpendStretchAmount_Brief)
					Else ' Brief: ' + Coalesce(Convert(VarChar(10), cd.SpendStretchAmount_Brief), 'N/A') + ' ' + CHAR(13) + 'PCR: ' + Coalesce(Convert(VarChar(10), pcr.SpendStretchAmount_PCR), 'N/A')
			   End as SpendStretchAmount
	   	 
			 , Case
					When cd.AboveSpendStretchRate_Brief = pcr.AboveSpendStretchRate_PCR Then Convert(VarChar(10), cd.AboveSpendStretchRate_Brief)
					Else ' Brief: ' + Coalesce(Convert(VarChar(10), cd.AboveSpendStretchRate_Brief), 'N/A') + ' ' + CHAR(13) + 'PCR: ' + Coalesce(Convert(VarChar(10), pcr.AboveSpendStretchRate_PCR), 'N/A')
			   End as AboveSpendStretchRate
	 
			 , Case
					When cd.AboveSpendStrechBillingRate_Brief = pcr.AboveSpendStrechBillingRate_PCR Then Convert(VarChar(10), cd.AboveSpendStrechBillingRate_Brief)
					Else ' Brief: ' + Coalesce(Convert(VarChar(10), cd.AboveSpendStrechBillingRate_Brief), 'N/A') + ' ' + CHAR(13) + 'PCR: ' + Coalesce(Convert(VarChar(10), pcr.AboveSpendStrechBillingRate_PCR), 'N/A')
			   End as AboveSpendStrechBillingRate
			 , Case
					When iof_slcr.ID Is Null Then 1
					When iof.StartDate > GetDate() Then 1
					When cd.CampaignStartDate > GetDate() Then 1
					Else 0
			   End as NewOffer
			 , Case
					When iof_slcr.Name != iof.Name Then 'Offer Name has been updated, '
					Else ''
			   End
			 + Case
					When iof_slcr.StartDate != iof.StartDate Then 'Start Date has been updated, '
					Else ''
			   End
			 + Case
					When iof_slcr.EndDate != iof.EndDate Then 'End Date has been updated, '
					Else ''
			   End
			 + Case
					When pa.Name != iof.PartnerName Then 'Partner has been updated, '
					Else ''
			   End
			 + ', ' as [Update]
		Into #PartnerCommissionRule_Validation
		From #IronOffer iof
		Left join Relational.IronOffer_Campaign_HTM htm
			on iof.ID = htm.IronOfferID
		Left join #AllPublisher_CampaignDetails cd
			on iof.ID = cd.IronOfferID
			and iof.ClubID = cd.ClubID
		Left join #PartnerCommissionRule pcr
			on iof.ID = pcr.IronOfferID
			and iof.ClubID = pcr.ClubID
		Left Join #nFI_Partner_Deals pd
			on iof.ClubID = pd.ClubID
			and iof.PartnerID = pd.PartnerID
		Left join SLC_Report..IronOffer iof_slcr 	--	#Update_IronOffer iof_slcr
			on iof.ID = iof_slcr.ID
		Left join SLC_Report..Partner pa
			on iof_slcr.PartnerID = pa.ID
							  

	/*******************************************************************************************************************************************
		10. Prepare for final report output
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			10.1. Populate initial table
		***********************************************************************************************************************/
	
			If Object_ID('tempdb..#OutputForReport_PreFormatting') Is Not Null Drop Table #OutputForReport_PreFormatting
			Select pcr.ClubID
				 , pcr.ClubName
				 , pcr.PartnerID
				 , pcr.PartnerName
				 , pcr.ClientServicesRef
				 , pcr.IronOfferID
				 , pcr.IronOfferName
				 , pcr.StartDate
				 , pcr.EndDate
				 , pcr.MerchantID
				 , pcr.RetailOutlet
				 , pcr.Channel
				 , Replace(Left(Replace(Error, ', , ', ', '), Len(Replace(Error, ', , ', ', ')) - 1), ',', ', ' + CHAR(13)) as Error
				 , Error_PartnerDeals
				 , Replace(Left(Replace([Update], ', , ', ', '), Len(Replace([Update], ', , ', ', ')) - 1), ',', ', ' + CHAR(13)) as [Update]
				 , pcr.OfferRate
				 , pcr.SpendStretchAmount
				 , pcr.AboveSpendStretchRate
				 , pcr.Override
				 , pcr.OfferBillingRate
				 , pcr.AboveSpendStrechBillingRate
				 , Case When pcr.Errors = 0 Then 0 Else 1 End as Errors
				 , Case When pcr.Updates = 0 Then 0 Else 1 End as Updates
				 , pcr.NewOffer
			Into #OutputForReport_PreFormatting
			From #PartnerCommissionRule_Validation pcr
			Where Case When pcr.Errors + pcr.Updates = 0 Then 0 Else 1 End in (@ErrorsAndUpdates, 1)
			And pcr.NewOffer in (@OfferAge, @OfferAge - 1)
			

		/***********************************************************************************************************************
			10.2. Find distinct list of Primary Partners
		***********************************************************************************************************************/
	
			If Object_ID('tempdb..#PrimaryPartners') Is Not Null Drop Table #PrimaryPartners
			Select Distinct
				   PrimaryPartnerID
				 , 1 as PrimaryPartner
			Into #PrimaryPartners
			From Warehouse.iron.PrimaryRetailerIdentification pri
			Where PrimaryPartnerID Is Not Null

		/***********************************************************************************************************************
			10.3. Select only rows chosen in report parameters and apply colour hex codes for report formatting
		***********************************************************************************************************************/
	
			If Object_ID('tempdb..#OutputForReport') Is Not Null Drop Table #OutputForReport
			Select ofr.ClubID
				 , ofr.ClubName
				 , ofr.PartnerID
				 , ofr.PartnerName
				 , pri.PrimaryPartner
				 , ofr.ClientServicesRef
				 , ofr.IronOfferID
				 , ofr.IronOfferName
				 , ofr.StartDate
				 , ofr.EndDate
				 , ofr.MerchantID
				 , ofr.RetailOutlet
				 , ofr.Channel
				 , ofr.Error
				 , ofr.Error_PartnerDeals
				 , '' as Error_OfferNotSetup
				 , ofr.[Update]
				 , ofr.OfferRate
				 , ofr.SpendStretchAmount
				 , ofr.AboveSpendStretchRate
				 , ofr.Override
				 , ofr.OfferBillingRate
				 , ofr.AboveSpendStrechBillingRate
				 , ofr.Errors
				 , ofr.Updates
				 --, ((Dense_Rank() Over (Order by ClubName) + 1) % 2) + 1 as ClubColourID
				 --, ((Dense_Rank() Over (Partition by ClubName Order by PartnerName) + 1) % 2) + 1 as PartnerColourID
				 --, ((Dense_Rank() Over (Partition by ClubName Order by PartnerName, ClientServicesRef) + 1) % 2) + 1 as ClientServicesRefColourID
				 , ((Dense_Rank() Over (Order by ofr.PartnerName) + 1) % 2) + 1 as PartnerColourID
				 , ((Dense_Rank() Over (Partition by ofr.PartnerName Order by ofr.ClubName) + 1) % 2) + 1 as ClubColourID
				 , ((Dense_Rank() Over (Partition by ofr.PartnerName Order by ofr.ClientServicesRef, ofr.ClubName) + 1) % 2) + 1 as ClientServicesRefColourID

				 , ((Dense_Rank() Over (Partition by pri.PrimaryPartner Order by ofr.PartnerName) + 1) % 2) + 1 as PartnerColourID_PartnerDeals
				 , ((Dense_Rank() Over (Partition by pri.PrimaryPartner, ofr.PartnerName Order by ofr.ClubName) + 1) % 2) + 1 as ClubColourID_PartnerDeals
			Into #OutputForReport
			From #OutputForReport_PreFormatting ofr
			Left join #PrimaryPartners pri
				on ofr.PartnerID = pri.PrimaryPartnerID

	/*******************************************************************************************************************************************
		11. Find rows from upcoming briefs that have not yet had their offers set up
	*******************************************************************************************************************************************/
	
		If Object_ID('tempdb..#OffersNotInputIntoBriefs') Is Not Null Drop Table #OffersNotInputIntoBriefs
		Select Distinct
			   cd.ClubID
			 , cl.Name as ClubName
			 , pa.ID as PartnerID
			 , pri.PrimaryPartner
			 , cd.PartnerName
			 , cd.ClientServicesRef
			 , 0 as IronOfferID
			 , '' as StartDate
			 , '' as EndDate
			 , '' as IronOfferName
			 , '' as MerchantID
			 , '' as RetailOutlet
			 , '' as Channel
			 , '' as Error
			 , '' as Error_PartnerDeals
			 , 'Offer not setup' as Error_OfferNotSetup
			 , '' as [Update]
			 , Convert(VarChar(15), OfferRate) as OfferRate
			 , Convert(VarChar(15), SpendStretchAmount) as SpendStretchAmount
			 , Convert(VarChar(15), AboveSpendStretchRate) as AboveSpendStretchRate
			 , Convert(VarChar(15), Override) as Override
			 , Convert(VarChar(15), OfferBillingRate) as OfferBillingRate
			 , Convert(VarChar(15), AboveSpendStrechBillingRate) as AboveSpendStrechBillingRate
			 , 1 as Errors
			 , 0 as Updates
			 --, ((Dense_Rank() Over (Order by cl.Name) + 1) % 2) + 1 as ClubColourID
			 --, ((Dense_Rank() Over (Partition by cl.Name Order by cd.PartnerName) + 1) % 2) + 1 as PartnerColourID
			 --, ((Dense_Rank() Over (Partition by cl.Name Order by cd.PartnerName, cd.ClientServicesRef) + 1) % 2) + 1 as ClientServicesRefColourID
			 , ((Dense_Rank() Over (Order by cd.PartnerName) + 1) % 2) + 1 as PartnerColourID
			 , ((Dense_Rank() Over (Partition by cd.PartnerName Order by cl.Name) + 1) % 2) + 1 as ClubColourID
			 , ((Dense_Rank() Over (Partition by cd.PartnerName Order by cd.ClientServicesRef, cl.Name) + 1) % 2) + 1 as ClientServicesRefColourID

			 , ((Dense_Rank() Over (Partition by pri.PrimaryPartner Order by cd.PartnerName) + 1) % 2) + 1 as PartnerColourID_PartnerDeals
			 , ((Dense_Rank() Over (Partition by pri.PrimaryPartner, cd.PartnerName Order by cl.Name) + 1) % 2) + 1 as ClubColourID_PartnerDeals
		Into #OffersNotInputIntoBriefs
		From Selections.AllPublisher_CampaignDetails cd
		Inner join Selections.AllPublisher_CampaignDetails_BriefsToImport bti
			on cd.ClientServicesRef = bti.ClientServicesRef
		Inner join SLC_Report..Club cl
			on cd.ClubID = cl.ID
		Left join SLC_Report..Partner pa
			on cd.PartnerName = pa.Name
		Left join #PrimaryPartners pri
			on pa.ID = pri.PrimaryPartnerID
		Where cd.IronOfferID Is Null
		And @OfferAge != 0


	/*******************************************************************************************************************************************
		11. Output final result for report
	*******************************************************************************************************************************************/

		Select ClubID
			 , ClubName
			 , PartnerID
			 , PartnerName
			 , PrimaryPartner
			 , ClientServicesRef
			 , IronOfferID
			 , IronOfferName
			 , StartDate
			 , EndDate
			 , MerchantID
			 , RetailOutlet
			 , Channel
			 , Error
			 , Error_PartnerDeals
			 , Error_OfferNotSetup
			 , [Update]
			 , OfferRate
			 , SpendStretchAmount
			 , AboveSpendStretchRate
			 , Override
			 , OfferBillingRate
			 , AboveSpendStrechBillingRate
			 , Errors
			 , Updates
			 , pc.PrimaryHex
			 , sc.SecondaryHex
			 , tc.TertiaryHex
			 , pc2.PrimaryHex as PrimaryHex_PartnerDeals
			 , sc2.SecondaryHex as SecondaryHex_PartnerDeals
			 , tc2.TertiaryHex as TertiaryHex_PartnerDeals
		From #OutputForReport ofr
		Left join Sandbox.Rory.PrimaryColour pc
			on ofr.PartnerColourID = pc.PrimaryID
		Left join Sandbox.Rory.SecondaryColour sc
			on ofr.PartnerColourID = sc.PrimaryID
			and ofr.ClientServicesRefColourID = sc.SecondaryID
		Left join Sandbox.Rory.TertiaryColour tc
			on ofr.PartnerColourID = tc.PrimaryID
			and ofr.ClubColourID = tc.TertiaryID
			
		Left join Sandbox.Rory.PrimaryColour pc2
			on ofr.PartnerColourID_PartnerDeals = pc2.PrimaryID
		Left join Sandbox.Rory.SecondaryColour sc2
			on ofr.PartnerColourID_PartnerDeals = sc2.PrimaryID
			and ofr.ClientServicesRefColourID = sc2.SecondaryID
		Left join Sandbox.Rory.TertiaryColour tc2
			on ofr.PartnerColourID_PartnerDeals = tc2.PrimaryID
			and ofr.ClubColourID_PartnerDeals = tc2.TertiaryID
		Union
		Select ClubID
			 , Case
					When ClubName Like '%MyRewards%' Then 'MyRewards'
					Else ClubName
			   End as ClubName
			 , PartnerID
			 , PartnerName
			 , PrimaryPartner
			 , ClientServicesRef
			 , IronOfferID
			 , IronOfferName
			 , StartDate
			 , EndDate
			 , MerchantID
			 , RetailOutlet
			 , Channel
			 , Error
			 , Error_PartnerDeals
			 , Error_OfferNotSetup
			 , [Update]
			 , OfferRate
			 , SpendStretchAmount
			 , AboveSpendStretchRate
			 , Override
			 , OfferBillingRate
			 , AboveSpendStrechBillingRate
			 , Errors
			 , Updates
			 , pc.PrimaryHex
			 , sc.SecondaryHex
			 , tc.TertiaryHex
			 , pc2.PrimaryHex as PrimaryHex_PartnerDeals
			 , sc2.SecondaryHex as SecondaryHex_PartnerDeals
			 , tc2.TertiaryHex as TertiaryHex_PartnerDeals
		From #OffersNotInputIntoBriefs oniib
		Left join Sandbox.Rory.PrimaryColour pc
			on oniib.PartnerColourID = pc.PrimaryID
		Left join Sandbox.Rory.SecondaryColour sc
			on oniib.PartnerColourID = sc.PrimaryID
			and oniib.ClientServicesRefColourID = sc.SecondaryID
		Left join Sandbox.Rory.TertiaryColour tc
			on oniib.PartnerColourID = tc.PrimaryID
			and oniib.ClubColourID = tc.TertiaryID
			
		Left join Sandbox.Rory.PrimaryColour pc2
			on oniib.PartnerColourID_PartnerDeals = pc2.PrimaryID
		Left join Sandbox.Rory.SecondaryColour sc2
			on oniib.PartnerColourID_PartnerDeals = sc2.PrimaryID
			and oniib.ClientServicesRefColourID = sc2.SecondaryID
		Left join Sandbox.Rory.TertiaryColour tc2
			on oniib.PartnerColourID_PartnerDeals = tc2.PrimaryID
			and oniib.ClubColourID_PartnerDeals = tc2.TertiaryID
		
		Order by PartnerName
			   , ClientServicesRef
			   , ClubName




End