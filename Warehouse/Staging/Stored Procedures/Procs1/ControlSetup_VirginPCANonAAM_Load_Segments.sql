
/******************************************************************************
Author: JasON Shipp
Created: 08/03/2018
Purpose: 
	- Load nFI offers for which to setup control members for
	- Add entries to [WH_VirginPCA].[Report].[OfferCycles] table
	- Load offer segments INTO [Warehouse].[Staging].[ControlSetup_OffersSegment_VirginPCA] table
	- Load validatiON of segment types assigned to each offer
	- @IronOfferIDList is a list of IronOffers, separated by commas OR new lines, all in one string
	 
------------------------------------------------------------------------------
ModificatiON History

JasON Shipp 28/08/2018
	- Used Warehouse.Relational.IronOfferSegment table AS source of segment codes instead of applying string searches to IronOfferNames

JasON Shipp 22/04/2020
	- Parameterised query to add control OVER whether to run for all retailers OR just retailers requiring flash reports

JasON Shipp 04/05/2020
	- Added parameterisatiON control whether to include a bespoke list of IronOfferIDs

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_VirginPCANonAAM_Load_Segments] (	@OnlyRunForFlashReportRetailers BIT
																	,	@IronOfferIDList VARCHAR(MAX))
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- For testing

	--	DECLARE @OnlyRunForFlashReportRetailers BIT = 0;
	--	DECLARE @IronOfferIDList VARCHAR(MAX) = '';

	-- Remove new lines FROM IrON Offer list (if applicable) AND spaces after commas
	
		SET @IronOfferIDList = REPLACE(REPLACE(@IronOfferIDList, CHAR(13) + CHAR(10), ','), ' ', '');

	/******************************************************************************
	Split list of Offer IDs FROM parameter INTO a table
	******************************************************************************/

		IF OBJECT_ID('tempdb..#OfferIDs') IS NOT NULL DROP TABLE #OfferIDs
		CREATE TABLE #OfferIDs (IronOfferID INT);

		WITH OfferIDs AS (SELECT @IronOfferIDList AS IronOfferID)

		INSERT INTO #OfferIDs (IronOfferID)
		SELECT	iof.Item AS IronOfferID
		FROM OfferIDs
		CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (IronOfferID, ',') iof
		WHERE iof.Item > 0
		
		CREATE CLUSTERED INDEX CIX_IronOfferID ON #OfferIDs (IronOfferID)


	/******************************************************************************
	Load Flash Report retailer PartnerIDs
	******************************************************************************/

		IF OBJECT_ID('tempdb..#FlashRetailerPartnerIDs') IS NOT NULL DROP TABLE #FlashRetailerPartnerIDs;
		SELECT PartnerID
		INTO #FlashRetailerPartnerIDs	
		FROM (	SELECT r.RetailerID AS PartnerID
				FROM [Warehouse].[Staging].[ControlSetup_FlashReportRetailers] r
				UNION 
				SELECT pa.PartnerID
				FROM [Warehouse].[Staging].[ControlSetup_FlashReportRetailers] r
				INNER JOIN [Warehouse].[APW].[PartnerAlternate] pa
					ON r.RetailerID = pa.AlternatePartnerID
				UNION
				SELECT pa.PartnerID
				FROM [Warehouse].[Staging].[ControlSetup_FlashReportRetailers] r
				INNER JOIN [nFI].[APW].[PartnerAlternate] pa
					ON r.RetailerID = pa.AlternatePartnerID) x;


	/******************************************************************************
	Load Campaign Cycle dates
	******************************************************************************/

		IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates;
		SELECT	MAX(d.StartDate) AS StartDate
			,	DATEADD(SECOND, -1, (DATEADD(day, 1, (CONVERT(DATETIME, MAX(d.EndDate)))))) AS EndDate
		INTO #Dates
		FROM [Warehouse].[Staging].[ControlSetup_Cycle_Dates] d;


	/******************************************************************************
	Load IrON Offers active during period that are NOT already in [WH_VirginPCA].[Report].[IronOfferCycles]
	******************************************************************************/

		DECLARE @OffersFromInputList INT = (SELECT COUNT(*) FROM #OfferIDs)

		IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers;
		SELECT	iof.ClubID
			,	iof.PartnerID
			,	iof.PartnerName
			,	iof.IronOfferID
			,	iof.IronOfferName
			,	iof.StartDate
			,	iof.EndDate
		INTO #Offers
		FROM (	SELECT	iof.ClubID
					,	iof.PartnerID
					,	pa.PartnerName
					,	iof.IronOfferID
					,	iof.IronOfferName
					,	CASE
							WHEN da.StartDate < iof.StartDate THEN iof.StartDate
							ELSE da.StartDate
						END AS StartDate
					,	CASE
							WHEN iof.EndDate < da.EndDate THEN iof.EndDate
							ELSE da.EndDate
						END AS EndDate
				FROM [WH_VirginPCA].[Derived].[IronOffer] iof
				INNER JOIN #Dates da
					ON iof.StartDate <= da.EndDate
					AND (da.StartDate < iof.EndDate OR iof.EndDate IS NULL)
				INNER JOIN [WH_VirginPCA].[Derived].[Partner] pa
					on	iof.PartnerID = pa.PartnerID
				LEFT JOIN [Warehouse].[Relational].[nFI_Partner_Deals] pd
					ON pa.PartnerID = pd.PartnerID
					AND iof.ClubID = pd.ClubID
					AND pd.ManagedBy != 1
				WHERE iof.IsSignedOff = 1
				AND iof.IronOfferName NOT LIKE 'Spare%' -- Exclude spare offers
				AND (@OnlyRunForFlashReportRetailers = 0 OR EXISTS (SELECT 1
																	FROM #FlashRetailerPartnerIDs frp
																	WHERE iof.PartnerID = frp.PartnerID))
				AND (@OffersFromInputList = 0 OR EXISTS (	SELECT 1
															FROM #OfferIDs oi
															WHERE iof.IronOfferID = oi.IronOfferID))) iof

	/******************************************************************************
	Load active offers that have members
	******************************************************************************/

		IF OBJECT_ID('tempdb..#OffersWithMembersVirginPCA') IS NOT NULL DROP TABLE #OffersWithMembersVirginPCA
		SELECT	o.IronOfferID
			,	o.IronOfferName
			,	o.StartDate
			,	o.EndDate
			,	o.PartnerID
			,	o.ClubID
			,	o.PartnerName
		INTO #OffersWithMembersVirginPCA
		FROM #Offers o
		WHERE EXISTS (	SELECT 1
						FROM [WH_VirginPCA].[Derived].[IronOfferMember] iom
						WHERE o.IronOfferID = iom.IronOfferID
						AND iom.StartDate <= o.EndDate
						AND (o.StartDate <= iom.EndDate OR iom.EndDate IS NULL))
		GROUP BY	o.IronOfferID
				,	o.IronOfferName
				,	o.StartDate
				,	o.EndDate
				,	o.PartnerID
				,	o.ClubID
				,	o.PartnerName


	/******************************************************************************
	Add entries to OfferCycles table (if new dates)
	******************************************************************************/

		INSERT INTO [WH_VirginPCA].[Report].[OfferCycles]
		SELECT	DISTINCT
				owm.StartDate
			,	owm.Enddate 
		FROM #OffersWithMembersVirginPCA owm
		WHERE NOT EXISTS (	SELECT 1
							FROM [WH_VirginPCA].[Report].[OfferCycles] oc
							WHERE owm.StartDate = oc.StartDate
							AND owm.EndDate = oc.EndDate)

	/******************************************************************************

	- Assign Segment type to each offer
	- Load results INTO [Warehouse].[Staging].[ControlSetup_OffersSegment_VirginPCA] table

	CREATE TABLE for storing results:

	CREATE TABLE [Warehouse].[Staging].[ControlSetup_OffersSegment_VirginPCA] (IronOfferID INT
																		,	IronOfferName NVARCHAR(200)
																		,	StartDate DATETIME
																		,	EndDate DATETIME
																		,	PartnerID INT
																		,	ClubID INT
																		,	PartnerName VARCHAR(100)
																		,	Segment VARCHAR(50)
																		,	CONSTRAINT PK_ControlSetup_OffersSegment_VirginPCA PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate))

	******************************************************************************/
	 
		TRUNCATE TABLE [Warehouse].[Staging].[ControlSetup_OffersSegment_VirginPCA];
		INSERT INTO [Warehouse].[Staging].[ControlSetup_OffersSegment_VirginPCA] (IronOfferID
																					,	IronOfferName
																					,	StartDate
																					,	EndDate
																					,	PartnerID
																					,	ClubID
																					,	PartnerName
																					,	Segment)		
		SELECT	o.IronOfferID
			,	o.IronOfferName
			,	o.StartDate
			,	o.EndDate
			,	o.PartnerID
			,	o.ClubID
			,	o.PartnerName
			,	s.SegmentCode AS Segment
		FROM #OffersWithMembersVirginPCA o
		LEFT JOIN Warehouse.Relational.IronOfferSegment s
			ON o.IronOfferID = s.IronOfferID;

	--	In the case that a IronOFfer has had a change in it's start date OR end date since the last crontrol group run, UPDATE the OfferCyclesID in [WH_VirginPCA].[Report].[IronOfferCycles]
	--	to prevent a second control group being sest up for the same retailer / segment

		UPDATE ioc
		SET ioc.OfferCyclesID = oc2.OfferCyclesID
		FROM [Warehouse].[Staging].[ControlSetup_OffersSegment_VirginPCA] os
		INNER JOIN [WH_VirginPCA].[Report].[IronOfferCycles] ioc
			ON os.IronOfferID = ioc.IronOfferID
		INNER JOIN [WH_VirginPCA].[Report].[OfferCycles] oc
			ON ioc.OfferCyclesID = oc.OfferCyclesID
		INNER JOIN [Staging].[ControlSetup_Cycle_Dates] cd
			ON oc.StartDate BETWEEN cd.StartDate AND cd.EndDate
		INNER JOIN [WH_VirginPCA].[Report].[OfferCycles] oc2
			ON os.StartDate = CONVERT(DATE, oc2.StartDate)
			AND os.EndDate = CONVERT(DATE, oc2.EndDate)
		WHERE 1 = 1
		AND oc.OfferCyclesID != oc2.OfferCyclesID


	/******************************************************************************
	CHECK POINT: If any entries are blank, check offer name follows naming convention

	CREATE TABLE for storing validatiON results

	CREATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Segments] (	PublisherType VARCHAR(50)
																			,	IronOfferID INT
																			,	IronOfferName NVARCHAR(200)
																			,	StartDate DATE
																			,	EndDate DATE
																			,	PartnerID INT
																			,	ClubID INT
																			,	PartnerName VARCHAR(200)
																			,	Segment VARCHAR(10)
																			,	CONSTRAINT PK_ControlSetup_Validation_VirginPCANonAAM_Segments PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate))

	******************************************************************************/

	-- Load errors

	TRUNCATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Segments];
	INSERT INTO [Warehouse].[Staging].[ControlSetup_Validation_VirginPCANonAAM_Segments] (	PublisherType  
																					,	IronOfferID
																					,	IronOfferName
																					,	StartDate
																					,	EndDate
																					,	PartnerID
																					,	ClubID
																					,	PartnerName
																					,	Segment)
	SELECT	'Visa B' AS PublisherType  
		,	d.IronOfferID
		,	d.IronOfferName
		,	d.StartDate
		,	d.EndDate
		,	d.PartnerID
		,	d.ClubID
		,	d.PartnerName
		,	d.Segment
	FROM [Warehouse].[Staging].[ControlSetup_OffersSegment_VirginPCA] d
	WHERE Segment = ''
	OR Segment IS NULL;

END



