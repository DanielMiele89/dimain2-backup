
CREATE Procedure [Selections].[AllPublisher_CampaignDetails_SeperateOfferIDs]
As 
Begin

	/*******************************************************************************************************************************************
		1. Store entries where there is a non numeric character in the IronOfferID column
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#IronOfferID_Edit') Is Not Null Drop table #IronOfferID_Edit
		Select IronOfferID
			 , IronOfferID as IronOfferID_Edit
			 , Null as IronOffer1
			 , Null as IronOffer2
			 , Null as IronOffer3
		Into #IronOfferID_Edit
		From Selections.AllPublisher_CampaignDetails_BriefInput
		Where PatIndex('%[^0-9]%', IronOfferID) > 0

	/*******************************************************************************************************************************************
		2. Split the stored IronOfferIDs into at 3 different IDs (more may need to be added depnding on counts of secondary partners)
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Extract the first IronOfferID by finding the first numeric character then taking all following numeric
				 characters without break.
				 Once seperated, remove this string from the IronOfferID_Edit column to prevent duplication
		***********************************************************************************************************************/

			Update #IronOfferID_Edit
			Set IronOffer1 = Substring(IronOfferID_Edit,
									   PatIndex('%[0-9]%', IronOfferID_Edit),
									   Case
						   				   When PatIndex('%[^0-9]%', Substring(IronOfferID_Edit, PatIndex('%[0-9]%', IronOfferID_Edit), Len(IronOfferID_Edit))) = 0 Then Len(Substring(IronOfferID_Edit, PatIndex('%[0-9]%', IronOfferID_Edit), Len(IronOfferID_Edit)))
						   				   Else PatIndex('%[^0-9]%', Substring(IronOfferID_Edit, PatIndex('%[0-9]%', IronOfferID_Edit), Len(IronOfferID_Edit))) - 1
										End)

			Update #IronOfferID_Edit
			Set IronOfferID_Edit = Replace(IronOfferID_Edit, IronOffer1, '')
									 

		/***********************************************************************************************************************
			2.2. Repeat the process for the second instance of an IronOfferID, leaving null values where no second offer found
		***********************************************************************************************************************/

			Update #IronOfferID_Edit
			Set IronOffer2 = Substring(IronOfferID_Edit,
									   PatIndex('%[0-9]%', IronOfferID_Edit),
									   Case
						   				   When PatIndex('%[^0-9]%', Substring(IronOfferID_Edit, PatIndex('%[0-9]%', IronOfferID_Edit), Len(IronOfferID_Edit))) = 0 Then Len(Substring(IronOfferID_Edit, PatIndex('%[0-9]%', IronOfferID_Edit), Len(IronOfferID_Edit)))
						   				   Else PatIndex('%[^0-9]%', Substring(IronOfferID_Edit, PatIndex('%[0-9]%', IronOfferID_Edit), Len(IronOfferID_Edit))) - 1
										End)
			Where PatIndex('%[0-9]%', IronOfferID_Edit) > 0

			Update #IronOfferID_Edit
			Set IronOfferID_Edit = Replace(IronOfferID_Edit, IronOffer2, '')
											 

		/***********************************************************************************************************************
			2.3. Repeat the process for the third instance of an IronOfferID, leaving null values where no second offer found
		***********************************************************************************************************************/


			Update #IronOfferID_Edit
			Set IronOffer3 = Substring(IronOfferID_Edit, 
									   PatIndex('%[0-9]%', IronOfferID_Edit),
									   Case
						   				   When PatIndex('%[^0-9]%', Substring(IronOfferID_Edit, PatIndex('%[0-9]%', IronOfferID_Edit), Len(IronOfferID_Edit))) = 0 Then Len(Substring(IronOfferID_Edit, PatIndex('%[0-9]%', IronOfferID_Edit), Len(IronOfferID_Edit)))
						   				   Else PatIndex('%[^0-9]%', Substring(IronOfferID_Edit, PatIndex('%[0-9]%', IronOfferID_Edit), Len(IronOfferID_Edit))) - 1
										End)
			Where PatIndex('%[0-9]%', IronOfferID_Edit) > 0

			Update #IronOfferID_Edit
			Set IronOfferID_Edit = Replace(IronOfferID_Edit, IronOffer3, '')		


	/*******************************************************************************************************************************************
		3. Union disinct entries per offer
	*******************************************************************************************************************************************/
	
		If Object_ID('tempdb..#IronOffer_Join') Is Not Null Drop table #IronOffer_Join
		Select Distinct
			   IronOffer_Join
			 , IronOfferID
		Into #IronOffer_Join
		From (	Select IronOfferID as IronOffer_Join
					 , IronOffer1 as IronOfferID
				From #IronOfferID_Edit
				Where IronOffer1 Is Not Null

				Union

				Select IronOfferID as IronOffer_Join
					 , IronOffer2 as IronOfferID
				From #IronOfferID_Edit
				Where IronOffer2 Is Not Null

				Union

				Select IronOfferID as IronOffer_Join
					 , IronOffer3 as IronOfferID
				From #IronOfferID_Edit
				Where IronOffer3 Is Not Null) a


	/*******************************************************************************************************************************************
		4. Rejoin to original table, replacing the concatenated IronOfferID string with individual IronOffers
	*******************************************************************************************************************************************/
	
		If Object_ID('tempdb..#AllPublisher_CampaignDetails_BriefInput') Is Not Null Drop table #AllPublisher_CampaignDetails_BriefInput
		Select Distinct
			   bi.Publisher
			 , bi.PartnerName
			 , bi.Override
			 , bi.ClientServicesRef
			 , bi.CampaignStartDate
			 , bi.CampaignEndDate
			 , ioj.IronOfferID
			 , bi.OfferRate
			 , bi.SpendStretchAmount
			 , bi.AboveSpendStretchRate
			 , bi.OfferBillingRate
			 , bi.AboveSpendStrechBillingRate
		Into #AllPublisher_CampaignDetails_BriefInput
		From #IronOffer_Join ioj
		Inner join Selections.AllPublisher_CampaignDetails_BriefInput bi
			on ioj.IronOffer_Join = bi.IronOfferID

	/*******************************************************************************************************************************************
		4. Delete the original entry of each offer from main table where a replacement has been gerenated
	*******************************************************************************************************************************************/
	
		Delete bi
		From Selections.AllPublisher_CampaignDetails_BriefInput bi
		Inner join #IronOffer_Join iof
			on bi.IronOfferID = iof.IronOffer_Join


	/*******************************************************************************************************************************************
		5. Insert new entries to AllPublisher_CampaignDetails_BriefInput
	*******************************************************************************************************************************************/

		Insert into Selections.AllPublisher_CampaignDetails_BriefInput (Publisher
																	  , PartnerName
																	  , Override
																	  , ClientServicesRef
																	  , CampaignStartDate
																	  , CampaignEndDate
																	  , IronOfferID
																	  , OfferRate
																	  , SpendStretchAmount
																	  , AboveSpendStretchRate
																	  , OfferBillingRate
																	  , AboveSpendStrechBillingRate)
		Select Publisher
			 , PartnerName
			 , Override
			 , ClientServicesRef
			 , CampaignStartDate
			 , CampaignEndDate
			 , IronOfferID
			 , OfferRate
			 , SpendStretchAmount
			 , AboveSpendStretchRate
			 , OfferBillingRate
			 , AboveSpendStrechBillingRate
		From #AllPublisher_CampaignDetails_BriefInput

End