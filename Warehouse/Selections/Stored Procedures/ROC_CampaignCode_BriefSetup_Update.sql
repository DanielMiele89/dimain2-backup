
CREATE Procedure [Selections].[ROC_CampaignCode_BriefSetup_Update] (@EmailDate VarChar(15))
As 
Begin



	--	Declare @EmailDate Date = '2018-09-13'

Update Warehouse.Selections.ROCShopperSegment_CampaignSetup
Set StartOnHalfCycle = Case When StartOnHalfCycle Is Null Then '' Else StartOnHalfCycle End
  , EndOnHalfCycle = Case When EndOnHalfCycle Is Null Then '' Else EndOnHalfCycle End


/***************************************************************************************************
		Split briefs with multiple offers per segment into seperate rows
***************************************************************************************************/

If Object_ID('tempdb..#OfferToSelectFromBrief') Is Not Null Drop Table #OfferToSelectFromBrief
Select PartnerID
	 , ClientServicesRef	
	 , OfferToSelectFromBrief
	 , PriorityFlag
Into #OfferToSelectFromBrief
From Warehouse.Selections.ROCShopperSegment_CampaignSetup cs
Where cs.CampaignStartDate = @EmailDate
and (OfferToSelectFromBrief != '' Or PartnerID in (4319,4523,4514,3432,4685,4715,4716,4637,4671))

If Object_ID('tempdb..#OfferToSelectFromBrief_CampaignsToEdit') Is Not Null Drop Table #OfferToSelectFromBrief_CampaignsToEdit
Select Distinct bi.*
	 , SUBSTRING(bi.IronOfferID, PatIndex('%[0-9]%', bi.IronOfferID), 5) as FirstOffer
	 , SUBSTRING(bi.IronOfferID, 4 + PatIndex('%[0-9]%', SUBSTRING(bi.IronOfferID, PatIndex('%[0-9]%', bi.IronOfferID) + 5, Len(bi.IronOfferID))) + PatIndex('%[0-9]%', bi.IronOfferID), 5) as SecondOffer
	 , SUBSTRING(bi.IronOfferID, 8 + PatIndex('%[0-9]%', bi.IronOfferID) + PatIndex('%[0-9]%', SUBSTRING(bi.IronOfferID, PatIndex('%[0-9]%', bi.IronOfferID) + 5, Len(bi.IronOfferID))) + PatIndex('%[0-9]%', SUBSTRING(bi.IronOfferID, PatIndex('%[0-9]%', SUBSTRING(bi.IronOfferID, PatIndex('%[0-9]%', bi.IronOfferID) + 5, Len(bi.IronOfferID))) + PatIndex('%[0-9]%', bi.IronOfferID) + 9, Len(bi.IronOfferID))), 5) as ThirdOffer
	 , PartnerID
Into #OfferToSelectFromBrief_CampaignsToEdit
From #OfferToSelectFromBrief ots
Inner join Warehouse.Selections.ROCShopperSegment_BriefInput bi
	on ots.ClientServicesRef = bi.ClientServicesRef
Where bi.CampaignStart = @EmailDate

Delete bi
From #OfferToSelectFromBrief ots
Inner join Warehouse.Selections.ROCShopperSegment_BriefInput bi
	on ots.ClientServicesRef = bi.ClientServicesRef
Where bi.CampaignStart = @EmailDate

Insert Into Warehouse.Selections.ROCShopperSegment_BriefInput
Select Publisher
	 , ClientServicesRef
	 , CampaignStart
	 , CampaignEnd
	 , CycleNumber
	 , CycleStart
	 , CycleEnd
	 , ShopperSegment
	 , SelectionTopXPercent
	 , Gender
	 , AgeGroupMin
	 , AgeGroupMax
	 , DriveTime
	 , SocialClassLowest
	 , SocialClassHighest
	 , MarketableByEmail
	 , OfferRate
	 , SpendStretchAmount
	 , AboveSpendStretchRate
	 , FirstOffer As IronOfferID
	 , RandomThrottle
	 , OfferBillingRate
	 , AboveSpendStretchBillingRate
	 , PredictedCardholderVolumes
	 , ActualCardholderVolumes
	 , Case When PartnerID = 4514 Then 'Debit' End as OfferToSelectFromBrief
From #OfferToSelectFromBrief_CampaignsToEdit

Union

Select Publisher
	 , ClientServicesRef
	 , CampaignStart
	 , CampaignEnd
	 , CycleNumber
	 , CycleStart
	 , CycleEnd
	 , ShopperSegment
	 , SelectionTopXPercent
	 , Gender
	 , AgeGroupMin
	 , AgeGroupMax
	 , DriveTime
	 , SocialClassLowest
	 , SocialClassHighest
	 , MarketableByEmail
	 , OfferRate
	 , SpendStretchAmount
	 , AboveSpendStretchRate
	 , SecondOffer As IronOfferID
	 , RandomThrottle
	 , OfferBillingRate
	 , AboveSpendStretchBillingRate
	 , PredictedCardholderVolumes
	 , ActualCardholderVolumes
	 , 'DebitCredit' as OfferToSelectFromBrief
From #OfferToSelectFromBrief_CampaignsToEdit
Where PartnerID = 4514

Union

Select Publisher
	 , ClientServicesRef
	 , CampaignStart
	 , CampaignEnd
	 , CycleNumber
	 , CycleStart
	 , CycleEnd
	 , ShopperSegment
	 , SelectionTopXPercent
	 , Gender
	 , AgeGroupMin
	 , AgeGroupMax
	 , DriveTime
	 , SocialClassLowest
	 , SocialClassHighest
	 , MarketableByEmail
	 , OfferRate
	 , SpendStretchAmount
	 , AboveSpendStretchRate
	 , ThirdOffer As IronOfferID
	 , RandomThrottle
	 , OfferBillingRate
	 , AboveSpendStretchBillingRate
	 , PredictedCardholderVolumes
	 , ActualCardholderVolumes
	 , 'Credit' as OfferToSelectFromBrief
From #OfferToSelectFromBrief_CampaignsToEdit
Where PartnerID = 4514

/***************************************************************************************************
		For campaigns requiring 2 week cycles update end dates and insert mid cycle campaigns
***************************************************************************************************/

			--	Declare @EmailDate Date = '2018-09-13'

			If Object_ID('tempdb..#TwoWeekCycles_EndOnHalfCycle') Is Not Null Drop Table #TwoWeekCycles_EndOnHalfCycle
			Select bi.ClientServicesRef
				 , Max(CycleStart) As CycleStart
			Into #TwoWeekCycles_EndOnHalfCycle
			From Warehouse.Selections.ROCShopperSegment_BriefInput bi
			Inner join Warehouse.Selections.ROCShopperSegment_CampaignSetup cs
				on bi.ClientServicesRef = cs.ClientServicesRef
			Where cs.EndOnHalfCycle = 1
			Group by bi.ClientServicesRef

		/*******************************************************************************************
			Starting on a half cycle
		*******************************************************************************************/
		
			/*******************************************************************************************
				Prepare tables to update
			*******************************************************************************************/

				If Object_ID('tempdb..#TwoWeekCycles_CampaignsToEdit_FirstCycle_HC') Is Not Null Drop Table #TwoWeekCycles_CampaignsToEdit_FirstCycle_HC
				Select Distinct
						bi.*
				Into #TwoWeekCycles_CampaignsToEdit_FirstCycle_HC
				From Warehouse.Selections.ROCShopperSegment_BriefInput bi
				Inner join Warehouse.Selections.ROCShopperSegment_CampaignSetup cs
					on bi.ClientServicesRef = cs.ClientServicesRef
					and (bi.OfferToSelectFromBrief = cs.OfferToSelectFromBrief or bi.OfferToSelectFromBrief is null)
				Where TwoWeekCycles = 1
				And CycleNumber = 1
				And StartOnHalfCycle = 1
				And bi.CampaignStart = @EmailDate
				And cs.CampaignStartDate = @EmailDate

				If Object_ID('tempdb..#TwoWeekCycles_CampaignsToEdit_FirstCycle_Counts_HC') Is Not Null Drop Table #TwoWeekCycles_CampaignsToEdit_FirstCycle_Counts_HC
				Select ClientServicesRef
					 , Count(Distinct ClientServicesRef) as Count
				Into #TwoWeekCycles_CampaignsToEdit_FirstCycle_Counts_HC
				From #TwoWeekCycles_CampaignsToEdit_FirstCycle_HC
				Group by ClientServicesRef
		
				If Object_ID('tempdb..#TwoWeekCycles_CampaignsToEdit_1_HC') Is Not Null Drop Table #TwoWeekCycles_CampaignsToEdit_1_HC
				Select Distinct
						bi.*
				Into #TwoWeekCycles_CampaignsToEdit_1_HC
				From Warehouse.Selections.ROCShopperSegment_BriefInput bi
				Inner join Warehouse.Selections.ROCShopperSegment_CampaignSetup cs
					on bi.ClientServicesRef = cs.ClientServicesRef
					and (bi.OfferToSelectFromBrief = cs.OfferToSelectFromBrief or bi.OfferToSelectFromBrief is null)
				Where TwoWeekCycles = 1
				And CycleNumber != 1
				And StartOnHalfCycle = 1
				And bi.CampaignStart = @EmailDate
				And cs.CampaignStartDate = @EmailDate

				If Object_ID('tempdb..#TwoWeekCycles_CampaignsToEdit_2_HC') Is Not Null Drop Table #TwoWeekCycles_CampaignsToEdit_2_HC
				Select *
				Into #TwoWeekCycles_CampaignsToEdit_2_HC
				From #TwoWeekCycles_CampaignsToEdit_1_HC

				Delete bi
				From Warehouse.Selections.ROCShopperSegment_BriefInput bi
				Inner join Warehouse.Selections.ROCShopperSegment_CampaignSetup cs
					on bi.ClientServicesRef = cs.ClientServicesRef
					and (bi.OfferToSelectFromBrief = cs.OfferToSelectFromBrief or bi.OfferToSelectFromBrief is null)
				Where TwoWeekCycles = 1
				And StartOnHalfCycle = 1
				And bi.CampaignStart = @EmailDate
				And cs.CampaignStartDate = @EmailDate

			/*******************************************************************************************
				Update cycle information
			*******************************************************************************************/

				Update cte
				Set CycleNumber = (cte.CycleNumber * 2) - 1 - cte_fc.Count
				  , CycleEnd = Convert(Date, DateAdd(day, -14, cte.CycleEnd))
				From #TwoWeekCycles_CampaignsToEdit_1_HC cte
				Left join #TwoWeekCycles_CampaignsToEdit_FirstCycle_Counts_HC cte_fc
					on cte.ClientServicesRef = cte_fc.ClientServicesRef
				Left join #TwoWeekCycles_EndOnHalfCycle ehc
					on cte.ClientServicesRef = ehc.ClientServicesRef
					and cte.CycleStart = ehc.CycleStart
				Where ehc.ClientServicesRef Is Null

				Update cte
				Set CycleNumber = (cte.CycleNumber * 2) - cte_fc.Count
				  , CycleStart = Convert(Date, DateAdd(day, 14, cte.CycleStart))
				From #TwoWeekCycles_CampaignsToEdit_2_HC cte
				Left join #TwoWeekCycles_CampaignsToEdit_FirstCycle_Counts_HC cte_fc
					on cte.ClientServicesRef = cte_fc.ClientServicesRef
				Left join #TwoWeekCycles_EndOnHalfCycle ehc
					on cte.ClientServicesRef = ehc.ClientServicesRef
					and cte.CycleStart = ehc.CycleStart
				Where ehc.ClientServicesRef Is Null

			/*******************************************************************************************
				Insert back to main table
			*******************************************************************************************/

				Insert Into Warehouse.Selections.ROCShopperSegment_BriefInput
				Select *
				From (Select *
					  From #TwoWeekCycles_CampaignsToEdit_1_HC
					  Union
					  Select *
					  From #TwoWeekCycles_CampaignsToEdit_2_HC
					  Union
					  Select *
					  From #TwoWeekCycles_CampaignsToEdit_FirstCycle_HC) a

		/*******************************************************************************************
			Not starting on a half cycle
		*******************************************************************************************/

			--	Declare @EmailDate Date = '2018-09-13'
		
			/*******************************************************************************************
				Prepare tables to update
			*******************************************************************************************/
		
				If Object_ID('tempdb..#TwoWeekCycles_CampaignsToEdit_1_FC') Is Not Null Drop Table #TwoWeekCycles_CampaignsToEdit_1_FC
				Select Distinct
						bi.*
				Into #TwoWeekCycles_CampaignsToEdit_1_FC
				From Warehouse.Selections.ROCShopperSegment_BriefInput bi
				Inner join Warehouse.Selections.ROCShopperSegment_CampaignSetup cs
					on bi.ClientServicesRef = cs.ClientServicesRef
					and (bi.OfferToSelectFromBrief = cs.OfferToSelectFromBrief or bi.OfferToSelectFromBrief is null)
				Where TwoWeekCycles = 1
				And StartOnHalfCycle != 1
				And bi.CampaignStart = @EmailDate
				And cs.CampaignStartDate = @EmailDate

				If Object_ID('tempdb..#TwoWeekCycles_CampaignsToEdit_2_FC') Is Not Null Drop Table #TwoWeekCycles_CampaignsToEdit_2_FC
				Select *
				Into #TwoWeekCycles_CampaignsToEdit_2_FC
				From #TwoWeekCycles_CampaignsToEdit_1_FC

				Delete bi
				From Warehouse.Selections.ROCShopperSegment_BriefInput bi
				Inner join Warehouse.Selections.ROCShopperSegment_CampaignSetup cs
					on bi.ClientServicesRef = cs.ClientServicesRef
					and (bi.OfferToSelectFromBrief = cs.OfferToSelectFromBrief or bi.OfferToSelectFromBrief is null)
				Where TwoWeekCycles = 1
				And StartOnHalfCycle != 1
				And bi.CampaignStart = @EmailDate
				And cs.CampaignStartDate = @EmailDate

			/*******************************************************************************************
				Update cycle information
			*******************************************************************************************/

				Update cte
				Set CycleNumber = (cte.CycleNumber * 2) - 1
				  , CycleEnd = Convert(Date, DateAdd(day, -14, cte.CycleEnd))
				From #TwoWeekCycles_CampaignsToEdit_1_FC cte
				Left join #TwoWeekCycles_EndOnHalfCycle ehc
					on cte.ClientServicesRef = ehc.ClientServicesRef
					and cte.CycleStart = ehc.CycleStart
				Where ehc.ClientServicesRef Is Null

				Update cte
				Set CycleNumber = (cte.CycleNumber * 2)
				  , CycleStart = Convert(Date, DateAdd(day, 14, cte.CycleStart))
				From #TwoWeekCycles_CampaignsToEdit_2_FC cte
				Left join #TwoWeekCycles_EndOnHalfCycle ehc
					on cte.ClientServicesRef = ehc.ClientServicesRef
					and cte.CycleStart = ehc.CycleStart
				Where ehc.ClientServicesRef Is Null


			/*******************************************************************************************
				Insert back to main table
			*******************************************************************************************/

				Insert Into Warehouse.Selections.ROCShopperSegment_BriefInput
				Select *
				From (Select *
					  From #TwoWeekCycles_CampaignsToEdit_1_FC
					  Union
					  Select *
					  From #TwoWeekCycles_CampaignsToEdit_2_FC) a


/***************************************************************************************************
		Set the customer base offer date
***************************************************************************************************/

Update bi1
Set bi1.CustomerBaseDate = bi2.CycleStart
From Warehouse.Selections.ROCShopperSegment_CampaignSetup_SelectionTable bi1
Inner join Warehouse.Selections.ROCShopperSegment_CampaignSetup_SelectionTable bi2
	on bi1.Publisher = bi2.Publisher
	and bi1.PartnerID = bi2.PartnerID
	and bi1.ClientServicesRef = bi2.ClientServicesRef
	and bi1.CycleNumber = (bi2.CycleNumber + 1)
Where bi1.ShopperSegment != 'Welcome'
And bi1.CampaignStart = @EmailDate
And bi2.CampaignStart = @EmailDate


Insert Into Warehouse.Selections.ROCShopperSegment_CampaignSetup_SelectionTable
Select Publisher
	 , cs.PartnerID
	 , pa.PartnerName
	 , cs.ClientServicesRef
	 , CampaignName
	 , CampaignStart
	 , CampaignEnd
	 , CycleNumber
	 , CycleStart
	 , CycleEnd
	 , ShopperSegment
	 , IronOfferID

	 , OfferRate
	 , SpendStretchAmount
	 , AboveSpendStretchRate
	 , OfferBillingRate
	 , AboveSpendStretchBillingRate

	 , Gender
	 , AgeGroupMin
	 , AgeGroupMax
	 , DriveTime
	 , SocialClassLowest
	 , SocialClassHighest
	 , MarketableByEmail

	 , Case
			When SelectionTopXPercent != '100%' Or RandomThrottle != '100%' Then 1
			Else 0
	   End as Throttle
	   
	 , Case
			When RandomThrottle != '100%' Then 1
			Else 0
	   End as RandomThrottle

	 , CompetitorType
	 , CompetitorCampaignID
	 , DedupeAgainstCampaigns
	 , SelectedInAnotherCampaign
	 , CustomerBaseDate
	 , sProcPreSelection
	 , PredictedCardholderVolumes
	 , ActualCardholderVolumes
	 , OutputTableName
	 , NotIn_TableName1
	 , NotIn_TableName2
	 , NotIn_TableName3
	 , NotIn_TableName4
	 , Must_BeInTableName1
	 , Must_BeInTableName2
	 , Must_BeInTableName3
	 , Must_BeInTableName4
	 , BriefFilePath
	 , PriorityFlag
	 , Row_Number() Over (Partition by Publisher, cs.PartnerID, CycleStart Order by PriorityFlag, Case
																									When ShopperSegment = 'Welcome' Then 1
																									When ShopperSegment = 'Birthday' Then 2
																									When ShopperSegment = 'Homemover' Then 3
																									When ShopperSegment = 'Launch' Then 4
																									When ShopperSegment = 'Acquire' Then 5
																									When ShopperSegment = 'Lapsed' Then 6
																									When ShopperSegment = 'Shopper' Then 7
																									When ShopperSegment = 'Universal' Then 8
																								  End) as PriorityFlag_Ranked

	 , Case
			When CycleStart = CampaignStart Then 1
			Else 0
	   End as NewCampaign
	 , ReadyToRun
	 , SelectionRun
From Warehouse.Selections.ROCShopperSegment_BriefInput bi
Inner join Warehouse.Selections.ROCShopperSegment_CampaignSetup cs
	on bi.ClientServicesRef = cs.ClientServicesRef
	and (bi.OfferToSelectFromBrief = cs.OfferToSelectFromBrief or bi.OfferToSelectFromBrief is null)
Left join Warehouse.Relational.Partner pa
	on cs.PartnerID = pa.PartnerID

End



/*
Select cs.PartnerID
	 , cs.ClientServicesRef
	 , cs.PriorityFlag
	 , bi.CycleStart
	 , bi.CycleEnd
	 , bi.ShopperSegment
	 , Case	
			When bi.ShopperSegment = 'Welcome' Then 1
			When bi.ShopperSegment = 'Birthday' Then 2
			When bi.ShopperSegment = 'Homemover' Then 3
			When bi.ShopperSegment = 'Acquire' Then 4
			When bi.ShopperSegment = 'Lapsed' Then 5
			When bi.ShopperSegment = 'Shopper' Then 6
	   End as ShopperSegmentPriority
	 , Row_number() Over (Partition by CycleStart, PartnerID Order By Case When bi.ShopperSegment = 'Welcome' Then 0 Else 1 End, cs.PriorityFlag, Case	
																																						When bi.ShopperSegment = 'Welcome' Then 1
																																						When bi.ShopperSegment = 'Birthday' Then 2
																																						When bi.ShopperSegment = 'Homemover' Then 3
																																						When bi.ShopperSegment = 'Acquire' Then 4
																																						When bi.ShopperSegment = 'Lapsed' Then 5
																																						When bi.ShopperSegment = 'Shopper' Then 6
																																				   End) As NewPriorityFlag
	 , bi.IronOfferID
From Warehouse.Selections.ROCShopperSegment_CampaignSetup cs
Left join Warehouse.Selections.ROCShopperSegment_BriefInput bi
	on cs.ClientServicesRef = bi.ClientServicesRef
Where cs.ClientServicesRef Like 'EC%'
Order by CycleStart
	   , PartnerID
	   , Dense_Rank() Over (Partition by CycleStart, PartnerID Order By Case When bi.ShopperSegment = 'Welcome' Then 0 Else 1 End, cs.PriorityFlag, Case	
																																						When bi.ShopperSegment = 'Welcome' Then 1
																																						When bi.ShopperSegment = 'Birthday' Then 2
																																						When bi.ShopperSegment = 'Homemover' Then 3
																																						When bi.ShopperSegment = 'Acquire' Then 4
																																						When bi.ShopperSegment = 'Lapsed' Then 5
																																						When bi.ShopperSegment = 'Shopper' Then 6
																																				   End)



Select PartnerID
	 , ClientServicesRef
	 , CycleStart
	 , CycleEnd
	 , ShopperSegment
	 , IronOfferID
	 , ShopperSegmentPriority
	 , Row_number() Over (Partition by CycleStart, PartnerID Order By Case When ShopperSegment = 'Welcome' Then 0 Else 1 End, PriorityFlag, Case	
																																				When ShopperSegment = 'Welcome' Then 1
																																				When ShopperSegment = 'Birthday' Then 2
																																				When ShopperSegment = 'Homemover' Then 3
																																				When ShopperSegment = 'Acquire' Then 4
																																				When ShopperSegment = 'Lapsed' Then 5
																																				When ShopperSegment = 'Shopper' Then 6
																																		    End) As NewPriorityFlag
Into #NewPriority
From (
	Select cs.PartnerID
		 , cs.ClientServicesRef
		 , bi.CycleStart
		 , bi.CycleEnd
		 , bi.ShopperSegment
		 , Case	
				When bi.ShopperSegment = 'Welcome' Then 1
				When bi.ShopperSegment = 'Birthday' Then 2
				When bi.ShopperSegment = 'Homemover' Then 3
				When bi.ShopperSegment = 'Acquire' Then 4
				When bi.ShopperSegment = 'Lapsed' Then 5
				When bi.ShopperSegment = 'Shopper' Then 6
		   End as ShopperSegmentPriority
		 , bi.IronOfferID
		 , Min(PriorityFlag) as PriorityFlag
	From Warehouse.Selections.ROCShopperSegment_CampaignSetup cs
	Left join Warehouse.Selections.ROCShopperSegment_BriefInput bi
		on cs.ClientServicesRef = bi.ClientServicesRef
	Group by cs.PartnerID
		  ,  cs.ClientServicesRef
		  ,  bi.CycleStart
		  ,  bi.CycleEnd
		  ,  bi.ShopperSegment
		  ,  Case	
		    	When bi.ShopperSegment = 'Welcome' Then 1
		    	When bi.ShopperSegment = 'Birthday' Then 2
		    	When bi.ShopperSegment = 'Homemover' Then 3
		    	When bi.ShopperSegment = 'Acquire' Then 4
		    	When bi.ShopperSegment = 'Lapsed' Then 5
		    	When bi.ShopperSegment = 'Shopper' Then 6
		     End
		  , bi.IronOfferID) a
Order by CycleStart
	   , PartnerID
	   , NewPriorityFlag

*/