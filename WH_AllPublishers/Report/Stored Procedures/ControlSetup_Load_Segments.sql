
/******************************************************************************
Author: JasON Shipp
Created: 08/03/2018
Purpose: 
	- Load nFI offers for which to setup control members for
	- Add entries to [WH_Visa].[Report].[OfferCycles] table
	- Load offer segments INTO [Warehouse].[Staging].[ControlSetup_OffersSegment] table
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
CREATE PROCEDURE [Report].[ControlSetup_Load_Segments] (	@OnlyRunForFlashReportRetailers BIT
													,	@IronOfferIDList VARCHAR(MAX))
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- For testing

		--DECLARE @OnlyRunForFlashReportRetailers BIT = 0;
		--DECLARE @IronOfferIDList VARCHAR(MAX) = '';

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
	Load retailers to exclude PartnerIDs
	******************************************************************************/
						
		IF OBJECT_ID('tempdb..#RetailersToExclude') IS NOT NULL DROP TABLE #RetailersToExclude;
		SELECT	DISTINCT
				PartnerID = pa.PartnerID
		INTO #RetailersToExclude
		FROM [Derived].[Partner] pa
		WHERE pa.PartnerID IN (4498, 4782, 4497, 4785, 4786, 4783, 4784, 4642, 99999, 99999, 99999, 99999, 99999, 99999, 99999, 99999, 99999, 99999)


	/******************************************************************************
	Load Flash Report retailer PartnerIDs
	******************************************************************************/
						
		IF OBJECT_ID('tempdb..#FlashRetailerPartnerIDs') IS NOT NULL DROP TABLE #FlashRetailerPartnerIDs;
		SELECT	DISTINCT
				PartnerID = COALESCE(pa.PartnerID, frr.RetailerID)
		INTO #FlashRetailerPartnerIDs
		FROM [Warehouse].[Staging].[ControlSetup_FlashReportRetailers] frr
		LEFT JOIN [Derived].[Partner] pa
			ON frr.RetailerID = pa.RetailerID


	/******************************************************************************
	Load Campaign Cycle dates
	******************************************************************************/

		IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates;
		SELECT	MAX(d.StartDate) AS StartDate
			,	DATEADD(SECOND, -1, (DATEADD(day, 1, (CONVERT(DATETIME, MAX(d.EndDate)))))) AS EndDate
		INTO #Dates
		FROM [Warehouse].[Staging].[ControlSetup_Cycle_Dates] d;


	/******************************************************************************
	Load IrON Offers active during period that are NOT already in [WH_Visa].[Report].[IronOfferCycles]
	******************************************************************************/

		DECLARE @OffersFromInputList INT = (SELECT COUNT(*) FROM #OfferIDs)

		IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers;
		SELECT	DISTINCT
				PublisherID = iof.PublisherID
			,	PartnerID = iof.PartnerID
			,	IronOfferID = iof.IronOfferID
			,	PartnerName = iof.PartnerName
			,	OfferName = iof.OfferName
			,	SegmentCode = iof.SegmentCode
			,	StartDate = iof.StartDate
			,	EndDate = iof.EndDate
		INTO #Offers
		FROM (	SELECT	iof.PublisherID
					,	iof.PartnerID
					,	pa.PartnerName
					,	iof.IronOfferID
					,	iof.OfferName
					,	iof.SegmentCode
					,	CASE
							WHEN da.StartDate < iof.StartDate THEN iof.StartDate
							ELSE da.StartDate
						END AS StartDate
					,	CASE
							WHEN iof.EndDate < da.EndDate THEN iof.EndDate
							ELSE da.EndDate
						END AS EndDate
				FROM [Derived].[Offer] iof
				INNER JOIN #Dates da
					ON iof.StartDate <= da.EndDate
					AND (da.StartDate < iof.EndDate OR iof.EndDate IS NULL)
				INNER JOIN [Derived].[Partner] pa
					on	iof.PartnerID = pa.PartnerID
				WHERE NOT EXISTS (	SELECT 1
									FROM #RetailersToExclude rte
									WHERE iof.PartnerID = rte.PartnerID)
				AND iof.IsSignedOff = 1
				AND iof.OfferName NOT LIKE 'Spare%' -- Exclude spare offers
				AND (@OnlyRunForFlashReportRetailers = 0 OR EXISTS (SELECT 1
																	FROM #FlashRetailerPartnerIDs frp
																	WHERE iof.PartnerID = frp.PartnerID))
				AND (@OffersFromInputList = 0 OR EXISTS (	SELECT 1
															FROM #OfferIDs oi
															WHERE iof.IronOfferID = oi.IronOfferID))) iof


	/******************************************************************************
	Add entries to OfferCycles table (if new dates)
	******************************************************************************/

		INSERT INTO [WH_AllPublishers].[Report].[OfferCycles] (	StartDate
															,	EndDate)
		SELECT	DISTINCT
				StartDate = owm.StartDate
			,	Enddate = owm.EndDate 
		FROM #Offers owm
		WHERE NOT EXISTS (	SELECT 1
							FROM [WH_AllPublishers].[Report].[OfferCycles] oc
							WHERE owm.StartDate = oc.StartDate
							AND owm.EndDate = oc.EndDate)

	/******************************************************************************

	- Assign Segment type to each offer
	- Load results INTO [WH_AllPublishers].[Staging].[ControlSetup_OffersSegment] table

	CREATE TABLE for storing results:

	CREATE TABLE [WH_AllPublishers].[Staging].[ControlSetup_OffersSegment] (IronOfferID INT
																		,	IronOfferName NVARCHAR(200)
																		,	StartDate DATE
																		,	EndDate DATE
																		,	PartnerID INT
																		,	ClubID INT
																		,	PartnerName VARCHAR(100)
																		,	Segment VARCHAR(50)
																		,	CONSTRAINT PK_ControlSetup_OffersSegment PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate))

	******************************************************************************/
	 
		TRUNCATE TABLE [WH_AllPublishers].[Staging].[ControlSetup_OffersSegment];
		INSERT INTO [WH_AllPublishers].[Staging].[ControlSetup_OffersSegment] (	IronOfferID
																			,	IronOfferName
																			,	StartDate
																			,	EndDate
																			,	PartnerID
																			,	ClubID
																			,	PartnerName
																			,	Segment)		
		SELECT	IronOfferID = o.IronOfferID
			,	IronOfferName = o.OfferName
			,	StartDate = o.StartDate
			,	EndDate = o.EndDate
			,	PartnerID = o.PartnerID
			,	ClubID = o.PublisherID
			,	PartnerName = o.PartnerName
			,	Segment = o.SegmentCode
		FROM #Offers o;

	--	In the case that a IronOFfer has had a change in it's start date OR end date since the last crontrol group run, UPDATE the OfferCyclesID in [WH_Visa].[Report].[IronOfferCycles]
	--	to prevent a second control group being sest up for the same retailer / segment

		UPDATE ioc
		SET ioc.OfferCyclesID = oc2.OfferCyclesID
		FROM [WH_AllPublishers].[Staging].[ControlSetup_OffersSegment] os
		INNER JOIN [WH_AllPublishers].[Report].[IronOfferCycles] ioc
			ON os.IronOfferID = ioc.IronOfferID
		INNER JOIN [WH_AllPublishers].[Report].[OfferCycles] oc
			ON ioc.OfferCyclesID = oc.OfferCyclesID
		INNER JOIN [Warehouse].[Staging].[ControlSetup_Cycle_Dates] cd
			ON oc.StartDate BETWEEN cd.StartDate AND cd.EndDate
		INNER JOIN [WH_AllPublishers].[Report].[OfferCycles] oc2
			ON os.StartDate = oc2.StartDate
			AND os.EndDate = oc2.EndDate
		WHERE 1 = 1
		AND oc.OfferCyclesID != oc2.OfferCyclesID


	/******************************************************************************
	CHECK POINT: If any entries are blank, check offer name follows naming convention

	CREATE TABLE for storing validatiON results
	
	DROP TABLE [WH_AllPublishers].[Staging].[ControlSetup_Validation_Segments]
	CREATE TABLE [WH_AllPublishers].[Staging].[ControlSetup_Validation_Segments] (	PublisherType VARCHAR(50)
																				,	PublisherName VARCHAR(200)
																				,	IronOfferID INT
																				,	IronOfferName VARCHAR(200)
																				,	StartDate DATE
																				,	EndDate DATE
																				,	PartnerID INT
																				,	ClubID INT
																				,	PartnerName VARCHAR(200)
																				,	Segment VARCHAR(10)
																				,	CONSTRAINT PK_ControlSetup_Validation_Segments PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate))

	******************************************************************************/

	-- Load errors

	TRUNCATE TABLE [WH_AllPublishers].[Staging].[ControlSetup_Validation_Segments];
	INSERT INTO [WH_AllPublishers].[Staging].[ControlSetup_Validation_Segments] (	PublisherType  
																				,	PublisherName  
																				,	IronOfferID
																				,	IronOfferName
																				,	StartDate
																				,	EndDate
																				,	PartnerID
																				,	ClubID
																				,	PartnerName
																				,	Segment)
	SELECT	o.PublisherType  
		,	pu.PublisherName  
		,	d.IronOfferID
		,	d.IronOfferName
		,	d.StartDate
		,	d.EndDate
		,	d.PartnerID
		,	d.ClubID
		,	d.PartnerName
		,	d.Segment
	FROM [WH_AllPublishers].[Staging].[ControlSetup_OffersSegment] d
	INNER JOIN [WH_AllPublishers].[Derived].[Offer] o
		ON d.IronOfferID = o.IronOfferID
	INNER JOIN [WH_AllPublishers].[Derived].[Publisher] pu
		ON d.ClubID = pu.PublisherID
	WHERE Segment = ''
	OR Segment IS NULL
	ORDER BY	o.PublisherType  
			,	pu.PublisherName  
			,	d.PartnerName
			,	d.IronOfferName
			,	d.StartDate;

END



