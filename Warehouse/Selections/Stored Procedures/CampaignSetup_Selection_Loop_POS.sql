

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

CREATE PROCEDURE [Selections].[CampaignSetup_Selection_Loop_POS] @RunType BIT
															  , @EmailDate VARCHAR(30)
AS
BEGIN
	SET NOCOUNT ON

	/*******************************************************************************************************************************************
		1.	Prepare parameters for sProc to run
	*******************************************************************************************************************************************/
							
	DECLARE @Today DATETIME
		,	@NewCampaign BIT
		,	@LoopStartTime DATETIME
		,	@LoopEndTime DATETIME
		,	@LoopLengthSeconds INT
		,	@RunID INT
		,	@MaxID INT
		,	@Qry NVARCHAR(MAX)
		,	@Qry1 NVARCHAR(max)
		,	@Qry2 NVARCHAR(max)
		,	@Time DATETIME = GETDATE()
		  , @SSMS BIT = NULL
		,	@Msg VARCHAR(2048)
		--,	@RunType BIT = 1
		--,	@EmailDate VARCHAR(30) = '2021-02-25'
		
							
	EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] 'CampaignSetup_Selection_Loop Start', @time OUTPUT, @SSMS OUTPUT

	/*******************************************************************************************************************************************
		2.	Prepare campaigns to run through for Selection loop
	*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				2.1.	Store all camapigns to be run in this cycle, whether they have been executed already or not
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#AllCampaigns') IS NOT NULL DROP TABLE #AllCampaigns
				SELECT	*
				INTO #AllCampaigns
				FROM [Selections].[CampaignSetup_POS]
				WHERE EmailDate = @EmailDate

				SELECT @msg ='Store all camapigns to be run in this cycle'
				EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

			/***********************************************************************************************************************
				2.2.	Find all partners with a new campaign
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#PartnersWithNewCampaign') IS NOT NULL DROP TABLE #PartnersWithNewCampaign
				SELECT	PartnerID
					,	MAX(CONVERT(INT, NewCampaign)) AS NewCampaign_Partner
				INTO #PartnersWithNewCampaign
				FROM #AllCampaigns
				WHERE NewCampaign = 1
				GROUP BY PartnerID

			/***********************************************************************************************************************
				2.3.	Store all camapigns to be run in this execution
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#CampaignsToRun') IS NOT NULL DROP TABLE #CampaignsToRun
				SELECT	als.*
					,	ROW_NUMBER() OVER (ORDER BY pwnc.NewCampaign_Partner DESC, als.PartnerID, als.PriorityFlag ASC, als.ID) AS RunID
				INTO #CampaignsToRun
				FROM Selections.CampaignSetup_POS als
				LEFT JOIN #PartnersWithNewCampaign pwnc
					ON als.PartnerID = pwnc.PartnerID
				WHERE EmailDate = @EmailDate
				AND ReadyToRun = 1
				AND SelectionRun = 0

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

				SELECT @msg ='Store all camapigns to be run in this execution'
				EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

				IF @RunType = 0 RETURN

	/*******************************************************************************************************************************************
		3.	Add campaigns to table to allow partner dedupe
	*******************************************************************************************************************************************/
	
		--Synchronize the target table with refreshed data from source table
		MERGE [Selections].[CampaignExecution_OutputTables] AS TARGET
		USING #AllCampaigns AS SOURCE 
		ON (TARGET.PreSelection_ALS_ID = SOURCE.ID) 

		--When records are matched, update the records if there is any change
		WHEN MATCHED
		AND TARGET.OutputTableName != SOURCE.OutputTableName
		OR TARGET.PriorityFlag != SOURCE.PriorityFlag
		OR TARGET.InPartnerDedupe != 0
		THEN UPDATE
		SET	TARGET.OutputTableName = SOURCE.OutputTableName
		,	TARGET.PriorityFlag = SOURCE.PriorityFlag
		,	TARGET.InPartnerDedupe = 0

		--When no records are matched, insert the incoming records from source table to target table
		WHEN NOT MATCHED BY TARGET
		THEN INSERT (PreSelection_ALS_ID, PartnerID, OutputTableName, PriorityFlag, InPartnerDedupe, RowNumber)
		VALUES (	SOURCE.ID
				,	SOURCE.PartnerID
				,	SOURCE.OutputTableName
				,	SOURCE.PriorityFlag
				,	0
				,	NULL)

		--When there is a row that exists in target and same record does not exist in source then delete this record target
		WHEN NOT MATCHED BY SOURCE
		THEN DELETE;

		SELECT @msg ='Add campaigns to table to allow partner dedupe'
		EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

		;WITH Updater AS (	SELECT	RowNumber
								,	ROW_NUMBER() OVER (ORDER BY PartnerID, PriorityFlag) AS NewRowNumber
							FROM [Selections].[CampaignExecution_OutputTables])

		 UPDATE Updater
		 SET RowNumber = NewRowNumber

		SELECT @msg ='Renumber rows in Partner dedupe table'
		EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT
							

	/*******************************************************************************************************************************************
		4.	Prepare variable to input into individual Selection sProc
	*******************************************************************************************************************************************/

		SELECT @MaxID = MAX(RunID)
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

			  , @ThrottleType CHAR(1)
			

	/*******************************************************************************************************************************************
		5.	Loop through each of the campaigns and run Selections
	*******************************************************************************************************************************************/
	
		IF (SELECT COUNT(*) FROM [iron].[OfferMemberAddition]) < 100000000 AND (SELECT COUNT(*) FROM #CampaignsToRun) > 3
			BEGIN
				ALTER INDEX [IUX_IronOfferStartEndComposite] ON [iron].[OfferMemberAddition] DISABLE
				ALTER INDEX [ix_Stuff] ON [iron].[OfferMemberAddition] DISABLE
			END

		WHILE @RunID <= @MaxID 
			BEGIN
				SET @LoopStartTime = GETDATE()

			/***********************************************************************************************************************
				5.1.	Parametrise entries from CampaignSetup_DD
			***********************************************************************************************************************/

				IF EXISTS (SELECT 1 FROM #CampaignsToRun WHERE RunID = @RunID)
					BEGIN
						SELECT	 @PartnerID = PartnerID
							,	 @StartDate = StartDate 
							,	 @EndDate = EndDate
							,	 @CampaignName = CampaignName
							,	 @ClientServicesRef = ClientServicesRef
							,	 @OfferID = OfferID
							,	 @PriorityFlag = PriorityFlag
							,	 @Throttling = Throttling
							,	 @RandomThrottle = RandomThrottle
							,	 @MarketableByEmail = MarketableByEmail
							,	 @Gender = Gender
							,	 @AgeRange = AgeRange
							,	 @DriveTimeMins = DriveTimeMins
							,	 @LiveNearAnyStore = LiveNearAnyStore
							,	 @SocialClass = SocialClass
							,	 @CustomerBaseOfferDate = CustomerBaseOfferDate
							,	 @SelectedInAnotherCampaign = SelectedInAnotherCampaign
							,	 @DeDupeAgainstCampaigns = DeDupeAgainstCampaigns
							,	 @CampaignID_Include = CampaignID_Include
							,	 @CampaignID_Exclude = CampaignID_Exclude
							,	 @sProcPreSelection = sProcPreSelection
							,	 @OutputTableName = OutputTableName
							,	 @NotIn_TableName1 = NotIn_TableName1
							,	 @NotIn_TableName2 = NotIn_TableName2
							,	 @NotIn_TableName3 = NotIn_TableName3
							,	 @NotIn_TableName4 = NotIn_TableName4
							,	 @MustBeIn_TableName1 = MustBeIn_TableName1
							,	 @MustBeIn_TableName2 = MustBeIn_TableName2
							,	 @MustBeIn_TableName3 = MustBeIn_TableName3
							,	 @MustBeIn_TableName4 = MustBeIn_TableName4
							,	 @NewCampaign = NewCampaign
							,	 @FreqStretch_TransCount = FreqStretch_TransCount
							,	 @ControlGroupPercentage = ControlGroupPercentage
							,	 @AlternatePartnerOutputTable = CASE
																	WHEN RIGHT(OutputTableName, 1) = ']' THEN LEFT(OutputTableName, LEN(OutputTableName) - 1) + '_APR]'
																	ELSE OutputTableName + '_APR'
																END
							,	 @ThrottleType = ThrottleType
						FROM #CampaignsToRun
						WHERE @RunID = RunID

						SELECT @msg = CHAR(10) + @OutputTableName + ' has now begun'
						EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				5.2.	If loop runs to new partner then truncate dedupe table
			***********************************************************************************************************************/

				IF @PartnerID != @PreviouslyRanPartnerID
					BEGIN

						SELECT @Qry1 = PartnerName
						FROM [Relational].[Partner] pa
						WHERE PartnerID = @PreviouslyRanPartnerID

						TRUNCATE TABLE [Selections].[CampaignCode_Selections_PartnerDedupe]

						UPDATE [Selections].[CampaignExecution_OutputTables]
						SET InPartnerDedupe = 0


						SELECT @msg = @Qry1 + ' has had entries removed from the Selections.CampaignCode_Selections_PartnerDedupe table'
						EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

					END	--	IF @PartnerID != @PreviouslyRanPartnerID


			/***********************************************************************************************************************
				5.3.	Populate CampaignCode_Selections_PartnerDedupe table with all customers already selected for this partner
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#CampaignSetup_OutputTables') IS NOT NULL DROP TABLE #CampaignSetup_OutputTables
				SELECT	OutputTableName
					,	RowNumber
				INTO #CampaignSetup_OutputTables
				FROM [Selections].[CampaignExecution_OutputTables]
				WHERE PartnerID = @PartnerID
				AND PriorityFlag < @PriorityFlag
				AND InPartnerDedupe = 0

				DECLARE @TableLoop INT
					  , @MaxTableLoop INT

				SELECT	@TableLoop = MIN(RowNumber)
					,	@MaxTableLoop = MAX(RowNumber)
				FROM #CampaignSetup_OutputTables

				ALTER INDEX [IX_CompositeID] ON [Selections].[CampaignCode_Selections_PartnerDedupe] DISABLE

				WHILE @TableLoop <= @MaxTableLoop
					BEGIN
						SET @OutputTableNamePartnerDedupe = (SELECT	DISTINCT
																	OutputTableName
															 FROM #CampaignSetup_OutputTables
															 WHERE RowNumber = @TableLoop)

						SET @Qry1 = '
						INSERT INTO [Selections].[CampaignCode_Selections_PartnerDedupe] (	PartnerID
																						,	CompositeID)
						SELECT PartnerID
							 , CompositeID
						FROM ' + @OutputTableNamePartnerDedupe + ''
		
						EXEC (@Qry1)

						UPDATE [Selections].[CampaignExecution_OutputTables]
						SET InPartnerDedupe = 1
						WHERE RowNumber = @TableLoop

						SELECT @msg = @OutputTableNamePartnerDedupe + ' has been added to the Selections.CampaignCode_Selections_PartnerDedupe table'
						EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

						SET @TableLoop = (SELECT MIN(RowNumber) FROM #CampaignSetup_OutputTables WHERE RowNumber > @TableLoop)
					END	--	WHILE @TableLoop <= @MaxTableLoop

				ALTER INDEX [IX_CompositeID] ON [Selections].[CampaignCode_Selections_PartnerDedupe] REBUILD WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
				UPDATE STATISTICS [Selections].[CampaignCode_Selections_PartnerDedupe]

				SELECT @msg = 'Populate CampaignCode_Selections_PartnerDedupe table'
				EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				5.4.	Populate CustomerBase table with all customers to be selected for this partner
			***********************************************************************************************************************/

				IF @PreviouslyRanPartnerID != @PartnerID
					BEGIN
				
						IF OBJECT_ID('tempdb..##CurrentCustomerSegment') IS NOT NULL DROP TABLE ##CurrentCustomerSegment
						SELECT	ccs.PartnerID
							,	ccs.FanID
							,	ccs.ShopperSegmentTypeID
						INTO ##CurrentCustomerSegment
						FROM [Segmentation].[CurrentCustomerSegment] ccs
						WHERE ccs.PartnerID = @PartnerID

						CREATE CLUSTERED INDEX CIX_FanID ON ##CurrentCustomerSegment (FanID) WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)

						IF INDEXPROPERTY(OBJECT_ID('[Selections].[CustomerBase]'), 'CSX_All', 'IndexId') IS NOT NULL
							BEGIN
								DROP INDEX [CSX_All] ON [Selections].[CustomerBase]
							END

						EXEC('	TRUNCATE TABLE [Selections].[CustomerBase]
								INSERT INTO [Selections].[CustomerBase]
								SELECT ccs.PartnerID
									 , ccs.ShopperSegmentTypeID
									 , cu.FanID
									 , cu.CompositeID
									 , cu.Postcode
									 , cu.ActivatedDate
									 , cu.Gender
									 , cu.MarketableByEmail
									 , cu.DOB
									 , cu.AgeCurrent
								FROM [Relational].[Customer] cu
								INNER JOIN ##CurrentCustomerSegment ccs
									ON cu.FanID = ccs.FanID

								UPDATE STATISTICS [Selections].[CustomerBase]')					

						IF INDEXPROPERTY(OBJECT_ID('[Selections].[CustomerBase]'), 'CSX_All', 'IndexId') IS NULL
							BEGIN
								CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_All] ON [Selections].[CustomerBase] ([PartnerID]
																											,	[CompositeID]
																											,	[ShopperSegmentTypeID]
																											,	[ActivatedDate]
																											,	[Gender]
																											,	[AgeCurrent]
																											,	[DOB]
																											,	[MarketableByEmail]) ON Warehouse_Columnstores

							END

						DROP TABLE ##CurrentCustomerSegment

					END

				SELECT @msg = 'Populate CustomerBase table'
				EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				5.5.	Exec Selection for individual campaign
			***********************************************************************************************************************/

				SELECT @msg = 'Starting Exec Selection for individual campaign'
				EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

				EXEC [Selections].[CampaignSetup_Selection_IndividualCampaign_POS_V3] @PartnerID
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
																				 , @FreqStretch_TransCount
																				 , @ControlGroupPercentage
																				 , @ThrottleType

				SELECT @msg = 'Finished Exec Selection for individual campaign'
				EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				5.6.	Insert the Selections counts for the campaign into the [Selections].[CampaignExecution_SelectionCounts] table
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

				INSERT INTO [Selections].[CampaignExecution_SelectionCounts] (	EmailDate
																			,	OutputTableName
																			,	IronOfferID
																			,	CountSelected
																			,	RunDateTime
																			,	NewCampaign
																			,	ClientServicesRef)
				SELECT ''' + CONVERT(VARCHAR(10), @EmailDate) + ''' AS EmailDate
					 , ''' + @OutputTableName + ''' AS OutputTableName
					 , sc.OfferID AS IronOfferID
					 , sc.CountSelected
					 , GETDATE() as RunDateTime
					 , ' + CONVERT(VARCHAR(1), @NewCampaign) + ' AS NewCampaign
					 , ''' + @ClientServicesRef + ''' AS ClientServicesRef
				FROM #SelectionCount sc'
			
				EXEC (@Qry1)

				SELECT @msg = 'Populated [Selections].[CampaignExecution_SelectionCounts] table'
				EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				5.7.	Update the [Selections].[CampaignSetup_POS] table to show the Selection has ran
			***********************************************************************************************************************/

				UPDATE cs
				SET SelectionRun = 1
				FROM #CampaignsToRun ctr
				INNER JOIN [Selections].[CampaignSetup_POS] cs
					ON ctr.ID = cs.ID
				WHERE @RunID = ctr.RunID


			/***********************************************************************************************************************
				5.8.	Update the previously ran partner variable to prepare for next loop
			***********************************************************************************************************************/

				SET @PreviouslyRanPartnerID = @PartnerID


			/***********************************************************************************************************************
				5.9.	If the partner being looped has an alternate partner record then replicate the Selection for that record
			***********************************************************************************************************************/

				IF @PartnerID IN (4805, 4825)	--	Ideal World, KitBag
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
								, iofp.ID as PrimaryIronOfferID
								, iofp.Name as PrimaryIronOfferName
								, iofs.ID as SecondaryIronOfferID
								, iofs.Name as SecondaryIronOfferName
								, LEFT(iofs.Name, CHARINDEX(''/'', iofs.Name) - 1) AS SecondaryClientServicesRef
						INTO #SecondaryPartnerOffers
						FROM #PrimaryPartnerOffers pps
						INNER JOIN SLC_REPL..IronOffer iofp
							ON pps.OfferID = iofp.ID
						INNER JOIN APW.PartnerAlternate pa
							ON	pps.PartnerID = pa.AlternatePartnerID
							AND	pa.PartnerID in (SELECT PartnerID FROM Relational.Partner)
						INNER JOIN Relational.Partner p
							ON pa.PartnerID = p.PartnerID
						INNER JOIN SLC_REPL..IronOffer iofs
							ON pa.PartnerID = iofs.PartnerID
							AND	iofp.EndDate = iofs.EndDate
							AND	SUBSTRING(iofp.Name,  LEN(iofp.Name) - CHARINDEX(''/'', REVERSE(iofp.Name)) + 2, 9999) = SUBSTRING(iofs.Name,  LEN(iofs.Name) - CHARINDEX(''/'', REVERSE(iofs.Name)) + 2, 9999)
						--	AND	iofp.StartDate = iofs.StartDate
						--	AND	iofp.IronOfferName = iofs.IronOfferName

						IF OBJECT_ID (''' + @AlternatePartnerOutputTable + ''') IS NOT NULL DROP TABLE ' + @AlternatePartnerOutputTable + '
						SELECT DISTINCT
								pps.FanID
							  , pps.CompositeID
							  , pps.ShopperSegmentTypeID
							  , spo.SecondaryPartnerID AS PartnerID
							  , spo.SecondaryPartnerName AS PartnerName
							  , spo.SecondaryIronOfferID AS OfferID
							  , spo.SecondaryClientServicesRef AS ClientServicesRef
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

						SELECT @msg = 'Replicate the Selection for alternate partner records'
						EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


						INSERT INTO [Selections].[CampaignExecution_TableNames] (TableName)
						SELECT @AlternatePartnerOutputTable
					END	--	IF @PartnerID IN (4805)


			/***********************************************************************************************************************
				5.10.	Show loop completition message and output time per loop
			***********************************************************************************************************************/
			
				SET @LoopEndTime = GETDATE()
				SET @LoopLengthSeconds = DATEDIFF(second, @LoopStartTime, @LoopEndTime)

				SELECT @msg = @OutputTableName + ' has completed in ' + CONVERT(VARCHAR(10), @LoopLengthSeconds) + ' seconds'
				EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


			/***********************************************************************************************************************
				5.11.	Prepare for next loop
			***********************************************************************************************************************/

						SET @RunID = @RunID + 1
		
				END	--	5.1 IF EXISTS (SELECT 1 FROM #CampaignsToRun WHERE RunID = @RunID)


		/***********************************************************************************************************************
			5.12.	Table clear down
		***********************************************************************************************************************/

					TRUNCATE TABLE [Selections].[CampaignCode_Selections_PartnerDedupe]

					UPDATE [Selections].[CampaignExecution_OutputTables]
					SET InPartnerDedupe = 0

			END	--	8. WHILE @RunID <= @MaxID

	/*******************************************************************************************************************************************
		6. Rebuild indexes on OMA
	*******************************************************************************************************************************************/

					IF EXISTS (	SELECT 1
								FROM sys.objects
								INNER JOIN sys.indexes
									ON sys.objects.object_id = sys.indexes.object_id
								WHERE sys.objects.name = 'OfferMemberAddition'
								AND is_disabled = 1
								AND sys.indexes.name = 'IUX_IronOfferStartEndComposite')
						BEGIN

							ALTER INDEX [IUX_IronOfferStartEndComposite] ON [iron].[OfferMemberAddition] REBUILD WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)

						END
	
					IF EXISTS (	SELECT 1
								FROM sys.objects
								INNER JOIN sys.indexes
									ON sys.objects.object_id = sys.indexes.object_id
								WHERE sys.objects.name = 'OfferMemberAddition'
								AND is_disabled = 1
								AND sys.indexes.name = 'ix_Stuff')
						BEGIN

							ALTER INDEX [ix_Stuff] ON [iron].[OfferMemberAddition] REBUILD WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)

						END
		

	/*******************************************************************************************************************************************
		7. Display all counts for all Selections run with email date
	*******************************************************************************************************************************************/

		SELECT *
		FROM [Selections].[CampaignExecution_SelectionCounts]
		WHERE EmailDate = @EmailDate
		ORDER BY RunDateTime
			   , EmailDate
			   , OutputTableName
			   , IronOfferID
END

RETURN 0