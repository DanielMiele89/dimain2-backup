
CREATE Procedure [Selections].[AllPublisher_CampaignDetails_ImportBrief]
As 
Begin

	/*******************************************************************************************************************************************
		1. Fetch and rank the rows from the temp import table
	*******************************************************************************************************************************************/

	If Object_ID('tempdb..#BriefInput_Temp') Is Not Null Drop table #BriefInput_Temp
	Select *
		 , ROW_NUMBER() Over (Order by (Select null)) as RowNum
	Into #BriefInput_Temp
	From Selections.AllPublisher_CampaignDetails_BriefInput_Temp

	UPDATE #BriefInput_Temp
	SET AboveSpendStretchRate = REPLACE(AboveSpendStretchRate, '£', '')
	,	AboveSpendStrechBillingRate = REPLACE(AboveSpendStrechBillingRate, '£', '')

	/*******************************************************************************************************************************************
		2. Fetch campaign details
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Find the first row that contains campaign details
		***********************************************************************************************************************/

			Declare @CampaignDetailsStart Int = (Select Min(RowNum)
												 From #BriefInput_Temp
												 Where CampaignDetails_Header = 'Campaign Name')
											 

		/***********************************************************************************************************************
			2.2. Store all rows containing relevant details in table
		***********************************************************************************************************************/

			If Object_ID('tempdb..#CampaignDetails') Is Not Null Drop table #CampaignDetails
			Select CampaignDetails_Header
				 , CampaignDetails_Values
				 , Row_Number() Over (Order by (Select Null)) as Rank
			Into #CampaignDetails
			From #BriefInput_Temp
			Where RowNum Between @CampaignDetailsStart And @CampaignDetailsStart + 7
			And CampaignDetails_Header != 'Brand ID'
											 

		/***********************************************************************************************************************
			2.3. Store all rows containing relevant details as parameters to later insert to table
		***********************************************************************************************************************/

			Declare @CampaignName VarChar(150) = (Select CampaignDetails_Values From #CampaignDetails Where Rank = 1)
				  , @CampaignCode VarChar(150) = (Select CampaignDetails_Values From #CampaignDetails Where Rank = 2)
				  , @RetailerName VarChar(150) = (Select CampaignDetails_Values From #CampaignDetails Where Rank = 3)
				  , @Override VarChar(150) = (Select CampaignDetails_Values From #CampaignDetails Where Rank = 4)
				  , @StartDate VarChar(150) = (Select CampaignDetails_Values From #CampaignDetails Where Rank = 5)
				  , @EndDate VarChar(150) = (Select CampaignDetails_Values From #CampaignDetails Where Rank = 6)


	/*******************************************************************************************************************************************
		3. Fetch campaign details
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#OfferDetails') Is Not Null Drop table #OfferDetails
		Select Publisher
			 , IronOfferID
			 , OfferRate
			 , SpendStretchAmount
			 , Case
				When AboveSpendStretchRate Like '%:%' Then Round(Convert(Float, Convert(DateTime, AboveSpendStretchRate)), 4) * 100.00
				When AboveSpendStretchRate Like '%/%' Then Convert(Float, 0.00)
				Else Convert(Float, Replace(AboveSpendStretchRate, '%', ''))
			   End as AboveSpendStretchRate
			 , Case
				When OfferBillingRate Like '%:%' Then Round(Convert(Float, Convert(DateTime, OfferBillingRate)), 4) * 100
				Else Convert(Float, Replace(OfferBillingRate, '%', ''))
			   End as OfferBillingRate
			 , AboveSpendStrechBillingRate
		Into #OfferDetails
		From #BriefInput_Temp
		Where Publisher != 'Publisher'

		UPDATE #OfferDetails
		SET SpendStretchAmount = '£24.00'
		WHERE IronOfferID = '17669'


	/*******************************************************************************************************************************************
		4. Insert to final table
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
			 , @RetailerName as PartnerName
			 , Case
					When @Override Like '%[%]%' Then Convert(Float, Replace(@Override, '%', ''))
					Else @Override
			   End as Override
			 , @CampaignCode as ClientServicesRef
			 , @StartDate as CampaignStartDate
			 , @EndDate as CampaignEndDate
			 , IronOfferID
			 , Case
					When OfferRate Like '%[%]%' Then Convert(Float, Replace(OfferRate, '%', ''))
					Else OfferRate
			   End as OfferRate
			 , Case
					When SpendStretchAmount Like '%£%' Then Convert(Float, Replace(Replace(SpendStretchAmount, '£', ''), ',', ''))
					Else SpendStretchAmount
			   End as SpendStretchAmount
			 , Case
					When AboveSpendStretchRate Like '%[%]%' Then Convert(Float, Replace(AboveSpendStretchRate, '%', ''))
					Else AboveSpendStretchRate
			   End as AboveSpendStretchRate
			 , OfferBillingRate as OfferBillingRate
			 , Case
					When AboveSpendStrechBillingRate Like '%[%]%' Then Convert(Float, Replace(AboveSpendStrechBillingRate, '%', ''))
					Else AboveSpendStrechBillingRate
			   End as AboveSpendStrechBillingRate
		From #OfferDetails od
		Where Not exists (Select 1
						  From Selections.AllPublisher_CampaignDetails_BriefInput bi
						  Where @CampaignCode = bi.ClientServicesRef)


	/*******************************************************************************************************************************************
		5. Clear down temp table
	*******************************************************************************************************************************************/

		Truncate Table Selections.AllPublisher_CampaignDetails_BriefInput_Temp

End








