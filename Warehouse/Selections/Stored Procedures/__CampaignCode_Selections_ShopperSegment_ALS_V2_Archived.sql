

/****************************************************************************************************
Modified Log:

Change No:	Name:			Date:			Description of change:
1.			Rory Francis	2018-05-02		Warehouse.Staging.ROCShopperSegment_PreSelection_ALSS to 
											Warehouse.Selections.ROCShopperSegment_PreSelection_AL

2.			Rory Francis	2018-05-03		Adding in process to use priority flag to dedupe while
											pulling Selections
											
****************************************************************************************************/
/*
Update Date		Updated By		Update
2018-05-02		Rory Francis	Warehouse.Staging.ROCShopperSegment_PreSelection_ALSS to Warehouse.Selections.ROCShopperSegment_PreSelection_AL
2018-05-03		Rory Francis	Adding in process to use priority flag to dedupe while pulling Selections
*/

CREATE PROCEDURE [Selections].[__CampaignCode_Selections_ShopperSegment_ALS_V2_Archived] @RunType Bit
																		   , @EmailDate VarChar(30)
																		   , @NewCampaign Bit
AS
Begin
	SET NOCOUNT ON

	Declare @Today DateTime
		  , @Time DateTime
		  , @msg VarChar(2048)
		  , @ExecStartTime DateTime
		  , @ExecTimeMsg VarChar(Max)
		  , @RunID Int
		  , @MaxID Int
		  , @Qry nVarChar(max)
		----		, @RunType Bit = 1,
		--		, @EmailDate VarChar(30) = '2018-08-02'
		----		, @NewCampaign Bit = 1
		--		, @PartnerID VarChar(30) = '4263'
		--		, @EndDate VarChar(30) = '2018-08-15'

	/******************************************************************		
			Get email campaigns for next email send 
	******************************************************************/

	If Object_ID('tempdb..#CampaignsToRun') Is Not Null Drop Table #CampaignsToRun
	Select *
		 , ROW_NUMBER() OVER (Order by PartnerID, PriorityFlag, ID) [RunID]
	Into #CampaignsToRun
	From Warehouse.Selections.ROCShopperSegment_PreSelection_ALS
	Where EmailDate = @EmailDate
	And SelectionRun = 0
	And ReadyToRun = 1
	And NewCampaign = @NewCampaign
	Order by RunID
			,PriorityFlag
		
	/******************************************************************		
			Add campaigns to table to allow partner dedupe
	******************************************************************/
	If @RunType = 1
		Begin
			Insert Into Warehouse.Selections.CampaignCode_Selections_OutputTables (PreSelection_ALS_ID
																				  ,PartnerID
																				  ,OutputTableName
																				  ,PriorityFlag
																				  ,InPartnerDedupe
																				  ,RowNumber)
			Select Distinct 
					  ID as PreSelection_ALS_ID
					, PartnerID
					, OutputTableName
					, PriorityFlag
					, 0 as InPartnerDedupe
					, null as RowNumber
			from #CampaignsToRun
			Where OutputTableName not in (Select OutputTableName from Warehouse.Selections.CampaignCode_Selections_OutputTables)
																														
			If Object_ID('tempdb..#CampaignCode_Selections_OutputTables_RowNumberUpdate') Is Not Null Drop Table #CampaignCode_Selections_OutputTables_RowNumberUpdate
			Select PreSelection_ALS_ID
				 , ROW_NUMBER() Over (Order by PartnerID, PriorityFlag) as RowNumber
			Into #CampaignCode_Selections_OutputTables_RowNumberUpdate
			From Warehouse.Selections.CampaignCode_Selections_OutputTables

			Update ot
			Set ot.RowNumber = ot_temp.RowNumber
			From #CampaignCode_Selections_OutputTables_RowNumberUpdate ot_temp
			Inner join Warehouse.Selections.CampaignCode_Selections_OutputTables ot
				on ot_temp.PreSelection_ALS_ID = ot.PreSelection_ALS_ID
		End

	If @RunType = 1 or @RunType = 0
		Begin
			Select * 
			from #CampaignsToRun
			Order by RunID, PriorityFlag
		End

	/******************************************************************		
			Declare And set variables 
	******************************************************************/

	If @RunType = 1
		Begin

			Set		@Today = GetDate()
			Set		@RunID = 1
			Select  @MaxID = Max(RunID) From #CampaignsToRun

			Declare @PartnerID Char(4)
				  , @StartDate VarChar(10)
				  , @EndDate VarChar(10)
				  , @MarketableByEmail Char(1)
				  , @PaymentMethodsAvailable VarChar(10)
				  , @OfferID VarChar(40)
				  , @Throttling VarChar(200)
				  , @ClientServicesRef VarChar(10)
				  , @OutputTableName VarChar (100)
				  , @CampaignName VarChar (250)
				  , @SelectionDate VarChar(11)
				  , @DeDupeAgainstCampaigns VarChar(50)
				  , @NotIn_TableName1 VarChar(100)
				  , @NotIn_TableName2 VarChar(100)
				  , @NotIn_TableName3 VarChar(100)
				  , @NotIn_TableName4 VarChar(100)
				  , @MustBeIn_TableName1 VarChar(100)
				  , @MustBeIn_TableName2 VarChar(100)
				  , @MustBeIn_TableName3 VarChar(100)
				  , @MustBeIn_TableName4 VarChar(100)
				  , @Gender Char(1)
				  , @AgeRange VarChar(7)
				  , @CampaignID_Include Char(3)
				  , @CampaignID_Exclude Char(3)
				  , @DriveTimeMins Char(3)
				  , @LiveNearAnyStore Bit
				  , @OutletSector Char(6)
				  , @SocialClass VarChar(5)
				  , @SelectedInAnotherCampaign VarChar(20)
				  , @CampaignTypeID Char(1)
				  , @CustomerBaseOfferDate VarChar(10)
				  , @RAndomThrottle Char(1)
				  , @PriorityFlag Int
				  , @OutputTableNamePartnerDedupe VarChar (100)
				  , @sProcPreSelection nVarChar(150)
				  , @AlternatePartnerOutputTable VarChar(150)
				  , @PreviouslyRanPartnerID Char(4) = ''

			/******************************************************************		
					Begin loop 
			******************************************************************/
			
			While @RunID <= @MaxID 
				Begin

					Set @ExecStartTime = GetDate()

					/******************************************************************		
							Parametrise entries from ROC_ShopperSegments Selections
					******************************************************************/

					If (Select Count(*) From #CampaignsToRun where RunID = @RunID) > 0
						Begin
							Select @PartnerID = PartnerID
								 , @StartDate = StartDate 
								 , @EndDate = EndDate
								 , @MarketableByEmail = MarketableByEmail
								 , @PaymentMethodsAvailable = PaymentMethodsAvailable
								 , @OfferID = OfferID
								 , @Throttling = Throttling
								 , @ClientServicesRef = ClientServicesRef
								 , @OutputTableName = OutputTableName
								 , @CampaignName = CampaignName
								 , @SelectionDate = SelectionDate
								 , @DeDupeAgainstCampaigns = DeDupeAgainstCampaigns
								 , @NotIn_TableName1 = NotIn_TableName1
								 , @NotIn_TableName2 = NotIn_TableName2
								 , @NotIn_TableName3 = NotIn_TableName3
								 , @NotIn_TableName4 = NotIn_TableName4
								 , @MustBeIn_TableName1 = MustBeIn_TableName1
								 , @MustBeIn_TableName2 = MustBeIn_TableName2
								 , @MustBeIn_TableName3 = MustBeIn_TableName3
								 , @MustBeIn_TableName4 = MustBeIn_TableName4
								 , @Gender = Gender
								 , @AgeRange = AgeRange
								 , @CampaignID_Include = CampaignID_Include
								 , @CampaignID_Exclude = CampaignID_Exclude
								 , @DriveTimeMins = DriveTimeMins
								 , @LiveNearAnyStore = LiveNearAnyStore
								 , @OutletSector = OutletSector
								 , @SocialClass = SocialClass
								 , @SelectedInAnotherCampaign = SelectedInAnotherCampaign
								 , @CampaignTypeID = CampaignTypeID
								 , @CustomerBaseOfferDate = CustomerBaseOfferDate
								 , @RAndomThrottle = RAndomThrottle
								 , @PriorityFlag = PriorityFlag
								 , @sProcPreSelection = sProcPreSelection
								 , @AlternatePartnerOutputTable = OutputTableName + '_APR'
							From #CampaignsToRun
							Where @RunID = RunID

					/******************************************************************		
						   If loop runs to new partner then truncate dedupe table
					******************************************************************/

							If @PartnerID <> @PreviouslyRanPartnerID
								Begin

									Truncate Table Warehouse.Selections.CampaignCode_Selections_PartnerDedupe

									Update Warehouse.Selections.CampaignCode_Selections_OutputTables
									Set InPartnerDedupe = 0

									Insert Into Warehouse.Selections.CampaignCode_Selections_PartnerDedupe
									Select PartnerID
										 , CompositeID
									From Warehouse.Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships
									Where PartnerID = @PartnerID

									Print 'CampaignCode_Selections_PartnerDedupe has been truncated and Partner with ID ' + @PartnerID + ' has had its existing Offer Memberships entries inserted'

								End --	@PartnerID <> @PreviouslyRanPartnerID

					/******************************************************************		
						   Fetch all Selections for the same partner with a
						   lower priority not existing in the dedupe table
					******************************************************************/

							If Object_ID('tempdb..#CampaignCode_Selections_OutputTables') Is Not Null Drop Table #CampaignCode_Selections_OutputTables
							Select OutputTableName
								 , RowNumber
							Into #CampaignCode_Selections_OutputTables
							From Warehouse.Selections.CampaignCode_Selections_OutputTables
							Where PartnerID = @PartnerID
							And PriorityFlag < @PriorityFlag
							And InPartnerDedupe = 0

					/******************************************************************		
						   Loop through fetched Selections for the same partner 
						   with a lower priority not existing in the dedupe table,
						   adding them to the dedupe table
					******************************************************************/
							
							If (Select Count(*) From #CampaignCode_Selections_OutputTables) > 0
								Begin 
									Declare @TableLoop Int
										  , @MaxTableLoop Int

									Select @TableLoop = MIN(RowNumber)
										 , @MaxTableLoop = MAX(RowNumber)
									From #CampaignCode_Selections_OutputTables

									While @TableLoop <= @MaxTableLoop
										Begin
											Set @OutputTableNamePartnerDedupe = (Select OutputTableName
																				 From #CampaignCode_Selections_OutputTables
																				 Where RowNumber = @TableLoop)

											Set @Qry = '
											Insert Into Warehouse.Selections.CampaignCode_Selections_PartnerDedupe (PartnerID
																												   ,CompositeID)
											Select PartnerID
												 , CompositeID
											From ' + @OutputTableNamePartnerDedupe + ''
		
											Exec (@Qry)

											Update Warehouse.Selections.CampaignCode_Selections_OutputTables
											Set InPartnerDedupe = 1
											Where RowNumber = @TableLoop

											Print @OutputTableNamePartnerDedupe + ' has been added to the Selections.CampaignCode_Selections_PartnerDedupe table'

											Select @TableLoop = MIN(RowNumber)
											From #CampaignCode_Selections_OutputTables
											Where RowNumber > @TableLoop

										End	--	@TableLoop <= @MaxTableLoop
								End	--	(Select Count(*) From #CampaignCode_Selections_OutputTables) > 0
				
							/******************************************************************		
									Exec ShopperSegment Selections 
							******************************************************************/
	
							Exec Warehouse.Selections.CampaignCode_AutoGeneration_ROC_SS_V2_ALS_Loop @PartnerID 						
																								   , @StartDate  					
																								   , @EndDate 						
																								   , @MarketableByEmail 				
																								   , @PaymentMethodsAvailable 		
																								   , @OfferID 						
																								   , @Throttling 					
																								   , @ClientServicesRef 				
																								   , @OutputTableName  				
																								   , @CampaignName 					
																								   , @SelectionDate 					
																								   , @DeDupeAgainstCampaigns 		
																								   , @NotIn_TableName1 				
																								   , @NotIn_TableName2 				
																								   , @NotIn_TableName3 				
																								   , @NotIn_TableName4 				
																								   , @MustBeIn_TableName1 			
																								   , @MustBeIn_TableName2			
																								   , @MustBeIn_TableName3			
																								   , @MustBeIn_TableName4			
																								   , @Gender 						
																								   , @AgeRange 						
																								   , @CampaignID_Include 			
																								   , @CampaignID_Exclude 			
																								   , @DriveTimeMins 					
																								   , @LiveNearAnyStore 				
																								   , @OutletSector 					
																								   , @SocialClass 					
																								   , @SelectedInAnotherCampaign 		
																								   , @CampaignTypeID 				
																								   , @CustomerBaseOfferDate 			
																								   , @RandomThrottle		 			
																								   , @NewCampaign

							/******************************************************************		
									Verify that the offer IDs listed are correct, stop script if there are errors 
							******************************************************************/

							--	Fetch PartnerID related to @OutputTableName
							If Object_ID ('tempdb..#OutputTablePartner') Is Not Null Drop Table #OutputTablePartner
							Select Count(Distinct ccss.PartnerID) as PartnerCount
							Into #OutputTablePartner
							From Warehouse.Selections.CampaignCode_Selections_Selection ccss
							Inner join Warehouse.Relational.IronOffer iof
								on ccss.OfferID = iof.IronOfferID
					
							--	Check @PartnerID matches to PartnerIDs related to @OutputTableName offers
							Declare @Proceed as Int = 1
							If (Select PartnerCount From #OutputTablePartner) != 1
								Begin
									Set @Qry = '
									Drop Table '+ @OutputTableName + '

									Select ''' +  @OutputTableName + ' has a conflict between its @PartnerID And the partner ID associated with the Offer IDs found in @OfferID, or no customers were added, please check the below entry in ROCShopperSegment_PreSelection_ALS'' as [Output Table With Errors]

									Select *
									From Warehouse.Selections.ROCShopperSegment_PreSelection_ALS
									Where OutputTableName = ''' + @OutputTableName + '''
									And EmailDate = ''' + @EmailDate + '''

									Select ''The below table shows campaigns that have exceuted successfully And the respective Selection counts'' as [Campaigns Executed Successfully]

									Select *
									from Warehouse.Selections.ROCShopperSegment_SelectionCounts
									Where EmailDate = ''' + @EmailDate + '''
									Order by RunDateTime, EmailDate, OutputTableName, IronOfferID'

									Exec (@Qry)
		
									Set @Proceed = 0
								End	--	(Select PartnerID From ##OutputTablePartner) <> @PartnerID

							If @Proceed = 0
								Begin
									Print 'Proceeed = 1, process has stopped'
									Return
								End
							
					/******************************************************************		
							Insert counts Into Counts table 
					******************************************************************/

							Insert Into Warehouse.Selections.ROCShopperSegment_SelectionCounts (EmailDate
																							  , OutputTableName
																							  , IronOfferID
																							  , CountSelected
																							  , RunDateTime
																							  , NewCampaign
																							  , ClientServicesRef)
							Select Convert(Date, @EmailDate) as EmailDate
								 , @OutputTableName as OutputTableName
								 , ccssc.OfferID as OfferID
								 , ccssc.NoOfCustomers as CountSelected
								 , GetDate() as RunDateTime
								 , als.NewCampaign
								 , @ClientServicesRef as ClientServicesRef
							from (
								Select OfferID
									 , Count(*) as NoOfCustomers
								From Warehouse.Selections.CampaignCode_Selections_Selection
					 			Group by OfferID) ccssc
							Inner Join #CampaignsToRun c
								on c.RunID = Convert(VarChar(4), @RunID)
							Inner join Warehouse.Selections.ROCShopperSegment_PreSelection_ALS als
								on c.ID = als.ID

					/******************************************************************		
							Update PreSelection table to show Selection has run 
					******************************************************************/
						
							Update als
							Set SelectionRun = 1
							From #CampaignsToRun ctr
							Inner Join Warehouse.Selections.ROCShopperSegment_PreSelection_ALS als
								On als.ID = ctr.ID
							Where @RunID = ctr.RunID

							Set @PreviouslyRanPartnerID = @PartnerID

					/******************************************************************		
							Duplicate for alternate partner record 
					******************************************************************/

							If @PartnerID in (4319,4715)
								Begin 
									Set @Qry = '
									IF Object_ID(''tempdb..#PrimaryPartnerOffers'') Is Not Null Drop Table #PrimaryPartnerOffers
									Select Distinct
											PartnerID
										  , OfferID
									Into #PrimaryPartnerOffers
									From ' + @OutputTableName + ' pps

									IF Object_ID(''tempdb..#SecondaryPartnerOffers'') Is Not Null Drop Table #SecondaryPartnerOffers
									Select Distinct
											  p.PartnerID as SecondaryPartnerID
											, p.PartnerName as SecondaryPartnerName
											, iofp.IronOfferID as PrimaryIronOfferID
											, iofp.IronOfferName as PrimaryIronOfferName
											, iofs.IronOfferID as SecondaryIronOfferID
											, iofs.IronOfferName as SecondaryIronOfferName
									Into #SecondaryPartnerOffers
									From #PrimaryPartnerOffers pps
									Inner join Warehouse.Relational.IronOffer iofp
										on pps.OfferID = iofp.IronOfferID
									Inner join Warehouse.APW.PartnerAlternate pa
										on	pps.PartnerID = pa.AlternatePartnerID
										And	pa.PartnerID in (Select PartnerID From Warehouse.Relational.Partner)
									Inner join Warehouse.Relational.Partner p
										on pa.PartnerID = p.PartnerID
									Left join Warehouse.Relational.IronOffer iofs
										on	pa.PartnerID = iofs.PartnerID
										And	iofp.StartDate = iofs.StartDate
										And	iofp.EndDate = iofs.EndDate
										And	iofp.IronOfferName = iofs.IronOfferName

									IF OBJECT_ID (''' + @AlternatePartnerOutputTable + ''') Is Not Null Drop Table ' + @AlternatePartnerOutputTable + '
									Select Distinct
											pps.FanID
										  , pps.CompositeID
										  , pps.ShopperSegmentTypeID
										  , pps.SOWCategory
										  , spo.SecondaryPartnerID as PartnerID
										  , spo.SecondaryPartnerName as PartnerName
										  , spo.SecondaryIronOfferID as OfferID
										  , pps.ClientServicesRef
										  , pps.StartDate
										  , pps.EndDate
									Into ' + @AlternatePartnerOutputTable + '
									From ' + @OutputTableName + ' pps
									Inner join #SecondaryPartnerOffers spo
										on pps.OfferID = spo.PrimaryIronOfferID'
									Exec (@Qry)

									Insert Into Warehouse.Selections.NominatedOfferMember_TableNames (TableName)
									Select @AlternatePartnerOutputTable
								End

					/******************************************************************		
							Show completion message for retailer
					******************************************************************/
			
							Set @ExecTimeMsg = Replace(@OutputTableName, 'Warehouse.Selections.', '') + ', campaign ' + Convert(VarChar(3), @RunID) + ' of ' + Convert(VarChar(3), @MaxID) + ' completed	>>>>>  Time Taken: ' + Convert(VarChar(10), DateDiff(second, @ExecStartTime, GetDate()))

							raiserror(@ExecTimeMsg,0,1) with nowait
		
						End	--	If (Select Count(*) From #CampaignsToRun where RunID = @RunID) > 0
						
					Set @RunID = @RunID + 1

				End	--	While @RunID <= @MaxID 
		
			/******************************************************************		
					Display all counts for all Selections run with email date 
			******************************************************************/

			Select *
			from Warehouse.Selections.ROCShopperSegment_SelectionCounts
			Where EmailDate = @EmailDate
			Order by RunDateTime, EmailDate, OutputTableName, IronOfferID
		
			/******************************************************************		
					Table clear down 
			******************************************************************/

			Truncate Table Selections.CampaignCode_Selections_PartnerDedupe

			Update Warehouse.Selections.CampaignCode_Selections_OutputTables
			Set InPartnerDedupe = 0

		End	--	If @RunType = 1

	SET NOCOUNT OFF

End	--	ALTER PROCEDURE [Selections].[CampaignCode_Selections_ShopperSegment_ALS] 