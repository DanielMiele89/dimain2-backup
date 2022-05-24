

/****************************************************************************************************
Modified Log:

Change No:	Name:			Date:			Description of change:
1.			Rory Francis	2018-05-02		Warehouse.Staging.ROCShopperSegment_PreSELECTion_ALSS to 
											Warehouse.Selections.ROCShopperSegment_PreSELECTion_AL

2.			Rory Francis	2018-05-03		Adding in process to use priority flag to dedupe while
											pulling Selections
											
****************************************************************************************************/
/*
Update Date		Updated By		Update
2018-05-02		Rory Francis	Warehouse.Staging.ROCShopperSegment_PreSELECTion_ALSS to Warehouse.Selections.ROCShopperSegment_PreSELECTion_AL
2018-05-03		Rory Francis	Adding in process to use priority flag to dedupe while pulling Selections
*/

CREATE PROCEDURE [Selections].[__CampaignSetup_Selection_Loop_POS_20200312_Archived] @RunType BIT
															  , @EmailDate VARCHAR(30)
AS
BEGIN
	SET NOCOUNT ON

	/*******************************************************************************************************************************************
		1. Prepare parameters for sProc to run
	*******************************************************************************************************************************************/

	DECLARE @Today DATETIME
		  , @NewCampaign BIT
		  , @LoopStartTime DATETIME
		  , @LoopEndTime DATETIME
		  , @LoopLengthSeconds INT
		  , @RunID INT
		  , @MaxID INT
		  , @Qry1 NVARCHAR(max)
		  , @Qry2 NVARCHAR(max)
		  , @Time DATETIME
		  , @Qry NVARCHAR(MAX)
		  , @Msg VARCHAR(2048)
		  --, @RunType BIT = 1
		  --, @EmailDate VARCHAR(30) = '2019-05-09'

		EXEC Staging.oo_TimerMessage 'CampaignSetup_Selection_Loop Start', @Time OUTPUT

	/*******************************************************************************************************************************************
		2. Prepare campaigns to run through for Selection loop
	*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				2.1. Store all camapigns to be run in this cycle
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#AllCampaigns') IS NOT NULL DROP TABLE #AllCampaigns
				SELECT *
				INTO #AllCampaigns
				FROM Selections.ROCShopperSegment_PreSelection_ALS
				WHERE EmailDate = @EmailDate
				AND ReadyToRun = 1

				EXEC Staging.oo_TimerMessage 'Store all camapigns to be run in this cycle', @Time OUTPUT

			/***********************************************************************************************************************
				2.2. Find all partners with a new campaign
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#PartnersWithNewCampaign') IS NOT NULL DROP TABLE #PartnersWithNewCampaign
				SELECT PartnerID
					 , MAX(CONVERT(INT, NewCampaign)) AS NewCampaign_Partner
				INTO #PartnersWithNewCampaign
				FROM #AllCampaigns
				GROUP BY PartnerID

			/***********************************************************************************************************************
				2.3. Store all camapigns to be run in this execution
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#CampaignsToRun') IS NOT NULL DROP TABLE #CampaignsToRun
				SELECT als.*
					 , ROW_NUMBER() OVER (ORDER BY pwnc.NewCampaign_Partner DESC, als.PartnerID, als.PriorityFlag ASC, als.ID) AS RunID
				INTO #CampaignsToRun
				FROM Selections.ROCShopperSegment_PreSelection_ALS als
				LEFT JOIN #PartnersWithNewCampaign pwnc
					ON als.PartnerID = pwnc.PartnerID
				WHERE EmailDate = @EmailDate
				AND SelectionRun = 0
				AND ReadyToRun = 1

				SELECT StartDate
					 , EndDate
					 , CampaignName
					 , ClientServicesRef
					 , OfferID
					 , Gender
					 , AgeRange
					 , DriveTimeMins
					 , LiveNearAnyStore
					 , SocialClass
					 , sProcPreSelection
					 , OutputTableName
					 , NotIn_TableName1
					 , NotIn_TableName2
					 , MustBeIn_TableName1
					 , MustBeIn_TableName2
					 , OutletSector
					 , MarketableByEmail
					 , CustomerBaseOfferDate
					 , SelectedInAnotherCampaign
					 , DeDupeAgainstCampaigns
					 , CampaignID_Include
					 , CampaignID_Exclude
					 , Throttling
					 , RandomThrottle
					 , PriorityFlag
				FROM #CampaignsToRun ctr
				ORDER BY RunID

				EXEC Staging.oo_TimerMessage 'Store all camapigns to be run in this execution', @Time OUTPUT

	/*******************************************************************************************************************************************
		3. Add campaigns to table to allow partner dedupe
	*******************************************************************************************************************************************/
		
		IF @RunType = 1
			BEGIN
				INSERT INTO Selections.CampaignCode_Selections_OutputTables (PreSelection_ALS_ID
																		   , PartnerID
																		   , OutputTableName
																		   , PriorityFlag
																		   , InPartnerDedupe
																		   , RowNumber)
				SELECT DISTINCT 
					   ID AS PreSelection_ALS_ID
					 , PartnerID
					 , OutputTableName
					 , PriorityFlag
					 , 0 AS InPartnerDedupe
					 , CONVERT(INT, NULL) AS RowNumber
				FROM #CampaignsToRun ctr
				WHERE NOT EXISTS (SELECT 1
								  FROM Selections.CampaignCode_Selections_OutputTables ot
								  WHERE ctr.OutputTableName = ot.OutputTableName)

				EXEC Staging.oo_TimerMessage 'Add campaigns to table to allow partner dedupe', @Time OUTPUT;

				WITH Updater AS (SELECT RowNumber
									   , ROW_NUMBER() OVER (ORDER BY PartnerID, PriorityFlag) AS NewRowNumber
								  FROM Selections.CampaignCode_Selections_OutputTables)

				 UPDATE Updater
				 SET RowNumber = NewRowNumber

				EXEC Staging.oo_TimerMessage 'Renumber rows in Partner dedupe table', @Time OUTPUT

			END	--	3. IF @RunType = 1


	/*******************************************************************************************************************************************
		4. Load the top available offer per partner into a holding table
	*******************************************************************************************************************************************/
		
		IF @RunType = 1
			BEGIN
				TRUNCATE TABLE Selections.CampaignSetup_TopPartnerOffer
				INSERT INTO Selections.CampaignSetup_TopPartnerOffer
				SELECT PartnerID
					 , IronOfferID
				     , IronOfferName
				     , TopCashBackRate
				FROM (
					SELECT PartnerID
						 , IronOfferID
						 , IronOfferName
						 , TopCashBackRate
						 , OfferPriority
						 , DENSE_RANK() OVER (PARTITION BY PartnerID ORDER BY TopCashBackRate DESC, OfferPriority, IronOfferID) AS OfferRank	
					FROM (
						SELECT DISTINCT
							   iof.PartnerID
							 , iof.ID AS IronOfferID
							 , iof.Name AS IronOfferName
							 , COALESCE(tcb.TopCashBackRate, 1) AS TopCashBackRate
							 , CASE 
									WHEN iof.Name LIKE '%Acquire%' THEN 1
									WHEN iof.Name LIKE '%Lapsed%' THEN 1
									WHEN iof.Name LIKE '%Shopper%' THEN 1
									WHEN iof.Name LIKE '%Universal%' THEN 2 
									WHEN iof.Name LIKE '%Launch%' THEN 2 
									WHEN iof.Name LIKE '%AllSegments%' THEN 3
									WHEN iof.Name LIKE '%Welcome%' THEN 4
									WHEN iof.Name LIKE '%Birthda%' THEN 5
									WHEN iof.Name LIKE '%Homemove%' THEN 5
									WHEN iof.Name LIKE '%Joiner%' THEN 6
									WHEN iof.Name LIKE '%Core%' THEN 7
									WHEN iof.Name LIKE '%Base%' THEN 7
								END AS OfferPriority
						FROM SLC_REPL..IronOffer iof
						LEFT JOIN Relational.IronOffer tcb
							ON iof.ID = tcb.IronOfferID
						INNER JOIN #AllCampaigns ac
							on iof.PartnerID = ac.PartnerID
						WHERE iof.StartDate <= CONVERT(Date, @EmailDate)
						And DATEADD(day, 13, CONVERT(Date, @EmailDate)) <= iof.EndDate) a) a
				WHERE OfferRank = 1

				EXEC Staging.oo_TimerMessage 'Load the top available offer per partner', @Time OUTPUT

			END	--	4. IF @RunType = 1


	/*******************************************************************************************************************************************
		5. If senior staff have already been assigned an ongoing offer then store those details to exclude from being foreced in
	*******************************************************************************************************************************************/

		IF @RunType = 1
			BEGIN
				IF OBJECT_ID('tempdb..#SSA_Campaigns') IS NOT NULL DROP TABLE #SSA_Campaigns
				SELECT ac.EmailDate
					 , ac.PartnerID
					 , ac.IronOfferID
					 , ssa.CompositeID
				INTO #SSA_Campaigns
				FROM (SELECT DISTINCT
							 ac.EmailDate
						   , ac.PartnerID
						   , iof.ID AS IronOfferID
					  FROM #AllCampaigns ac
					  INNER JOIN SLC_REPL..IronOffer iof
						  ON ac.PartnerID = iof.PartnerID
					  WHERE iof.EndDate > @EmailDate) ac	--	GETDATE()
				CROSS JOIN Selections.ROCShopperSegment_SeniorStaffAccounts ssa

				EXEC Staging.oo_TimerMessage 'Load offers that Senior Staff could already be placed on', @Time OUTPUT

				CREATE CLUSTERED INDEX CIX_SSA_Campaigns ON #SSA_Campaigns (IronOfferID, CompositeID)

				INSERT INTO Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships (PartnerID
																							  , CompositeID)
				
				SELECT DISTINCT
					   ca.PartnerID
					 , ca.CompositeID
				FROM #SSA_Campaigns ca
				INNER JOIN SLC_Report..IronOfferMember iom
					ON ca.IronOfferID = iom.IronOfferID
					AND ca.CompositeID = iom.CompositeID
					AND ca.EmailDate BETWEEN iom.StartDate and iom.EndDate

				EXEC Staging.oo_TimerMessage 'Store senior staff have already been assigned an ongoing offer', @Time OUTPUT

			END	--	5. IF @RunType = 1





	/*******************************************************************************************************************************************
		7. Prepare variable to input into individual Selection sProc
	*******************************************************************************************************************************************/

			IF @RunType = 1
				BEGIN
					SELECT @MaxID = Max(RunID)
						 , @Today = GETDATE()
						 , @RunID = 1
					FROM #CampaignsToRun

					DECLARE @PartnerID CHAR(4)
						  , @StartDate VARCHAR(10)
						  , @EndDate VARCHAR(10)
						  , @CampaignName VARCHAR (250)
						  , @ClientServicesRef VARCHAR(10)
						  , @OfferID VARCHAR(40)
						  , @PriorityFlag INT
						  , @Throttling VARCHAR(200)
						  , @RandomThrottle CHAR(1)
						  , @MarketableByEmail CHAR(1)
						  , @Gender CHAR(1)
						  , @AgeRange VARCHAR(7)
						  , @DriveTimeMins CHAR(3)
						  , @LiveNearAnyStore BIT
						  , @SocialClass VARCHAR(5)
						  , @OutletSector CHAR(6)
						  , @CustomerBaseOfferDate VARCHAR(10)
						  , @SelectedInAnotherCampaign VARCHAR(20)
						  , @DeDupeAgainstCampaigns VARCHAR(50)
						  , @CampaignID_Include CHAR(3)
						  , @CampaignID_Exclude CHAR(3)
						  , @sProcPreSelection NVARCHAR(150)
						  , @OutputTableName VARCHAR (100)
						  , @NotIn_TableName1 VARCHAR(100)
						  , @NotIn_TableName2 VARCHAR(100)
						  , @NotIn_TableName3 VARCHAR(100)
						  , @NotIn_TableName4 VARCHAR(100)
						  , @MustBeIn_TableName1 VARCHAR(100)
						  , @MustBeIn_TableName2 VARCHAR(100)
						  , @MustBeIn_TableName3 VARCHAR(100)
						  , @MustBeIn_TableName4 VARCHAR(100)
						  , @CampaignTypeID INT
				  
						  , @OutputTableNamePartnerDedupe VARCHAR (100)
						  , @AlternatePartnerOutputTable VARCHAR(150)
						  , @PreviouslyRanPartnerID INT = 0
						  
						  , @FreqStretch_TransCount INT
						  , @ControlGroupPercentage INT
			

	/*******************************************************************************************************************************************
		8. Loop through each of the campaigns and run Selections
	*******************************************************************************************************************************************/
			
						WHILE @RunID <= @MaxID 
							BEGIN
				
								SET @LoopStartTime = GETDATE()

		/***********************************************************************************************************************
			8.1. Parametrise entries from CampaignSetup_DD
		***********************************************************************************************************************/

									IF EXISTS (SELECT 1 FROM #CampaignsToRun WHERE RunID = @RunID)
										BEGIN
											SELECT @PartnerID = PartnerID
												 , @StartDate = StartDate 
												 , @EndDate = EndDate
												 , @CampaignName = CampaignName
												 , @ClientServicesRef = ClientServicesRef
												 , @OfferID = OfferID
												 , @PriorityFlag = PriorityFlag
												 , @Throttling = Throttling
												 , @RandomThrottle = RandomThrottle
												 , @MarketableByEmail = MarketableByEmail
												 , @Gender = Gender
												 , @AgeRange = AgeRange
												 , @DriveTimeMins = DriveTimeMins
												 , @LiveNearAnyStore = LiveNearAnyStore
												 , @SocialClass = SocialClass
												 , @OutletSector = OutletSector
												 , @CustomerBaseOfferDate = CustomerBaseOfferDate
												 , @SelectedInAnotherCampaign = SelectedInAnotherCampaign
												 , @DeDupeAgainstCampaigns = DeDupeAgainstCampaigns
												 , @CampaignID_Include = CampaignID_Include
												 , @CampaignID_Exclude = CampaignID_Exclude
												 , @sProcPreSelection = sProcPreSelection
												 , @OutputTableName = OutputTableName
												 , @NotIn_TableName1 = NotIn_TableName1
												 , @NotIn_TableName2 = NotIn_TableName2
												 , @NotIn_TableName3 = NotIn_TableName3
												 , @NotIn_TableName4 = NotIn_TableName4
												 , @MustBeIn_TableName1 = MustBeIn_TableName1
												 , @MustBeIn_TableName2 = MustBeIn_TableName2
												 , @MustBeIn_TableName3 = MustBeIn_TableName3
												 , @MustBeIn_TableName4 = MustBeIn_TableName4
												 , @CampaignTypeID = CampaignTypeID
												 , @NewCampaign = NewCampaign
												 , @FreqStretch_TransCount = FreqStretch_TransCount
												 , @ControlGroupPercentage = ControlGroupPercentage
												 , @AlternatePartnerOutputTable = OutputTableName + '_APR'
											FROM #CampaignsToRun
											WHERE @RunID = RunID

											PRINT CHAR(10) + @OutputTableName + ' has now begun'


		/***********************************************************************************************************************
			8.2. If loop runs to new partner then truncate dedupe table
		***********************************************************************************************************************/

											IF @PartnerID != @PreviouslyRanPartnerID
												BEGIN
													SET @Qry1 = (SELECT PartnerID FROM Relational.Partner Where PartnerID = (SELECT DISTINCT PartnerID FROM Selections.CampaignCode_Selections_PartnerDedupe))
													SET @Qry2 = (SELECT COUNT(1) FROM Selections.CampaignCode_Selections_PartnerDedupe)

													TRUNCATE TABLE Selections.CampaignCode_Selections_PartnerDedupe

													UPDATE Selections.CampaignCode_Selections_OutputTables
													SET InPartnerDedupe = 0

													PRINT @Qry1 + ' has had ' + @Qry2 + ' entries removed from the Selections.CampaignCode_Selections_PartnerDedupe table'
												End	--	IF @PartnerID != @PreviouslyRanPartnerID


		/***********************************************************************************************************************
			8.3. Populate CampaignCode_Selections_PartnerDedupe table with all customers already Selected for this partner
		***********************************************************************************************************************/

											IF OBJECT_ID('tempdb..#CampaignSetup_OutputTables') IS NOT NULL DROP TABLE #CampaignSetup_OutputTables
											SELECT OutputTableName
												 , RowNumber
											INTO #CampaignSetup_OutputTables
											FROM Selections.CampaignCode_Selections_OutputTables
											WHERE PartnerID = @PartnerID
											AND PriorityFlag < @PriorityFlag
											AND InPartnerDedupe = 0

											DECLARE @TableLoop INT
												  , @MaxTableLoop INT

											SELECT @TableLoop = MIN(RowNumber)
												 , @MaxTableLoop = MAX(RowNumber)
											FROM #CampaignSetup_OutputTables

											WHILE @TableLoop <= @MaxTableLoop
												BEGIN
													SET @OutputTableNamePartnerDedupe = (SELECT DISTINCT OutputTableName
																						 FROM #CampaignSetup_OutputTables
																						 WHERE RowNumber = @TableLoop)

													SET @Qry1 = '
													INSERT INTO Selections.CampaignCode_Selections_PartnerDedupe (PartnerID
																												, CompositeID)
													SELECT PartnerID
														 , CompositeID
													FROM ' + @OutputTableNamePartnerDedupe + ''
		
													EXEC (@Qry1)

													UPDATE Selections.CampaignCode_Selections_OutputTables
													SET InPartnerDedupe = 1
													WHERE RowNumber = @TableLoop

													PRINT @OutputTableNamePartnerDedupe + ' has been added to the Selections.CampaignCode_Selections_PartnerDedupe table'

													SET @TableLoop = (SELECT MIN(RowNumber) FROM #CampaignSetup_OutputTables WHERE RowNumber > @TableLoop)
												END	--	WHILE @TableLoop <= @MaxTableLoop

											EXEC Staging.oo_TimerMessage 'Populate CampaignCode_Selections_PartnerDedupe table', @Time OUTPUT


		/***********************************************************************************************************************
			8.4. Populate CustomerBase table with all customers to be selected for this partner
		***********************************************************************************************************************/

			IF @PreviouslyRanPartnerID != @PartnerID
				BEGIN
					TRUNCATE TABLE Selections.CustomerBase				
					INSERT INTO Selections.CustomerBase
					SELECT DISTINCT
						   cs.PartnerID
						 , cs.ShopperSegmentTypeID
						 , cu.FanID
						 , cu.CompositeID
						 , cu.Postcode
						 , cu.ActivatedDate
						 , cu.Gender
						 , cu.MarketableByEmail
						 , cu.DOB
						 , cu.AgeCurrent
					FROM Relational.Customer cu
					INNER JOIN Segmentation.Roc_Shopper_Segment_Members cs
						ON cu.FanID = cs.FanID
						AND cs.EndDate IS NULL
						AND PartnerID = @PartnerID
					WHERE cu.CurrentlyActive = 1
					AND NOT EXISTS (SELECT 1
									FROM Selections.ROCShopperSegment_SeniorStaffAccounts ssa
									WHERE cu.CompositeID = ssa.CompositeID)
					AND EXISTS (SELECT 1
								FROM #CampaignsToRun ctr
								WHERE cs.PartnerID = ctr.PartnerID)

					ALTER INDEX CIX_PartnerActivateGenderAgeDOBMarket ON Selections.CustomerBase REBUILD
				END

		/***********************************************************************************************************************
			8.5. Exec Selection for individual campaign
		***********************************************************************************************************************/

											EXEC Staging.oo_TimerMessage 'Starting Exec Selection for individual campaign', @Time OUTPUT

											EXEC [Selections].[CampaignSetup_Selection_IndividualCampaign_POS] @PartnerID
																											 , @StartDate
																											 , @EndDate
																											 , @CampaignName
																											 , @ClientServicesRef
																											 , @OfferID
																											 , @Throttling
																											 , @RandomThrottle
																											 , @MarketableByEmail
																											 , @Gender
																											 , @AgeRange
																											 , @DriveTimeMins
																											 , @LiveNearAnyStore
																											 , @SocialClass
																											 , @OutletSector
																											 , @CustomerBaseOfferDate
																											 , @SelectedInAnotherCampaign
																											 , @DeDupeAgainstCampaigns
																											 , @CampaignID_Include
																											 , @CampaignID_Exclude
																											 , @OutputTableName
																											 , @NotIn_TableName1
																											 , @NotIn_TableName2
																											 , @NotIn_TableName3
																											 , @NotIn_TableName4
																											 , @MustBeIn_TableName1
																											 , @MustBeIn_TableName2
																											 , @MustBeIn_TableName3
																											 , @MustBeIn_TableName4
																											 , @NewCampaign
																											 , @CampaignTypeID
																											 , @FreqStretch_TransCount
																											 , @ControlGroupPercentage

											EXEC Staging.oo_TimerMessage 'Finished Exec Selection for individual campaign', @Time OUTPUT


		/***********************************************************************************************************************
			8.6. Insert the Selections counts for the campaign into the CampaignSelectionCounts_DD table
		***********************************************************************************************************************/

											Set @Qry1 = '
											IF OBJECT_ID(''#tempdb..#SelectionCount'') IS NOT NULL DROP TABLE #SelectionCount
											SELECT ClientServicesRef
												 , OfferID
												 , COUNT(1) as CountSelected
											INTO #SelectionCount
											FROM ' + @OutputTableName + '
											GROUP BY ClientServicesRef
												   , OfferID


											INSERT INTO Selections.ROCShopperSegment_SelectionCounts (EmailDate
																									, OutputTableName
																									, IronOfferID
																									, CountSelected
																									, RunDateTime
																									, NewCampaign
																									, ClientServicesRef)
											SELECT ''' + CONVERT(VARCHAR(10), @EmailDate) + ''' AS EmailDate
												 , ''' + @OutputTableName + ''' AS OutputTableName
												 , sc.OfferID AS IronOfferID
												 , sc.CountSelected
												 , GETDATE() as RunDateTime
												 , ' + CONVERT(VARCHAR(1), @NewCampaign) + ' AS NewCampaign
												 , ''' + @ClientServicesRef + ''' AS ClientServicesRef
											FROM #SelectionCount sc'
											
											EXEC (@Qry1)

											EXEC Staging.oo_TimerMessage 'Populated ROCShopperSegment_SelectionCounts table', @time Output


		/***********************************************************************************************************************
			8.7. Update the ROCShopperSegment_PreSelection_ALS table to show the Selection has ran
		***********************************************************************************************************************/

											UPDATE cs
											SET SelectionRun = 1
											FROM #CampaignsToRun ctr
											INNER JOIN Selections.ROCShopperSegment_PreSelection_ALS cs
												ON ctr.ID = cs.ID
											WHERE @RunID = ctr.RunID


		/***********************************************************************************************************************
			8.8. Update the previously ran partner variable to prepare for next loop
		***********************************************************************************************************************/

											SET @PreviouslyRanPartnerID = @PartnerID


		/***********************************************************************************************************************
			8.9. If the partner being looped has an alternate partner record then replicate the Selection for that record
		***********************************************************************************************************************/

											IF @PartnerID IN (4319, 4715, 4263)
												BEGIN 
													SET @Qry1 = '
													IF OBJECT_ID(''tempdb..#PrimaryPartnerOffers'') IS NOT NULL DROP TABLE #PrimaryPartnerOffers
													SELECT DISTINCT
															PartnerID
														  , OfferID
													INTO #PrimaryPartnerOffers
													FROM ' + @OutputTableName + ' pps

													IF OBJECT_ID(''tempdb..#SecondaryPartnerOffers'') IS NOT NULL DROP TABLE #SecondaryPartnerOffers
													SELECT DISTINCT
															  p.PartnerID as SecondaryPartnerID
															, p.PartnerName as SecondaryPartnerName
															, iofp.IronOfferID as PrimaryIronOfferID
															, iofp.IronOfferName as PrimaryIronOfferName
															, iofs.IronOfferID as SecondaryIronOfferID
															, iofs.IronOfferName as SecondaryIronOfferName
													INTO #SecondaryPartnerOffers
													FROM #PrimaryPartnerOffers pps
													INNER JOIN Relational.IronOffer iofp
														ON pps.OfferID = iofp.IronOfferID
													INNER JOIN APW.PartnerAlternate pa
														ON	pps.PartnerID = pa.AlternatePartnerID
														AND	pa.PartnerID in (SELECT PartnerID FROM Relational.Partner)
													INNER JOIN Relational.Partner p
														ON pa.PartnerID = p.PartnerID
													INNER JOIN Relational.IronOffer iofs
														ON pa.PartnerID = iofs.PartnerID
														AND	iofp.StartDate = iofs.StartDate
														AND	iofp.EndDate = iofs.EndDate
														AND	iofp.IronOfferName = iofs.IronOfferName

													IF OBJECT_ID (''' + @AlternatePartnerOutputTable + ''') IS NOT NULL DROP TABLE ' + @AlternatePartnerOutputTable + '
													SELECT DISTINCT
															pps.FanID
														  , pps.CompositeID
														  , pps.ShopperSegmentTypeID
														  , spo.SecondaryPartnerID AS PartnerID
														  , spo.SecondaryPartnerName AS PartnerName
														  , spo.SecondaryIronOfferID AS OfferID
														  , pps.ClientServicesRef
														  , pps.StartDate
														  , pps.EndDate
													INTO ' + @AlternatePartnerOutputTable + '
													FROM ' + @OutputTableName + ' pps
													INNER JOIN #SecondaryPartnerOffers spo
														ON pps.OfferID = spo.PrimaryIronOfferID
														
													INSERT INTO [Iron].[OfferMemberAddition]
													SELECT CompositeID
														 , OfferID
														 , StartDate
														 , EndDate
														 , GETDATE() AS Date
														 , 0 AS IsControl
													FROM ' + @AlternatePartnerOutputTable + ''

													EXEC (@Qry1)

													EXEC Staging.oo_TimerMessage 'Replicate the Selection for alternate partner records', @Time Output	

													INSERT INTO Selections.NominatedOfferMember_TableNames (TableName)
													SELECT @AlternatePartnerOutputTable
												END	--	IF @PartnerID IN (3432,4319,4715,4637)


		/***********************************************************************************************************************
			8.10. Show loop completition message and output time per loop
		***********************************************************************************************************************/
			
										SET @LoopEndTime = GETDATE()
										SET @LoopLengthSeconds = DATEDIFF(second, @LoopStartTime, @LoopEndTime)

										PRINT @OutputTableName + ' has completed in ' + CONVERT(VARCHAR(10), @LoopLengthSeconds) + ' seconds'


		/***********************************************************************************************************************
			8.11. Prepare for next loop
		***********************************************************************************************************************/

									SET @RunID = @RunID + 1
		
							END	--	8.1 IF EXISTS (SELECT 1 FROM #CampaignsToRun WHERE RunID = @RunID)

	/*******************************************************************************************************************************************
		9. Table clear down
	*******************************************************************************************************************************************/

							TRUNCATE TABLE Selections.CampaignCode_Selections_PartnerDedupe

							UPDATE Selections.CampaignCode_Selections_OutputTables
							SET InPartnerDedupe = 0

					END	--	8. WHILE @RunID <= @MaxID

	/*******************************************************************************************************************************************
		10. Display all counts for all Selections run with email date
	*******************************************************************************************************************************************/

							SELECT *
							FROM Selections.ROCShopperSegment_SelectionCounts
							WHERE EmailDate = @EmailDate
							ORDER BY RunDateTime
								   , EmailDate
								   , OutputTableName
								   , IronOfferID

				END	--	6. IF @RunType = 1
END

RETURN 0