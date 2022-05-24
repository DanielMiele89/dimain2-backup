
/***********************************************************************************************************************
Title: Auto-Generation of all PreSelections table for upcoming campaigns
Author: Rory Francis
Creation Date: 20 July 2018
Purpose: Run through each of the upcoming cmapigns AND run their required bespoke code to populate PreSelections tables

------------------------------------------------------------------------------------------------------------------------

Modified Log:

Change No:	Name:			Date:			Description of change:

											
***********************************************************************************************************************/

CREATE PROCEDURE [Selections].[CampaignSetup_PreSelections_POS] @EmailDate DATE

AS
BEGIN
	
	SET NOCOUNT ON

	--	DECLARE @EmailDate DATE = '2021-07-01'

	/*******************************************************************************************************************************************
		1.	Store all camapigns to be run in this cycle
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#AllCampaigns') IS NOT NULL DROP TABLE #AllCampaigns
		SELECT	ID
			,	PartnerID
			,	ClientServicesRef
			,	OfferID
			,	NotIn_TableName1
			,	MustBeIn_TableName1
			,	sProcPreSelection
			,	PriorityFlag
			,	NewCampaign
			,	CustomerBaseOfferDate
			,	SelectionRun
			,	ReadyToRun
		INTO #AllCampaigns
		FROM [Selections].[CampaignSetup_POS]
		WHERE EmailDate = @EmailDate

		CREATE CLUSTERED INDEX CIX_PartnerID ON #AllCampaigns (PartnerID)

	/*******************************************************************************************************************************************
		2.	Fetch campaigns requiring preselection to be run
	*******************************************************************************************************************************************/
	
			/***********************************************************************************************************************
				2.1.	Place all camapigns requiring preselection into holding table, add entry for Europcar's card type split
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#PreSelectionsToRun') IS NOT NULL DROP TABLE #PreSelectionsToRun
				CREATE TABLE #PreSelectionsToRun (RunID INT
												, PartnerID INT
												, ClientServicesRef VARCHAR(10)
												, NotIn_TableName1 VARCHAR(100) NULL
												, MustBeIn_TableName1 VARCHAR(100) NULL
												, sProcPreSelection VARCHAR(150) NULL
												, sProcPreSelectionCounts BIGINT NULL)
			
				;WITH
				PreSelectionsToRun AS (	SELECT	PartnerID
											,	ClientServicesRef
											,	NotIn_TableName1
											,	MustBeIn_TableName1
											,	sProcPreSelection
											,	MIN(PriorityFlag) AS PriorityFlag
										FROM #AllCampaigns
										WHERE ReadyToRun = 1
										AND sProcPreSelection != ''
										AND SelectionRun = 0
										GROUP BY	PartnerID
												,	ClientServicesRef
												,	NotIn_TableName1
												,	MustBeIn_TableName1
												,	sProcPreSelection)

				INSERT INTO #PreSelectionsToRun
				SELECT	 DISTINCT
						 DENSE_RANK() OVER (ORDER BY PartnerID, PriorityFlag) AS RunID
					,	 PartnerID
					,	 ClientServicesRef
					,	 NotIn_TableName1
					,	 MustBeIn_TableName1
					,	 sProcPreSelection
					,	 CONVERT(BIGINT, NULL) AS sProcPreSelectionCounts
				FROM PreSelectionsToRun
				ORDER BY RunID
	
			/***********************************************************************************************************************
				2.2.	List PreSelections to be ran
			***********************************************************************************************************************/

				SELECT 'PreSelections to run through' AS [Result set displayed below]
				SELECT *
				FROM #PreSelectionsToRun
				ORDER BY RunID


	/*******************************************************************************************************************************************
		3.	Loop through each of the campaigns requiring preselection and run the bespoke code
	*******************************************************************************************************************************************/

		DECLARE @RunID INT
			,	@MaxRunID INT
			,	@PreSelectionsProc VARCHAR(250)
			,	@PreSelectionTable VARCHAR(250)
			,	@CreateIndex VARCHAR(500)
			,	@PreSelectionRowCount VARCHAR(50)
			,	@TableName VARCHAR(500)

		SELECT @RunID = 1
			 , @MaxRunID = Max(RunID)
		FROM #PreSelectionsToRun
			
			WHILE @RunID <= @MaxRunID 
				BEGIN

					SELECT @PreSelectionsProc = sProcPreSelection
					FROM #PreSelectionsToRun
					WHERE RunID = @RunID

					EXEC @PreSelectionsProc

					SET @PreSelectionRowCount = (SELECT @@ROWCOUNT)

					UPDATE #PreSelectionsToRun
					SET sProcPreSelectionCounts = @PreSelectionRowCount
					WHERE RunID = @RunID

					SELECT @TableName = CASE
											WHEN LEN(MustBeIn_TableName1) < 5 THEN NotIn_TableName1
											ELSE MustBeIn_TableName1
										END
					FROM #PreSelectionsToRun
					WHERE RunID = @RunID

					SET @CreateIndex = 'Create Index CIX_Fan on ' + @TableName + ' (FanID)'

					If @RunID > 1
						BEGIN
							If IndexProperty(Object_Id(@TableName), 'CIX_Fan', 'IndexID') IS NULL EXEC (@CreateIndex)
						END

					SELECT @RunID = Min(RunID)
					FROM #PreSelectionsToRun
					WHERE RunID > @RunID

				END	--	@RunID <= @MaxRunID

		SELECT 'PreSelections ran'
		SELECT *
		FROM #PreSelectionsToRun
		ORDER BY RunID


	/*******************************************************************************************************************************************
		4. Fetch all current segmentation
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			4.1.	Store all camapigns to be run in this execution
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CurrentCustomerSegment') IS NOT NULL DROP TABLE #CurrentCustomerSegment
			SELECT	DISTINCT
					ac.PartnerID
			INTO #CurrentCustomerSegment
			FROM #AllCampaigns ac
			WHERE SelectionRun = 0
			AND ReadyToRun = 1

			CREATE CLUSTERED INDEX CIX_PartnerID ON #CurrentCustomerSegment (PartnerID)


		/***********************************************************************************************************************
			4.2.	Fetch the existing segmentation from Roc_Shopper_Segment_Members
		***********************************************************************************************************************/
	
			IF INDEXPROPERTY(OBJECT_ID('[Segmentation].[CurrentCustomerSegment]'), 'CSX_All', 'IndexId') IS NOT NULL
				BEGIN
					DROP INDEX [CSX_All] ON [Segmentation].[CurrentCustomerSegment]
				END

			EXEC('	TRUNCATE TABLE [Segmentation].[CurrentCustomerSegment]
					INSERT INTO [Segmentation].[CurrentCustomerSegment] (PartnerID, FanID, ShopperSegmentTypeID)
					SELECT	PartnerID
						,	FanID
						,	ShopperSegmentTypeID
					FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
					WHERE EXISTS (	SELECT 1
									FROM #CurrentCustomerSegment ccs
									WHERE sg.PartnerID = ccs.PartnerID)
					AND EXISTS (SELECT 1
								FROM [Derived].[Customer] cu
								WHERE cu.FanID = sg.FanID
								AND cu.CurrentlyActive = 1)
					AND sg.EndDate IS NULL
				
					UPDATE STATISTICS [Segmentation].[CurrentCustomerSegment]')

			IF INDEXPROPERTY(OBJECT_ID('[Segmentation].[CurrentCustomerSegment]'), 'CSX_All', 'IndexId') IS NULL
				BEGIN
					CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_All] ON [Segmentation].[CurrentCustomerSegment] ([PartnerID]
																											,	[FanID]
																											,	[ShopperSegmentTypeID])
				END

	/*******************************************************************************************************************************************
		5.	Store all CustomerBaseOfferDate memberships
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			5.1.	Store all camapigns to be run in this execution
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#ExistingUniverseOffers') IS NOT NULL DROP TABLE #ExistingUniverseOffers
			SELECT	DISTINCT
					ac.CustomerBaseOfferDate
				,	iof.Item AS IronOfferID
			INTO #ExistingUniverseOffers
			FROM #AllCampaigns ac
			CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
			WHERE iof.Item > 0
			AND ac.ReadyToRun = 1
			AND ac.SelectionRun = 0

			CREATE CLUSTERED INDEX CIX_IronOfferID ON #ExistingUniverseOffers (CustomerBaseOfferDate, IronOfferID)


		/***********************************************************************************************************************
			5.2.	Fetch the existing memberships from IronOfferMember
		***********************************************************************************************************************/

			IF INDEXPROPERTY(OBJECT_ID('[Selections].[CampaignExecution_ExistingUniverse]'), 'CSX_All', 'IndexId') IS NOT NULL
				BEGIN
					DROP INDEX [CSX_All] ON [Selections].[CampaignExecution_ExistingUniverse]
				END

			EXEC('	TRUNCATE TABLE [Selections].[CampaignExecution_ExistingUniverse]
					INSERT INTO [Selections].[CampaignExecution_ExistingUniverse] (IronOfferID, StartDate, CompositeID)
					SELECT	iom.IronOfferID
						,	iom.StartDate
						,	iom.CompositeID
					FROM [Derived].[IronOfferMember] iom
					WHERE EXISTS (SELECT 1
								  FROM #ExistingUniverseOffers euo
								  WHERE iom.IronOfferID = euo.IronOfferID
								  AND euo.CustomerBaseOfferDate <= iom.StartDate)

					UPDATE STATISTICS [Selections].[CampaignExecution_ExistingUniverse]')

			IF INDEXPROPERTY(OBJECT_ID('[Selections].[CampaignExecution_ExistingUniverse]'), 'CSX_All', 'IndexId') IS NULL
				BEGIN
					CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_All] ON [Selections].[CampaignExecution_ExistingUniverse] (	[IronOfferID]
																														,	[StartDate]
																														,	[CompositeID])
				END


END