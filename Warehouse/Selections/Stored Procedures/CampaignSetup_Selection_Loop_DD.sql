

/****************************************************************************************************
Modified Log:

Change No:	Name:			Date:			Description of change:
1.			Rory Francis	2018-05-02		Warehouse.Staging.CampaignSetup_DDS to 
											Warehouse.Selections.ROCShopperSegment_PreSelection_AL

2.			Rory Francis	2018-05-03		Adding in process to use priority flag to dedupe while
											pulling Selections
											
****************************************************************************************************/
/*
Update Date		Updated By		Update
2018-05-02		Rory Francis	Warehouse.Staging.CampaignSetup_DDS to Warehouse.Selections.ROCShopperSegment_PreSelection_AL
2018-05-03		Rory Francis	Adding in process to use priority flag to dedupe while pulling Selections
*/

CREATE PROCEDURE [Selections].[CampaignSetup_Selection_Loop_DD] @RunType BIT
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
			  , @Msg VARCHAR(2048)
				--	, @RunType BIT = 1
				--	, @EmailDate VARCHAR(30) = '2019-07-04'

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
				FROM Selections.CampaignSetup_DD
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
				FROM Selections.CampaignSetup_DD als
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
					 , ControlGroupPercentage
					 , PriorityFlag
					 , ThrottleType
				FROM #CampaignsToRun ctr
				ORDER BY RunID

				EXEC Staging.oo_TimerMessage 'Store all camapigns to be run in this execution', @Time OUTPUT

	/*******************************************************************************************************************************************
		3. Add campaigns to table to allow partner dedupe
	*******************************************************************************************************************************************/
		
		IF @RunType = 1
			BEGIN
				INSERT INTO [Selections].[CampaignExecution_OutputTables] (	PreSelection_ALS_ID
																		,	PartnerID
																		,	OutputTableName
																		,	PriorityFlag
																		,	InPartnerDedupe
																		,	RowNumber)
				SELECT DISTINCT 
					   ID AS PreSelection_ALS_ID
					 , PartnerID
					 , OutputTableName
					 , PriorityFlag
					 , 0 AS InPartnerDedupe
					 , CONVERT(INT, NULL) AS RowNumber
				FROM #CampaignsToRun ctr
				WHERE NOT EXISTS (SELECT 1
								  FROM [Selections].[CampaignExecution_OutputTables] ot
								  WHERE ctr.OutputTableName = ot.OutputTableName)

				EXEC Staging.oo_TimerMessage 'Add campaigns to table to allow partner dedupe', @Time OUTPUT

				;WITH Updater AS (SELECT RowNumber
									   , ROW_NUMBER() OVER (ORDER BY PartnerID, PriorityFlag) AS NewRowNumber
								  FROM [Selections].[CampaignExecution_OutputTables])

				 UPDATE Updater
				 SET RowNumber = NewRowNumber

				EXEC Staging.oo_TimerMessage 'Renumber rows in Partner dedupe table', @Time OUTPUT

			END	--	3. IF @RunType = 1


	/*******************************************************************************************************************************************
		4. Load the top available offer per partner into a holding table
	*******************************************************************************************************************************************/
		
		--IF @RunType = 1
		--	BEGIN
		--		IF OBJECT_ID ('tempdb..##TopPartnerOffer') IS NOT NULL DROP TABLE ##TopPartnerOffer
		--		SELECT PartnerID
		--			 , IronOfferID
		--		     , IronOfferName
		--		     , TopCashBackRate
		--		Into ##TopPartnerOffer
		--		FROM (
		--			SELECT PartnerID
		--				 , IronOfferID
		--				 , IronOfferName
		--				 , TopCashBackRate
		--				 , OfferPriority
		--				 , DENSE_RANK() OVER (PARTITION BY PartnerID ORDER BY TopCashBackRate DESC, OfferPriority, IronOfferID) AS OfferRank	
		--			FROM (
		--				SELECT DISTINCT
		--					   iof.PartnerID
		--					 , iof.IronOfferID
		--					 , iof.IronOfferName
		--					 , iof.TopCashBackRate
		--					 , CASE 
		--							WHEN iof.IronOfferName LIKE '%Acquire%' THEN 1
		--							WHEN iof.IronOfferName LIKE '%Lapsed%' THEN 1
		--							WHEN iof.IronOfferName LIKE '%Shopper%' THEN 1
		--							WHEN iof.IronOfferName LIKE '%Universal%' THEN 2 
		--							WHEN iof.IronOfferName LIKE '%Launch%' THEN 2 
		--							WHEN iof.IronOfferName LIKE '%AllSegments%' THEN 3
		--							WHEN iof.IronOfferName LIKE '%Welcome%' THEN 4
		--							WHEN iof.IronOfferName LIKE '%Birthda%' THEN 5
		--							WHEN iof.IronOfferName LIKE '%Homemove%' THEN 5
		--							WHEN iof.IronOfferName LIKE '%Joiner%' THEN 6
		--							WHEN iof.IronOfferName LIKE '%Core%' THEN 7
		--							WHEN iof.IronOfferName LIKE '%Base%' THEN 7
		--						END AS OfferPriority
		--				FROM Relational.IronOffer iof
		--				INNER JOIN #AllCampaigns ac
		--					on iof.PartnerID = ac.PartnerID
		--				WHERE iof.IronOfferName LIKE '%MFDD%'
		--				AND iof.StartDate <= CONVERT(Date, @EmailDate)
		--				And DATEADD(day, 13, CONVERT(Date, @EmailDate)) <= iof.EndDate) a) a
		--		WHERE OfferRank = 1

		--		EXEC Staging.oo_TimerMessage 'Load the top available offer per partner', @Time OUTPUT

		--	END	--	4. IF @RunType = 1


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
						   , iof.IronOfferID
					  FROM #AllCampaigns ac
					  INNER JOIN Relational.IronOffer iof
						  ON ac.PartnerID = iof.PartnerID
						  AND iof.IronOfferName LIKE '%MFDD%'
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
		6. Prepare variable to input into individual Selection sProc
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

						  , @ControlGroupPercentage INT
						  , @ThrottleType VARCHAR(1)


	/*******************************************************************************************************************************************
		7. Create table of customers on joint accounts for use within each loop
	*******************************************************************************************************************************************/

			--IF OBJECT_ID ('tempdb..#JointAccounts') IS NOT NULL DROP TABLE #JointAccounts
			--SELECT iba.BankAccountID
			--	 , ic.SourceUID
			--INTO #JointAccounts
			--FROM SLC_Report..IssuerCustomer ic
			--INNER JOIN SLC_Report..IssuerBankAccount iba
			--	ON ic.ID = iba.IssuerCustomerID
			--INNER JOIN SLC_Report..BankAccount ba
			--	ON iba.BankAccountID = ba.ID
			--WHERE iba.CustomerStatus = 1
			--AND ba.Status = 1

			--TRUNCATE TABLE Selections.JointAccountCustomers_DD
			--ALTER INDEX CIX_JointAccounts_Bank ON Selections.JointAccountCustomers_DD DISABLE
			--ALTER INDEX IX_JointAccounts_Composite ON Selections.JointAccountCustomers_DD DISABLE

			--INSERT INTO Selections.JointAccountCustomers_DD
			--SELECT ja.BankAccountID
			--	 , cu.CompositeID
			--	 , cu.FanID
			--FROM #JointAccounts ja
			--INNER JOIN Relational.Customer cu
			--	on ja.SourceUID = cu.SourceUID
			--WHERE cu.CurrentlyActive = 1
			
			--ALTER INDEX CIX_JointAccounts_Bank ON Selections.JointAccountCustomers_DD REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
			--ALTER INDEX IX_JointAccounts_Composite ON Selections.JointAccountCustomers_DD REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
			

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
												 , @NewCampaign = NewCampaign
												 , @ControlGroupPercentage = ControlGroupPercentage
												 , @ThrottleType = ThrottleType
												 , @AlternatePartnerOutputTable = OutputTableName + '_APR'
											FROM #CampaignsToRun
											WHERE @RunID = RunID


		/***********************************************************************************************************************
			8.2. If loop runs to new partner then truncate dedupe table
		***********************************************************************************************************************/

											IF @PartnerID != @PreviouslyRanPartnerID
												BEGIN
													SET @Qry1 = (SELECT PartnerID FROM Relational.Partner Where PartnerID = (SELECT DISTINCT PartnerID FROM Selections.CampaignSetup_PartnerDedupe_DD))
													SET @Qry2 = (SELECT COUNT(1) FROM Selections.CampaignSetup_PartnerDedupe_DD)

													TRUNCATE TABLE Selections.CampaignSetup_PartnerDedupe_DD

													UPDATE [Selections].[CampaignExecution_OutputTables]
													SET InPartnerDedupe = 0

													PRINT @Qry1 + ' has had ' + @Qry2 + ' entries removed from the Selections.CampaignSetup_PartnerDedupe_DD table'
												End	--	IF @PartnerID != @PreviouslyRanPartnerID


		/***********************************************************************************************************************
			8.3. Populate CampaignSetup_PartnerDedupe_DD table with all customers already Selected for this partner
		***********************************************************************************************************************/

											IF OBJECT_ID('tempdb..#CampaignExecution_OutputTables') IS NOT NULL DROP TABLE #CampaignExecution_OutputTables
											SELECT OutputTableName
												 , RowNumber
											INTO #CampaignExecution_OutputTables
											FROM [Selections].[CampaignExecution_OutputTables]
											WHERE PartnerID = @PartnerID
											AND PriorityFlag < @PriorityFlag
											AND InPartnerDedupe = 0

											DECLARE @TableLoop INT
												  , @MaxTableLoop INT

											SELECT @TableLoop = MIN(RowNumber)
												 , @MaxTableLoop = MAX(RowNumber)
											FROM #CampaignExecution_OutputTables

											WHILE @TableLoop <= @MaxTableLoop
												BEGIN
													SET @OutputTableNamePartnerDedupe = (SELECT DISTINCT OutputTableName
																						 FROM #CampaignExecution_OutputTables
																						 WHERE RowNumber = @TableLoop)

													SET @Qry1 = '
													INSERT INTO Selections.CampaignSetup_PartnerDedupe_DD (PartnerID
																										 , CompositeID)
													SELECT PartnerID
														 , CompositeID
													FROM ' + @OutputTableNamePartnerDedupe + ''
		
													EXEC (@Qry1)

													UPDATE [Selections].[CampaignExecution_OutputTables]
													SET InPartnerDedupe = 1
													WHERE RowNumber = @TableLoop

													PRINT @OutputTableNamePartnerDedupe + ' has been added to the Selections.CampaignSetup_PartnerDedupe_DD table'

													SET @TableLoop = (SELECT MIN(RowNumber) FROM #CampaignExecution_OutputTables WHERE RowNumber > @TableLoop)
												END	--	WHILE @TableLoop <= @MaxTableLoop

											EXEC Staging.oo_TimerMessage 'Populate CampaignSetup_PartnerDedupe_DD table', @Time OUTPUT



		/***********************************************************************************************************************
			8.4. Exec Selection for individual campaign
		***********************************************************************************************************************/

											EXEC Staging.oo_TimerMessage 'Starting Exec Selection for individual campaign', @Time OUTPUT

											EXEC [Selections].[CampaignSetup_Selection_IndividualCampaign_DD] @PartnerID
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
																											, @ControlGroupPercentage
																											, @ThrottleType

											EXEC Staging.oo_TimerMessage 'Finished Exec Selection for individual campaign', @Time OUTPUT

		/***********************************************************************************************************************
			8.5. Insert the Selections counts for the campaign into the [Selections].[CampaignExecution_SelectionCounts] table
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

											EXEC Staging.oo_TimerMessage 'Populated [Selections].[CampaignExecution_SelectionCounts] table', @time Output	


		/***********************************************************************************************************************
			8.6. Update the CampaignSetup_DD table to show the Selection has ran
		***********************************************************************************************************************/

											UPDATE cs
											SET SelectionRun = 1
											FROM #CampaignsToRun ctr
											INNER JOIN Selections.CampaignSetup_DD cs
												ON ctr.ID = cs.ID
											WHERE @RunID = ctr.RunID


		/***********************************************************************************************************************
			8.7. Update the previously ran partner variable to prepare for next loop
		***********************************************************************************************************************/

											SET @PreviouslyRanPartnerID = @PartnerID


		/***********************************************************************************************************************
			8.8. If the partner being looped has an alternate partner record then replicate the Selection for that record
		***********************************************************************************************************************/

											IF @PartnerID IN (3432,4319,4715,4637)
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
														AND	pa.PartnerID in (SELECT PartnerID FROM Warehouse.Relational.Partner)
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
														  , pps.SOWCategory
														  , spo.SecondaryPartnerID AS PartnerID
														  , spo.SecondaryPartnerName AS PartnerName
														  , spo.SecondaryIronOfferID AS OfferID
														  , pps.ClientServicesRef
														  , pps.StartDate
														  , pps.EndDate
														  , pps.[Comm Type]
														  , pps.TriggerBatch
														  , pps.Grp
													INTO ' + @AlternatePartnerOutputTable + '
													FROM ' + @OutputTableName + ' pps
													INNER JOIN #SecondaryPartnerOffers spo
														ON pps.OfferID = spo.PrimaryIronOfferID'

													EXEC (@Qry1)

													EXEC Staging.oo_TimerMessage 'Replicate the Selection for alternate partner records', @Time Output	

													INSERT INTO [Selections].[CampaignExecution_TableNames] (TableName)
													SELECT @AlternatePartnerOutputTable
												END	--	IF @PartnerID IN (3432,4319,4715,4637)


		/***********************************************************************************************************************
			8.9. Show loop completition message and output time per loop
		***********************************************************************************************************************/
			
										SET @LoopEndTime = GETDATE()
										SET @LoopLengthSeconds = DATEDIFF(second, @LoopStartTime, @LoopEndTime)

										PRINT @OutputTableName + ' has completed in ' + CONVERT(VARCHAR(10), @LoopLengthSeconds) + ' seconds'


		/***********************************************************************************************************************
			8.10. Prepare for next loop
		***********************************************************************************************************************/

									SET @RunID = @RunID + 1
		
							END	--	8.1 IF EXISTS (SELECT 1 FROM #CampaignsToRun WHERE RunID = @RunID)

	/*******************************************************************************************************************************************
		9. Display all counts for all Selections run with email date
	*******************************************************************************************************************************************/

							SELECT *
							FROM [Selections].[CampaignExecution_SelectionCounts]
							WHERE EmailDate = @EmailDate
							ORDER BY RunDateTime
								   , EmailDate
								   , OutputTableName
								   , IronOfferID

	/*******************************************************************************************************************************************
		10. Table clear down
	*******************************************************************************************************************************************/

							TRUNCATE TABLE Selections.CampaignSetup_PartnerDedupe_DD

							UPDATE [Selections].[CampaignExecution_OutputTables]
							SET InPartnerDedupe = 0

							IF OBJECT_ID('tempdb..##TopPartnerOffer') IS NOT NULL DROP TABLE ##TopPartnerOffer

					END	--	8. WHILE @RunID <= @MaxID

				END	--	6. IF @RunType = 1
END

RETURN 0