
CREATE PROCEDURE [Selections].[CampaignSetup_Selection_IndividualCampaign_DD] (@PartnerID CHAR(4)
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
																			, @ControlGroupPercentage INT
																			, @ThrottleType VARCHAR(1)
)

AS
BEGIN
/****************************************************************************************************
Title:			CampaignSetup_Selection_IndividualCampaign_DD
Author:			Rory Francis
Creation Date:	2019-02-05
Purpose:		Looped selection of an indivdual Merchant Funded Direct Debit Offer
-----------------------------------------------------------------------------------------------------
Modified Log:

Change No:	Name:			Date:			Description of change:

			
****************************************************************************************************/


	/*******************************************************************************************************************************************
		1. Prepare parameters for script
	*******************************************************************************************************************************************/

		DECLARE @SQLCode NVARCHAR(MAX)
			  , @Time DATETIME
			  , @Msg VARCHAR(2048)

		EXEC [Staging].[oo_TimerMessage] 'Starting CampaignSetup_Selection_IndividualCampaign_DD', @Time OUTPUT

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
			  , @HomemoverDate DATE = DATEADD(day, -28, @StartDate)
			  , @ActivatedDate DATE = DATEADD(day, -28, @StartDate)
			  , @EndDateTime DATETIME = DATEADD(second, -1, CONVERT(DATETIME, DATEADD(day, 1, @EndDate)))
			  , @AgeRange_Min INT = LEFT(@AgeRange, CHARINDEX('-', @AgeRange) - 1)
			  , @AgeRange_Max INT = RIGHT(@AgeRange, LEN(@AgeRange) - CHARINDEX('-', @AgeRange))
			  , @SocialClass_Min VARCHAR(5) = LEFT(@SocialClass, CHARINDEX('-', @SocialClass) - 1)
			  , @SocialClass_Max VARCHAR(5) = RIGHT(@SocialClass, LEN(@SocialClass) - CHARINDEX('-', @SocialClass))
			  , @TotalCustomers INT = (SELECT COUNT(*) FROM [Relational].[Customer])


	/*******************************************************************************************************************************************
		2. Create tables to hold details previously held in comma seperated column
	*******************************************************************************************************************************************/
			
			/***********************************************************************************************************************
				2.1. Offer details
			***********************************************************************************************************************/

				DECLARE @Throttled BIT = (SELECT CASE WHEN @Throttling = '0,0,0,0,0,0' THEN 0 ELSE 1 END)
			
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
				CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (ShopperSegmentTypeID, ',') sst
				CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (IronOfferID, ',') iof
				CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (Throttling, ',') thr
				WHERE sst.ItemNumber = iof.ItemNumber
				AND iof.ItemNumber = thr.ItemNumber
				AND iof.Item > 0

				EXEC [Staging].[oo_TimerMessage] 'Extricating parameters', @Time OUTPUT
		
				CREATE CLUSTERED INDEX CIX_ShopperSegmentTypeID on #OfferIDs (ShopperSegmentTypeID)
			
					/***********************************************************************************************************************
						2.1.1. If PartnerID does not match the PartnerID linked to each offer then exit
					***********************************************************************************************************************/
					
							IF EXISTS (SELECT 1
									   FROM #OfferIDs o
									   INNER JOIN [Relational].[IronOffer] iof
										   ON o.IronOfferID = iof.IronOfferID
										   AND iof.PartnerID != @PartnerID)
								BEGIN
									PRINT 'PartnerID linked to campaign does not match the PartnerID the selected offers have been set up under'
									RETURN
								END
			

			/***********************************************************************************************************************
				2.2. Gender details
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#Gender') IS NOT NULL DROP TABLE #Gender
				CREATE TABLE #Gender (Gender VARCHAR(1));

				WITH Gender AS (SELECT @Gender AS Gender)
				
				INSERT INTO #Gender (Gender)
				SELECT Item AS Gender
				FROM Gender
				CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (Gender, ',') ge
		
				CREATE CLUSTERED INDEX CIX_Gender_Gender on #Gender (Gender)
			
			/***********************************************************************************************************************
				2.2. Marketable By Email details
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#MarketableByEmail') IS NOT NULL DROP TABLE #MarketableByEmail
				CREATE TABLE #MarketableByEmail (MarketableByEmail VARCHAR(1));

				WITH MarketableByEmail AS (SELECT @MarketableByEmail AS MarketableByEmail)
				
				INSERT INTO #MarketableByEmail (MarketableByEmail)
				SELECT Item AS Gender
				FROM MarketableByEmail
				CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (MarketableByEmail, ',') mbe
				
				CREATE CLUSTERED INDEX CIX_Gender on #MarketableByEmail (MarketableByEmail)

	/*******************************************************************************************************************************************
		3. Find customers already on an offer for this partner
	*******************************************************************************************************************************************/
	
		/***********************************************************************************************************************
			3.1. Fetch all live offers for this partner
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
	
		/***********************************************************************************************************************
			3.2. Fetch all live offers for this partner
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CustomersOnOfferAlready') IS NOT NULL DROP TABLE #CustomersOnOfferAlready
			SELECT DISTINCT
				   iom.CompositeID
			INTO #CustomersOnOfferAlready
			FROM [Relational].[IronOfferMember] iom
			INNER JOIN #LiveOfferPerPartner lopp
				ON iom.IronOfferID = lopp.IronOfferID
			WHERE (iom.EndDate > @StartDate OR iom.EndDate IS NULL)

			CREATE CLUSTERED INDEX CIX_CompositeID ON #CustomersOnOfferAlready (CompositeID)


	/*******************************************************************************************************************************************
		4. Build customer base
	*******************************************************************************************************************************************/
			
		/***********************************************************************************************************************
			4.1. Fetch credit card only customers
		***********************************************************************************************************************/
			
			IF OBJECT_ID ('tempdb..#CreditCardCustomer') IS NOT NULL DROP TABLE #CreditCardCustomer
			SELECT DISTINCT
				   ipc.IssuerCustomerID
			INTO #CreditCardCustomer
			FROM [SLC_Report].[dbo].[PaymentCard] pc
			INNER JOIN [SLC_Report].[dbo].[IssuerPaymentCard] ipc
				ON pc.ID = ipc.PaymentCardID
			WHERE pc.CardTypeID = 1
			AND ipc.Status = 1
			AND EXISTS (SELECT 1
						FROM [SLC_Report].[dbo].[IssuerCustomer] ic
						INNER JOIN [SLC_Report].[dbo].[Fan] fa
							ON ic.SourceUID = fa.SourceUID
							AND fa.ClubID IN (132, 138)
							AND fa.[Status] = 1
						WHERE ipc.IssuerCustomerID = ic.ID)
			
			IF OBJECT_ID ('tempdb..#CreditCardOnly') IS NOT NULL DROP TABLE #CreditCardOnly
			SELECT fa.CompositeID
			INTO #CreditCardOnly
			FROM #CreditCardCustomer ccc
			INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
				ON ccc.IssuerCustomerID = ic.ID
			INNER JOIN [SLC_Report].[dbo].[Fan] fa
				ON ic.SourceUID = fa.SourceUID
				AND fa.ClubID IN (132, 138)
				AND fa.[Status] = 1
			WHERE NOT EXISTS (SELECT 1
							  FROM [SLC_Report].[dbo].[IssuerBankAccount] iba
							  WHERE ccc.IssuerCustomerID = iba.IssuerCustomerID
							  AND iba.CustomerStatus = 1)

			CREATE CLUSTERED INDEX CIX_CompositeID ON #CreditCardOnly (CompositeID)
	
			EXEC [Staging].[oo_TimerMessage] 'Collecting #CreditCardOnly', @Time OUTPUT

			
		/***********************************************************************************************************************
			4.2. Fetch control group customers
		***********************************************************************************************************************/
			
			IF OBJECT_ID ('tempdb..#ControlGroupCustomers') IS NOT NULL DROP TABLE #ControlGroupCustomers
			SELECT CompositeID
			INTO #ControlGroupCustomers
			FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] cg
			INNER JOIN Relational.Customer cu
				ON cg.FanID = cu.FanID
			WHERE PartnerID = @PartnerID
			AND EndDate > @StartDate

			CREATE CLUSTERED INDEX CIX_CompositeID ON #ControlGroupCustomers (CompositeID)


		/***********************************************************************************************************************
			4.3. Fetch customer universe
		***********************************************************************************************************************/

			IF OBJECT_ID ('tempdb..#CustomerBaseTemp') IS NOT NULL DROP TABLE #CustomerBaseTemp
			SELECT DISTINCT
				   cu.FanID
				 , cu.CompositeID
				 , cu.Postcode
				 , CASE
						WHEN cu.ActivatedDate > @ActivatedDate AND EXISTS (SELECT 1 FROM #OfferIDs WHERE ShopperSegmentTypeID = 10) THEN 10
						WHEN FLOOR(DATEDIFF(dd, DOB, @StartDate) / 365.25) != FLOOR(DATEDIFF(dd, DOB, @EndDate) / 365.25) AND EXISTS (SELECT 1 FROM #OfferIDs WHERE ShopperSegmentTypeID = 11) THEN 11
						ELSE ShopperSegmentTypeID
				   END AS ShopperSegmentTypeID
			INTO #CustomerBaseTemp
			FROM [Relational].[Customer] cu
			INNER JOIN [Segmentation].[CustomerSegment_DD] cs
				ON cu.FanID = cs.FanID
				AND cs.PartnerID = @PartnerID
				AND cs.EndDate IS NULL
			WHERE cu.CurrentlyActive = 1
			AND cu.Gender IN (SELECT Gender FROM #Gender)
			AND cu.MarketableByEmail IN (SELECT MarketableByEmail FROM #MarketableByEmail)
			AND cu.AgeCurrent BETWEEN @AgeRange_Min AND @AgeRange_Max

			CREATE CLUSTERED INDEX CIX_CompositeID ON #CustomerBaseTemp (CompositeID)

			IF OBJECT_ID ('tempdb..#CustomerBase') IS NOT NULL DROP TABLE #CustomerBase
			SELECT Distinct 
				   cb.FanID
				 , cb.CompositeID
				 , cb.Postcode
				 , cb.ShopperSegmentTypeID
			INTO #CustomerBase
			FROM #CustomerBaseTemp cb
			WHERE NOT EXISTS (SELECT 1
							  FROM #ControlGroupCustomers cgc
							  WHERE cb.CompositeID = cgc.CompositeID)
			AND NOT EXISTS (SELECT 1
							FROM Selections.CampaignSetup_PartnerDedupe_DD pd
							WHERE cb.CompositeID = pd.CompositeID)
			AND NOT EXISTS (SELECT 1
							FROM #CustomersOnOfferAlready cooa
							WHERE cb.CompositeID = cooa.CompositeID)
			AND NOT EXISTS (SELECT 1
							FROM #CreditCardOnly cco
							WHERE cco.CompositeID = cb.CompositeID)
			--AND EXISTS (SELECT 1
			--			FROM [SLC_Report].[dbo].[Pan] pa With (NoLock) 
			--			INNER JOIN [SLC_Report].[dbo].[PaymentCard] pc
			--				ON pa.PaymentCardID = pc.ID
			--			INNER JOIN [SLC_Report].[dbo].[Fan] fa
			--				ON pa.CompositeID = fa.CompositeID
			--			WHERE CardTypeID = 2
			--			AND cu.FanID = fa.ID)
			--AND NOT EXISTS (SELECT 1
			--				FROM Selections.ROCShopperSegment_SeniorStaffAccounts ssa
			--				WHERE cu.CompositeID = ssa.CompositeID)
	
			EXEC [Staging].[oo_TimerMessage] 'Collecting #CustomerBase', @Time OUTPUT
								
			IF @SocialClassFilter != ''
				BEGIN
					DELETE cu
					FROM #CustomerBase cu
					LEFT JOIN [Relational].[CAMEO] ca
						ON ca.Postcode = cu.PostCode
					LEFT JOIN [Relational].[CAMEO_CODE] cc
						ON cc.CAMEO_CODE = ca.CAMEO_CODE
					WHERE cc.Social_Class NOT BETWEEN @SocialClass_Min AND @SocialClass_Max
					OR cc.Social_Class IS NULL
				END
			
		/***********************************************************************************************************************
			4.4. Update homemover details
		***********************************************************************************************************************/

			IF EXISTS (SELECT 1 FROM #OfferIDs WHERE ShopperSegmentTypeID = 12)
				BEGIN
					--IF OBJECT_ID ('tempdb..#Homemover_Details') IS NOT NULL DROP TABLE #Homemover_Details
					--SELECT DISTINCT
					--	   FanID
					--INTO #Homemover_Details
					--FROM [Relational].[Homemover_Details hm
					--WHERE hm.LoadDate >= @HomemoverDate

					--UPDATE cb
					--SET cb.ShopperSegmentTypeID = 12
					--FROM #CustomerBase cb
					--INNER JOIN #Homemover_Details hd
					--	on cb.FanID = hd.FanID
					--WHERE ShopperSegmentTypeID NOT IN (10,11)

					UPDATE cb
					SET ShopperSegmentTypeID = 12
					FROM #CustomerBase cb
					WHERE cb.ShopperSegmentTypeID NOT IN (10,11)
					AND EXISTS (SELECT 1 
								FROM [Relational].[Homemover_Details] hm
								WHERE hm.LoadDate >= @HomemoverDate
								AND cb.FanID = hm.FanID)

				END

	--	CREATE CLUSTERED INDEX CIX_CustomerBase_CompositeID on #CustomerBase (CompositeID)
	--	CREATE NONCLUSTERED INDEX IX_CustomerBase_FanID on #CustomerBase (FanID)

	/*******************************************************************************************************************************************
		5. Exec competitior steal campaigns where required
	*******************************************************************************************************************************************/
	
		IF @CampaignID_Include != ''
			BEGIN
				EXEC [Selections].[Partner_GenerateTriggerMember] @CampaignID_Include

				DELETE cb
				FROM #CustomerBase cb
				WHERE NOT EXISTS (SELECT 1
								  FROM [Relational].[PartnerTrigger_Members] ptm
								  WHERE cb.FanID = ptm.FanID
								  AND ptm.CampaignID = @CampaignID_Include)

			END

		IF @CampaignID_Exclude != ''
			BEGIN
				EXEC [Selections].[Partner_GenerateTriggerMember] @CampaignID_Exclude

				DELETE cb
				FROM #CustomerBase cb
				WHERE EXISTS (SELECT 1
							  FROM [Relational].[PartnerTrigger_Members] ptm
							  WHERE cb.FanID = ptm.FanID
							  AND ptm.CampaignID = @CampaignID_Include)
			END


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
					CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (ClientServicesRef, ',') mbe

					CREATE CLUSTERED INDEX CIX_SelectedInAnotherCampaign_ClientServicesRef ON #SelectedInAnotherCampaign (ClientServicesRef)
				
							
				/***********************************************************************************************************************
					6.2. Store customers that have been previously exposed to the given campaigns
				***********************************************************************************************************************/

					IF OBJECT_ID('tempdb..#MustBeIn') IS NOT NULL DROP TABLE #MustBeIn
					SELECT DISTINCT
						   iom.CompositeID
					INTO #MustBeIn
					FROM [Relational].[IronOfferMember] iom
					WHERE EXISTS (SELECT 1
								  FROM #SelectedInAnotherCampaign siac
								  INNER JOIN [Relational].[IronOffer_Campaign_HTM] htm
									  ON siac.ClientServicesRef = htm.ClientServicesRef
								  Where iom.IronOfferID = htm.IronOfferID)

					CREATE CLUSTERED INDEX CIX_MustBeIn_CompositeID ON #MustBeIn (CompositeID)

			
				/***********************************************************************************************************************
					6.3. Remove customers than have not previously been selected
				***********************************************************************************************************************/

					DELETE cb
					FROM #CustomerBase cb
					WHERE ShopperSegmentTypeID != 10
					AND NOT EXISTS (SELECT 1
									FROM #MustBeIn mbi
									WHERE cb.CompositeID = mbi.CompositeID)


			END	--	IF @SelectedInAnotherCampaign != ''

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
					FROM [Relational].[IronOffer] iof
					INNER JOIN [Relational].[IronOffer_Campaign_HTM] htm
						ON iof.IronOfferID = htm.IronOfferID
					WHERE htm.ClientServicesRef = @ClientServicesRef

					CREATE CLUSTERED INDEX CIX_IronOfferID ON #ExistingUniverseOffers (IronOfferID)
	
				/***********************************************************************************************************************
					7.2. Fetch all customers that have been assigned any of the previous offers
				***********************************************************************************************************************/

					IF OBJECT_ID ('tempdb..#ExistingUniverse') IS NOT NULL DROP TABLE #ExistingUniverse
					SELECT DISTINCT
						   iom.CompositeID
					INTO #ExistingUniverse
					FROM [Relational].[IronOfferMember] iom
					INNER JOIN #ExistingUniverseOffers euo
						ON iom.IronOfferID = euo.IronOfferID
					WHERE iom.StartDate = @CustomerBaseOfferDate
				
					CREATE CLUSTERED INDEX CIX_CompositeID on #ExistingUniverse (CompositeID)

			
				/***********************************************************************************************************************
					7.3. Remove customers than have not previously been selected
				***********************************************************************************************************************/

					DELETE cb
					FROM #CustomerBase cb
					WHERE ShopperSegmentTypeID != 10
					AND NOT EXISTS (SELECT 1
									FROM #ExistingUniverse eu
									WHERE cb.CompositeID = eu.CompositeID)

			END	--	IF @CustomerBaseOfferDate IS NOT NULL

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
					FROM [Relational].[Outlet] o
					WHERE o.PartnerID = @PartnerID
					AND LEFT(MerchantID, 1) NOT IN ('a', 'x', '#')
	
				/***********************************************************************************************************************
					8.2. Fetch all customers within desginated drive time of the previous postal sectors
				***********************************************************************************************************************/
				
					IF OBJECT_ID ('tempdb..#CustomersWithinDrivetime') IS NOT NULL DROP TABLE #CustomersWithinDrivetime
					SELECT DISTINCT
						   cu.CompositeID
					INTO #CustomersWithinDrivetime
					FROM [Relational].[Customer] cu
					INNER JOIN [Relational].[DriveTimeMatrix] dtm
						ON cu.PostalSector = dtm.FROMSector
					INNER JOIN #PostalSectors ps
						ON dtm.ToSector = ps.PostalSector
						AND dtm.DriveTimeMins <= @DriveTimeMins
						
					CREATE CLUSTERED INDEX CIX_CompositeID ON #CustomersWithinDrivetime (CompositeID)

			
				/***********************************************************************************************************************
					8.3. Remove customers than have not previously been selected
				***********************************************************************************************************************/

					DELETE cb
					FROM #CustomerBase cb
					WHERE NOT EXISTS (SELECT 1
									  FROM #CustomersWithinDrivetime cwd
									  WHERE cb.CompositeID = cwd.CompositeID)

			END	--	IF @LiveNearAnyStore = 1 AND @DriveTimeMins != ''

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
					FROM #CustomerBase cb
					WHERE NOT EXISTS (SELECT 1
									  FROM #MustBeIn_TableName mbi
									  WHERE cb.FanID = mbi.FanID)

			END	--	IF @MustBeIn_TableCount > 0


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
					FROM #CustomerBase cb
					WHERE EXISTS (SELECT 1
								  FROM #NotIn_TableName ni
								  WHERE cb.FanID = ni.FanID)

			END	--	IF LEN(@NotIn_TableName1 + @NotIn_TableName2 + @NotIn_TableName3 + @NotIn_TableName4) > 0


	/*******************************************************************************************************************************************
		11. Output to assign offers and apply throttling if required
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Selection') IS NOT NULL DROP TABLE #Selection
		CREATE TABLE #Selection (FanID BIGINT
							   , CompositeID BIGINT
							   , ShopperSegmentTypeID INT
							   , IronOfferID INT
							   , StartDate DATETIME
							   , EndDate DATETIME)
			
		/***********************************************************************************************************************
			11.1. Convert throttle percentage to actual counts
		***********************************************************************************************************************/

			IF @Throttled = 1 AND @ThrottleType = '%'
				BEGIN
					IF OBJECT_ID('tempdb..#ThrottleUpdate') IS NOT NULL DROP TABLE #ThrottleUpdate
					SELECT oi.ShopperSegmentTypeID
						 , oi.Throttling
						 , COUNT(DISTINCT mfh.HouseholdID) AS Households
					INTO #ThrottleUpdate
					FROM #OfferIDs oi
					INNER JOIN #CustomerBase cb
					   ON oi.ShopperSegmentTypeID = cb.ShopperSegmentTypeID
					INNER JOIN [Relational].[MFDD_Households] mfh
					   ON cb.FanID = mfh.FanID
					   AND mfh.EndDate IS NULL
					GROUP BY oi.ShopperSegmentTypeID
						  , oi.Throttling

					UPDATE oi
					SET oi.Throttling = oi.Throttling * tu.Households / 100.0
					FROM #OfferIDs oi
					INNER JOIN #ThrottleUpdate tu
						ON oi.ShopperSegmentTypeID = tu.ShopperSegmentTypeID
				END

		/***********************************************************************************************************************
			11.2. Randomly throttle is condition met
		***********************************************************************************************************************/

			IF @RandomThrottle = 0
				BEGIN
					INSERT INTO #Selection
					SELECT FanID
						 , CompositeID
						 , ShopperSegmentTypeID
						 , IronOfferID
						 , @StartDate
						 , @EndDateTime
					FROM (	SELECT	cb.FanID
								,	cb.CompositeID
								,	cb.ShopperSegmentTypeID
								,	iof.IronOfferID
								,	iof.Throttling
								,	DENSE_RANK() OVER (PARTITION BY iof.IronOfferID ORDER BY cr.Engagement_Rank ASC) AS RowNum	--	Swapped To Engagement Ranking 2021-01-15
							--	,	DENSE_RANK() OVER (PARTITION BY iof.IronOfferID ORDER BY cr.Ranking ASC) AS RowNum
							FROM #CustomerBase cb
							INNER JOIN #OfferIDs iof
					  			ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
							LEFT JOIN [Warehouse].[InsightArchive].[EngagementScore] cr
								ON cb.FanID = cr.FanID
							--LEFT JOIN [Segmentation].[CustomerRanking_DD] cr													--	Swapped To Engagement Ranking 2021-01-15
							--	ON cb.FanID = cr.FanID																			--	Swapped To Engagement Ranking 2021-01-15
							--	AND cr.PartnerID = @PartnerID																	--	Swapped To Engagement Ranking 2021-01-15
						  ) cb
					WHERE RowNum <= Throttling


				END

			
		/***********************************************************************************************************************
			11.2. Throttle by determined criteria if condition met
		***********************************************************************************************************************/

			IF @RandomThrottle = 1
				BEGIN
					INSERT INTO #Selection
					SELECT FanID
						 , CompositeID
						 , ShopperSegmentTypeID
						 , IronOfferID
						 , @StartDate
						 , @EndDateTime
					FROM (SELECT cb.FanID
					  		   , cb.CompositeID
					  		   , cb.ShopperSegmentTypeID
					  		   , iof.IronOfferID
					  		   , iof.Throttling
							   , ROW_NUMBER() OVER (PARTITION BY iof.IronOfferID ORDER BY ABS(CHECKSUM(NewID())) ASC) AS RowNum
						  FROM #CustomerBase cb
						  INNER JOIN #OfferIDs iof
					  		  ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID) cb
					WHERE RowNum <= Throttling
				END


	/*******************************************************************************************************************************************
		12. Create in programme control group
	*******************************************************************************************************************************************/
	
		IF @ControlGroupPercentage > 0
			BEGIN
				
				DECLARE @AcquireCount INT = ((SELECT COUNT(DISTINCT mf.HouseholdID) FROM #CustomerBase s INNER JOIN [Relational].[MFDD_Households] mf ON s.FanID = mf.FanID AND mf.EndDate IS NULL WHERE ShopperSegmentTypeID = 7) * 1.0 / 100) * @ControlGroupPercentage
					  , @LaspsedCount INT = ((SELECT COUNT(DISTINCT mf.HouseholdID) FROM #CustomerBase s INNER JOIN [Relational].[MFDD_Households] mf ON s.FanID = mf.FanID AND mf.EndDate IS NULL WHERE ShopperSegmentTypeID = 8) * 1.0 / 100) * @ControlGroupPercentage
					  , @ShopperCount INT = ((SELECT COUNT(DISTINCT mf.HouseholdID) FROM #CustomerBase s INNER JOIN [Relational].[MFDD_Households] mf ON s.FanID = mf.FanID AND mf.EndDate IS NULL WHERE ShopperSegmentTypeID = 9) * 1.0 / 100) * @ControlGroupPercentage
					  , @WelcomeCount INT = ((SELECT COUNT(DISTINCT mf.HouseholdID) FROM #CustomerBase s INNER JOIN [Relational].[MFDD_Households] mf ON s.FanID = mf.FanID AND mf.EndDate IS NULL WHERE ShopperSegmentTypeID = 10) * 1.0 / 100) * @ControlGroupPercentage
					  , @HomemoverCount INT = ((SELECT COUNT(DISTINCT mf.HouseholdID) FROM #CustomerBase s INNER JOIN [Relational].[MFDD_Households] mf ON s.FanID = mf.FanID AND mf.EndDate IS NULL WHERE ShopperSegmentTypeID = 11) * 1.0 / 100) * @ControlGroupPercentage
					  , @BirthdayCount INT = ((SELECT COUNT(DISTINCT mf.HouseholdID) FROM #CustomerBase s INNER JOIN [Relational].[MFDD_Households] mf ON s.FanID = mf.FanID AND mf.EndDate IS NULL WHERE ShopperSegmentTypeID = 12) * 1.0 / 100) * @ControlGroupPercentage

					 

				IF OBJECT_ID('tempdb..#ControlGroup_Setup') IS NOT NULL DROP TABLE #ControlGroup_Setup
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
					 , Ranking = cr.Engagement_Rank
				INTO #ControlGroup_Setup
				FROM #CustomerBase cb
				INNER JOIN #OfferIDs iof
					  ON cb.ShopperSegmentTypeID = iof.ShopperSegmentTypeID
				LEFT JOIN [Warehouse].[InsightArchive].[EngagementScore] cr
					ON cb.FanID = cr.FanID
				--LEFT JOIN [Segmentation].[CustomerRanking_DD] cr													--	Swapped To Engagement Ranking 2021-01-15
				--	ON cb.FanID = cr.FanID																			--	Swapped To Engagement Ranking 2021-01-15
				--	AND cr.PartnerID = @PartnerID																	--	Swapped To Engagement Ranking 2021-01-15
				WHERE NOT EXISTS (SELECT 1
								  FROM #Selection s
								  WHERE cb.FanID = s.FanID)
				UNION
				SELECT s.FanID
					 , s.ShopperSegmentTypeID
					 , s.IronOfferID
					 , CASE
							WHEN s.ShopperSegmentTypeID = 7 THEN @AcquireCount
							WHEN s.ShopperSegmentTypeID = 8 THEN @LaspsedCount
							WHEN s.ShopperSegmentTypeID = 9 THEN @ShopperCount
							WHEN s.ShopperSegmentTypeID = 10 THEN @WelcomeCount
							WHEN s.ShopperSegmentTypeID = 11 THEN @HomemoverCount
							WHEN s.ShopperSegmentTypeID = 12 THEN @BirthdayCount
					   END AS ControlGroupCount
					 , 2 AS ControlGroupOrder
					 , Ranking = cr.Engagement_Rank
				FROM #Selection s
				LEFT JOIN [Warehouse].[InsightArchive].[EngagementScore] cr
					ON s.FanID = cr.FanID
				--LEFT JOIN [Segmentation].[CustomerRanking_DD] cr													--	Swapped To Engagement Ranking 2021-01-15
				--	ON cb.FanID = cr.FanID																			--	Swapped To Engagement Ranking 2021-01-15
				--	AND cr.PartnerID = @PartnerID																	--	Swapped To Engagement Ranking 2021-01-15

				IF OBJECT_ID('tempdb..#Households') IS NOT NULL DROP TABLE #Households
				SELECT DISTINCT
					   HouseHoldID
					 , FanID
				INTO #Households
				FROM [Relational].[MFDD_Households] mfh
				WHERE mfh.EndDate IS NULL

				CREATE CLUSTERED INDEX CIX_FanID ON #Households (FanID)

				IF OBJECT_ID('tempdb..#ControlGroup') IS NOT NULL DROP TABLE #ControlGroup
				SELECT @PartnerID AS PartnerID
					 , @ClientServicesRef AS ClientServicesRef
					 , IronOfferID
					 , ShopperSegmentTypeID
					 , @StartDate AS StartDate
					 , @EndDate AS EndDate
					 , FanID
				INTO #ControlGroup
				FROM (SELECT cgs.FanID
						   , cgs.ShopperSegmentTypeID
						   , cgs.IronOfferID
						   , cgs.ControlGroupCount
						   , DENSE_RANK() OVER (PARTITION BY ShopperSegmentTypeID ORDER BY ControlGroupOrder, Ranking DESC, HouseHoldID DESC) AS RowNum
					  FROM #ControlGroup_Setup cgs
					  INNER JOIN #Households mfh
					      ON cgs.FanID = mfh.FanID) cg
				WHERE RowNum <= ControlGroupCount

				DELETE s
				FROM #Selection s
				WHERE EXISTS (SELECT 1
							  FROM #ControlGroup cg
							  WHERE s.FanID = cg.FanID)

				
				IF EXISTS (SELECT 1 FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] WHERE [ClientServicesRef] = @ClientServicesRef AND [StartDate] = @StartDate)
					BEGIN
						DELETE ipcg
						FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] ipcg
						WHERE EXISTS (SELECT 1
									  FROM #ControlGroup cg
									  WHERE ipcg.ClientServicesRef = cg.ClientServicesRef
									  AND ipcg.StartDate = cg.StartDate)
					END

				--SET @SQLCode = '
				--IF OBJECT_ID(''' + REPLACE(@OutputTableName,  '_Selection_', '_ControlGroup_') + ''') IS NOT NULL DROP TABLE ' + REPLACE(@OutputTableName,  '_Selection_', '_ControlGroup_') + '
				--CREATE TABLE ' + REPLACE(@OutputTableName,  '_Selection_', '_ControlGroup_') + '([PartnerID] [INT] NOT NULL
				--																			   , [ClientServicesRef] [VARCHAR](10) NOT NULL
				--																			   , [IronOfferID] [INT] NULL
				--																			   , [ShopperSegmentTypeID] [INT] NOT NULL
				--																			   , [StartDate] [DATETIME] NULL
				--																			   , [EndDate] [DATETIME] NULL
				--																			   , [FanID] [INT] NOT NULL PRIMARY KEY)
				--INSERT INTO ' + REPLACE(@OutputTableName,  '_Selection_', '_ControlGroup_') + '
				--SELECT DISTINCT
				--	   PartnerID
				--	 , ClientServicesRef
				--	 , IronOfferID
				--	 , ShopperSegmentTypeID
				--	 , StartDate
				--	 , EndDate
				--	 , FanID
				--FROM #ControlGroup'

				--EXEC (@SQLCode)

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
				FROM #ControlGroup
								
			END

/*
	/*******************************************************************************************************************************************
		13. Force senior staff into top offers
	*******************************************************************************************************************************************/
			
		/***********************************************************************************************************************
			13.1. Remove existing senior staff memberships
		***********************************************************************************************************************/
		
			/*	RF 20190218 - Where not exists added to #Customer table selection*/
			--DELETE sl
			--FROM #Selection sl
			--INNER JOIN Selections.ROCShopperSegment_SeniorStaffAccounts ssa
			--	ON sl.CompositeID = ssa.CompositeID
			
		/***********************************************************************************************************************
			13.2. Where campaign includes the top offer per partner then force senior staff into offer
		***********************************************************************************************************************/

			/***********************************************************************************************************************
				13.2.1 Sotre offer details if campaign contains top offer
			***********************************************************************************************************************/
			
				IF OBJECT_ID('tempdb..#TopPartnerOffer') IS NOT NULL DROP TABLE #TopPartnerOffer
				SELECT o.IronOfferID
					 , o.ShopperSegmentTypeID
				INTO #TopPartnerOffer
				FROM ##TopPartnerOffer tpo
				INNER JOIN #OfferIDs o
					ON tpo.IronOfferID = o.IronOfferID
				WHERE PartnerID = @PartnerID

				IF (SELECT COUNT(1) FROM #TopPartnerOffer) > 0
					BEGIN

						/***********************************************************************************************************************
							13.2.2 Where campaign includes the top offer per partner then store senior staff where not already on partner offer
						***********************************************************************************************************************/

							IF OBJECT_ID('tempdb..#ROCShopperSegment_SeniorStaffAccounts') IS NOT NULL DROP TABLE #ROCShopperSegment_SeniorStaffAccounts
							SELECT *
							Into #ROCShopperSegment_SeniorStaffAccounts
							FROM Selections.ROCShopperSegment_SeniorStaffAccounts ssa
							WHERE NOT EXISTS (SELECT 1
											  FROM Selections.CampaignCode_Selections_ExistingPartnerOfferMemberships epom
											  WHERE ssa.CompositeID = epom.CompositeID
											  AND epom.PartnerID = @PartnerID)

						/***********************************************************************************************************************
							13.2.2 Where campaign includes the top offer per partner then force senior staff into offer
						***********************************************************************************************************************/

							INSERT INTO #Selection
							SELECT FanID
								 , CompositeID
								 , ShopperSegmentTypeID
								 , IronOfferID
								 , @StartDate
								 , @EndDateTime
							FROM #TopPartnerOffer tpo
							CROSS JOIN #ROCShopperSegment_SeniorStaffAccounts ssa

					END	--	IF (SELECT COUNT(1) FROM #TopPartnerOffer) > 0
*/

	/*******************************************************************************************************************************************
		14. Output to final table
	*******************************************************************************************************************************************/

		SET @SQLCode = 
'IF OBJECT_ID(''' + @OutputTableName + ''') IS NOT NULL DROP TABLE ' + @OutputTableName + '
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


	/*******************************************************************************************************************************************
		15. Insert to [Selections].[CampaignExecution_TableNames]
	*******************************************************************************************************************************************/

		INSERT INTO [Selections].[CampaignExecution_TableNames] (TableName, ClientServicesRef)
		SELECT @OutputTableName
			 , @ClientServicesRef


	/*******************************************************************************************************************************************
		16. Insert to CBP_CampaignNames
	*******************************************************************************************************************************************/

		INSERT INTO [Relational].[CBP_CampaignNames] (ClientServicesRef
													, CampaignName)
		SELECT @ClientServicesRef
			 , @CampaignName
		WHERE NOT EXISTS (SELECT 1
						  FROM [Relational].[CBP_CampaignNames]
						  WHERE ClientServicesRef = @ClientServicesRef)


	/*******************************************************************************************************************************************
		17. Insert to IronOffer_Campaign_Type
	*******************************************************************************************************************************************/

		INSERT INTO [Staging].[IronOffer_Campaign_Type] (ClientServicesRef
													   , CampaignTypeID
													   , IsTrigger
													   , ControlPercentage)
		SELECT @ClientServicesRef
			 , 4 AS CampaignTypeID
			 , 0 IsTrigger
			 , 0 ControlPercentage
		WHERE NOT EXISTS (SELECT 1
						  FROM [Staging].[IronOffer_Campaign_Type]
						  WHERE ClientServicesRef = @ClientServicesRef)


	/*******************************************************************************************************************************************
		18. Insert to IronOffer_ROCOffers
	*******************************************************************************************************************************************/

		INSERT INTO [Relational].[IronOffer_ROCOffers] (IronOfferID)
		SELECT DISTINCT
			   IronOfferID
		FROM #OfferIDs iof
		WHERE NOT EXISTS (SELECT 1
						  FROM [Relational].[IronOffer_ROCOffers] roc
						  WHERE iof.IronOfferID = roc.IronOfferID)


	/*******************************************************************************************************************************************
		19. Insert to OfferMemberAdditions
	*******************************************************************************************************************************************/

		INSERT INTO [iron].[OfferMemberAddition]
		SELECT CompositeID
			 , IronOfferID
			 , StartDate
			 , EndDate
			 , GETDATE() AS Date
			 , 0 AS IsControl
		FROM #Selection


	/*******************************************************************************************************************************************
		20. Drop all temp tables
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#OfferIDs') IS NOT NULL DROP TABLE #OfferIDs
		IF OBJECT_ID('tempdb..#Gender') IS NOT NULL DROP TABLE #Gender
		IF OBJECT_ID('tempdb..#MarketableByEmail') IS NOT NULL DROP TABLE #MarketableByEmail
		IF OBJECT_ID('tempdb..#LiveOfferPerPartner') IS NOT NULL DROP TABLE #LiveOfferPerPartner
		IF OBJECT_ID('tempdb..#CustomersOnOfferAlready') IS NOT NULL DROP TABLE #CustomersOnOfferAlready
		IF OBJECT_ID('tempdb..#CustomerBase') IS NOT NULL DROP TABLE #CustomerBase
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




