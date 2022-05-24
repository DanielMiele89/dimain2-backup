

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

CREATE PROCEDURE [Selections].[CampaignExecution_Loop_POS] @EmailDate DATE
AS
BEGIN

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT


	/*******************************************************************************************************************************************
		1.	Prepare parameters for sProc to run
	*******************************************************************************************************************************************/
	
		--DECLARE @EmailDate DATE = '2022-05-05'

		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Start';
		EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

		DECLARE @Today DATETIME
			,	@NewCampaign BIT
			,	@LoopStartTime DATETIME
			,	@LoopEndTime DATETIME
			,	@LoopLengthSeconds INT
			,	@RunID INT
			,	@MaxID INT
			,	@Qry1 NVARCHAR(max)
			,	@Qry2 NVARCHAR(max)
			,	@Qry NVARCHAR(MAX)
			,	@Msg VARCHAR(2048)


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
								
				SET @RowsAffected = @@ROWCOUNT;
				SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Store all camapigns to be run in this cycle [' + CAST(@RowsAffected AS VARCHAR(10)) + ']';
				EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT


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
				FROM [Selections].[CampaignSetup_POS] als
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
								
				SET @RowsAffected = @@ROWCOUNT;
				SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Store all camapigns to be run in this execution [' + CAST(@RowsAffected AS VARCHAR(10)) + ']';
				EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

		
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

		SET @RowsAffected = @@ROWCOUNT;
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Add campaigns to table to allow partner dedupe [' + CAST(@RowsAffected AS VARCHAR(10)) + ']';
		EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

		;WITH Updater AS (	SELECT	RowNumber
								,	ROW_NUMBER() OVER (ORDER BY PartnerID, PriorityFlag) AS NewRowNumber
							FROM [Selections].[CampaignExecution_OutputTables])

		UPDATE Updater
		SET RowNumber = NewRowNumber

		SET @RowsAffected = @@ROWCOUNT;
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Renumber rows in Partner dedupe table [' + CAST(@RowsAffected AS VARCHAR(10)) + ']';
		EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT


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
		
			  , @OutputTableNamePartnerDedupe VARCHAR (100)
			  , @AlternatePartnerOutputTable VARCHAR(150)
			  , @PreviouslyRanPartnerID INT = 0
			  
			  , @FreqStretch_TransCount INT
			  , @ControlGroupPercentage INT
			

	/*******************************************************************************************************************************************
		5.	Loop through each of the campaigns and run Selections
	*******************************************************************************************************************************************/
	
		ALTER INDEX [IUX_IronOfferStartEndComposite] ON [Segmentation].[OfferMemberAddition] DISABLE
		ALTER INDEX [ix_Stuff] ON [Segmentation].[OfferMemberAddition] DISABLE

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
							,	 @AlternatePartnerOutputTable = OutputTableName + '_APR'
						FROM #CampaignsToRun
						WHERE @RunID = RunID

						SET @AlternatePartnerOutputTable = REPLACE(@AlternatePartnerOutputTable, ']_APR', '_APR]')

						IF @PartnerID = 4825 SET @AlternatePartnerOutputTable = REPLACE(@AlternatePartnerOutputTable, 'KIT', 'FAN')
												
						SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' ' + @OutputTableName + ' - Start';
						EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

			/***********************************************************************************************************************
				5.2.	If loop runs to new partner then truncate dedupe table
			***********************************************************************************************************************/

				IF @PartnerID != @PreviouslyRanPartnerID AND @PreviouslyRanPartnerID > 0
					BEGIN

						SELECT @Qry1 = Name
						FROM [SLC_REPL].[dbo].[Partner] pa
						WHERE ID = @PreviouslyRanPartnerID

						TRUNCATE TABLE [Selections].[CampaignExecution_PartnerDedupe]

						UPDATE [Selections].[CampaignExecution_OutputTables]
						SET InPartnerDedupe = 0

						SET @RowsAffected = @@ROWCOUNT;
						SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' ' + @Qry1 + ' has had entries removed from the [Selections].[CampaignExecution_PartnerDedupe] table [' + CAST(@RowsAffected AS VARCHAR(10)) + ']';
						EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

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

				ALTER INDEX [IX_CompositeID] ON [Selections].[CampaignExecution_PartnerDedupe] DISABLE

				WHILE @TableLoop <= @MaxTableLoop
					BEGIN
						SET @OutputTableNamePartnerDedupe = (SELECT	DISTINCT
																	OutputTableName
															 FROM #CampaignSetup_OutputTables
															 WHERE RowNumber = @TableLoop)

						SET @Qry1 = '
						INSERT INTO [Selections].[CampaignExecution_PartnerDedupe] (PartnerID
																				,	CompositeID)
						SELECT PartnerID
							 , CompositeID
						FROM ' + @OutputTableNamePartnerDedupe + ''
		
						EXEC (@Qry1)

						SET @RowsAffected = @@ROWCOUNT;
						SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' ' + @OutputTableNamePartnerDedupe + ' has been added to the [Selections].[CampaignExecution_PartnerDedupe] table  [' + CAST(@RowsAffected AS VARCHAR(10)) + ']';
						EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

						UPDATE [Selections].[CampaignExecution_OutputTables]
						SET InPartnerDedupe = 1
						WHERE RowNumber = @TableLoop

						SET @TableLoop = (SELECT MIN(RowNumber) FROM #CampaignSetup_OutputTables WHERE RowNumber > @TableLoop)

					END	--	WHILE @TableLoop <= @MaxTableLoop

				ALTER INDEX [IX_CompositeID] ON [Selections].[CampaignExecution_PartnerDedupe] REBUILD WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
				UPDATE STATISTICS [Selections].[CampaignExecution_PartnerDedupe]


			/***********************************************************************************************************************
				5.4.	Populate CustomerBase table with all customers to be selected for this partner
			***********************************************************************************************************************/

				IF @PreviouslyRanPartnerID != @PartnerID
					BEGIN
				
						IF OBJECT_ID('tempdb..##CurrentCustomerSegment_VisaBarclaycard') IS NOT NULL DROP TABLE ##CurrentCustomerSegment_VisaBarclaycard
						SELECT	ccs.PartnerID
							,	ccs.FanID
							,	ccs.ShopperSegmentTypeID
						INTO ##CurrentCustomerSegment_VisaBarclaycard
						FROM [Segmentation].[CurrentCustomerSegment] ccs
						WHERE ccs.PartnerID = @PartnerID

						CREATE CLUSTERED INDEX CIX_FanID ON ##CurrentCustomerSegment_VisaBarclaycard (FanID) WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)

						IF INDEXPROPERTY(OBJECT_ID('[Selections].[CampaignExecution_CustomerBase]'), 'CSX_All', 'IndexId') IS NOT NULL
							BEGIN
								DROP INDEX [CSX_All] ON [Selections].[CampaignExecution_CustomerBase]
							END

						EXEC('	TRUNCATE TABLE [Selections].[CampaignExecution_CustomerBase]
								INSERT INTO [Selections].[CampaignExecution_CustomerBase]
								SELECT ccs.PartnerID
									 , ccs.ShopperSegmentTypeID
									 , cu.FanID
									 , cu.CompositeID
									 , cup.Postcode
									 , cu.RegistrationDate
									 , cu.Gender
									 , cu.MarketableByEmail
									 , cup.DOB
									 , cu.AgeCurrent
								FROM [Derived].[Customer] cu
								INNER JOIN [Derived].[Customer_PII] cup
									ON cu.FanID = cup.FanID
								INNER JOIN ##CurrentCustomerSegment_VisaBarclaycard ccs
									ON cu.FanID = ccs.FanID

								UPDATE STATISTICS [Selections].[CampaignExecution_CustomerBase]')
								
						SET @RowsAffected = @@ROWCOUNT;
						SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Populated [Selections].[CampaignExecution_CustomerBase] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']';
						EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

						IF INDEXPROPERTY(OBJECT_ID('[Selections].[CampaignExecution_CustomerBase]'), 'CSX_All', 'IndexId') IS NULL
							BEGIN
								CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_All] ON [Selections].[CampaignExecution_CustomerBase] (	[PartnerID]
																																,	[CompositeID]
																																,	[ShopperSegmentTypeID]
																																,	[ActivatedDate]
																																,	[Gender]
																																,	[AgeCurrent]
																																,	[DOB]
																																,	[MarketableByEmail])

							END
								
						SET @RowsAffected = @@ROWCOUNT;
						SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Indexed [Selections].[CampaignExecution_CustomerBase] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']';
						EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

						DROP TABLE ##CurrentCustomerSegment_VisaBarclaycard

					END


			/***********************************************************************************************************************
				5.5.	Exec Selection for individual campaign
			***********************************************************************************************************************/

				EXEC [Selections].[CampaignExecution_IndividualCampaign_POS]	@PartnerID
																			,	@StartDate
																			,	@EndDate
																			,	@CampaignName
																			,	@ClientServicesRef
																			,	@OfferID
																			,	@Throttling
																			,	@RandomThrottle
																			,	@MarketableByEmail
																			,	@Gender
																			,	@AgeRange
																			,	@DriveTimeMins
																			,	@LiveNearAnyStore
																			,	@SocialClass
																			,	@CustomerBaseOfferDate
																			,	@SelectedInAnotherCampaign
																			,	@DeDupeAgainstCampaigns
																			,	@CampaignID_Include
																			,	@CampaignID_Exclude
																			,	@OutputTableName
																			,	@NotIn_TableName1
																			,	@NotIn_TableName2
																			,	@NotIn_TableName3
																			,	@NotIn_TableName4
																			,	@MustBeIn_TableName1
																			,	@MustBeIn_TableName2
																			,	@MustBeIn_TableName3
																			,	@MustBeIn_TableName4
																			,	@NewCampaign
																			,	@FreqStretch_TransCount
																			,	@ControlGroupPercentage

				SET @RowsAffected = @@ROWCOUNT;
				SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Finished Exec Selection for individual campaign';
				EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT


			/***********************************************************************************************************************
				5.6.	Insert the Selections counts for the campaign into the [Selections].[CampaignExecution_SelectionCounts] table
			***********************************************************************************************************************/

				DECLARE @Query_SelectionCount VARCHAR(MAX)

				SET @Query_SelectionCount = '
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
				SELECT	''' + CONVERT(VARCHAR(10), @EmailDate) + ''' AS EmailDate
					,	''' + @OutputTableName + ''' AS OutputTableName
					,	sc.OfferID AS IronOfferID
					,	sc.CountSelected
					,	GETDATE() as RunDateTime
					,	' + CONVERT(VARCHAR(1), @NewCampaign) + ' AS NewCampaign
					,	''' + @ClientServicesRef + ''' AS ClientServicesRef
				FROM #SelectionCount sc'
			
				EXEC (@Query_SelectionCount)

				SET @RowsAffected = @@ROWCOUNT;
				SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Populated [Selections].[CampaignExecution_SelectionCounts]';
				EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT


			/***********************************************************************************************************************
				5.7.	Update the ROCShopperSegment_PreSelection_ALS table to show the Selection has ran
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

				DECLARE @Query_AltPartner VARCHAR(MAX)

				IF @PartnerID IN (4805, 4825)	--	Ideal World, KitBag
					BEGIN 
						SET @Query_AltPartner = '

						IF OBJECT_ID (''' + @OutputTableName + ''') IS NOT NULL
							BEGIN
								IF OBJECT_ID(''tempdb..#PrimaryPartnerOffers'') IS NOT NULL DROP TABLE #PrimaryPartnerOffers
								SELECT DISTINCT
										PartnerID
									  , OfferID
								INTO #PrimaryPartnerOffers
								FROM ' + @OutputTableName + ' pps

								IF OBJECT_ID(''tempdb..#SecondaryPartnerOffers'') IS NOT NULL DROP TABLE #SecondaryPartnerOffers
								SELECT DISTINCT
										  p.ID as SecondaryPartnerID
										, p.Name as SecondaryPartnerName
										, iofp.ID as PrimaryIronOfferID
										, iofp.Name as PrimaryIronOfferName
										, iofs.ID as SecondaryIronOfferID
										, iofs.Name as SecondaryIronOfferName
										, LEFT(iofs.Name, CHARINDEX(''/'', iofs.Name) - 1) AS SecondaryClientServicesRef
								INTO #SecondaryPartnerOffers
								FROM #PrimaryPartnerOffers pps
								INNER JOIN [SLC_REPL].[dbo].[IronOffer] iofp
									ON pps.OfferID = iofp.ID
								INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] iofcp
									ON pps.OfferID = iofcp.IronOfferID
								INNER JOIN [Warehouse].[APW].[PartnerAlternate] pa
									ON	pps.PartnerID = pa.AlternatePartnerID
									AND	pa.PartnerID in (SELECT PartnerID FROM [Derived].[Partner])
								INNER JOIN [SLC_REPL].[dbo].[Partner] p
									ON pa.PartnerID = p.ID
								INNER JOIN [SLC_REPL].[dbo].[IronOffer] iofs
									ON pa.PartnerID = iofs.PartnerID
									AND	iofp.EndDate = iofs.EndDate
									AND	SUBSTRING(iofp.Name,  LEN(iofp.Name) - CHARINDEX(''/'', REVERSE(iofp.Name)) + 2, 9999) = SUBSTRING(iofs.Name,  LEN(iofs.Name) - CHARINDEX(''/'', REVERSE(iofs.Name)) + 2, 9999)
								--	AND	iofp.StartDate = iofs.StartDate
								--	AND	iofp.IronOfferName = iofs.IronOfferName
								INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] iofcs
									ON iofs.ID = iofcp.IronOfferID
									AND iofcp.ClubID = iofcs.ClubID

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
						
								INSERT INTO [Segmentation].[OfferMemberAddition]
								SELECT apot.CompositeID
									 , apot.OfferID AS IronOfferID
									 , apot.StartDate
									 , apot.EndDate
									 , GETDATE() AS AddedDate
								FROM ' + @AlternatePartnerOutputTable + ' apot
								LEFT JOIN [Segmentation].[OfferMemberAddition] oma
								ON	apot.CompositeID = oma.CompositeID
								AND apot.OfferID = oma.IronOfferID
								AND apot.StartDate = oma.StartDate
								AND apot.EndDate = oma.EndDate
								WHERE oma.CompositeID IS NULL
						
								INSERT INTO [Selections].[CampaignExecution_TableNames]
								SELECT	DISTINCT
										''' + @AlternatePartnerOutputTable + '''
									,	SecondaryClientServicesRef
								FROM #SecondaryPartnerOffers
						
							END'

						EXEC (@Query_AltPartner)

						SET @RowsAffected = @@ROWCOUNT;
						SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Replicate the Selection for alternate partner records';
						EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
	
					END	--	IF @PartnerID IN (4805, 4825)



			/***********************************************************************************************************************
				5.10.	Show loop completition message and output time per loop
			***********************************************************************************************************************/
			
				SET @LoopEndTime = GETDATE()
				SET @LoopLengthSeconds = DATEDIFF(second, @LoopStartTime, @LoopEndTime)

				SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - ' + @OutputTableName + ' has completed in ' + CONVERT(VARCHAR(10), @LoopLengthSeconds) + ' seconds';

				EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
					
				PRINT CHAR(10)
				

			/***********************************************************************************************************************
				5.11.	Prepare for next loop
			***********************************************************************************************************************/

						SET @RunID = @RunID + 1
		
				END	--	5.1 IF EXISTS (SELECT 1 FROM #CampaignsToRun WHERE RunID = @RunID)


		/***********************************************************************************************************************
			5.12.	Table clear down
		***********************************************************************************************************************/

					TRUNCATE TABLE [Selections].[CampaignExecution_PartnerDedupe]

					UPDATE [Selections].[CampaignExecution_OutputTables]
					SET InPartnerDedupe = 0

			END	--	8. WHILE @RunID <= @MaxID

	/*******************************************************************************************************************************************
		6. Rebuild indexes on OMA
	*******************************************************************************************************************************************/
	
					ALTER INDEX [IUX_IronOfferStartEndComposite] ON [Segmentation].[OfferMemberAddition] REBUILD WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
					ALTER INDEX [ix_Stuff] ON [Segmentation].[OfferMemberAddition] REBUILD WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
		

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
