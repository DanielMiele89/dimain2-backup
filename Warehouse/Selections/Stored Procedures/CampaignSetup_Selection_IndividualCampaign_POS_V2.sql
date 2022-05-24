
CREATE PROCEDURE [Selections].[CampaignSetup_Selection_IndividualCampaign_POS_V2] (@PartnerID CHAR(4)
																			 , @StartDate VARCHAR(10)
																			 , @EndDate VARCHAR(10)
																			 , @CampaignName VARCHAR (250)
																			 , @ClientServicesRef VARCHAR(10)
																			 , @OfferID VARCHAR(40)
																			 , @Throttling VARCHAR(200)
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
																			 , @ControlGroupPercentage INT)

AS
BEGIN
/****************************************************************************************************
Title:			CampaignSetup_Selection_IndividualCampaign_POS
Author:			Rory Francis
Creation Date:	2019-02-05
Purpose:		Looped selection of an indivdual Point of Sale Offer
-----------------------------------------------------------------------------------------------------
Modified Log:

Change No:	Name:			Date:			Description of change:

			
****************************************************************************************************/

/*

DECLARE @TestID INT = (SELECT MIN(ID) FROM Selections.ROCShopperSegment_PreSelection_ALS WHERE PartnerID = (SELECT MIN(PartnerID) FROM Selections.CustomerBase cb) AND EmailDate > GETDATE())


DECLARE @PartnerID CHAR(4)
	  , @StartDate VARCHAR(10)
	  , @EndDate VARCHAR(10)
	  , @CampaignName VARCHAR (250)
	  , @ClientServicesRef VARCHAR(10)
	  , @OfferID VARCHAR(40)
	  , @Throttling VARCHAR(200)
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
	 , @CampaignTypeID = CampaignTypeID
	 , @FreqStretch_TransCount = FreqStretch_TransCount
	 , @ControlGroupPercentage = ControlGroupPercentage
FROM Selections.ROCShopperSegment_PreSelection_ALS
WHERE ID = 8878

*/




	/*******************************************************************************************************************************************
		1. Prepare parameters for script
	*******************************************************************************************************************************************/

		DECLARE @SQLCode NVARCHAR(MAX)
			  , @Time DATETIME
			  , @Msg VARCHAR(2048)

		EXEC Staging.oo_TimerMessage 'Starting CampaignSetup_Selection_IndividualCampaign_POS', @Time OUTPUT

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
			  , @TotalCustomers INT = (SELECT COUNT(*) FROM Relational.Customer)
			  , @IsThrottleApplied INT = 0
			  , @FreqStretch_TransDate DATE = DATEADD(day, -56, @StartDate)
			  , @ControlGroupEndDate DATE = (SELECT MAX(EndDate) FROM [Selections].[ROCShopperSegment_PreSelection_ALS] WHERE ClientServicesRef = @ClientServicesRef)
			  

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


				INSERT INTO #OfferIDs (ShopperSegmentTypeID
									 , IronOfferID
									 , Throttling)
				SELECT sst.Item AS ShopperSegmentTypeID
					 , iof.Item AS IronOfferID
					 , CASE
							WHEN thr.Item = 0 THEN @TotalCustomers
							ELSE thr.Item
					   END AS Throttling
				FROM OfferIDs
				CROSS APPLY dbo.il_SplitDelimitedStringArray (ShopperSegmentTypeID, ',') sst
				CROSS APPLY dbo.il_SplitDelimitedStringArray (IronOfferID, ',') iof
				CROSS APPLY dbo.il_SplitDelimitedStringArray (Throttling, ',') thr
				WHERE sst.ItemNumber = iof.ItemNumber
				AND iof.ItemNumber = thr.ItemNumber
				AND iof.Item > 0
		
				CREATE CLUSTERED INDEX CIX_ShopperSegmentTypeID on #OfferIDs (ShopperSegmentTypeID)

			
					/***********************************************************************************************************************
						2.1.1. If PartnerID does not match the PartnerID linked to each offer then exit
					***********************************************************************************************************************/
					
							IF EXISTS (SELECT 1
									   FROM #OfferIDs o
									   INNER JOIN Relational.IronOffer iof
										   ON o.IronOfferID = iof.IronOfferID
										   AND iof.PartnerID != @PartnerID)
								BEGIN
									PRINT 'PartnerID linked to campaign does not match the PartnerID the selected offers have been set up under'
									RETURN
								END

			
					/***********************************************************************************************************************
						2.1.2. Check whether there is any throttling
					***********************************************************************************************************************/
			
						SELECT @IsThrottleApplied = CASE WHEN SUM(Throttling) = COUNT(*) * @TotalCustomers THEN 0 ELSE 1 END
						FROM #OfferIDs

			/***********************************************************************************************************************
				2.2. Gender details
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#Gender') IS NOT NULL DROP TABLE #Gender
				CREATE TABLE #Gender (Gender VARCHAR(1));

				WITH Gender AS (SELECT @Gender AS Gender)
				
				INSERT INTO #Gender (Gender)
				SELECT Item AS Gender
				FROM Gender
				CROSS APPLY dbo.il_SplitDelimitedStringArray (Gender, ',') ge
		
				CREATE CLUSTERED INDEX CIX_Gender_Gender on #Gender (Gender)
			
			/***********************************************************************************************************************
				2.2. Marketable By Email details
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#MarketableByEmail') IS NOT NULL DROP TABLE #MarketableByEmail
				CREATE TABLE #MarketableByEmail (MarketableByEmail VARCHAR(1));

				WITH MarketableByEmail AS (SELECT @MarketableByEmail AS MarketableByEmail)
				
				INSERT INTO #MarketableByEmail (MarketableByEmail)
				SELECT Item AS MarketableByEmail
				FROM MarketableByEmail
				CROSS APPLY dbo.il_SplitDelimitedStringArray (MarketableByEmail, ',') mbe
				
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
				FROM [Relational].[CAMEO_CODE] cc
				WHERE cc.Social_Class BETWEEN @SocialClass_Min AND @SocialClass_Max

				CREATE CLUSTERED INDEX CIX_All ON #SocialClass (Social_Class)

				EXEC Staging.oo_TimerMessage 'Extricating parameters', @Time OUTPUT


	/*******************************************************************************************************************************************
		3. Find customers already on an offer for this partner
	*******************************************************************************************************************************************/
	
		/***********************************************************************************************************************
			3.1. Fetch all live offers for this partner
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#LiveOfferPerPartner') IS NOT NULL DROP TABLE #LiveOfferPerPartner
			SELECT iof.IronOfferID
			INTO #LiveOfferPerPartner
			FROM Relational.IronOffer iof
			WHERE PartnerID = @PartnerID
			AND (iof.EndDate > @StartDate OR iof.EndDate IS NULL)
			AND iof.CampaignType NOT LIKE '%Base%'
			AND iof.IsSignedOff = 1
			AND NOT EXISTS (SELECT 1
							FROM Relational.Partner_NonCoreBaseOffer ncb
							WHERE iof.IronOfferID = ncb.IronOfferID)

			CREATE CLUSTERED INDEX CIX_IronOfferID ON #LiveOfferPerPartner (IronOfferID)

				EXEC Staging.oo_TimerMessage 'Fetch all live offers for this partner', @Time OUTPUT
	
		/***********************************************************************************************************************
			3.2. Fetch all customers assigned offers for this partner
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CustomersOnOfferAlready') IS NOT NULL DROP TABLE #CustomersOnOfferAlready
			SELECT DISTINCT
				   iom.CompositeID
			INTO #CustomersOnOfferAlready
			FROM Relational.IronOfferMember iom
			INNER JOIN #LiveOfferPerPartner lopp
				ON iom.IronOfferID = lopp.IronOfferID
			WHERE (iom.EndDate > @StartDate OR iom.EndDate IS NULL)

			CREATE CLUSTERED INDEX CIX_CompositeID ON #CustomersOnOfferAlready (CompositeID)

			EXEC Staging.oo_TimerMessage 'Fetch all customers assigned offers for this partner', @Time OUTPUT


	/*******************************************************************************************************************************************
		4. Build customer base
	*******************************************************************************************************************************************/
			
		/***********************************************************************************************************************
			4.1. Fetch control group customers
		***********************************************************************************************************************/
			
			IF OBJECT_ID ('tempdb..#ControlGroupCustomers') IS NOT NULL DROP TABLE #ControlGroupCustomers
			SELECT CompositeID
			INTO #ControlGroupCustomers
			FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] cg
			INNER JOIN Relational.Customer cu
				ON cg.FanID = cu.FanID
			WHERE PartnerID = @PartnerID
			AND EndDate >= @StartDate

			CREATE CLUSTERED INDEX CIX_CompositeID ON #ControlGroupCustomers (CompositeID)

			EXEC Staging.oo_TimerMessage 'Fetch control group customers', @Time OUTPUT

		/***********************************************************************************************************************
			4.2. Fetch customer universe
		***********************************************************************************************************************/
				
			--SET @PartnerID = (SELECT MIN(PartnerID) FROM Selections.CustomerBase cb)

			DECLARE @CustomerBaseQuery VARCHAR(MAX)

			SET @CustomerBaseQuery =	'IF OBJECT_ID (''tempdb..##CustomerBase'') IS NOT NULL DROP TABLE ##CustomerBase
										SELECT DISTINCT 
											   cb.FanID
											 , cb.CompositeID
											 , cb.ShopperSegmentTypeID
											 , CASE
													WHEN cgc.CompositeID IS NULL THEN 0
													ELSE 1
											   END AS ControlGroupCustomer
										INTO ##CustomerBase
										FROM [Selections].[CustomerBase] cb
										LEFT JOIN #ControlGroupCustomers cgc
											ON cb.CompositeID = cgc.CompositeID
										WHERE NOT EXISTS (	SELECT 1
															FROM Selections.CampaignCode_Selections_PartnerDedupe pd
															WHERE cb.CompositeID = pd.CompositeID)
										AND NOT EXISTS (SELECT 1
														FROM #CustomersOnOfferAlready cooa
														WHERE cb.CompositeID = cooa.CompositeID)'

			IF @Gender != 'U,M,F'
				BEGIN

					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM #Gender ge
														WHERE cb.Gender = ge.Gender)'
				END
				
			IF @MarketableByEmail != '0,1'
				BEGIN

					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM #MarketableByEmail mbe
														WHERE cb.MarketableByEmail = mbe.MarketableByEmail)'
				END


			IF @AgeRange != '0-999'
				BEGIN
					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM #AgeRange ar
														WHERE cb.AgeCurrent = ar.AgeCurrent)'
				END


	
			IF @SocialClass != 'AB-DE'
				BEGIN
					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM [Relational].[CAMEO] ca
														INNER JOIN Relational.CAMEO_CODE cc
															ON cc.CAMEO_CODE = ca.CAMEO_CODE
														INNER JOIN #SocialClass sc
															ON cc.Social_Class = sc.Social_Class
														WHERE cb.Postcode = ca.PostCode)'
				END

			EXEC(@CustomerBaseQuery)
			

			EXEC Staging.oo_TimerMessage 'Collecting ##CustomerBase', @Time OUTPUT



		/***********************************************************************************************************************
			4.4. Update ShopperSegmentTypeID
		***********************************************************************************************************************/
			
			/***********************************************************************************************************************
				4.4.1. Update welcome details
			***********************************************************************************************************************/

				IF EXISTS (SELECT 1 FROM #OfferIDs WHERE ShopperSegmentTypeID = 10)
					BEGIN

						UPDATE cb
						SET cb.ShopperSegmentTypeID = 10
						FROM ##CustomerBase cb
						INNER JOIN [Selections].[CustomerBase] c
							ON cb.CompositeID = c.CompositeID
						WHERE c.ShopperSegmentTypeID NOT IN (10, 11, 12)
						AND c.ActivatedDate > @ActivatedDate

					END
			
				EXEC Staging.oo_TimerMessage 'Update welcome details', @Time OUTPUT

			
			/***********************************************************************************************************************
				4.4.2. Update birthday details
			***********************************************************************************************************************/

				IF EXISTS (SELECT 1 FROM #OfferIDs WHERE ShopperSegmentTypeID = 11)
					BEGIN

						UPDATE cb
						SET cb.ShopperSegmentTypeID = 11
						FROM ##CustomerBase cb
						INNER JOIN [Selections].[CustomerBase] c
							ON cb.CompositeID = c.CompositeID
						WHERE c.ShopperSegmentTypeID NOT IN (10, 11, 12)
						AND FLOOR(DATEDIFF(dd, DOB, @StartDate) / 365.25) != FLOOR(DATEDIFF(dd, DOB, @EndDate) / 365.25)

					END
			
				EXEC Staging.oo_TimerMessage 'Update birthday details', @Time OUTPUT

			
			/***********************************************************************************************************************
				4.4.3. Update homemover details
			***********************************************************************************************************************/

				IF EXISTS (SELECT 1 FROM #OfferIDs WHERE ShopperSegmentTypeID = 12)
					BEGIN

						UPDATE cb
						SET cb.ShopperSegmentTypeID = 12
						FROM ##CustomerBase cb
						INNER JOIN [Selections].[CustomerBase] c
							ON cb.CompositeID = c.CompositeID
						WHERE cb.ShopperSegmentTypeID NOT IN (10, 11, 12)
						AND EXISTS (SELECT 1 
									FROM Relational.Homemover_Details hm
									WHERE hm.LoadDate >= @HomemoverDate
									AND cb.FanID = hm.FanID)

					END
			
				EXEC Staging.oo_TimerMessage 'Update homemover details', @Time OUTPUT

			
		/***********************************************************************************************************************
			4.5. Indexing ##CustomerBase
		***********************************************************************************************************************/

			CREATE CLUSTERED INDEX CIX_CompositeID ON ##CustomerBase (CompositeID, ShopperSegmentTypeID, ControlGroupCustomer)
			CREATE NONCLUSTERED INDEX IX_FanID ON ##CustomerBase (FanID)
			CREATE NONCLUSTERED INDEX IX_CompSeg ON ##CustomerBase (CompositeID, ShopperSegmentTypeID)
			
			EXEC Staging.oo_TimerMessage 'Indexing ##CustomerBase', @Time OUTPUT

	/*******************************************************************************************************************************************
		5. Exec competitior steal campaigns where required
	*******************************************************************************************************************************************/
	
		IF @CampaignID_Include != ''
			BEGIN
				EXEC Warehouse.Selections.Partner_GenerateTriggerMember @CampaignID_Include

				DELETE cb
				FROM ##CustomerBase cb
				WHERE NOT EXISTS (SELECT 1
								  FROM Relational.PartnerTrigger_Members ptm
								  WHERE cb.FanID = ptm.FanID
								  AND ptm.CampaignID = @CampaignID_Include)

			END

		IF @CampaignID_Exclude != ''
			BEGIN
				EXEC Warehouse.Selections.Partner_GenerateTriggerMember @CampaignID_Exclude

				DELETE cb
				FROM ##CustomerBase cb
				WHERE EXISTS (SELECT 1
							  FROM Relational.PartnerTrigger_Members ptm
							  WHERE cb.FanID = ptm.FanID
							  AND ptm.CampaignID = @CampaignID_Include)
			END
			
		EXEC Staging.oo_TimerMessage 'Exec competitior steal campaigns', @Time OUTPUT


	/*******************************************************************************************************************************************
		6. If campaign is targeting universe of previous campaign then fetch those customers
	*******************************************************************************************************************************************/
	
		IF @SelectedInAnotherCampaign != ''
			BEGIN
			
				/***********************************************************************************************************************
					6.1. Create table storing each ClientServiceReference to build universe from
				***********************************************************************************************************************/

					IF OBJECT_ID('tempdb..#SelectedInAnotherCampaign') IS NOT NULL DROP TABLE #SelectedInAnotherCampaign
					CREATE TABLE #SelectedInAnotherCampaign (ClientServicesRef VARCHAR(250));

					WITH SelectedInAnotherCampaign AS (SELECT @SelectedInAnotherCampaign AS ClientServicesRef)
				
					INSERT INTO #SelectedInAnotherCampaign (ClientServicesRef)
					SELECT Item AS ClientServicesRef
					FROM SelectedInAnotherCampaign
					CROSS APPLY dbo.il_SplitDelimitedStringArray (ClientServicesRef, ',') mbe

					CREATE CLUSTERED INDEX CIX_SelectedInAnotherCampaign_ClientServicesRef ON #SelectedInAnotherCampaign (ClientServicesRef)
				
							
				/***********************************************************************************************************************
					6.2. Store customers that have been previously exposed to the given campaigns
				***********************************************************************************************************************/

					IF OBJECT_ID('tempdb..#MustBeIn') IS NOT NULL DROP TABLE #MustBeIn
					SELECT DISTINCT
						   iom.CompositeID
					INTO #MustBeIn
					FROM Relational.IronOfferMember iom
					WHERE EXISTS (SELECT 1
								  FROM #SelectedInAnotherCampaign siac
								  INNER JOIN Relational.IronOffer_Campaign_HTM htm
									  ON siac.ClientServicesRef = htm.ClientServicesRef
								  Where iom.IronOfferID = htm.IronOfferID)

					CREATE CLUSTERED INDEX CIX_MustBeIn_CompositeID ON #MustBeIn (CompositeID)

			
				/***********************************************************************************************************************
					6.3. Remove customers than have not previously been selected
				***********************************************************************************************************************/

					DELETE cb
					FROM ##CustomerBase cb
					WHERE ShopperSegmentTypeID != 10
					AND NOT EXISTS (SELECT 1
									FROM #MustBeIn mbi
									WHERE cb.CompositeID = mbi.CompositeID)


			END	--	IF @SelectedInAnotherCampaign != ''
			
		EXEC Staging.oo_TimerMessage 'If campaign is targeting universe of previous campaign then fetch those customers', @Time OUTPUT


	/*******************************************************************************************************************************************
		7. Find customers previously selected in this campaign
	*******************************************************************************************************************************************/
	
		IF @CustomerBaseOfferDate IS NOT NULL
			BEGIN
	
				/***********************************************************************************************************************
					7.1. Fetch all offers that have run in this campaign
				***********************************************************************************************************************/

					IF OBJECT_ID('tempdb..#ExistingUniverseOffers') IS NOT NULL DROP TABLE #ExistingUniverseOffers
					SELECT Distinct
						   iof.IronOfferID
					INTO #ExistingUniverseOffers
					FROM Relational.IronOffer iof
					INNER JOIN Relational.IronOffer_Campaign_HTM htm
						ON iof.IronOfferID = htm.IronOfferID
					WHERE htm.ClientServicesRef = @ClientServicesRef

					CREATE CLUSTERED INDEX CIX_IronOfferID ON #ExistingUniverseOffers (IronOfferID)
	
				/***********************************************************************************************************************
					7.2. Fetch all customers that have been assigned any of the previous offers
				***********************************************************************************************************************/

					IF OBJECT_ID ('tempdb..#ExistingUniverse') IS NOT NULL DROP TABLE #ExistingUniverse
					SELECT eu.CompositeID
					INTO #ExistingUniverse
					FROM Selections.CampaignSetup_ExistingUniverse eu
					WHERE EXISTS (SELECT 1
								  FROM #ExistingUniverseOffers euo
								  WHERE eu.IronOfferID = euo.IronOfferID
								  AND eu.StartDate = @CustomerBaseOfferDate)
				
					CREATE CLUSTERED INDEX CIX_CompositeID on #ExistingUniverse (CompositeID)

			
				/***********************************************************************************************************************
					7.3. Remove customers than have not previously been selected
				***********************************************************************************************************************/

					DELETE cb
					FROM ##CustomerBase cb
					WHERE ShopperSegmentTypeID != 10
					AND NOT EXISTS (SELECT 1
									FROM #ExistingUniverse eu
									WHERE cb.CompositeID = eu.CompositeID)

			END	--	IF @CustomerBaseOfferDate IS NOT NULL
			
		EXEC Staging.oo_TimerMessage 'Find customers previously selected in this campaign', @Time OUTPUT

	/*******************************************************************************************************************************************
		8. Find customers living within designated drivetime
	*******************************************************************************************************************************************/
			
		IF @LiveNearAnyStore = 1 AND @DriveTimeMins != ''
			BEGIN
	
				/***********************************************************************************************************************
					8.1. Fetch all postal sectors of the stores for this partner
				***********************************************************************************************************************/

					IF OBJECT_ID ('tempdb..#PostalSectors') IS NOT NULL DROP TABLE #PostalSectors
					SELECT DISTINCT
						   o.PostalSector
					INTO #PostalSectors
					FROM Relational.Outlet o
					WHERE o.PartnerID = @PartnerID
					AND LEFT(MerchantID, 1) NOT IN ('a', 'x', '#')
	
				/***********************************************************************************************************************
					8.2. Fetch all customers within desginated drive time of the previous postal sectors
				***********************************************************************************************************************/
				
					IF OBJECT_ID ('tempdb..#CustomersWithinDrivetime') IS NOT NULL DROP TABLE #CustomersWithinDrivetime
					SELECT DISTINCT
						   cu.CompositeID
					INTO #CustomersWithinDrivetime
					FROM Relational.Customer cu
					INNER JOIN Relational.DriveTimeMatrix dtm
						ON cu.PostalSector = dtm.FROMSector
					INNER JOIN #PostalSectors ps
						ON dtm.ToSector = ps.PostalSector
						AND dtm.DriveTimeMins <= @DriveTimeMins
						
					CREATE CLUSTERED INDEX CIX_CompositeID ON #CustomersWithinDrivetime (CompositeID)

			
				/***********************************************************************************************************************
					8.3. Remove customers than have not previously been selected
				***********************************************************************************************************************/

					DELETE cb
					FROM ##CustomerBase cb
					WHERE NOT EXISTS (SELECT 1
									  FROM #CustomersWithinDrivetime cwd
									  WHERE cb.CompositeID = cwd.CompositeID)

			END	--	IF @LiveNearAnyStore = 1 AND @DriveTimeMins != ''
			
		EXEC Staging.oo_TimerMessage 'Find customers living within designated drivetime', @Time OUTPUT


	/*******************************************************************************************************************************************
		9. Fetch customers from the MustBeIn tables
	*******************************************************************************************************************************************/

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
							SET @SQLCode = 'INSERT INTO #MustBeIn_TableName_Temp SELECT FanID FROM ' + @MustBeIn_TableName1
							EXEC (@SQLCode)
						END

					IF OBJECT_ID(@MustBeIn_TableName2) IS NOT NULL
						BEGIN
							SET @SQLCode = 'INSERT INTO #MustBeIn_TableName_Temp SELECT FanID FROM ' + @MustBeIn_TableName2
							EXEC (@SQLCode)
						END

					IF OBJECT_ID(@MustBeIn_TableName3) IS NOT NULL
						BEGIN
							SET @SQLCode = 'INSERT INTO #MustBeIn_TableName_Temp SELECT FanID FROM ' + @MustBeIn_TableName3
							EXEC (@SQLCode)
						END

					IF OBJECT_ID(@MustBeIn_TableName4) IS NOT NULL
						BEGIN
							SET @SQLCode = 'INSERT INTO #MustBeIn_TableName_Temp SELECT FanID FROM ' + @MustBeIn_TableName4
							EXEC (@SQLCode)
						END

					IF OBJECT_ID('tempdb..#MustBeIn_TableName') IS NOT NULL DROP TABLE #MustBeIn_TableName
					SELECT FanID
					INTO #MustBeIn_TableName
					FROM #MustBeIn_TableName_Temp
					GROUP BY FanID
					HAVING COUNT(1) = @MustBeIn_TableCount

					CREATE CLUSTERED INDEX CIX_MustBeIn_FanID ON #MustBeIn_TableName (FanID)

			
				/***********************************************************************************************************************
					9.2. Remove customers that have not been preselected
				***********************************************************************************************************************/

					DELETE cb
					FROM ##CustomerBase cb
					WHERE NOT EXISTS (SELECT 1
									  FROM #MustBeIn_TableName mbi
									  WHERE cb.FanID = mbi.FanID)

			END	--	IF @MustBeIn_TableCount > 0
			
		EXEC Staging.oo_TimerMessage 'Fetch customers from the MustBeIn tables', @Time OUTPUT
			

	/*******************************************************************************************************************************************
		10. Fetch customers from the NotIn tables
	*******************************************************************************************************************************************/

		IF LEN(@NotIn_TableName1 + @NotIn_TableName2 + @NotIn_TableName3 + @NotIn_TableName4) > 0
			BEGIN
	
				/***********************************************************************************************************************
					10.1. For each existing preselection table insert the customers into a holding table
				***********************************************************************************************************************/

					IF OBJECT_ID('tempdb..#NotIn_TableName') IS NOT NULL DROP TABLE #NotIn_TableName
					CREATE TABLE #NotIn_TableName (FanID BIGINT)

					IF OBJECT_ID(@NotIn_TableName1) IS NOT NULL
						BEGIN
							SET @SQLCode = 'INSERT INTO #NotIn_TableName SELECT FanID FROM ' + @NotIn_TableName1
							EXEC (@SQLCode)
						END

					IF OBJECT_ID(@NotIn_TableName2) IS NOT NULL
						BEGIN
							SET @SQLCode = 'INSERT INTO #NotIn_TableName SELECT FanID FROM ' + @NotIn_TableName2
							EXEC (@SQLCode)
						END

					IF OBJECT_ID(@NotIn_TableName3) IS NOT NULL
						BEGIN
							SET @SQLCode = 'INSERT INTO #NotIn_TableName SELECT FanID FROM ' + @NotIn_TableName3
							EXEC (@SQLCode)
						END

					IF OBJECT_ID(@NotIn_TableName4) IS NOT NULL
						BEGIN
							SET @SQLCode = 'INSERT INTO #NotIn_TableName SELECT FanID FROM ' + @NotIn_TableName4
							EXEC (@SQLCode)
						END

			
				/***********************************************************************************************************************
					10.2. Remove customers that have not been preselected
				***********************************************************************************************************************/

					DELETE cb
					FROM ##CustomerBase cb
					WHERE EXISTS (SELECT 1
								  FROM #NotIn_TableName ni
								  WHERE cb.FanID = ni.FanID)

			END	--	IF LEN(@NotIn_TableName1 + @NotIn_TableName2 + @NotIn_TableName3 + @NotIn_TableName4) > 0
			
		EXEC Staging.oo_TimerMessage 'Fetch customers from the NotIn tables', @Time OUTPUT


	/*******************************************************************************************************************************************
		11. Remove customers that have meet the designated amount of purchases per campaign
	*******************************************************************************************************************************************/
	
		IF @FreqStretch_TransCount > 0
			BEGIN

				IF OBJECT_ID('tempdb..#CustomersWithMultipleTrans') IS NOT NULL DROP TABLE #CustomersWithMultipleTrans
				SELECT pt.FanID
					 , pt.IronOfferID
					 , SUM(CASE
								WHEN TransactionAmount > 0 THEN 1
								ELSE -1
						   END) AS ValidTransactions
				INTO #CustomersWithMultipleTrans
				FROM Relational.PartnerTrans pt
				WHERE EXISTS (SELECT 1
							  FROM #OfferIDs iof
							  WHERE pt.IronOfferID = iof.IronOfferID)
				AND pt.TransactionDate > @FreqStretch_TransDate
				GROUP BY pt.IronOfferID
					   , pt.FanID
				HAVING COUNT(1) >= @FreqStretch_TransCount

				DELETE
				FROM #CustomersWithMultipleTrans
				WHERE ValidTransactions < @FreqStretch_TransCount

				DELETE cb
				FROM ##CustomerBase cb
				INNER JOIN #CustomersWithMultipleTrans cwmt
					ON cb.FanID = cwmt.FanID

			END	--	IF @FreqStretch_TransCount > 0
			
		EXEC Staging.oo_TimerMessage 'Remove customers that have meet the designated amount of purchases per campaign', @Time OUTPUT


	/*******************************************************************************************************************************************
		12. Output to assign offers and apply throttling if required
	*******************************************************************************************************************************************/

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
				FROM ##CustomerBase cb
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
							 , ROW_NUMBER() OVER (PARTITION BY iof.IronOfferID ORDER BY cr.Ranking ASC) AS RowNum
						FROM ##CustomerBase cb
						INNER JOIN #OfferIDs iof
							ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
						LEFT JOIN Segmentation.Roc_Shopper_Segment_CustomerRanking cr
							ON cb.FanID = cr.FanID
							AND cr.PartnerID = @PartnerID
						WHERE ControlGroupCustomer = 0
						) cb
				WHERE RowNum <= Throttling
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
						FROM ##CustomerBase cb
						INNER JOIN #OfferIDs iof
							ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
						LEFT JOIN Segmentation.Roc_Shopper_Segment_CustomerRanking cr
							ON cb.FanID = cr.FanID
							AND cr.PartnerID = @PartnerID
						WHERE ControlGroupCustomer = 0) cb
				WHERE RowNum <= Throttling
			END
			
		EXEC Staging.oo_TimerMessage 'Output to assign offers and apply throttling if required', @Time OUTPUT


	/*******************************************************************************************************************************************
		13. Create in programme control group
	*******************************************************************************************************************************************/
	
		IF @ControlGroupPercentage > 0
			BEGIN
				
				DECLARE @AcquireCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 7) * 1.0 / 100) * @ControlGroupPercentage
					  , @LaspsedCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 8) * 1.0 / 100) * @ControlGroupPercentage
					  , @ShopperCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 9) * 1.0 / 100) * @ControlGroupPercentage
					  , @WelcomeCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 10) * 1.0 / 100) * @ControlGroupPercentage
					  , @HomemoverCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 11) * 1.0 / 100) * @ControlGroupPercentage
					  , @BirthdayCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 12) * 1.0 / 100) * @ControlGroupPercentage

					 
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
				FROM ##CustomerBase cb
				INNER JOIN #OfferIDs iof
					  ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
				LEFT JOIN Segmentation.Roc_Shopper_Segment_CustomerRanking cr
					  ON cb.FanID = cr.FanID
					  AND cr.PartnerID = @PartnerID
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
				FROM ##CustomerBase cb
				INNER JOIN #OfferIDs iof
					  ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
				LEFT JOIN Segmentation.Roc_Shopper_Segment_CustomerRanking cr
					  ON cb.FanID = cr.FanID
					  AND cr.PartnerID = @PartnerID
				WHERE NOT EXISTS (SELECT 1
								  FROM #Selection s
								  WHERE cb.FanID = s.FanID)
				AND NOT EXISTS (SELECT 1
								FROM #ControlGroup_Setup cgs
								WHERE cb.FanID = cgs.FanID)

				INSERT INTO #ControlGroup_Setup
				SELECT FanID
					 , ShopperSegmentTypeID
					 , IronOfferID
					 , CASE
							WHEN ShopperSegmentTypeID = 7 THEN @AcquireCount
							WHEN ShopperSegmentTypeID = 8 THEN @LaspsedCount
							WHEN ShopperSegmentTypeID = 9 THEN @ShopperCount
							WHEN ShopperSegmentTypeID = 10 THEN @WelcomeCount
							WHEN ShopperSegmentTypeID = 11 THEN @HomemoverCount
							WHEN ShopperSegmentTypeID = 12 THEN @BirthdayCount
					   END AS ControlGroupCount
					 , 3 AS ControlGroupOrder
				FROM #Selection s
				WHERE NOT EXISTS (	SELECT 1
									FROM #ControlGroup_Setup cgs
									WHERE s.FanID = cgs.FanID)

				IF OBJECT_ID('tempdb..#ControlGroup') IS NOT NULL DROP TABLE #ControlGroup
				SELECT @PartnerID AS PartnerID
					 , @ClientServicesRef AS ClientServicesRef
					 , IronOfferID
					 , ShopperSegmentTypeID
					 , @StartDate AS StartDate
					 , @ControlGroupEndDate AS EndDate
					 , FanID
				INTO #ControlGroup
				FROM (SELECT FanID
						   , ShopperSegmentTypeID
						   , IronOfferID
						   , ControlGroupCount
						   , ROW_NUMBER() OVER (PARTITION BY ShopperSegmentTypeID ORDER BY ControlGroupOrder, ABS(CHECKSUM(NEWID())) ASC) AS RowNum
					  FROM #ControlGroup_Setup) cg
				WHERE RowNum <= ControlGroupCount

				DELETE s
				FROM #Selection s
				WHERE EXISTS (SELECT 1
							  FROM #ControlGroup cg
							  WHERE s.FanID = cg.FanID)

				
				IF EXISTS (SELECT 1 FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] WHERE [ClientServicesRef] = @ClientServicesRef)
					BEGIN
						DELETE ipcg
						FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] ipcg
						WHERE EXISTS (SELECT 1
									  FROM #ControlGroup cg
									  WHERE ipcg.ClientServicesRef = cg.ClientServicesRef
									  AND ipcg.StartDate = cg.StartDate)
					END
						

				INSERT INTO [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] (	[PartnerID]
																							,	[ClientServicesRef]
																							,	[IronOfferID]
																							,	[ShopperSegmentTypeID]
																							,	[ShopperSegment]
																							,	[StartDate]
																							,	[EndDate]
																							,	[FanID]
																							,	[PercentageTaken]
																							,	[ExcludeFromAnalysis])
				SELECT PartnerID
					 , ClientServicesRef
					 , IronOfferID
					 , ShopperSegmentTypeID
					 , CASE
							WHEN ShopperSegmentTypeID = 7 THEN 'Acquire'
							WHEN ShopperSegmentTypeID = 8 THEN 'Laspsed'
							WHEN ShopperSegmentTypeID = 9 THEN 'Shopper'
							WHEN ShopperSegmentTypeID = 10 THEN 'Welcome'
							WHEN ShopperSegmentTypeID = 11 THEN 'Homemover'
							WHEN ShopperSegmentTypeID = 12 THEN 'Birthday'
					   END AS ShopperSegment
					 , StartDate
					 , EndDate
					 , FanID
					 , @ControlGroupPercentage
					 , 0
				FROM #ControlGroup cgn
				WHERE NOT EXISTS (	SELECT 1
									FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] cne
									WHERE cgn.FanID = cne.FanID
									AND cgn.ClientServicesRef = cne.ClientServicesRef
									AND @StartDate BETWEEN cne.StartDate AND cne.EndDate)
				
			END	--	IF @ControlGroupPercentage > 0
			
		EXEC Staging.oo_TimerMessage 'Create in programme control group', @Time OUTPUT


	/*******************************************************************************************************************************************
		15. Output to final table
	*******************************************************************************************************************************************/

		SET @SQLCode = 'IF OBJECT_ID(''' + @OutputTableName + ''') IS NOT NULL DROP TABLE ' + @OutputTableName + '
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

		EXEC (@SQLCode)
			
		EXEC Staging.oo_TimerMessage 'Output to final table', @Time OUTPUT


	/*******************************************************************************************************************************************
		16. Insert to [Selections].[CampaignExecution_TableNames]
	*******************************************************************************************************************************************/
	
		INSERT INTO [Selections].[CampaignExecution_TableNames] (TableName, ClientServicesRef)
		SELECT @OutputTableName
			 , @ClientServicesRef


	/*******************************************************************************************************************************************
		17. Insert to CBP_CampaignNames
	*******************************************************************************************************************************************/

		INSERT INTO Relational.CBP_CampaignNames (ClientServicesRef
												, CampaignName)
		SELECT @ClientServicesRef
			 , @CampaignName
		WHERE NOT EXISTS (SELECT 1
						  FROM Relational.CBP_CampaignNames
						  WHERE ClientServicesRef = @ClientServicesRef)


	/*******************************************************************************************************************************************
		18. Insert to IronOffer_Campaign_Type
	*******************************************************************************************************************************************/

		INSERT INTO Staging.IronOffer_Campaign_Type (ClientServicesRef
												   , CampaignTypeID
												   , IsTrigger
												   , ControlPercentage)
		SELECT @ClientServicesRef
			 , @CampaignTypeID
			 , 0 IsTrigger
			 , 0 ControlPercentage
		WHERE NOT EXISTS (SELECT 1
						  FROM Staging.IronOffer_Campaign_Type
						  WHERE ClientServicesRef = @ClientServicesRef)


	/*******************************************************************************************************************************************
		19. Insert to IronOffer_ROCOffers
	*******************************************************************************************************************************************/

		INSERT INTO Relational.IronOffer_ROCOffers (IronOfferID)
		SELECT DISTINCT
			   IronOfferID
		FROM #OfferIDs iof
		WHERE NOT EXISTS (SELECT 1
						  FROM Relational.IronOffer_ROCOffers roc
						  WHERE iof.IronOfferID = roc.IronOfferID)
			
		EXEC Staging.oo_TimerMessage 'Insert to [Selections].[CampaignExecution_TableNames], CBP_CampaignNames, IronOffer_Campaign_Type, IronOffer_ROCOffers', @Time OUTPUT


	/*******************************************************************************************************************************************
		20. Insert to OfferMemberAdditions
	*******************************************************************************************************************************************/

		DECLARE @GETDATE DATETIME = GETDATE()

		INSERT INTO [Iron].[OfferMemberAddition]
		SELECT CompositeID
			 , IronOfferID
			 , StartDate
			 , EndDate
			 , @GETDATE AS Date
			 , 0 AS IsControl
		FROM #Selection
			
		EXEC Staging.oo_TimerMessage 'Insert to OfferMemberAdditions', @Time OUTPUT


	/*******************************************************************************************************************************************
		21. Drop all temp tables
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#OfferIDs') IS NOT NULL DROP TABLE #OfferIDs
		IF OBJECT_ID('tempdb..#Gender') IS NOT NULL DROP TABLE #Gender
		IF OBJECT_ID('tempdb..#MarketableByEmail') IS NOT NULL DROP TABLE #MarketableByEmail
		IF OBJECT_ID('tempdb..#LiveOfferPerPartner') IS NOT NULL DROP TABLE #LiveOfferPerPartner
		IF OBJECT_ID('tempdb..#CustomersOnOfferAlready') IS NOT NULL DROP TABLE #CustomersOnOfferAlready
		IF OBJECT_ID('tempdb..##CustomerBase') IS NOT NULL DROP TABLE ##CustomerBase
		IF OBJECT_ID('tempdb..#SelectedInAnotherCampaign') IS NOT NULL DROP TABLE #SelectedInAnotherCampaign
		IF OBJECT_ID('tempdb..#MustBeIn') IS NOT NULL DROP TABLE #MustBeIn
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