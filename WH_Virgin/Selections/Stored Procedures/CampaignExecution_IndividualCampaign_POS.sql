
CREATE PROCEDURE [Selections].[CampaignExecution_IndividualCampaign_POS] (	@PartnerID CHAR(4)
																		,	@StartDate VARCHAR(10)
																		,	@EndDate VARCHAR(10)
																		,	@CampaignName VARCHAR (250)
																		,	@ClientServicesRef VARCHAR(10)
																		,	@OfferID VARCHAR(40)
																		,	@Throttling VARCHAR(200)
																		,	@ThrottleType CHAR(1)
																		,	@RandomThrottle CHAR(1)
																		,	@MarketableByEmail VARCHAR(10)
																		,	@Gender VARCHAR(10)
																		,	@AgeRange VARCHAR(7)
																		,	@DriveTimeMins CHAR(3)
																		,	@LiveNearAnyStore CHAR(1)
																		,	@SocialClass VARCHAR(5)
																		,	@CustomerBaseOfferDate VARCHAR(10)
																		,	@SelectedInAnotherCampaign VARCHAR(20)
																		,	@DeDupeAgainstCampaigns VARCHAR(50)
																		,	@CampaignID_Include CHAR(3)
																		,	@CampaignID_Exclude CHAR(3)
																		,	@OutputTableName VARCHAR (100)
																		,	@NotIn_TableName1 VARCHAR(100)
																		,	@NotIn_TableName2 VARCHAR(100)
																		,	@NotIn_TableName3 VARCHAR(100)
																		,	@NotIn_TableName4 VARCHAR(100)
																		,	@MustBeIn_TableName1 VARCHAR(100)
																		,	@MustBeIn_TableName2 VARCHAR(100)
																		,	@MustBeIn_TableName3 VARCHAR(100)
																		,	@MustBeIn_TableName4 VARCHAR(100)
																		,	@NewCampaign CHAR(1)
																		,	@FreqStretch_TransCount INT
																		,	@ControlGroupPercentage INT)

AS
BEGIN

/****************************************************************************************************
Title:			[Selections].[CampaignExecution_IndividualCampaign_POS]
Author:			Rory Francis
Creation Date:	2019-02-05
Purpose:		Looped selection of an indivdual Point of Sale Offer
-----------------------------------------------------------------------------------------------------
Modified Log:

Change No:	Name:			Date:			Description of change:

			
****************************************************************************************************/

/*

DECLARE @TestID INT = (SELECT MIN(ID) FROM [Selections].[CampaignSetup_POS] WHERE PartnerID = (SELECT MIN(PartnerID) FROM [Selections].[CampaignExecution_CustomerBase] cb) AND EmailDate > GETDATE())


DECLARE @PartnerID CHAR(4)
	  , @StartDate VARCHAR(10)
	  , @EndDate VARCHAR(10)
	  , @CampaignName VARCHAR (250)
	  , @ClientServicesRef VARCHAR(10)
	  , @OfferID VARCHAR(40)
	  , @Throttling VARCHAR(200)
	  , @ThrottleType CHAR(1)
	  , @RandomThrottle CHAR(1)
	  , @MarketableByEmail VARCHAR(10)
	  , @Gender VARCHAR(10)
	  , @AgeRange VARCHAR(7)
	  , @DriveTimeMins CHAR(3)
	  , @LiveNearAnyStore CHAR(1)
	  , @SocialClass VARCHAR(5)
	  , @OutletSector CHAR(6)
	  , @CustomerBaseOfferDate VARCHAR(10)
	  , @SelectedInAnotherCampaign VARCHAR(20)
	  , @DeDupeAgainstCampaigns VARCHAR(50)
	  , @CampaignID_Include CHAR(3)
	  , @CampaignID_Exclude CHAR(3)
	  , @OutputTableName VARCHAR (100)
	  , @NotIn_TableName1 VARCHAR(100)
	  , @NotIn_TableName2 VARCHAR(100)
	  , @NotIn_TableName3 VARCHAR(100)
	  , @NotIn_TableName4 VARCHAR(100)
	  , @MustBeIn_TableName1 VARCHAR(100)
	  , @MustBeIn_TableName2 VARCHAR(100)
	  , @MustBeIn_TableName3 VARCHAR(100)
	  , @MustBeIn_TableName4 VARCHAR(100)
	  , @NewCampaign CHAR(1)
	  , @CampaignTypeID CHAR(1)
	  , @FreqStretch_TransCount INT
	  , @ControlGroupPercentage INT

SELECT @PartnerID = PartnerID
	 , @StartDate = StartDate
	 , @EndDate = EndDate
	 , @CampaignName = CampaignName
	 , @ClientServicesRef = ClientServicesRef
	 , @OfferID = OfferID
	 , @Throttling = Throttling
	 , @ThrottleType = ThrottleType
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
	 , @FreqStretch_TransCount = FreqStretch_TransCount
	 , @ControlGroupPercentage = ControlGroupPercentage
FROM [Selections].[CampaignSetup_POS]
WHERE ID = 8878

*/

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT


	/*******************************************************************************************************************************************
		1. Prepare parameters for script
	*******************************************************************************************************************************************/
	
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Start CampaignExecution_IndividualCampaign_POS';
		EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

		DECLARE @SocialClassFilter VARCHAR(10) = @SocialClass 

		IF @MarketableByEmail = '' SET @MarketableByEmail = '0,1'
		IF @Gender = '' SET @Gender = 'U,M,F'
		IF @AgeRange = '' SET @AgeRange = '0-999'
		IF @SocialClass = '' SET @SocialClass = 'AB-DE'

		DECLARE @Offer1 INT
			  , @Offer2 INT
			  , @Offer3 INT
			  , @Offer4 INT
			  , @Offer5 INT
			  , @Offer6 INT
			  , @ShopperSegments VARCHAR(15)
			  , @ShopperSegment VARCHAR(15) = 7
			  , @MustBeIn_TableCount INT = 0
			  , @Dedupe BIT = 1
			  , @HomemoverDate DATE = DATEADD(day, -31, @StartDate)
			  , @ActivatedDate DATE = DATEADD(day, -31, @StartDate)
			  , @EndDateTime DATETIME = DATEADD(second, -1, CONVERT(DATETIME, DATEADD(day, 1, @EndDate)))
			  , @AgeRange_Min INT = LEFT(@AgeRange, CHARINDEX('-', @AgeRange) - 1)
			  , @AgeRange_Max INT = RIGHT(@AgeRange, LEN(@AgeRange) - CHARINDEX('-', @AgeRange))
			  , @SocialClass_Min VARCHAR(5) = LEFT(@SocialClass, CHARINDEX('-', @SocialClass) - 1)
			  , @SocialClass_Max VARCHAR(5) = RIGHT(@SocialClass, LEN(@SocialClass) - CHARINDEX('-', @SocialClass))
			  , @TotalCustomers INT = (SELECT COUNT(*) FROM [Derived].[Customer])
			  , @IsThrottleApplied INT = 0
			  , @FreqStretch_TransDate DATE = DATEADD(day, -56, @StartDate)
			  , @ControlGroupEndDate DATE = (SELECT MAX([Selections].[CampaignSetup_POS].[EndDate]) FROM [Selections].[CampaignSetup_POS] WHERE [Selections].[CampaignSetup_POS].[ClientServicesRef] = @ClientServicesRef)
			  

	/*******************************************************************************************************************************************
		2. Create tables to hold details previously held in comma seperated column
	*******************************************************************************************************************************************/
			
			/***********************************************************************************************************************
				2.1. Offer details
			***********************************************************************************************************************/

			
				IF OBJECT_ID('tempdb..#OfferIDs') IS NOT NULL DROP TABLE #OfferIDs
				CREATE TABLE #OfferIDs (ShopperSegmentTypeID INT
									  , IronOfferID INT
									  , Throttling INT);

				WITH OfferIDs AS (SELECT '7,8,9,10,11,12' AS ShopperSegmentTypeID
									   , @OfferID AS IronOfferID
									   , @Throttling AS Throttling)


				INSERT INTO #OfferIDs (#OfferIDs.[ShopperSegmentTypeID]
									 , #OfferIDs.[IronOfferID]
									 , #OfferIDs.[Throttling])
				SELECT sst.Item AS ShopperSegmentTypeID
					 , iof.Item AS IronOfferID
					 , CASE
							WHEN thr.Item = 0 THEN @TotalCustomers
							ELSE thr.Item
					   END AS Throttling
				FROM OfferIDs
				CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] ([OfferIDs].[ShopperSegmentTypeID], ',') sst
				CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (IronOfferID, ',') iof
				CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (Throttling, ',') thr
				WHERE sst.ItemNumber = iof.ItemNumber
				AND iof.ItemNumber = thr.ItemNumber
				AND iof.Item > 0
		
				CREATE CLUSTERED INDEX CIX_ShopperSegmentTypeID on #OfferIDs (ShopperSegmentTypeID)

			
					/***********************************************************************************************************************
						2.1.1. If PartnerID does not match the PartnerID linked to each offer then exit
					***********************************************************************************************************************/
					
							IF EXISTS (SELECT 1
									   FROM #OfferIDs o
									   INNER JOIN [Derived].[IronOffer] iof
										   ON o.IronOfferID = iof.IronOfferID
										   AND iof.PartnerID != @PartnerID)
								BEGIN
									PRINT 'PartnerID linked to campaign does not match the PartnerID the selected offers have been set up under'
									RETURN
								END

			
					/***********************************************************************************************************************
						2.1.2. Check whether there is any throttling
					***********************************************************************************************************************/
			
						SELECT @IsThrottleApplied = CASE WHEN SUM(#OfferIDs.[Throttling]) = COUNT(*) * @TotalCustomers THEN 0 ELSE 1 END
						FROM #OfferIDs

			/***********************************************************************************************************************
				2.2. Gender details
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#Gender') IS NOT NULL DROP TABLE #Gender
				CREATE TABLE #Gender (Gender VARCHAR(1));

				WITH Gender AS (SELECT @Gender AS Gender)
				
				INSERT INTO #Gender (#Gender.[Gender])
				SELECT [Warehouse].[dbo].[il_SplitDelimitedStringArray].[Item] AS Gender
				FROM Gender
				CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (Gender, ',') ge
		
				CREATE CLUSTERED INDEX CIX_Gender_Gender on #Gender (Gender)
			
			/***********************************************************************************************************************
				2.3. Marketable By Email details
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#MarketableByEmail') IS NOT NULL DROP TABLE #MarketableByEmail
				CREATE TABLE #MarketableByEmail (MarketableByEmail VARCHAR(1));

				WITH MarketableByEmail AS (SELECT @MarketableByEmail AS MarketableByEmail)
				
				INSERT INTO #MarketableByEmail (#MarketableByEmail.[MarketableByEmail])
				SELECT [Warehouse].[dbo].[il_SplitDelimitedStringArray].[Item] AS MarketableByEmail
				FROM MarketableByEmail
				CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (MarketableByEmail, ',') mbe
				
				CREATE CLUSTERED INDEX CIX_Gender on #MarketableByEmail (MarketableByEmail)
			
			/***********************************************************************************************************************
				2.3. Age range details
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#AgeRanges') IS NOT NULL DROP TABLE #AgeRanges
				SELECT @AgeRange_Min AS AgeCurrent
				INTO #AgeRanges

				WHILE @AgeRange_Min < @AgeRange_Max
					BEGIN
						SET @AgeRange_Min = @AgeRange_Min + 1

						INSERT INTO #AgeRanges
						SELECT @AgeRange_Min
					END

				CREATE CLUSTERED INDEX CIX_All ON #AgeRanges (AgeCurrent)
			
			/***********************************************************************************************************************
				2.4. Social class details
			***********************************************************************************************************************/
			
				IF OBJECT_ID('tempdb..#SocialClass') IS NOT NULL DROP TABLE #SocialClass
				SELECT DISTINCT
					   cc.Social_Class
				INTO #SocialClass
				FROM [Warehouse].[Relational].[CAMEO_CODE] cc
				WHERE cc.Social_Class BETWEEN @SocialClass_Min AND @SocialClass_Max

				CREATE CLUSTERED INDEX CIX_All ON #SocialClass (Social_Class)

				SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Extricating parameters'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
				

	/*******************************************************************************************************************************************
		3. Find customers already on or previously an offer for this partner
	*******************************************************************************************************************************************/
	
		/***********************************************************************************************************************
			3.1. Fetch all customers that are currently have an existing offer membership for this partner
		***********************************************************************************************************************/

					/***********************************************************************************************************************
						3.1.1. Fetch all live offers for this partner
					***********************************************************************************************************************/

						IF OBJECT_ID('tempdb..#LiveOfferPerPartner') IS NOT NULL DROP TABLE #LiveOfferPerPartner
						SELECT iof.IronOfferID
						INTO #LiveOfferPerPartner
						FROM [Derived].[IronOffer] iof
						WHERE [iof].[PartnerID] = @PartnerID
						AND (iof.EndDate > @StartDate OR iof.EndDate IS NULL)
						AND iof.IsSignedOff = 1

						SET @RowsAffected = @@ROWCOUNT;

						CREATE CLUSTERED INDEX CIX_IronOfferID ON #LiveOfferPerPartner (IronOfferID)
						
						SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Fetch all live offers for this partner [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
	
					/***********************************************************************************************************************
						3.1.2. Fetch all customers assigned offers for this partner
					***********************************************************************************************************************/

						IF OBJECT_ID('tempdb..#CustomersOnOfferAlready') IS NOT NULL DROP TABLE #CustomersOnOfferAlready
						SELECT	iom.CompositeID
						INTO #CustomersOnOfferAlready
						FROM [Derived].[IronOfferMember] iom
						INNER JOIN #LiveOfferPerPartner lopp
							ON iom.IronOfferID = lopp.IronOfferID
						WHERE iom.EndDate > @StartDate

						SET @RowsAffected = @@ROWCOUNT

						INSERT INTO #CustomersOnOfferAlready
						SELECT	iom.CompositeID
						FROM [Derived].[IronOfferMember] iom
						INNER JOIN #LiveOfferPerPartner lopp
							ON iom.IronOfferID = lopp.IronOfferID
						WHERE iom.EndDate IS NULL

						SET @RowsAffected = @@ROWCOUNT + @RowsAffected;

						CREATE CLUSTERED INDEX CIX_CompositeID ON #CustomersOnOfferAlready (CompositeID)

						SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Fetch all customers assigned offers for this partner [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
	
		/***********************************************************************************************************************
			3.2. Fetch control group customers
		***********************************************************************************************************************/
			
			IF OBJECT_ID ('tempdb..#ControlGroupCustomers') IS NOT NULL DROP TABLE #ControlGroupCustomers
			SELECT [cu].[CompositeID]
			INTO #ControlGroupCustomers
			FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] cg
			INNER JOIN [Derived].[Customer] cu
				ON cg.FanID = cu.FanID
			WHERE PartnerID = @PartnerID
			AND EndDate >= @StartDate

			SET @RowsAffected = @@ROWCOUNT;
			
			CREATE CLUSTERED INDEX CIX_CompositeID ON #ControlGroupCustomers (CompositeID) WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
			
			SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Fetch control group customers [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

		/*******************************************************************************************************************************************
			3.3. Exec competitior steal campaigns where required
		*******************************************************************************************************************************************/
	
			--IF @CampaignID_Include != ''
			--	BEGIN
			--		EXEC Warehouse.Selections.Partner_GenerateTriggerMember @CampaignID_Include
			--	END

			--IF @CampaignID_Exclude != ''
			--	BEGIN
			--		EXEC Warehouse.Selections.Partner_GenerateTriggerMember @CampaignID_Exclude
			--	END

			SET @RowsAffected = @@ROWCOUNT;
			SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Exec competitior steal campaigns - NOT RUNNING [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT


		/*******************************************************************************************************************************************
			3.4. If campaign is targeting universe of previous campaign then fetch those customers
		*******************************************************************************************************************************************/
		
			IF @SelectedInAnotherCampaign != ''
				BEGIN
				
					/***********************************************************************************************************************
						3.4.1. Create table storing each ClientServiceReference to build universe from
					***********************************************************************************************************************/
	
						IF OBJECT_ID('tempdb..#SelectedInAnotherCampaign') IS NOT NULL DROP TABLE #SelectedInAnotherCampaign
						CREATE TABLE #SelectedInAnotherCampaign (ClientServicesRef VARCHAR(250));
	
						WITH SelectedInAnotherCampaign AS (SELECT @SelectedInAnotherCampaign AS ClientServicesRef)
					
						INSERT INTO #SelectedInAnotherCampaign (#SelectedInAnotherCampaign.[ClientServicesRef])
						SELECT [Warehouse].[dbo].[il_SplitDelimitedStringArray].[Item] AS ClientServicesRef
						FROM SelectedInAnotherCampaign
						CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (ClientServicesRef, ',') mbe
	
						CREATE CLUSTERED INDEX CIX_SelectedInAnotherCampaign_ClientServicesRef ON #SelectedInAnotherCampaign (ClientServicesRef)

								
					/***********************************************************************************************************************
						3.4.2. Store customers that have been previously exposed to the given campaigns
					***********************************************************************************************************************/
	
						IF OBJECT_ID('tempdb..#SelectedInAnotherCampaignCustomers') IS NOT NULL DROP TABLE #SelectedInAnotherCampaignCustomers
						SELECT DISTINCT
							   iom.CompositeID
						INTO #SelectedInAnotherCampaignCustomers
						FROM [Derived].[IronOfferMember] iom
						WHERE EXISTS (SELECT 1
									  FROM #SelectedInAnotherCampaign siac
									  INNER JOIN [Derived].[IronOffer_Campaign_HTM] htm
										  ON siac.ClientServicesRef = htm.ClientServicesRef
									  Where #SelectedInAnotherCampaign.[iom].IronOfferID = htm.IronOfferID)

						SET @RowsAffected = @@ROWCOUNT

				
					/***********************************************************************************************************************
						3.4.3. Add in customers that have joined since that point if there's a welcome offer running
					***********************************************************************************************************************/

						IF EXISTS (SELECT 1 FROM #OfferIDs WHERE #OfferIDs.[ShopperSegmentTypeID] = 10)
							BEGIN

								INSERT INTO #SelectedInAnotherCampaignCustomers
								SELECT c.CompositeID
								FROM [Selections].[CampaignExecution_CustomerBase] c
								WHERE c.ActivatedDate > @ActivatedDate

								SET @RowsAffected = @@ROWCOUNT + @RowsAffected


							END					
	
						CREATE CLUSTERED INDEX CIX_MustBeIn_CompositeID ON #SelectedInAnotherCampaignCustomers (CompositeID) WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
	
						SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - If campaign is targeting universe of previous campaign then fetch those customers [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
	
				END	--	IF @SelectedInAnotherCampaign != ''
			


		/*******************************************************************************************************************************************
			3.5. Find customers previously selected in this campaign
		*******************************************************************************************************************************************/
		
			IF @CustomerBaseOfferDate IS NOT NULL
				BEGIN
		
					/***********************************************************************************************************************
						3.5.1. Fetch all offers that have run in this campaign
					***********************************************************************************************************************/
	
						IF OBJECT_ID('tempdb..#ExistingUniverseOffers') IS NOT NULL DROP TABLE #ExistingUniverseOffers
						SELECT Distinct
							   iof.IronOfferID
						INTO #ExistingUniverseOffers
						FROM [Derived].[IronOffer] iof
						INNER JOIN [Derived].[IronOffer_Campaign_HTM] htm
							ON iof.IronOfferID = htm.IronOfferID
						WHERE htm.ClientServicesRef = @ClientServicesRef
	
						CREATE CLUSTERED INDEX CIX_IronOfferID ON #ExistingUniverseOffers (IronOfferID)
		
					/***********************************************************************************************************************
						3.5.2. Fetch all customers that have been assigned any of the previous offers
					***********************************************************************************************************************/
	
						IF OBJECT_ID ('tempdb..#ExistingUniverse') IS NOT NULL DROP TABLE #ExistingUniverse
						SELECT eu.CompositeID
						INTO #ExistingUniverse
						FROM [Selections].[CampaignExecution_ExistingUniverse] eu
						WHERE EXISTS (	SELECT 1
										FROM #ExistingUniverseOffers euo
										WHERE #ExistingUniverseOffers.[eu].IronOfferID = euo.IronOfferID
										AND @CustomerBaseOfferDate <= #ExistingUniverseOffers.[eu].StartDate)

						SET @RowsAffected = @@ROWCOUNT
	
				
					/***********************************************************************************************************************
						3.5.3. Add in customers that have joined since that point if there's a welcome offer running
					***********************************************************************************************************************/

						IF EXISTS (SELECT 1 FROM #OfferIDs WHERE #OfferIDs.[ShopperSegmentTypeID] = 10)
							BEGIN

								INSERT INTO #ExistingUniverse
								SELECT c.CompositeID
								FROM [Selections].[CampaignExecution_CustomerBase] c
								WHERE c.ActivatedDate > @ActivatedDate

								SET @RowsAffected = @@ROWCOUNT + @RowsAffected

							END					
	
						CREATE CLUSTERED INDEX CIX_MustBeIn_CompositeID ON #ExistingUniverse (CompositeID) WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
						
						SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Find customers previously selected in this campaign [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
	
				END	--	IF @CustomerBaseOfferDate IS NOT NULL
				


		/*******************************************************************************************************************************************
			3.6. Find customers living within designated drivetime
		*******************************************************************************************************************************************/
				
			IF @LiveNearAnyStore = 1 AND @DriveTimeMins != ''
				BEGIN
		
					/***********************************************************************************************************************
						3.6.1. Fetch all postal sectors of the stores for this partner
					***********************************************************************************************************************/

						IF OBJECT_ID ('tempdb..#PostalSectors') IS NOT NULL DROP TABLE #PostalSectors
						SELECT DISTINCT
							   o.PostalSector
						INTO #PostalSectors
						FROM [Derived].[Outlet] o
						WHERE o.PartnerID = @PartnerID
						AND LEFT([o].[MerchantID], 1) NOT IN ('a', 'x', '#')
		
					/***********************************************************************************************************************
						3.6.2. Fetch all customers within desginated drive time of the previous postal sectors
					***********************************************************************************************************************/
					
						IF OBJECT_ID ('tempdb..#CustomersWithinDrivetime') IS NOT NULL DROP TABLE #CustomersWithinDrivetime
						SELECT DISTINCT
							   cu.CompositeID
						INTO #CustomersWithinDrivetime
						FROM [Derived].[Customer] cu
						INNER JOIN [Warehouse].[Relational].[DriveTimeMatrix] dtm
							ON cu.PostalSector = dtm.FROMSector
						INNER JOIN #PostalSectors ps
							ON #PostalSectors.[dtm].ToSector = ps.PostalSector
							AND #PostalSectors.[dtm].DriveTimeMins <= @DriveTimeMins
							
						SET @RowsAffected = @@ROWCOUNT;
						
						CREATE CLUSTERED INDEX CIX_CompositeID ON #CustomersWithinDrivetime (CompositeID)

						SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Find customers living within designated drivetime [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

				END	--	IF @LiveNearAnyStore = 1 AND @DriveTimeMins != ''


	/*******************************************************************************************************************************************
		4. Build customer base
	*******************************************************************************************************************************************/
			
		/***********************************************************************************************************************
			4.1. Fetch customer universe
		***********************************************************************************************************************/
				
			--SET @PartnerID = (SELECT MIN(PartnerID) FROM [Selections].[CampaignExecution_CustomerBase] cb)

			DECLARE @CustomerBaseQuery VARCHAR(MAX)

			SET @CustomerBaseQuery =	'IF OBJECT_ID (''tempdb..##CustomerBase_Virgin'') IS NOT NULL DROP TABLE ##CustomerBase_Virgin
										SELECT DISTINCT 
											   cb.FanID
											 , cb.CompositeID
											 , cb.ShopperSegmentTypeID
											 , CASE
													WHEN cgc.CompositeID IS NULL THEN 0
													ELSE 1
											   END AS ControlGroupCustomer
										INTO ##CustomerBase_Virgin
										FROM [Selections].[CampaignExecution_CustomerBase] cb
										LEFT JOIN #ControlGroupCustomers cgc
											ON cb.CompositeID = cgc.CompositeID
										WHERE NOT EXISTS (	SELECT 1
															FROM [Selections].[CampaignExecution_PartnerDedupe] pd
															WHERE cb.CompositeID = pd.CompositeID)'

			--	2.2. Gender details

			IF @Gender != 'U,M,F'
				BEGIN

					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM #Gender ge
														WHERE cb.Gender = ge.Gender)'
				END

			--	2.3. Marketable By Email details
				
			IF @MarketableByEmail != '0,1'
				BEGIN

					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM #MarketableByEmail mbe
														WHERE cb.MarketableByEmail = mbe.MarketableByEmail)'
				END
				
			--	2.3. Age range details

			IF @AgeRange != '0-999'
				BEGIN
					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM #AgeRanges ar
														WHERE cb.AgeCurrent = ar.AgeCurrent)'
				END
				
			--	2.4. Social class details

	
			IF @SocialClass != 'AB-DE'
				BEGIN
					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM [Warehouse].[Relational].[CAMEO] ca
														INNER JOIN [Warehouse].[Relational].[CAMEO_CODE] cc
															ON cc.CAMEO_CODE = ca.CAMEO_CODE
														INNER JOIN #SocialClass sc
															ON cc.Social_Class = sc.Social_Class
														WHERE cb.Postcode = ca.PostCode)'
				END

			--	3.1. Fetch all customers that are currently have an existing offer membership for this partner

			IF (SELECT COUNT(*) FROM #CustomersOnOfferAlready) > 0
				BEGIN
					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND NOT EXISTS (SELECT 1
														FROM #CustomersOnOfferAlready cooa
														WHERE cb.CompositeID = cooa.CompositeID)'
				END

			--	3.2. Fetch control group customers
			
			IF (SELECT COUNT(*) FROM #ControlGroupCustomers) > 0
				BEGIN
					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND NOT EXISTS (SELECT 1
														FROM #ControlGroupCustomers cgc
														WHERE cb.CompositeID = cgc.CompositeID)'
				END

			--	3.3. Exec competitior steal campaigns where required

			--IF @CampaignID_Include != ''
			--	BEGIN
			--		SET @CustomerBaseQuery = @CustomerBaseQuery + '
			--							AND EXISTS (	SELECT 1
			--											FROM [Relational].[PartnerTrigger_Members] ptm
			--											WHERE cb.FanID = ptm.FanID
			--											AND ptm.CampaignID = ' + @CampaignID_Include + ')'
			--	END
				
			--IF @CampaignID_Exclude != ''
			--	BEGIN
			--		SET @CustomerBaseQuery = @CustomerBaseQuery + '
			--							AND NOT EXISTS (SELECT 1
			--											FROM [Relational].[PartnerTrigger_Members] ptm
			--											WHERE cb.FanID = ptm.FanID
			--											AND ptm.CampaignID = ' + @CampaignID_Exclude + ')'
			--	END

			--	3.4. If campaign is targeting universe of previous campaign then fetch those customers
		
			IF @SelectedInAnotherCampaign != ''
				BEGIN
					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM #SelectedInAnotherCampaignCustomers siac
														WHERE cb.CompositeID = siac.CompositeID)'
				END

			--	3.5. Add in customers that have joined since that point if there's a welcome offer running

			IF @CustomerBaseOfferDate IS NOT NULL
				BEGIN
					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM #ExistingUniverse eu
														WHERE cb.CompositeID = eu.CompositeID)'
				END

			--	3.6. Find customers living within designated drivetime
			
			IF @LiveNearAnyStore = 1 AND @DriveTimeMins != ''
				BEGIN
					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM #CustomersWithinDrivetime eu
														WHERE cb.CompositeID = eu.CompositeID)'
				END

			EXEC(@CustomerBaseQuery)
			
			SET @RowsAffected = @@ROWCOUNT;

			CREATE CLUSTERED INDEX CIX_CompositeID ON ##CustomerBase_Virgin (CompositeID, ShopperSegmentTypeID, ControlGroupCustomer) WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
			CREATE NONCLUSTERED INDEX IX_FanID ON ##CustomerBase_Virgin (FanID) WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
			CREATE NONCLUSTERED INDEX IX_CompSeg ON ##CustomerBase_Virgin (CompositeID, ShopperSegmentTypeID) WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)

			SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Collecting ##CustomerBase_Virgin [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

		/***********************************************************************************************************************
			4.4. Update ShopperSegmentTypeID
		***********************************************************************************************************************/
			
			/***********************************************************************************************************************
				4.4.1. Update welcome details
			***********************************************************************************************************************/

				--IF EXISTS (SELECT 1 FROM #OfferIDs WHERE ShopperSegmentTypeID = 10)
				--	BEGIN

				--		UPDATE cb
				--		SET cb.ShopperSegmentTypeID = 10
				--		FROM ##CustomerBase_Virgin cb
				--		INNER JOIN [Selections].[CampaignExecution_CustomerBase] c
				--			ON cb.CompositeID = c.CompositeID
				--		WHERE c.ShopperSegmentTypeID NOT IN (10, 11, 12)
				--		AND c.ActivatedDate > @ActivatedDate

				--	END
			
				SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Update welcome details - NOT RUNNING [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT


			/***********************************************************************************************************************
				4.4.2. Update birthday details
			***********************************************************************************************************************/

				IF EXISTS (SELECT 1 FROM #OfferIDs WHERE #OfferIDs.[ShopperSegmentTypeID] = 11)
					BEGIN

						UPDATE cb
						SET cb.ShopperSegmentTypeID = 11
						FROM ##CustomerBase_Virgin cb
						INNER JOIN [Selections].[CampaignExecution_CustomerBase] c
							ON cb.CompositeID = c.CompositeID
						WHERE c.ShopperSegmentTypeID NOT IN (10, 11, 12)
						AND FLOOR(DATEDIFF(dd, DOB, @StartDate) / 365.25) != FLOOR(DATEDIFF(dd, DOB, @EndDate) / 365.25)
						
						SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Update birthday details [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

					END

			
			/***********************************************************************************************************************
				4.4.3. Update homemover details
			***********************************************************************************************************************/

				IF EXISTS (SELECT 1 FROM #OfferIDs WHERE #OfferIDs.[ShopperSegmentTypeID] = 12)
					BEGIN

						UPDATE cb
						SET cb.ShopperSegmentTypeID = 12
						FROM ##CustomerBase_Virgin cb
						INNER JOIN [Selections].[CampaignExecution_CustomerBase] c
							ON cb.CompositeID = c.CompositeID
						WHERE cb.ShopperSegmentTypeID NOT IN (10, 11, 12)
						AND EXISTS (SELECT 1 
									FROM [Derived].Homemover_Details hm
									WHERE ##CustomerBase_Virgin.[hm].LoadDate >= @HomemoverDate
									AND cb.FanID = ##CustomerBase_Virgin.[hm].FanID)

						SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Update homemover details [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

					END

			
		/***********************************************************************************************************************
			4.5. Indexing ##CustomerBase_Virgin
		***********************************************************************************************************************/

			ALTER INDEX CIX_CompositeID ON ##CustomerBase_Virgin REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
			ALTER INDEX IX_FanID ON ##CustomerBase_Virgin REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
			ALTER INDEX IX_CompSeg ON ##CustomerBase_Virgin REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
			
			SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Indexing ##CustomerBase_Virgin'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
			

	/*******************************************************************************************************************************************
		9. Fetch customers from the MustBeIn tables
	*******************************************************************************************************************************************/

		DECLARE @SQLCode_MustBeIn VARCHAR(MAX)

		IF OBJECT_ID(@MustBeIn_TableName1) IS NOT NULL SET @MustBeIn_TableCount = @MustBeIn_TableCount + 1
		IF OBJECT_ID(@MustBeIn_TableName2) IS NOT NULL SET @MustBeIn_TableCount = @MustBeIn_TableCount + 1
		IF OBJECT_ID(@MustBeIn_TableName3) IS NOT NULL SET @MustBeIn_TableCount = @MustBeIn_TableCount + 1
		IF OBJECT_ID(@MustBeIn_TableName4) IS NOT NULL SET @MustBeIn_TableCount = @MustBeIn_TableCount + 1

		IF @MustBeIn_TableCount > 0
			BEGIN
	
				/***********************************************************************************************************************
					9.1. For each existing preselection table insert the customers into a holding table
				***********************************************************************************************************************/

					IF OBJECT_ID('tempdb..#MustBeIn_TableName_Temp') IS NOT NULL DROP TABLE #MustBeIn_TableName_Temp
					CREATE TABLE #MustBeIn_TableName_Temp (FanID BIGINT)

					IF OBJECT_ID(@MustBeIn_TableName1) IS NOT NULL
						BEGIN
							SET @SQLCode_MustBeIn = 'INSERT INTO #MustBeIn_TableName_Temp SELECT FanID FROM ' + @MustBeIn_TableName1
							EXEC (@SQLCode_MustBeIn)
						END

					IF OBJECT_ID(@MustBeIn_TableName2) IS NOT NULL
						BEGIN
							SET @SQLCode_MustBeIn = 'INSERT INTO #MustBeIn_TableName_Temp SELECT FanID FROM ' + @MustBeIn_TableName2
							EXEC (@SQLCode_MustBeIn)
						END

					IF OBJECT_ID(@MustBeIn_TableName3) IS NOT NULL
						BEGIN
							SET @SQLCode_MustBeIn = 'INSERT INTO #MustBeIn_TableName_Temp SELECT FanID FROM ' + @MustBeIn_TableName3
							EXEC (@SQLCode_MustBeIn)
						END

					IF OBJECT_ID(@MustBeIn_TableName4) IS NOT NULL
						BEGIN
							SET @SQLCode_MustBeIn = 'INSERT INTO #MustBeIn_TableName_Temp SELECT FanID FROM ' + @MustBeIn_TableName4
							EXEC (@SQLCode_MustBeIn)
						END

					IF OBJECT_ID('tempdb..#MustBeIn_TableName') IS NOT NULL DROP TABLE #MustBeIn_TableName
					SELECT #MustBeIn_TableName_Temp.[FanID]
					INTO #MustBeIn_TableName
					FROM #MustBeIn_TableName_Temp
					GROUP BY #MustBeIn_TableName_Temp.[FanID]
					HAVING COUNT(1) = @MustBeIn_TableCount

					CREATE CLUSTERED INDEX CIX_MustBeIn_FanID ON #MustBeIn_TableName (FanID)

				/***********************************************************************************************************************
					9.2. Remove customers that have not been preselected
				***********************************************************************************************************************/

					DELETE cb
					FROM ##CustomerBase_Virgin cb
					WHERE NOT EXISTS (SELECT 1
									  FROM #MustBeIn_TableName mbi
									  WHERE #MustBeIn_TableName.[cb].FanID = mbi.FanID)
					
					SET @RowsAffected = @@ROWCOUNT;
					SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Fetch customers from the MustBeIn tables [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
			
			END	--	IF @MustBeIn_TableCount > 0
			

	/*******************************************************************************************************************************************
		10. Fetch customers from the NotIn tables
	*******************************************************************************************************************************************/
	
		DECLARE @SQLCode_NotIn VARCHAR(MAX)

		IF LEN(@NotIn_TableName1 + @NotIn_TableName2 + @NotIn_TableName3 + @NotIn_TableName4) > 0
			BEGIN
	
				/***********************************************************************************************************************
					10.1. For each existing preselection table insert the customers into a holding table
				***********************************************************************************************************************/

					IF OBJECT_ID('tempdb..#NotIn_TableName') IS NOT NULL DROP TABLE #NotIn_TableName
					CREATE TABLE #NotIn_TableName (FanID BIGINT)

					IF OBJECT_ID(@NotIn_TableName1) IS NOT NULL
						BEGIN
							SET @SQLCode_NotIn = 'INSERT INTO #NotIn_TableName SELECT FanID FROM ' + @NotIn_TableName1
							EXEC (@SQLCode_NotIn)
						END

					IF OBJECT_ID(@NotIn_TableName2) IS NOT NULL
						BEGIN
							SET @SQLCode_NotIn = 'INSERT INTO #NotIn_TableName SELECT FanID FROM ' + @NotIn_TableName2
							EXEC (@SQLCode_NotIn)
						END

					IF OBJECT_ID(@NotIn_TableName3) IS NOT NULL
						BEGIN
							SET @SQLCode_NotIn = 'INSERT INTO #NotIn_TableName SELECT FanID FROM ' + @NotIn_TableName3
							EXEC (@SQLCode_NotIn)
						END

					IF OBJECT_ID(@NotIn_TableName4) IS NOT NULL
						BEGIN
							SET @SQLCode_NotIn = 'INSERT INTO #NotIn_TableName SELECT FanID FROM ' + @NotIn_TableName4
							EXEC (@SQLCode_NotIn)
						END

			
				/***********************************************************************************************************************
					10.2. Remove customers that have not been preselected
				***********************************************************************************************************************/

					DELETE cb
					FROM ##CustomerBase_Virgin cb
					WHERE EXISTS (SELECT 1
								  FROM #NotIn_TableName ni
								  WHERE #NotIn_TableName.[cb].FanID = ni.FanID)
					
					SET @RowsAffected = @@ROWCOUNT;
					SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Fetch customers from the NotIn tables [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
			

			END	--	IF LEN(@NotIn_TableName1 + @NotIn_TableName2 + @NotIn_TableName3 + @NotIn_TableName4) > 0


	/*******************************************************************************************************************************************
		11. Remove customers that have meet the designated amount of purchases per campaign
	*******************************************************************************************************************************************/
	
		IF @FreqStretch_TransCount > 0
			BEGIN

				IF OBJECT_ID('tempdb..#CustomersWithMultipleTrans') IS NOT NULL DROP TABLE #CustomersWithMultipleTrans
				SELECT pt.FanID
					 , pt.IronOfferID
					 , SUM(CASE
								WHEN [pt].[TransactionAmount] > 0 THEN 1
								ELSE -1
						   END) AS ValidTransactions
				INTO #CustomersWithMultipleTrans
				FROM [Derived].[PartnerTrans] pt
				WHERE EXISTS (SELECT 1
							  FROM #OfferIDs iof
							  WHERE #OfferIDs.[pt].IronOfferID = iof.IronOfferID)
				AND pt.TransactionDate > @FreqStretch_TransDate
				GROUP BY pt.IronOfferID
					   , pt.FanID
				HAVING COUNT(1) >= @FreqStretch_TransCount

				DELETE
				FROM #CustomersWithMultipleTrans
				WHERE #CustomersWithMultipleTrans.[ValidTransactions] < @FreqStretch_TransCount

				DELETE cb
				FROM ##CustomerBase_Virgin cb
				INNER JOIN #CustomersWithMultipleTrans cwmt
					ON cb.FanID = cwmt.FanID

				SET @RowsAffected = @@ROWCOUNT;
				SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Remove customers that have meet the designated amount of purchases per campaign [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
			
			END	--	IF @FreqStretch_TransCount > 0


	/*******************************************************************************************************************************************
		12. Output to assign offers and apply throttling if required
	*******************************************************************************************************************************************/
	
		IF @IsThrottleApplied = 1 AND @ThrottleType = '%'
			BEGIN
				IF OBJECT_ID('tempdb..#ThrottleUpdate') IS NOT NULL DROP TABLE #ThrottleUpdate
				SELECT oi.ShopperSegmentTypeID
					 , oi.Throttling
					 , COUNT(DISTINCT cb.FanID) AS Customers
				INTO #ThrottleUpdate
				FROM #OfferIDs oi
				INNER JOIN ##CustomerBase_Virgin cb
				   ON oi.ShopperSegmentTypeID = cb.ShopperSegmentTypeID
				GROUP BY oi.ShopperSegmentTypeID
					  , oi.Throttling

				UPDATE oi
				SET oi.Throttling = oi.Throttling * tu.Customers / 100.0
				FROM #OfferIDs oi
				INNER JOIN #ThrottleUpdate tu
					ON oi.ShopperSegmentTypeID = tu.ShopperSegmentTypeID
			END

		IF OBJECT_ID('tempdb..#Selection') IS NOT NULL DROP TABLE #Selection
		CREATE TABLE #Selection (FanID BIGINT
							   , CompositeID BIGINT
							   , ShopperSegmentTypeID INT
							   , IronOfferID INT
							   , StartDate DATETIME
							   , EndDate DATETIME)


		IF @IsThrottleApplied = 0
			BEGIN
				INSERT INTO #Selection
				SELECT cb.FanID
					 , cb.CompositeID
					 , cb.ShopperSegmentTypeID
					 , iof.IronOfferID
					 , @StartDate
					 , @EndDateTime
				FROM ##CustomerBase_Virgin cb
				INNER JOIN #OfferIDs iof
					ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
				WHERE ControlGroupCustomer = 0
			END

		IF @IsThrottleApplied = 1 AND @RandomThrottle = 0
			BEGIN
				INSERT INTO #Selection
				SELECT FanID
					 , CompositeID
					 , ShopperSegmentTypeID
					 , IronOfferID
					 , @StartDate
					 , @EndDateTime
				FROM (	SELECT cb.FanID
							 , cb.CompositeID
							 , cb.ShopperSegmentTypeID
							 , iof.IronOfferID
							 , iof.Throttling
							 , ROW_NUMBER() OVER (PARTITION BY iof.IronOfferID ORDER BY cr.Engagement_Rank ASC) AS RowNum
						FROM ##CustomerBase_Virgin cb
						INNER JOIN #OfferIDs iof
							ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
						LEFT JOIN [Derived].[Customer_EngagementScore] cr
							ON cb.FanID = cr.FanID
						WHERE ControlGroupCustomer = 0
						) cb
				WHERE [cb].[RowNum] <= Throttling
			END

			
		IF @IsThrottleApplied = 1 AND @RandomThrottle = 1
			BEGIN
				INSERT INTO #Selection
				SELECT FanID
					 , CompositeID
					 , ShopperSegmentTypeID
					 , IronOfferID
					 , @StartDate
					 , @EndDateTime
				FROM (	SELECT cb.FanID
							 , cb.CompositeID
							 , cb.ShopperSegmentTypeID
							 , iof.IronOfferID
							 , iof.Throttling
							 , ROW_NUMBER() OVER (PARTITION BY iof.IronOfferID ORDER BY ABS(CHECKSUM(NewID())) ASC) AS RowNum
						FROM ##CustomerBase_Virgin cb
						INNER JOIN #OfferIDs iof
							ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
						WHERE ControlGroupCustomer = 0) cb
				WHERE [cb].[RowNum] <= Throttling
			END
			
		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Output to assign offers and apply throttling if required [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		13. Create in programme control group
	*******************************************************************************************************************************************/
	
		IF @ControlGroupPercentage > 0
			BEGIN

				DECLARE @AcquireCount INT = ((SELECT COUNT(*) FROM #Selection WHERE #Selection.[ShopperSegmentTypeID] = 7) * 1.0 / 100) * @ControlGroupPercentage
					  , @LaspsedCount INT = ((SELECT COUNT(*) FROM #Selection WHERE #Selection.[ShopperSegmentTypeID] = 8) * 1.0 / 100) * @ControlGroupPercentage
					  , @ShopperCount INT = ((SELECT COUNT(*) FROM #Selection WHERE #Selection.[ShopperSegmentTypeID] = 9) * 1.0 / 100) * @ControlGroupPercentage
					  , @WelcomeCount INT = ((SELECT COUNT(*) FROM #Selection WHERE #Selection.[ShopperSegmentTypeID] = 10) * 1.0 / 100) * @ControlGroupPercentage
					  , @HomemoverCount INT = ((SELECT COUNT(*) FROM #Selection WHERE #Selection.[ShopperSegmentTypeID] = 11) * 1.0 / 100) * @ControlGroupPercentage
					  , @BirthdayCount INT = ((SELECT COUNT(*) FROM #Selection WHERE #Selection.[ShopperSegmentTypeID] = 12) * 1.0 / 100) * @ControlGroupPercentage

					 
				IF OBJECT_ID('tempdb..#ControlGroup_Setup') IS NOT NULL DROP TABLE #ControlGroup_Setup
				CREATE TABLE #ControlGroup_Setup (FanID BIGINT
												, ShopperSegmentTypeID TINYINT
												, IronOfferID INT
												, ControlGroupCount BIGINT
												, ControlGroupOrder TINYINT);

				CREATE CLUSTERED INDEX CIX_FanID ON #ControlGroup_Setup (FanID) WITH (FILLFACTOR = 70)

				INSERT INTO #ControlGroup_Setup
				SELECT cb.FanID
					 , cb.ShopperSegmentTypeID
					 , iof.IronOfferID
					 , CASE
							WHEN cb.ShopperSegmentTypeID = 7 THEN @AcquireCount
							WHEN cb.ShopperSegmentTypeID = 8 THEN @LaspsedCount
							WHEN cb.ShopperSegmentTypeID = 9 THEN @ShopperCount
							WHEN cb.ShopperSegmentTypeID = 10 THEN @WelcomeCount
							WHEN cb.ShopperSegmentTypeID = 11 THEN @HomemoverCount
							WHEN cb.ShopperSegmentTypeID = 12 THEN @BirthdayCount
					   END AS ControlGroupCount
					 , 1 AS ControlGroupOrder
				FROM ##CustomerBase_Virgin cb
				INNER JOIN #OfferIDs iof
					  ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
				LEFT JOIN [Derived].[Customer_EngagementScore] cr
					  ON cb.FanID = cr.FanID
				WHERE cb.ControlGroupCustomer = 1
				
				INSERT INTO #ControlGroup_Setup
				SELECT cb.FanID
					 , cb.ShopperSegmentTypeID
					 , iof.IronOfferID
					 , CASE
							WHEN cb.ShopperSegmentTypeID = 7 THEN @AcquireCount
							WHEN cb.ShopperSegmentTypeID = 8 THEN @LaspsedCount
							WHEN cb.ShopperSegmentTypeID = 9 THEN @ShopperCount
							WHEN cb.ShopperSegmentTypeID = 10 THEN @WelcomeCount
							WHEN cb.ShopperSegmentTypeID = 11 THEN @HomemoverCount
							WHEN cb.ShopperSegmentTypeID = 12 THEN @BirthdayCount
					   END AS ControlGroupCount
					 , 2 AS ControlGroupOrder
				FROM ##CustomerBase_Virgin cb
				INNER JOIN #OfferIDs iof
					  ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
				LEFT JOIN [Derived].[Customer_EngagementScore] cr
					  ON cb.FanID = cr.FanID
				WHERE NOT EXISTS (SELECT 1
								  FROM #Selection s
								  WHERE #Selection.[cb].FanID = s.FanID)
				AND NOT EXISTS (SELECT 1
								FROM #ControlGroup_Setup cgs
								WHERE #ControlGroup_Setup.[cb].FanID = cgs.FanID)

				INSERT INTO #ControlGroup_Setup
				SELECT [s].[FanID]
					 , [s].[ShopperSegmentTypeID]
					 , [s].[IronOfferID]
					 , CASE
							WHEN [s].[ShopperSegmentTypeID] = 7 THEN @AcquireCount
							WHEN [s].[ShopperSegmentTypeID] = 8 THEN @LaspsedCount
							WHEN [s].[ShopperSegmentTypeID] = 9 THEN @ShopperCount
							WHEN [s].[ShopperSegmentTypeID] = 10 THEN @WelcomeCount
							WHEN [s].[ShopperSegmentTypeID] = 11 THEN @HomemoverCount
							WHEN [s].[ShopperSegmentTypeID] = 12 THEN @BirthdayCount
					   END AS ControlGroupCount
					 , 3 AS ControlGroupOrder
				FROM #Selection s
				WHERE NOT EXISTS (	SELECT 1
									FROM #ControlGroup_Setup cgs
									WHERE #ControlGroup_Setup.[s].FanID = cgs.FanID)

				IF OBJECT_ID('tempdb..#ControlGroup') IS NOT NULL DROP TABLE #ControlGroup
				SELECT @PartnerID AS PartnerID
					 , @ClientServicesRef AS ClientServicesRef
					 , [cg].[IronOfferID]
					 , [cg].[ShopperSegmentTypeID]
					 , @StartDate AS StartDate
					 , @ControlGroupEndDate AS EndDate
					 , [cg].[FanID]
				INTO #ControlGroup
				FROM (SELECT #ControlGroup_Setup.[FanID]
						   , #ControlGroup_Setup.[ShopperSegmentTypeID]
						   , #ControlGroup_Setup.[IronOfferID]
						   , #ControlGroup_Setup.[ControlGroupCount]
						   , ROW_NUMBER() OVER (PARTITION BY #ControlGroup_Setup.[ShopperSegmentTypeID] ORDER BY #ControlGroup_Setup.[ControlGroupOrder], ABS(CHECKSUM(NEWID())) ASC) AS RowNum
					  FROM #ControlGroup_Setup) cg
				WHERE [cg].[RowNum] <= [cg].[ControlGroupCount]

				DELETE s
				FROM #Selection s
				WHERE EXISTS (SELECT 1
							  FROM #ControlGroup cg
							  WHERE #ControlGroup.[s].FanID = cg.FanID)

				
				IF EXISTS (SELECT 1 FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] WHERE [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram].[ClientServicesRef] = @ClientServicesRef)
					BEGIN
						DELETE ipcg
						FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] ipcg
						WHERE EXISTS (	SELECT 1
										FROM #ControlGroup cg
										INNER JOIN [WH_AllPublishers].[Derived].[Offer] o
											ON cg.IronOfferID = #ControlGroup.[o].IronOfferID
										WHERE #ControlGroup.[ipcg].ClientServicesRef = cg.ClientServicesRef
										AND #ControlGroup.[ipcg].StartDate = cg.StartDate
										AND #ControlGroup.[ipcg].PublisherID = #ControlGroup.[o].PublisherID)
					END
						
						
				INSERT INTO [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] (	[WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram].[PublisherID]
																							,	[WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram].[PartnerID]
																							,	[WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram].[ClientServicesRef]
																							,	[WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram].[IronOfferID]
																							,	[WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram].[ShopperSegmentTypeID]
																							,	[WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram].[StartDate]
																							,	[WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram].[EndDate]
																							,	[WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram].[FanID]
																							,	[WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram].[PercentageTaken]
																							,	[WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram].[ExcludeFromAnalysis])
				SELECT	#ControlGroup.[o].PublisherID
					,	cgn.PartnerID
					,	cgn.ClientServicesRef
					,	cgn.IronOfferID
					,	cgn.ShopperSegmentTypeID
					,	cgn.StartDate
					,	cgn.EndDate
					,	cgn.FanID
					,	@ControlGroupPercentage
					,	0
				FROM #ControlGroup cgn
				INNER JOIN [WH_AllPublishers].[Derived].[Offer] o
					ON cgn.IronOfferID = #ControlGroup.[o].IronOfferID
				WHERE NOT EXISTS (	SELECT 1
									FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] cne
									WHERE cgn.FanID = #ControlGroup.[cne].FanID
									AND cgn.ClientServicesRef = #ControlGroup.[cne].ClientServicesRef
									AND @StartDate BETWEEN #ControlGroup.[cne].StartDate AND #ControlGroup.[cne].EndDate)
				
				SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Create in programme control group [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

			END	--	IF @ControlGroupPercentage > 0


	/*******************************************************************************************************************************************
		15. Output to final table
	*******************************************************************************************************************************************/

		DECLARE @SQLCode_FinalTable VARCHAR(MAX)

		SET @SQLCode_FinalTable = '
		IF OBJECT_ID(''' + @OutputTableName + ''') IS NOT NULL DROP TABLE ' + @OutputTableName + '
		CREATE TABLE ' +@OutputTableName+ '
				([FanID] [int] NOT NULL PRIMARY KEY
				,[CompositeID] [bigint] NULL
				,[ShopperSegmentTypeID] int null
				,[PartnerID] [int] NOT NULL
				,[OfferID] [int] NULL
				,[ClientServicesRef] [varchar](10) NOT NULL
				,[StartDate] [datetime] NULL
				,[EndDate] [datetime] NULL)

		INSERT INTO ' +@OutputTableName+ '
		SELECT DISTINCT
				FanID
			  , CompositeID
			  , ShopperSegmentTypeID
			  , ' + CONVERT(VARCHAR(10), @PartnerID) + '
			  , IronOfferID
			  , ''' + CONVERT(VARCHAR(10), @ClientServicesRef) + '''
			  , StartDate
			  , EndDate
		FROM #Selection'

		EXEC (@SQLCode_FinalTable)
			
		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Output to final table [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
		

	/*******************************************************************************************************************************************
		16. Insert to [Selections].[CampaignExecution_TableNames]
	*******************************************************************************************************************************************/
	
		INSERT INTO [Selections].[CampaignExecution_TableNames] ([Selections].[CampaignExecution_TableNames].[TableName], [Selections].[CampaignExecution_TableNames].[ClientServicesRef])
		SELECT @OutputTableName
			 , @ClientServicesRef

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Insert to [Selections].[CampaignExecution_TableNames] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT
			   

	/*******************************************************************************************************************************************
		20. Insert to OfferMemberAdditions
	*******************************************************************************************************************************************/

		DECLARE @GETDATE DATETIME = GETDATE()

		INSERT INTO [Segmentation].[OfferMemberAddition]
		SELECT #Selection.[CompositeID]
			 , #Selection.[IronOfferID]
			 , #Selection.[StartDate]
			 , #Selection.[EndDate]
			 , @GETDATE AS AddedDate
		FROM #Selection
			
		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Insert to [Segmentation].[OfferMemberAddition]] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'Selections', @Activity, @time OUTPUT, @SSMS OUTPUT

	/*******************************************************************************************************************************************
		21. Drop all temp tables
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#OfferIDs') IS NOT NULL DROP TABLE #OfferIDs
		IF OBJECT_ID('tempdb..#Gender') IS NOT NULL DROP TABLE #Gender
		IF OBJECT_ID('tempdb..#MarketableByEmail') IS NOT NULL DROP TABLE #MarketableByEmail
		IF OBJECT_ID('tempdb..#LiveOfferPerPartner') IS NOT NULL DROP TABLE #LiveOfferPerPartner
		IF OBJECT_ID('tempdb..#CustomersOnOfferAlready') IS NOT NULL DROP TABLE #CustomersOnOfferAlready
		IF OBJECT_ID('tempdb..##CustomerBase_Virgin') IS NOT NULL DROP TABLE ##CustomerBase_Virgin
		IF OBJECT_ID('tempdb..#SelectedInAnotherCampaign') IS NOT NULL DROP TABLE #SelectedInAnotherCampaign
		IF OBJECT_ID('tempdb..#SelectedInAnotherCampaignCustomers') IS NOT NULL DROP TABLE #SelectedInAnotherCampaignCustomers
		IF OBJECT_ID('tempdb..#ExistingUniverseOffers') IS NOT NULL DROP TABLE #ExistingUniverseOffers
		IF OBJECT_ID('tempdb..#ExistingUniverse') IS NOT NULL DROP TABLE #ExistingUniverse
		IF OBJECT_ID('tempdb..#PostalSectors') IS NOT NULL DROP TABLE #PostalSectors
		IF OBJECT_ID('tempdb..#CustomersWithinDrivetime') IS NOT NULL DROP TABLE #CustomersWithinDrivetime
		IF OBJECT_ID('tempdb..#MustBeIn_TableName_Temp') IS NOT NULL DROP TABLE #MustBeIn_TableName_Temp
		IF OBJECT_ID('tempdb..#MustBeIn_TableName') IS NOT NULL DROP TABLE #MustBeIn_TableName
		IF OBJECT_ID('tempdb..#NotIn_TableName') IS NOT NULL DROP TABLE #NotIn_TableName
		IF OBJECT_ID('tempdb..#CustomersWithMultipleTrans') IS NOT NULL DROP TABLE #CustomersWithMultipleTrans
		IF OBJECT_ID('tempdb..#Selection') IS NOT NULL DROP TABLE #Selection
		IF OBJECT_ID('tempdb..#ControlGroup_Setup') IS NOT NULL DROP TABLE #ControlGroup_Setup
		IF OBJECT_ID('tempdb..#ControlGroup') IS NOT NULL DROP TABLE #ControlGroup
		IF OBJECT_ID('tempdb..#TopPartnerOffer') IS NOT NULL DROP TABLE #TopPartnerOffer
		IF OBJECT_ID('tempdb..#ROCShopperSegment_SeniorStaffAccounts') IS NOT NULL DROP TABLE #ROCShopperSegment_SeniorStaffAccounts

END