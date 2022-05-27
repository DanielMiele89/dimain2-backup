
CREATE PROCEDURE [Selections].[CampaignSetup_Selection_IndividualCampaign_POS_V3] (@PartnerID CHAR(4)
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
																			 , @FreqStretch_TransCount INT
																			 , @ControlGroupPercentage INT
																			 , @ThrottleType CHAR(1))

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
FROM Selections.ROCShopperSegment_PreSelection_ALS
WHERE ID = 8878

*/




	/*******************************************************************************************************************************************
		1. Prepare parameters for script
	*******************************************************************************************************************************************/

		DECLARE	@SQLCode NVARCHAR(MAX)
			,	@Time DATETIME
			,	@SSMS BIT = NULL
			,	@Msg VARCHAR(2048)

		SELECT @msg = 'Starting CampaignSetup_Selection_IndividualCampaign_POS'
		EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

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
			  , @FreqStretch_TransDate DATE = DATEADD(day, -364, @StartDate)
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
				2.3. Marketable By Email details
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

				SELECT @msg = 'Extricating parameters'
				EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


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
						FROM [Relational].[IronOffer] iof
						WHERE PartnerID = @PartnerID
						AND (iof.EndDate > @StartDate OR iof.EndDate IS NULL)
						AND iof.CampaignType NOT LIKE '%Base%'
						AND iof.IsSignedOff = 1
						AND NOT EXISTS (SELECT 1
										FROM [Relational].[Partner_NonCoreBaseOffer] ncb
										WHERE iof.IronOfferID = ncb.IronOfferID)

						CREATE CLUSTERED INDEX CIX_IronOfferID ON #LiveOfferPerPartner (IronOfferID)
						
						SELECT @msg = 'Fetch all live offers for this partner'
						EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT
	
					/***********************************************************************************************************************
						3.1.2. Fetch all customers assigned offers for this partner
					***********************************************************************************************************************/

						IF OBJECT_ID('tempdb..#CustomersOnOfferAlready') IS NOT NULL DROP TABLE #CustomersOnOfferAlready
						SELECT	iom.CompositeID
						INTO #CustomersOnOfferAlready
						FROM [Relational].[IronOfferMember] iom
						INNER JOIN #LiveOfferPerPartner lopp
							ON iom.IronOfferID = lopp.IronOfferID
						WHERE iom.EndDate > @StartDate

						INSERT INTO #CustomersOnOfferAlready
						SELECT	iom.CompositeID
						FROM [Relational].[IronOfferMember] iom
						INNER JOIN #LiveOfferPerPartner lopp
							ON iom.IronOfferID = lopp.IronOfferID
						WHERE iom.EndDate IS NULL

						CREATE CLUSTERED INDEX CIX_CompositeID ON #CustomersOnOfferAlready (CompositeID)

						SELECT @msg = 'Fetch all customers assigned offers for this partner'
						EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

	
		/***********************************************************************************************************************
			3.2. Fetch control group customers
		***********************************************************************************************************************/
			
			IF OBJECT_ID ('tempdb..#ControlGroupCustomers') IS NOT NULL DROP TABLE #ControlGroupCustomers
			SELECT CompositeID
			INTO #ControlGroupCustomers
			FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] cg
			INNER JOIN Relational.Customer cu
				ON cg.FanID = cu.FanID
			WHERE PartnerID = @PartnerID
			AND EndDate >= @StartDate

			CREATE CLUSTERED INDEX CIX_CompositeID ON #ControlGroupCustomers (CompositeID) WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)

			SELECT @msg = 'Fetch control group customers'
			EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


		/*******************************************************************************************************************************************
			3.3. Exec competitior steal campaigns where required
		*******************************************************************************************************************************************/
	
			IF @CampaignID_Include != ''
				BEGIN
					EXEC Warehouse.Selections.Partner_GenerateTriggerMember @CampaignID_Include
				END

			IF @CampaignID_Exclude != ''
				BEGIN
					EXEC Warehouse.Selections.Partner_GenerateTriggerMember @CampaignID_Exclude
				END
			
			SELECT @msg = 'Exec competitior steal campaigns'
			EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


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
					
						INSERT INTO #SelectedInAnotherCampaign (ClientServicesRef)
						SELECT Item AS ClientServicesRef
						FROM SelectedInAnotherCampaign
						CROSS APPLY dbo.il_SplitDelimitedStringArray (ClientServicesRef, ',') mbe
	
						CREATE CLUSTERED INDEX CIX_SelectedInAnotherCampaign_ClientServicesRef ON #SelectedInAnotherCampaign (ClientServicesRef)
					
								
					/***********************************************************************************************************************
						3.4.2. Store customers that have been previously exposed to the given campaigns
					***********************************************************************************************************************/
	
						IF OBJECT_ID('tempdb..#SelectedInAnotherCampaignCustomers') IS NOT NULL DROP TABLE #SelectedInAnotherCampaignCustomers
						SELECT DISTINCT
							   iom.CompositeID
						INTO #SelectedInAnotherCampaignCustomers
						FROM Relational.IronOfferMember iom
						WHERE EXISTS (SELECT 1
									  FROM #SelectedInAnotherCampaign siac
									  INNER JOIN Relational.IronOffer_Campaign_HTM htm
										  ON siac.ClientServicesRef = htm.ClientServicesRef
									  Where iom.IronOfferID = htm.IronOfferID)
	
				
					/***********************************************************************************************************************
						3.4.3. Add in customers that have joined since that point if there's a welcome offer running
					***********************************************************************************************************************/

						IF EXISTS (SELECT 1 FROM #OfferIDs WHERE ShopperSegmentTypeID = 10)
							BEGIN

								INSERT INTO #SelectedInAnotherCampaignCustomers
								SELECT c.CompositeID
								FROM [Selections].[CustomerBase] c
								WHERE c.ActivatedDate > @ActivatedDate

							END					
	
						CREATE CLUSTERED INDEX CIX_MustBeIn_CompositeID ON #SelectedInAnotherCampaignCustomers (CompositeID) WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
				
					SELECT @msg = 'If campaign is targeting universe of previous campaign then fetch those customers'
					EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT
	
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
						FROM Relational.IronOffer iof
						INNER JOIN Relational.IronOffer_Campaign_HTM htm
							ON iof.IronOfferID = htm.IronOfferID
						WHERE htm.ClientServicesRef = @ClientServicesRef
	
						CREATE CLUSTERED INDEX CIX_IronOfferID ON #ExistingUniverseOffers (IronOfferID)
		
					/***********************************************************************************************************************
						3.5.2. Fetch all customers that have been assigned any of the previous offers
					***********************************************************************************************************************/
	
						IF OBJECT_ID ('tempdb..#ExistingUniverse') IS NOT NULL DROP TABLE #ExistingUniverse
						SELECT eu.CompositeID
						INTO #ExistingUniverse
						FROM Selections.CampaignSetup_ExistingUniverse eu
						WHERE EXISTS (SELECT 1
									  FROM #ExistingUniverseOffers euo
									  WHERE eu.IronOfferID = euo.IronOfferID
									  AND eu.StartDate = @CustomerBaseOfferDate)
	
				
					/***********************************************************************************************************************
						3.5.3. Add in customers that have joined since that point if there's a welcome offer running
					***********************************************************************************************************************/

						IF EXISTS (SELECT 1 FROM #OfferIDs WHERE ShopperSegmentTypeID = 10)
							BEGIN

								INSERT INTO #ExistingUniverse
								SELECT c.CompositeID
								FROM [Selections].[CustomerBase] c
								WHERE c.ActivatedDate > @ActivatedDate

							END					
	
						CREATE CLUSTERED INDEX CIX_MustBeIn_CompositeID ON #ExistingUniverse (CompositeID) WITH (DATA_COMPRESSION = ROW, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
				
						SELECT @msg = 'Find customers previously selected in this campaign'
						EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT
	
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
						FROM Relational.Outlet o
						WHERE o.PartnerID = @PartnerID
						AND LEFT(MerchantID, 1) NOT IN ('a', 'x', '#')
		
					/***********************************************************************************************************************
						3.6.2. Fetch all customers within desginated drive time of the previous postal sectors
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
				
						SELECT @msg = 'Find customers living within designated drivetime'
						EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

				END	--	IF @LiveNearAnyStore = 1 AND @DriveTimeMins != ''

	/*******************************************************************************************************************************************
		4. Build customer base
	*******************************************************************************************************************************************/
			
		/***********************************************************************************************************************
			4.1. Fetch customer universe
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
														FROM [Relational].[CAMEO] ca
														INNER JOIN Relational.CAMEO_CODE cc
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

			IF @CampaignID_Include != ''
				BEGIN
					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND EXISTS (	SELECT 1
														FROM [Relational].[PartnerTrigger_Members] ptm
														WHERE cb.FanID = ptm.FanID
														AND ptm.CampaignID = ' + @CampaignID_Include + ')'
				END
				
			IF @CampaignID_Exclude != ''
				BEGIN
					SET @CustomerBaseQuery = @CustomerBaseQuery + '
										AND NOT EXISTS (SELECT 1
														FROM [Relational].[PartnerTrigger_Members] ptm
														WHERE cb.FanID = ptm.FanID
														AND ptm.CampaignID = ' + @CampaignID_Exclude + ')'
				END

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

			SELECT @msg = 'Collecting ##CustomerBase'
			EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

			CREATE CLUSTERED INDEX CIX_CompositeID ON ##CustomerBase (CompositeID, ShopperSegmentTypeID, ControlGroupCustomer) WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
			CREATE NONCLUSTERED INDEX IX_FanID ON ##CustomerBase (FanID) WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
			CREATE NONCLUSTERED INDEX IX_CompSeg ON ##CustomerBase (CompositeID, ShopperSegmentTypeID) WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)



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

						SELECT @msg = 'Update welcome details'
						EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

					END

			
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
			
						SELECT @msg = 'Update birthday details'
						EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

					END

			
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
			
						SELECT @msg = 'Update homemover details'
						EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT

					END

			
		/***********************************************************************************************************************
			4.5. Indexing ##CustomerBase
		***********************************************************************************************************************/

			ALTER INDEX CIX_CompositeID ON ##CustomerBase REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
			ALTER INDEX IX_FanID ON ##CustomerBase REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
			ALTER INDEX IX_CompSeg ON ##CustomerBase REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR = 80, SORT_IN_TEMPDB = ON)
			
			SELECT @msg = 'Indexing ##CustomerBase'
			EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT



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
			
		SELECT @msg = 'Fetch customers from the MustBeIn tables'
		EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT
			

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

		SELECT @msg = 'Fetch customers from the NotIn tables'
		EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


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
			
		SELECT @msg = 'Remove customers that have meet the designated amount of purchases per campaign'
		EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


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
				INNER JOIN ##CustomerBase cb
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
							 , ROW_NUMBER() OVER (PARTITION BY iof.IronOfferID ORDER BY cr.Engagement_Rank ASC) AS RowNum
						--	 , ROW_NUMBER() OVER (PARTITION BY iof.IronOfferID ORDER BY cr.Ranking ASC) AS RowNum			--	Swapped To Engagement Ranking 2021-01-15
						FROM ##CustomerBase cb
						INNER JOIN #OfferIDs iof
							ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
						LEFT JOIN [Warehouse].[InsightArchive].[EngagementScore] cr
							ON cb.FanID = cr.FanID
						--LEFT JOIN Segmentation.[Roc_Shopper_Segment_CustomerRanking] cr									--	Swapped To Engagement Ranking 2021-01-15
						--	ON cb.FanID = cr.FanID																			--	Swapped To Engagement Ranking 2021-01-15
						--	AND cr.PartnerID = @PartnerID																	--	Swapped To Engagement Ranking 2021-01-15
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
						WHERE ControlGroupCustomer = 0) cb
				WHERE RowNum <= Throttling
			END
			
		SELECT @msg = 'Output to assign offers and apply throttling if required'
		EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		13. Create in programme control group
	*******************************************************************************************************************************************/
	
		IF @ControlGroupPercentage > 0
			BEGIN

				DECLARE @AcquireCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 7) * 1.000 / 100) * @ControlGroupPercentage
					  , @LaspsedCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 8) * 1.000 / 100) * @ControlGroupPercentage
					  , @ShopperCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 9) * 1.000 / 100) * @ControlGroupPercentage
					  , @WelcomeCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 10) * 1.000 / 100) * @ControlGroupPercentage
					  , @HomemoverCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 11) * 1.000 / 100) * @ControlGroupPercentage
					  , @BirthdayCount INT = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 12) * 1.000 / 100) * @ControlGroupPercentage

				IF EXISTS (SELECT 1 FROM #OfferIDs WHERE IronOfferID = 25076)
					BEGIN
						
						SET @AcquireCount = ((SELECT COUNT(*) FROM #Selection WHERE ShopperSegmentTypeID = 7) * 1.000 / 100) * 5

					END
					 
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
				LEFT JOIN [Warehouse].[InsightArchive].[EngagementScore] cr
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
				FROM ##CustomerBase cb
				INNER JOIN #OfferIDs iof
					  ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
				LEFT JOIN [Warehouse].[InsightArchive].[EngagementScore] cr
					  ON cb.FanID = cr.FanID
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
						WHERE EXISTS (	SELECT 1
										FROM #ControlGroup cg
										INNER JOIN [WH_AllPublishers].[Derived].[Offer] o
											ON cg.IronOfferID = o.IronOfferID
										WHERE ipcg.ClientServicesRef = cg.ClientServicesRef
										AND ipcg.StartDate = cg.StartDate
										AND ipcg.PublisherID = o.PublisherID)
					END

				INSERT INTO [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] (	[PublisherID]
																							,	[PartnerID]
																							,	[ClientServicesRef]
																							,	[IronOfferID]
																							,	[ShopperSegmentTypeID]
																							,	[StartDate]
																							,	[EndDate]
																							,	[FanID]
																							,	[PercentageTaken]
																							,	[ExcludeFromAnalysis])
				SELECT	o.PublisherID
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
					ON cgn.IronOfferID = o.IronOfferID
				WHERE NOT EXISTS (	SELECT 1
									FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] cne
									WHERE cgn.FanID = cne.FanID
									AND cgn.ClientServicesRef = cne.ClientServicesRef
									AND @StartDate BETWEEN cne.StartDate AND cne.EndDate)
				
			END	--	IF @ControlGroupPercentage > 0
			

		SELECT @msg = 'Create in programme control group'
		EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


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

		SELECT @msg = 'Output to final table'
		EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


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
			 , 4 AS CampaignTypeID
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
			
		SELECT @msg = 'Insert to [Selections].[CampaignExecution_TableNames], CBP_CampaignNames, IronOffer_Campaign_Type, IronOffer_ROCOffers'
		EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


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

		SELECT @msg = 'Insert to OfferMemberAdditions'
		EXEC [SLC_Report].[dbo].[oo_TimerMessageV2] @msg, @time Output, @SSMS OUTPUT


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