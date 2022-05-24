
CREATE PROCEDURE [Selections].[AllPublisher_CampaignDetails_FinalInsert_Alt]
As 
Begin

	/*******************************************************************************************************************************************
		1. Delete entries of the briefs being imported if they already exist in the table
	*******************************************************************************************************************************************/
		
		If Object_ID('tempdb..#FullyImported') Is Not Null Drop Table #FullyImported
		Select bti.ClientServicesRef
			 , Convert(Date, bti.StartDate, 103) as StartDate
			 , Case
					When Count(cd.ClubID) > 0
					 And Count(cd.ClubID) = Count(cd.PartnerName) 
					 And Count(cd.PartnerName) = Count(cd.Override) 
					 And Count(cd.Override) = Count(cd.ClientServicesRef) 
					 And Count(cd.ClientServicesRef) = Count(cd.CampaignStartDate) 
					 And Count(cd.CampaignStartDate) = Count(cd.CampaignEndDate) 
					 And Count(cd.CampaignEndDate) = Count(cd.IronOfferID) 
					 And Count(cd.IronOfferID) = Count(cd.OfferRate) 
					 And Count(cd.OfferRate) = Count(cd.SpendStretchAmount) 
					 And Count(cd.SpendStretchAmount) = Count(cd.AboveSpendStretchRate) 
					 And Count(cd.AboveSpendStretchRate) = Count(cd.OfferBillingRate) 
					 And Count(cd.OfferBillingRate) = Count(cd.AboveSpendStrechBillingRate)
					Then 1
					Else 0
			   End as FullyImported
		Into #FullyImported
		From [Selections].[CampaignSetup_BriefInsert_BriefsToImport] bti
		Inner join [Selections].[AllPublisher_CampaignDetails] cd
			on bti.ClientServicesRef = cd.ClientServicesRef
			and Convert(Date, bti.StartDate, 103) = cd.CampaignStartDate
		Group by bti.ClientServicesRef
			   , bti.StartDate

		Delete cd
		From #FullyImported fi
		Inner join Selections.AllPublisher_CampaignDetails cd
			on fi.ClientServicesRef = cd.ClientServicesRef
			and fi.StartDate = cd.CampaignStartDate
		Where fi.FullyImported = 0



	/*******************************************************************************************************************************************
		2. Store entries where there is a non numeric character in the IronOfferID column
	*******************************************************************************************************************************************/

		Insert into Selections.AllPublisher_CampaignDetails (ClubID
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
		Select Case
					When bi.Publisher = 'Gobsmack - Mustard' Then 157
					When bi.Publisher = 'Complete Savings' Then 159
					When bi.Publisher = 'MyRewards' Then 132
					When bi.Publisher = 'Emirates' Then 955
					When bi.Publisher = 'Emirates' Then 955
					Else pub.PublisherID
			   End as ClubID
			 , PartnerName
			 , Override
			 , ClientServicesRef
			 , Convert(Date, CampaignStartDate, 103) as CampaignStartDate
			 , Convert(Date, CampaignEndDate, 103) as CampaignEndDate
			 , IronOfferID
			 , OfferRate
			 , SpendStretchAmount
			 , AboveSpendStretchRate
			 , OfferBillingRate
			 , AboveSpendStrechBillingRate
		From [Selections].[CampaignSetup_BriefInsert_OfferDetails] bi
		LEFT JOIN ExcelQuery.ROCEFT_Publishers pub
			ON bi.Publisher = pub.PublisherName
		Where Not Exists (Select 1
						  From Selections.AllPublisher_CampaignDetails cd
						  Where bi.ClientServicesRef = cd.ClientServicesRef)

END