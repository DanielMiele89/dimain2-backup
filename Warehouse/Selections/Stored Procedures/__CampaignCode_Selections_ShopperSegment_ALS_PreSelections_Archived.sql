
/***********************************************************************************************************************
Title: Auto-Generation of all PreSelections table for upcoming campaigns
Author: Rory Francis
Creation Date: 20 July 2018
Purpose: Run through each of the upcoming cmapigns and run their required bespoke code to populate PreSelections tables

------------------------------------------------------------------------------------------------------------------------

Modified Log:

Change No:	Name:			Date:			Description of change:

											
***********************************************************************************************************************/

CREATE Procedure [Selections].[__CampaignCode_Selections_ShopperSegment_ALS_PreSelections_Archived] @RunType Bit
																					  , @EmailDate VarChar(30)

As
	Begin
		Set NoCount On

		Declare @RunID Int
			  , @MaxRunID Int
			  , @PreSelectionsProc Varchar(250)
			  , @PreSelectionTable Varchar(250)
			  , @CreateIndex Varchar(500)
			  , @ExecutionStartTime DateTime
			  , @PreSelectionRowCount Varchar(50)
			  , @ExecutionMessage Varchar(Max)
			  --, @RunType Bit = 1
			  --, @EmailDate VarChar(30) = '2019-05-23'

/***********************************************************************************************************************
		Fetch campaigns requiring preselection to be run
***********************************************************************************************************************/

		/***************************************************************************************************************
				Place all camapigns requiring preselection into holding table, add entry for Europcar's card type split
		***************************************************************************************************************/

			If Object_ID('tempdb..#PreSelectionsToRun') IS NOT NULL DROP TABLE #PreSelectionsToRun
			Select 1 as RunID
					, 4514 as PartnerID
					, 'EC' as ClientServicesRef
					, Null as NotIn_TableName1
					, Null as MustBeIn_TableName1
					, 'Warehouse.Selections.EC_PaymentMethod_PreSelection' as sProcPreSelection
					, Convert(BigInt, Null) as sProcPreSelectionCounts
			Into #PreSelectionsToRun

			Union

			Select Distinct
					Dense_Rank() OVER (Order by PartnerID, PriorityFlag) + 1 as RunID
					, PartnerID
					, ClientServicesRef
					, Replace(Replace(NotIn_TableName1,'Warehouse.Selections.',''),'Warehouse.','') as NotIn_TableName1
					, MustBeIn_TableName1
					, sProcPreSelection
					, Convert(BigInt, Null) as sProcPreSelectionCounts
			From Warehouse.Selections.ROCShopperSegment_PreSelection_ALS
			Where EmailDate = @EmailDate
			And ReadyToRun = 1
			And sProcPreSelection != ''
			Order by RunID

		/***************************************************************************************************************
				If there are no eligible Europcar campaigns, remove this entry
		***************************************************************************************************************/

			If (Select Count(*)
				From Warehouse.Selections.ROCShopperSegment_PreSelection_ALS
				Where EmailDate = @EmailDate
				And ReadyToRun = 1
				And PartnerID = 4514) = 0

				Begin
					Delete
					From #PreSelectionsToRun
					Where RunID = 1

					Update #PreSelectionsToRun
					Set RunID = RunID - 1
				End

		/***************************************************************************************************************
				Remove duplicate entries
		***************************************************************************************************************/
			
			If Object_ID('tempdb..#Dupe_Campaigns') IS NOT NULL DROP TABLE #Dupe_Campaigns
			SELECT PartnerID
				 , ClientServicesRef
				 , NotIn_TableName1
				 , MustBeIn_TableName1
				 , sProcPreSelection
				 , sProcPreSelectionCounts
				 , MIN(RunID) AS MinRunID
			INTO #Dupe_Campaigns
			FROM #PreSelectionsToRun
			GROUP BY PartnerID
				   , ClientServicesRef
				   , NotIn_TableName1
				   , MustBeIn_TableName1
				   , sProcPreSelection
				   , sProcPreSelectionCounts
			HAVING COUNT(*) > 1

			DELETE ps
			FROM #PreSelectionsToRun ps
			INNER JOIN #Dupe_Campaigns dc
				ON ps.PartnerID = dc.PartnerID
				AND ps.ClientServicesRef = dc.ClientServicesRef
				AND ps.RunID != dc.MinRunID

		/***************************************************************************************************************
				List PreSelections to be ran
		***************************************************************************************************************/

			Select 'PreSelections to run through' as [Result set displayed below]
			Select *
			From #PreSelectionsToRun
			Order by RunID

/***********************************************************************************************************************
		Fetch campaigns requiring customers selected from the previous cycle of the same campaign
***********************************************************************************************************************/

		/***************************************************************************************************************
				Place all camapigns requiring base offer date into holding table
		***************************************************************************************************************/

			--If Object_ID('tempdb..#BaseOfferDateOffersToRun') IS NOT NULL DROP TABLE #BaseOfferDateOffersToRun
			--Select Distinct
			--		PartnerID
			--	  , ClientServicesRef
			--	  , CustomerBaseOfferDate
			--Into #BaseOfferDateOffersToRun
			--From Warehouse.Selections.ROCShopperSegment_PreSelection_ALS
			--Where CustomerBaseOfferDate Is not null
			--And EmailDate = @EmailDate
			--And ReadyToRun = 1

		/***************************************************************************************************************
				List campaigns requiring base offer date
		***************************************************************************************************************/
		
			--Select 'Base Offer Dates to run through' as [Result set displayed below]
			--Select *
			--From #BaseOfferDateOffersToRun
			--Order by ClientServicesRef

/***********************************************************************************************************************
		Fetch campaigns requiring customers selected from another campaign
***********************************************************************************************************************/

		/***************************************************************************************************************
				Place all camapigns requiring selection from another campaign into holding table
		***************************************************************************************************************/

			--If object_ID('tempdb..#SelectedInAnotherCampaignToRun') Is Not Null Drop Table #SelectedInAnotherCampaignToRun
			--Select Distinct
			--		PartnerID
			--	  , ClientServicesRef
			--	  , Upper(SelectedInAnotherCampaign) + ',' as SelectedInAnotherCampaign
			--Into #SelectedInAnotherCampaignToRun
			--From Warehouse.Selections.ROCShopperSegment_PreSelection_ALS
			--Where SelectedInAnotherCampaign != ''
			--And EmailDate = @EmailDate
			--And ReadyToRun = 1

		/***************************************************************************************************************
				List campaigns requiring selection from another campaign
		***************************************************************************************************************/
		
			--Select 'Selected in another campaign to run through' as [Result set displayed below]
			--Select *
			--From #SelectedInAnotherCampaignToRun
			--Order by ClientServicesRef

/***********************************************************************************************************************
		If @RunType = 1 then all tables will be populated for upcoming campaign selection
***********************************************************************************************************************/

	If @RunType = 1
		Begin

		/***************************************************************************************************************
				Loop through each of the campaigns requiring preselection and run the bespoke code
		***************************************************************************************************************/

			Select @RunID = 1
				 , @MaxRunID = Max(RunID)
			From #PreSelectionsToRun
			
			While @RunID <= @MaxRunID 
				Begin

					Select @PreSelectionsProc = sProcPreSelection
					From #PreSelectionsToRun
					Where RunID = @RunID
						
					Set @ExecutionStartTime = GETDATE()

					Exec @PreSelectionsProc

					Set @PreSelectionRowCount = (Select @@ROWCOUNT)

					Update #PreSelectionsToRun
					Set sProcPreSelectionCounts = @PreSelectionRowCount
					Where RunID = @RunID

					Set @ExecutionMessage = Replace(@PreSelectionsProc,'Warehouse.Selections.','') + ' inserted ' + @PreSelectionRowCount + ' rows in ' + Convert(VarChar(8),Convert(Time, GETDATE() - @ExecutionStartTime))

					Select @CreateIndex = 'Create Index CIX_' + Replace(Replace(Replace(MustBeIn_TableName1,'Warehouse.Selections.',''),'.',''),'_','') + '_Fan on ' + MustBeIn_TableName1 + ' (FanID)'
					From #PreSelectionsToRun
					Where RunID = @RunID

					If @RunID = 1
						Begin
							Raiserror (@ExecutionMessage, 0, 1) With NoWait
						End

					If @RunID > 1
						Begin
							Begin Try  
								Set @ExecutionStartTime = GETDATE()
								Exec (@CreateIndex)
								Set @ExecutionMessage = @ExecutionMessage + ', FanID Index created in '  + Convert(VarChar(8),Convert(Time, GETDATE() - @ExecutionStartTime))

								Raiserror (@ExecutionMessage, 0, 1) With NoWait

							End Try  
							Begin Catch  
								Set @ExecutionMessage = @ExecutionMessage + ', no Index created'
								If @RunID > 1
									Begin
										Set @ExecutionMessage = @ExecutionMessage + ', the attempt was made with the following code:' + CHAR(13) + @CreateIndex
									End

								Raiserror (@ExecutionMessage, 0, 1) With NoWait

							End Catch
						End

					Select @RunID = Min(RunID)
					From #PreSelectionsToRun
					Where RunID > @RunID

				End	--	@RunID <= @MaxRunID

		/***************************************************************************************************************
				Add all existing memberships that overlap with upcoming selection to holding table to dedupe against
		***************************************************************************************************************/
							
			--If Object_ID('tempdb..#CampaignsToRun') Is Not Null Drop Table #CampaignsToRun
			--Select Distinct
			--			als.PartnerID
			--		  , pa.PartnerName
			--		  , EmailDate
			--Into #CampaignsToRun
			--From Warehouse.Selections.ROCShopperSegment_PreSelection_ALS als
			--Inner join Warehouse.Relational.Partner pa
			--	on als.PartnerID = pa.PartnerID
			--Where EmailDate = @EmailDate
			--And ReadyToRun = 1

			--Truncate table Warehouse.Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships

			--Insert Into Warehouse.Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships ( PartnerID
			--																						 , CompositeID)
			--Select Distinct
			--			ctr.PartnerID
			--		  , iom.CompositeID
			--From #CampaignsToRun ctr
			--Inner join Warehouse.Relational.IronOffer iof
			--	on ctr.PartnerID = iof.PartnerID
			--Inner join Warehouse.Relational.IronOfferMember iom
			--	on iof.IronOfferID = iom.IronOfferID
			--Where iom.EndDate > ctr.EmailDate
			--And Not Exists (Select 1
			--				From Warehouse.Relational.PartnerOffers_Base pob
			--				Where iof.IronOfferID = pob.OfferID)
			--Order by ctr.PartnerID
			--	   , iom.CompositeID
			
			--Alter Index CIX_ExistingPartnerOfferMemberships_PartnerCompositeID ON Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships Rebuild

				/*******************************************************************************************************
						Seperate existing senior staff memberships that overlap with upcoming selection
				*******************************************************************************************************/

					--Truncate table Warehouse.Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships_SeniorStaff

					--Insert Into Warehouse.Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships_SeniorStaff ( PartnerID
					--																									 , CompositeID)
					--Select Distinct 
					--			eom.PartnerID
					--		  , eom.CompositeID
					--From Warehouse.Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships eom
					--Inner join Warehouse.Selections.ROCShopperSegment_SeniorStaffAccounts ssa
					--	on eom.CompositeID = ssa.CompositeID

		/***************************************************************************************************************
				Create Base Offer Date Offers table
		***************************************************************************************************************/
							
			--If Object_ID('tempdb..#BaseOfferDateOffers') Is Not Null Drop Table #BaseOfferDateOffers
			--Select Distinct
			--			bodotr.ClientServicesRef
			--		  , CustomerBaseOfferDate
			--		  , IronOfferID
			--Into #BaseOfferDateOffers
			--From #BaseOfferDateOffersToRun bodotr
			--Inner join Warehouse.Relational.IronOffer_Campaign_HTM htm
			--	On bodotr.ClientServicesRef = htm.ClientServicesRef

			--Create Clustered Index CIX_BaseOfferDateOffers_DateCSRIronOfferID on #BaseOfferDateOffers (CustomerBaseOfferDate, IronOfferID, ClientServicesRef)

			--Truncate Table Warehouse.Selections.CampaignCode_Selections_BaseOfferDateMembers
			--Insert Into Warehouse.Selections.CampaignCode_Selections_BaseOfferDateMembers
			--Select ClientServicesRef
			--	 , CustomerBaseOfferDate
			--	 , CompositeID
			--From #BaseOfferDateOffers bodo
			--Inner join Warehouse.Relational.IronOfferMember iom
			--	On bodo.IronOfferID = iom.IronOfferID
			--	And bodo.CustomerBaseOfferDate = iom.StartDate
				
			--Alter Index CIX_BaseOfferDateMembers_CSRDateCompositeID On Warehouse.Selections.CampaignCode_Selections_BaseOfferDateMembers Rebuild

		/***************************************************************************************************************
				Create SelectedInAnotherCampaign table
		***************************************************************************************************************/

			--If object_ID('tempdb..#SelectedInAnotherCampaignTemp') Is Not Null Drop Table #SelectedInAnotherCampaignTemp
			--Select ClientServicesRef
			--	 , SelectedInAnotherCampaign
			--	 , Row_Number() Over (Order by ClientServicesRef, SelectedInAnotherCampaign) as LoopNumber
			--Into #SelectedInAnotherCampaignTemp
			--From #SelectedInAnotherCampaignToRun siactr

			--Declare @Limit Int
			--	  , @ClientServicesRefLoop VarChar(10)
			--	  , @SelectedInAnotherCampaignLoopNum Int = 1
			--	  , @SelectedInAnotherCampaignLoopNumMax Int = (Select Max(LoopNumber) From #SelectedInAnotherCampaignTemp)
			--	  , @SelectedInAnotherCampaignLoopValue VarChar(100)

			--If object_ID('tempdb..#SelectedCampaigns') Is Not Null Drop Table #SelectedCampaigns
			--Create Table #SelectedCampaigns (ClientServicesRef VarChar(10)
			--							   , SelectedInAnotherCampaign VarChar(10))

			--While @SelectedInAnotherCampaignLoopNum <= @SelectedInAnotherCampaignLoopNumMax
			--	Begin
			--		Select @ClientServicesRefLoop = ClientServicesRef
			--			 , @SelectedInAnotherCampaignLoopValue = SelectedInAnotherCampaign
			--		From #SelectedInAnotherCampaignTemp
			--		Where LoopNumber = @SelectedInAnotherCampaignLoopNum

			--		While CharIndex(',', @SelectedInAnotherCampaignLoopValue, 0) > 0
			--			Begin
			--				Set @Limit = CharIndex(',', @SelectedInAnotherCampaignLoopValue, 0)
				
			--				Insert Into #SelectedCampaigns (ClientServicesRef
			--											  , SelectedInAnotherCampaign)
			--				Select @ClientServicesRefLoop
			--					 , RTRIM(LTRIM(SUBSTRING(@SelectedInAnotherCampaignLoopValue, 0, @Limit)))

			--				Set @SelectedInAnotherCampaignLoopValue = STUFF(@SelectedInAnotherCampaignLoopValue, 1, @Limit, '') 
			--			End
		
			--		Set @SelectedInAnotherCampaignLoopNum = @SelectedInAnotherCampaignLoopNum + 1
			--	End

			--	If object_ID('tempdb..#SelectedInAnotherCampaign') Is Not Null Drop Table #SelectedInAnotherCampaign
			--	Select Distinct
			--			sc.ClientServicesRef
			--		  , SelectedInAnotherCampaign
			--		  , IronOfferID
			--	Into #SelectedInAnotherCampaign
			--	From #SelectedCampaigns sc
			--	Inner join Warehouse.Relational.IronOffer_Campaign_HTM htm
			--		on sc.SelectedInAnotherCampaign = htm.ClientServicesRef		 
 
			--	Create Clustered Index CIX_SelectedInAnotherCampaign_ClientServicesRefOfferID on #SelectedInAnotherCampaign (IronOfferID)

			--	Truncate Table Warehouse.Selections.CampaignCode_Selections_SelectedInAnotherCampaignMembers
			--	Insert Into Warehouse.Selections.CampaignCode_Selections_SelectedInAnotherCampaignMembers
			--	Select Distinct 
			--				ClientServicesRef
			--			  , SelectedInAnotherCampaign
			--			  , CompositeID
			--	From #SelectedInAnotherCampaign siac
			--	Inner join Warehouse.Relational.IronOfferMember iom
			--		on siac.IronOfferID = iom.IronOfferID

			--	Alter Index CIX_SelectedInAnotherCampaignMembers_CSROtherCampaignCompositeID On Warehouse.Selections.CampaignCode_Selections_SelectedInAnotherCampaignMembers Rebuild

		/***************************************************************************************************************
				Fetch the result of all of the table populations
		***************************************************************************************************************/

				Select 'PreSelections ran'
				Select *
				From #PreSelectionsToRun
				Order by RunID

				--Select 'Existing offer memberships counts'
				--Select ctr.PartnerID
				--	 , ctr.PartnerName
				--	 , Count(epom.CompositeID) as Customers
				--From #CampaignsToRun ctr
				--Left join Warehouse.Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships epom
				--	on ctr.PartnerID = epom.PartnerID
				--Group by ctr.PartnerID
				--	   , ctr.PartnerName

				--Select 'Base Offer Date cusotmer counts'
				--Select tr.ClientServicesRef
				--	 , Count(r.CompositeID) as Customers
				--From #BaseOfferDateOffersToRun tr
				--Left join Warehouse.Selections.CampaignCode_Selections_BaseOfferDateMembers r
				--	on tr.ClientServicesRef = r.ClientServicesRef
				--Group by tr.ClientServicesRef

				--Select 'Selected in another campaign to run through'
				--Select tr.ClientServicesRef
				--	 , Count(r.CompositeID) as Customers
				--From #SelectedInAnotherCampaignToRun tr
				--Left join Warehouse.Selections.CampaignCode_Selections_SelectedInAnotherCampaignMembers r
				--	on tr.ClientServicesRef = r.ClientServicesRef
				--Group by tr.ClientServicesRef

			End	--	If @RunType = 1

		Set NoCount Off

	End	--	Alter Procedure [Selections].[CampaignCode_Selections_ShopperSegment_ALS_PreSelections]