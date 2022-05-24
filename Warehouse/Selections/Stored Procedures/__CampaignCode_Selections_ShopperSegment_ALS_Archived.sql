

/****************************************************************************************************
Modified Log:

Change No:	Name:			Date:			Description of change:
1.			Rory Francis	2018-05-02		Warehouse.Staging.ROCShopperSegment_PreSelection_ALSS to 
											Warehouse.Selections.ROCShopperSegment_PreSelection_AL

2.			Rory Francis	2018-05-03		Adding in process to use priority flag to dedupe while
											pulling selections
											
****************************************************************************************************/
/*
Update Date		Updated By		Update
2018-05-02		Rory Francis	Warehouse.Staging.ROCShopperSegment_PreSelection_ALSS to Warehouse.Selections.ROCShopperSegment_PreSelection_AL
2018-05-03		Rory Francis	Adding in process to use priority flag to dedupe while pulling selections
*/

CREATE PROCEDURE [Selections].[__CampaignCode_Selections_ShopperSegment_ALS_Archived] @RunType bit, @EmailDate varchar(30)
AS
BEGIN
	SET NOCOUNT ON

	Declare @Today datetime,
			@time DATETIME,
			@msg VARCHAR(2048),
			@RunID int, 
			@MaxID int,
			@Qry nvarchar(max)
				--,@RunType bit = 1
				--,@EmailDate varchar(30) = '2019-05-09'

	/******************************************************************		
			Get email campaigns for next email send 
	******************************************************************/

	If Object_ID('tempdb..#CampaignsToRun') IS NOT NULL DROP TABLE #CampaignsToRun
	Select *
		 , ROW_NUMBER() OVER (Order by PartnerID, Case When PriorityFlag = 0 Then 99 Else PriorityFlag End asc, ID) [RunID]
	Into #CampaignsToRun
	from Warehouse.Selections.ROCShopperSegment_PreSelection_ALS
	Where EmailDate = @EmailDate
	and SelectionRun = 0
	and ReadyToRun = 1
	Order by RunID
			,PriorityFlag

	/******************************************************************		
	  Find all instances of senior staff on an existing partner offer 
	******************************************************************/

	If @RunType = 1
		Begin

			If Object_ID('tempdb..#ExistingPartnerOfferMemberships') IS NOT NULL DROP TABLE #ExistingPartnerOfferMemberships
			SELECT ctr.PartnerID
				 , iof.ID AS IronOfferID
				 , ctr.EmailDate
				 , ssa.CompositeID
			INTO #ExistingPartnerOfferMemberships
			FROM SLC_REPL..IronOffer iof
			INNER JOIN #CampaignsToRun ctr
				ON iof.PartnerID = ctr.PartnerID
			CROSS JOIN Selections.ROCShopperSegment_SeniorStaffAccounts ssa
			WHERE iof.EndDate > GETDATE()
			AND EXISTS (SELECT 1
						FROM SLC_REPL..IronOfferClub ioc
						WHERE iof.ID = ioc.IronOfferID
						AND ioc.ClubID IN (132, 138))
						
			INSERT INTO Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships (PartnerID
																						  , CompositeID)
			SELECT DISTINCT
				   PartnerID
				 , epom.CompositeID
			FROM #ExistingPartnerOfferMemberships epom
			INNER JOIN SLC_Report..IronOfferMember iom
				ON epom.IronOfferID = iom.IronOfferID
				AND epom.EmailDate BETWEEN iom.StartDate AND iom.EndDate
				AND epom.CompositeID = iom.CompositeID
		End
		
	/******************************************************************		
			Add campaigns to table to allow partner dedupe
	******************************************************************/

	If @RunType = 1
		Begin
			INSERT INTO Selections.CampaignCode_Selections_OutputTables (PreSelection_ALS_ID
																	   , PartnerID
																	   , OutputTableName
																	   , PriorityFlag
																	   , InPartnerDedupe
																	   , RowNumber)
			Select Distinct 
					  ID as PreSelection_ALS_ID
					, PartnerID
					, OutputTableName
					, PriorityFlag
					, 0 as InPartnerDedupe
					, null as RowNumber
			from #CampaignsToRun
			Where OutputTableName not in (Select OutputTableName from Warehouse.Selections.CampaignCode_Selections_OutputTables)
																														
			If Object_ID('tempdb..#CampaignCode_Selections_OutputTables_RowNumberUpdate') IS NOT NULL DROP TABLE #CampaignCode_Selections_OutputTables_RowNumberUpdate
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
			Select PartnerID
				 , StartDate
				 , EndDate
				 , CampaignName
				 , ClientServicesRef
				 , PriorityFlag
				 , OfferID
				 , Throttling
				 , OutputTableName
				 , NotIn_TableName1
				 , NotIn_TableName2
				 , MustBeIn_TableName1
				 , MustBeIn_TableName2
				 , Gender
				 , AgeRange
				 , DriveTimeMins
				 , LiveNearAnyStore
				 , SocialClass
				 , SelectedInAnotherCampaign
				 , DeDupeAgainstCampaigns
				 , CustomerBaseOfferDate
			from #CampaignsToRun
			Order by RunID, PriorityFlag
		End

	/******************************************************************		
			Declare and set variables 
	******************************************************************/

	If @RunType = 1
		BEGIN

			Set		@Today = getdate()
			Set		@RunID = 1
			Select  @MaxID = Max(RunID) From #CampaignsToRun

			Declare		@PartnerID CHAR(4),
						@StartDate VARCHAR(10), 
						@EndDate VARCHAR(10),
						@MarketableByEmail CHAR(1),
						@PaymentMethodsAvailable VARCHAR(10),
						@OfferID VARCHAR(40),
						@Throttling varchar(200),
						@ClientServicesRef VARCHAR(10),
						@OutputTableName VARCHAR (100),
						@CampaignName VARCHAR (250),
						@SelectionDate VARCHAR(11),
						@DeDupeAgainstCampaigns VARCHAR(50),
						@NotIn_TableName1 VARCHAR(100),
						@NotIn_TableName2 VARCHAR(100),
						@NotIn_TableName3 VARCHAR(100),
						@NotIn_TableName4 VARCHAR(100),
						@MustBeIn_TableName1  VARCHAR(100),
						@MustBeIn_TableName2  VARCHAR(100),
						@MustBeIn_TableName3  VARCHAR(100),
						@MustBeIn_TableName4  VARCHAR(100),
						@Gender CHAR(1),
						@AgeRange VARCHAR(7),
						@CampaignID_Include CHAR(3),
						@CampaignID_Exclude CHAR(3),
						@DriveTimeMins CHAR(3),
						@LiveNearAnyStore BIT,
						@OutletSector CHAR(6), 
						@SocialClass VARCHAR(5),
						@SelectedInAnotherCampaign VARCHAR(200),
						@CampaignTypeID CHAR(1),
						@CustomerBaseOfferDate varchar(10),
						@RandomThrottle CHAR(1),
						@PriorityFlag INT,
						@OutputTableNamePartnerDedupe VARCHAR (100),
						@sProcPreSelection nvarchar(150),
						@AlternatePartnerOutputTable varchar(150),
						@PreviouslyRanPartnerID CHAR(4) = ''


			/******************************************************************		
					Forcing senior staff into all offers 2 / 2
			******************************************************************/

				--	Fetch top offer per partner
				IF OBJECT_ID ('tempdb..##TopPartnerOffer') IS NOT NULL DROP TABLE ##TopPartnerOffer
				Select PartnerID
					 , IronOfferID
				     , IronOfferName
				     , TopCashBackRate
				Into ##TopPartnerOffer
				From (
					Select PartnerID
						 , IronOfferID
						 , IronOfferName
						 , TopCashBackRate
						 , OfferPriority
						 , DENSE_RANK() Over (Partition by PartnerID Order by TopCashBackRate desc, OfferPriority, IronOfferID) as OfferRank	
					From (
						Select Distinct
							   iofr.PartnerID
							 , iofr.ID AS IronOfferID
							 , iofr.Name AS IronOfferName
							 , COALESCE(iof.TopCashBackRate, 0) AS TopCashBackRate
							 , Case 
									When iofr.Name like '%Acquire%' then 1
									When iofr.Name like '%Lapsed%' then 1
									When iofr.Name like '%Shopper%' then 1
									When iofr.Name like '%Universal%' then 2 
									When iofr.Name like '%Launch%' then 2 
									When iofr.Name like '%AllSegments%' then 3
									When iofr.Name like '%Welcome%' then 4
									When iofr.Name like '%Birthda%' then 5
									When iofr.Name like '%Homemove%' then 5
									When iofr.Name like '%Joiner%' then 6
									When iofr.Name like '%Core%' then 7
									When iofr.Name like '%Base%' then 7
								End as OfferPriority
						From SLC_REPL..IronOffer iofr
						INNER JOIN SLC_REPL..IronOfferClub ioc
							ON iofr.ID = ioc.IronOfferID
							AND ioc.ClubID IN (132, 138)
						LEFT JOIN Warehouse.Relational.IronOffer iof
							ON iofr.ID = iof.IronOfferID
						Inner join #CampaignsToRun ctr
							on iofr.PartnerID = ctr.PartnerID
						Where	iofr.StartDate <= Convert(Date,@EmailDate)
						And		iofr.EndDate   >=  DATEADD(DAY,13,Convert(Date,@EmailDate))) a ) a
				Where OfferRank = 1

			/******************************************************************		
					Begin loop 
			******************************************************************/
			
			While @RunID <= @MaxID 
				Begin

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
								 , @RandomThrottle = RandomThrottle
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
									Set @Qry = (Select Distinct PartnerID From Warehouse.Selections.CampaignCode_Selections_PartnerDedupe)
									Truncate Table Warehouse.Selections.CampaignCode_Selections_PartnerDedupe
									Update Warehouse.Selections.CampaignCode_Selections_OutputTables
									Set InPartnerDedupe = 0
									Print 'Partner with ID ' + @Qry + ' has had its entries removed from the Selections.CampaignCode_Selections_PartnerDedupe table'
								End --	@PartnerID <> (Select Distinct PartnerID From Warehouse.Selections.CampaignCode_Selections_PartnerDedupe)

					/******************************************************************		
						   Fetch all selections for the same partner with a
						   lower priority not existing in the dedupe table
					******************************************************************/

							If Object_ID('tempdb..#CampaignCode_Selections_OutputTables') IS NOT NULL DROP TABLE #CampaignCode_Selections_OutputTables
							Select OutputTableName
								 , RowNumber
							Into #CampaignCode_Selections_OutputTables
							From Warehouse.Selections.CampaignCode_Selections_OutputTables
							Where PartnerID = @PartnerID
							And PriorityFlag < @PriorityFlag
							And InPartnerDedupe = 0

					/******************************************************************		
						   Loop through fetched selections for the same partner 
						   with a lower priority not existing in the dedupe table,
						   adding them to the dedupe table
					******************************************************************/

							Declare @TableLoop INT
								  , @MaxTableLoop INT

							SELECT @TableLoop = MIN(RowNumber)
								 , @MaxTableLoop = MAX(RowNumber)
							From #CampaignCode_Selections_OutputTables

							While @TableLoop <= @MaxTableLoop
								Begin
									Set @OutputTableNamePartnerDedupe = (Select Distinct OutputTableName
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

									Set @TableLoop = (Select MIN(RowNumber) From #CampaignCode_Selections_OutputTables Where RowNumber > @TableLoop)
								End	--	@TableLoop <= @MaxTableLoop
				
							/******************************************************************		
									Exec ShopperSegment selections 
							******************************************************************/
	
							Exec Warehouse.Selections.CampaignCode_AutoGeneration_ROC_SS_V1_9_ALS_Loop
										@PartnerID 						 ,
										@StartDate  					 ,
										@EndDate 						 ,
										@MarketableByEmail 				 ,
										@PaymentMethodsAvailable 		 ,
										@OfferID 						 ,
										@Throttling 					 ,
										@ClientServicesRef 				 ,
										@OutputTableName  				 ,
										@CampaignName 					 ,
										@SelectionDate 					 ,
										@DeDupeAgainstCampaigns 		 ,
										@NotIn_TableName1 				 ,
										@NotIn_TableName2 				 ,
										@NotIn_TableName3 				 ,
										@NotIn_TableName4 				 ,
										@MustBeIn_TableName1 			 ,
										@MustBeIn_TableName2			 ,
										@MustBeIn_TableName3			 ,
										@MustBeIn_TableName4			 ,
										@Gender 						 ,
										@AgeRange 						 ,
										@CampaignID_Include 			 ,
										@CampaignID_Exclude 			 ,
										@DriveTimeMins 					 ,
										@LiveNearAnyStore 				 ,
										@OutletSector 					 ,
										@SocialClass 					 ,
										@SelectedInAnotherCampaign 		 ,
										@CampaignTypeID 				 ,
										@CustomerBaseOfferDate 			 ,
										@RandomThrottle		 			 


--IF OBJECT_ID('Warehouse.Selections.MOR019_Selection_Script_1') IS NOT NULL DELETE FROM Warehouse.Selections.MOR019_Selection_Script_1 WHERE OfferID = 16608

--DECLARE @CG_Query VARCHAR(MAX)
--	  , @ControlGroupPercentage INT = 10
--	  , @TableName_Destination VARCHAR(250) = 'Warehouse.InsightArchive.Morrisons_ControlGroup_InProgram_20190314'

--DECLARE @ControlGroupNTiles INT = (SELECT 100 / @ControlGroupPercentage)

--SET @CG_Query = '

----CREATE TABLE ' + @TableName_Destination + ' (ID INT IDENTITY, ClientServicesRef VARCHAR(25), Segment VARCHAR(25), FanID BIGINT)
--INSERT INTO ' + @TableName_Destination + '
--SELECT ClientServicesRef
--	 , Segment
--	 , FanID
--FROM (
--SELECT CASE
--			WHEN ShopperSegmentTypeID IS NULL THEN ''Welcome''
--			WHEN ShopperSegmentTypeID = 7 THEN ''Acquire''
--			WHEN ShopperSegmentTypeID = 8 THEN ''Lapsed''
--			WHEN ShopperSegmentTypeID = 9 THEN ''Shopper''
--			ELSE ''Unknown''
--	   END AS Segment
--	 , NTILE(' + CONVERT(VARCHAR(5), @ControlGroupNTiles) + ') OVER (PARTITION BY ShopperSegmentTypeID ORDER BY NEWID()) AS SegmentNtile
--	 , FanID
--	 , ClientServicesRef
--FROM ' + @OutputTableName + ') sl
--WHERE SegmentNtile = 1

--DELETE otn
--FROM ' + @OutputTableName + ' otn
--INNER JOIN ' + @TableName_Destination + ' tnd
--	ON otn.FanID = tnd.FanID'

--EXEC (@CG_Query)





							/******************************************************************		
									Verify that the offer IDs listed are correct
							******************************************************************/

							--	Fetch PartnerID related to @OutputTableName
							IF OBJECT_ID ('tempdb..##OutputTablePartner') IS NOT NULL DROP TABLE ##OutputTablePartner
							Set @Qry = '
							Select SUM(PartnerID) as PartnerID
							Into ##OutputTablePartner
							From (
								Select Distinct iof.PartnerID
								From '+ @OutputTableName +' ot
								Inner join SLC_REPL..IronOffer iof
									on ot.OfferID = iof.ID) dp'
							Exec (@Qry)
					
							--	Check @PartnerID matches to PartnerIDs related to @OutputTableName offers
							Declare @Proceed as INT = 1
							If (Select Sum(Distinct Convert(INT,PartnerID)) From ##OutputTablePartner) <> @PartnerID
								Begin
									Set @Qry = '
									DROP TABLE '+ @OutputTableName + '

									Select ''' +  @OutputTableName + ' has a conflict between its @PartnerID and the partner ID associated with the Offer IDs found in @OfferID, please check the below entry in ROCShopperSegment_PreSelection_ALS'' as [Output Table With Errors]

									select *
									From Warehouse.Selections.ROCShopperSegment_PreSelection_ALS
									Where OutputTableName = ''' + @OutputTableName + '''
									And EmailDate = ''' + @EmailDate + '''

									Select ''The below table shows campaigns that have exceuted successfully and the respective selection counts'' as [Campaigns Executed Successfully]

									Select *
									from Warehouse.Selections.ROCShopperSegment_SelectionCounts
									Where EmailDate = ''' + @EmailDate + '''
									Order by RunDateTime, EmailDate, OutputTableName, IronOfferID'

									Exec (@Qry)
		
									Set @Proceed = 0
								End	--	(Select PartnerID From ##OutputTablePartner) <> @PartnerID
					
							IF OBJECT_ID ('tempdb..##OutputTablePartner') IS NOT NULL DROP TABLE ##OutputTablePartner

							If @Proceed = 0
								Begin
									Return
								End

							/******************************************************************		
									Forcing senior staff into all offers 2 / 2
							******************************************************************/

							--If (Select Count(*) From ##TopPartnerOffer) = 1
							--	Begin 
								--	Remove any existing selections of senior staff from @OutputTableName
								Set @Qry = '
								Delete ot
								From '+ @OutputTableName +' ot
								Inner join Warehouse.Selections.ROCShopperSegment_SeniorStaffAccounts ssa
									on ot.CompositeID = ssa.CompositeID'
								Exec (@Qry)

								--	Exclude senior staff members are currently assigned to a @PartnerIDs offer in IronOfferMember
								IF OBJECT_ID ('tempdb..##ROCShopperSegment_SeniorStaffAccounts') IS NOT NULL DROP TABLE ##ROCShopperSegment_SeniorStaffAccounts
								Select *
								Into ##ROCShopperSegment_SeniorStaffAccounts
								From Warehouse.Selections.ROCShopperSegment_SeniorStaffAccounts
								Where CompositeID not in (	Select CompositeID
															From Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships
															Where PartnerID = @PartnerID)

								--	Insert senior staff member to @OutputTableName if top offer is included
								Set @Qry = '
								Insert into ' + @OutputTableName + ' (FanID
																	 ,CompositeID
																	 ,ShopperSegmentTypeID
																	 ,SOWCategory
																	 ,PartnerID
																	 ,PartnerName
																	 ,OfferID
																	 ,ClientServicesRef
																	 ,StartDate
																	 ,EndDate
																	 ,[Comm Type]
																	 ,TriggerBatch
																	 ,Grp)
								Select Distinct
										  ssa.FanID
										, ssa.CompositeID
										, ot.ShopperSegmentTypeID
										, ot.SOWCategory
										, ot.PartnerID
										, ot.PartnerName
										, ot.OfferID
										, ot.ClientServicesRef
										, ot.StartDate
										, ot.EndDate
										, ot.[Comm Type]
										, ot.TriggerBatch
										, ot.Grp
								From ' + @OutputTableName + ' ot
								Inner join ##TopPartnerOffer tpo
									on ot.OfferID = tpo.IronOfferID
								Cross join ##ROCShopperSegment_SeniorStaffAccounts ssa
								Where ssa.CompositeID is not null'
								Exec (@Qry)

								Drop table ##ROCShopperSegment_SeniorStaffAccounts
							--End
							
							--If (Select Count(*)
							--    From ##TopPartnerOffer
							--	Where PartnerID = @PartnerID) <> 1
							--	Begin 
							--		Set @Qry =  'Partner with ID ' + @PartnerID + ' has not assigned Senior staff to any offer memberships'
							--		Print @Qry
							--	End
							
					/******************************************************************		
							Insert counts into Counts table 
					******************************************************************/
			
							Set @Qry = '
							Insert Into Warehouse.Selections.ROCShopperSegment_SelectionCounts (EmailDate
																							   ,OutputTableName
																							   ,IronOfferID
																							   ,CountSelected
																							   ,RunDateTime
																							   ,NewCampaign
																							   ,ClientServicesRef)
							Select cast('''+@EmailDate+''' as date) EmailDate
								 , '''+@OutputTableName+''' OutputTableName
								 , x.OfferID as OfferID
								 , x.NoOfCustomers as CountSelected
								 , getdate() as RunDateTime
								 , als.NewCampaign
								 , '''+@ClientServicesRef+''' ClientServicesRef
							from (
								Select OfferID
									 , count(*) NoOfCustomers
								from '+ @OutputTableName +'
					 			Group by OfferID) x
							Inner Join #CampaignsToRun c
								on c.RunID = '+ Cast(@RunID as varchar(4)) +'
							Inner join Warehouse.Selections.ROCShopperSegment_PreSelection_ALS als
								on c.ID = als.ID'					

							Exec (@Qry)

					/******************************************************************		
							Update PreSelection table to show selection has run 
					******************************************************************/
						
							Update a
							Set SelectionRun = 1
							From #CampaignsToRun b
							Inner Join Warehouse.Selections.ROCShopperSegment_PreSelection_ALS a
							On a.ID = b.ID
							Where @RunID = b.RunID

							Set @PreviouslyRanPartnerID = @PartnerID

					/******************************************************************		
							Duplicate for alternate partner record 
					******************************************************************/

							If @PartnerID in (4319,4715,4263)
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
											, iofp.ID as PrimaryIronOfferID
											, iofp.Name as PrimaryIronOfferName
											, iofs.ID as SecondaryIronOfferID
											, iofs.Name as SecondaryIronOfferName
									Into #SecondaryPartnerOffers
									From #PrimaryPartnerOffers pps
									Inner join SLC_REPL..IronOffer iofp
										on pps.OfferID = iofp.ID
									INNER JOIN SLC_REPL..IronOfferClub ioc
										ON iofp.ID = ioc.IronOfferID
										AND ioc.ClubID IN (132, 138)
									Inner join Warehouse.APW.PartnerAlternate pa
										on	pps.PartnerID = pa.AlternatePartnerID
										and	pa.PartnerID in (Select PartnerID From Warehouse.Relational.Partner)
									Inner join Warehouse.Relational.Partner p
										on pa.PartnerID = p.PartnerID
									Left join SLC_REPL..IronOffer iofs
										on	pa.PartnerID = iofs.PartnerID
										and	iofp.StartDate = iofs.StartDate
										and	iofp.EndDate = iofs.EndDate
										and	iofp.Name = iofs.Name

									IF OBJECT_ID (''' + @AlternatePartnerOutputTable + ''') IS NOT NULL DROP TABLE ' + @AlternatePartnerOutputTable + '
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
										  , pps.[Comm Type]
										  , pps.TriggerBatch
										  , pps.Grp
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
			
							SELECT @msg = @OutputTableName + ' completed'
							EXEC Staging.oo_TimerMessage @msg, @time OUTPUT
		
						End	--	If (Select Count(*) From #CampaignsToRun where RunID = @RunID) > 0
						
					Set @RunID = @RunID + 1

				End	--	While @RunID <= @MaxID 
		
			/******************************************************************		
					Display all counts for all selections run with email date 
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

			Drop table ##TopPartnerOffer

		End	--	If @RunType = 1

	SET NOCOUNT OFF

End	--	ALTER PROCEDURE [Selections].[CampaignCode_Selections_ShopperSegment_ALS] 