/******************************************************************************
Author: Jason Shipp
Created: 08/03/2018
Purpose: 
	- Load nFI offers for which to setup control members for
	- Add entries to nFI.Relational.OfferCycles table
	- Load offer segments into Warehouse.Staging.ControlSetup_OffersSegment_nFI table
	- Load validation of segment types assigned to each offer
	- @IronOfferIDList is a list of IronOffers, separated by commas or new lines, all in one string
	 
------------------------------------------------------------------------------
Modification History

Jason Shipp 28/08/2018
	- Used Warehouse.Relational.IronOfferSegment table as source of segment codes instead of applying string searches to OfferNames

Jason Shipp 22/04/2020
	- Parameterised query to add control over whether to run for all retailers or just retailers requiring flash reports

Jason Shipp 04/05/2020
	- Added parameterisation control whether to include a bespoke list of IronOfferIDs

******************************************************************************/
CREATE PROCEDURE [Report].[ControlSetup_Load_Offers]	@OnlyRunForFlashReportRetailers BIT
												,	@IronOfferIDList VARCHAR(MAX)
	
AS
BEGIN
	
	SET NOCOUNT ON;

	--DECLARE @OnlyRunForFlashReportRetailers BIT = 0;
	--DECLARE @IronOfferIDList VARCHAR(MAX) = '';

	/******************************************************************************
	Convert Offer List String to Table
	******************************************************************************/

		-- Remove new lines from Iron Offer list (if applicable) and spaces after commas
		SET @IronOfferIDList = REPLACE(REPLACE(@IronOfferIDList, CHAR(13) + CHAR(10), ','), ', ', ',');

		IF OBJECT_ID('tempdb..#OfferIDs') IS NOT NULL DROP TABLE #OfferIDs
		CREATE TABLE #OfferIDs (IronOfferID INT);

		WITH OfferIDs AS (SELECT @IronOfferIDList AS IronOfferID)

		INSERT INTO #OfferIDs (IronOfferID)
		SELECT	CONVERT(INT, iof.Item) AS IronOfferID
		FROM OfferIDs
		CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (IronOfferID, ',') iof
		WHERE iof.Item != 0

	/******************************************************************************
	Load Flash Report retailer PartnerIDs
	******************************************************************************/

		IF OBJECT_ID('tempdb..#FlashRetailerPartnerIDs') IS NOT NULL DROP TABLE #FlashRetailerPartnerIDs;

		SELECT PartnerID
		INTO #FlashRetailerPartnerIDs	
		FROM ( 
				SELECT r.RetailerID AS PartnerID FROM Warehouse.Staging.ControlSetup_FlashReportRetailers r
				UNION 
				SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_FlashReportRetailers r
				INNER JOIN Warehouse.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
				UNION
				SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_FlashReportRetailers r
				INNER JOIN nFI.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
			) x;

	/******************************************************************************
	Load All PartnerIDs
	******************************************************************************/

		IF OBJECT_ID('tempdb..#Partner') IS NOT NULL DROP TABLE #Partner;
		SELECT	PartnerID = pa.ID
			,	PartnerName = pa.Name 
		INTO #Partner	
		FROM [SLC_REPL].[dbo].[Partner] pa

		CREATE CLUSTERED INDEX CIX_Partner ON #Partner (PartnerID, PartnerName)

		IF @OnlyRunForFlashReportRetailers = 1
			BEGIN
				DELETE pa
				FROM #Partner pa
				WHERE NOT EXISTS (	SELECT 1
									FROM #FlashRetailerPartnerIDs frp
									WHERE pa.PartnerID = frp.PartnerID)

			END
			

	/******************************************************************************
	Load Campaign Cycle dates
	******************************************************************************/

		DECLARE @StartDate DATETIME
			,	@EndDate DATETIME
	
		SELECT	@StartDate = cd.StartDate
			,	@EndDate = cd.EndDate
		FROM [Report].[ControlSetup_CycleDates] cd;

		--	SELECT @StartDate, @EndDate
		

	/******************************************************************************
	Load Iron Offers active during period that are not already in nFI.Relational.ironoffercycles
	******************************************************************************/

		IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers;
		SELECT	PublisherType = o.PublisherType
			,	PublisherID = o.PublisherID
			,	ClubName = cl.Name
			,	RetailerName = pa.PartnerName
			,	RetailerID = o.RetailerID
			,	PartnerID = o.PartnerID
			,	OfferID = o.OfferID
			,	IronOfferID = o.IronOfferID
			,	OfferName = o.OfferName
			,	SegmentName = o.SegmentName
			,	SegmentID = CASE
								WHEN o.SegmentName IN ('Acquire', 'Acquire - Low Interest', 'Acquisition', 'Welcome') THEN 7
								WHEN o.SegmentName IN ('Lapsed') THEN 8
								WHEN o.SegmentName IN ('Shopper', 'Shopper Grow', 'Shopper Risk Of Lapsing') THEN 9

								WHEN o.OfferName LIKE '%Acquire%' OR o.OfferName LIKE '%Acquisition%' OR o.OfferName LIKE '%Welcome%' THEN 7
								WHEN o.OfferName LIKE '%Lapsed%' THEN 8
								WHEN o.OfferName LIKE '%Shopper' OR o.OfferName LIKE '%Lapsing%'  OR o.OfferName LIKE '%Nursery%' THEN 9
								WHEN o.OfferName LIKE '%Base Offer%' THEN 0
								WHEN o.OfferName LIKE '%Universal%' THEN 0
							END
			,	StartDate =	CASE
								WHEN o.StartDate > @StartDate THEN o.StartDate
								ELSE @StartDate
							END
			,	EndDate =	CASE
								WHEN o.EndDate < @EndDate THEN DATEADD(SECOND, -1, (DATEADD(day, 1, (CONVERT(DATETIME, CONVERT(DATE, o.EndDate)))))) 
								ELSE @EndDate
							END
		INTO #Offers
		FROM [Derived].[Offer] o
		INNER JOIN [SLC_REPL].[dbo].[Club] cl
			ON	o.PublisherID = cl.ID
		INNER JOIN #Partner pa
			ON	o.RetailerID = pa.PartnerID
		WHERE o.StartDate <= @EndDate
		AND (o.EndDate > @StartDate OR o.EndDate IS NULL)
		AND o.OfferName NOT LIKE 'Spare%' -- Exclude spare offers
		AND o.PartnerID NOT IN (4497, 4498, 4782, 4785, 4786, 4642) -- Exclude "Credit Supermarket 1%" and "Spend 0.5%"
		AND o.PublisherID != 138

		IF (SELECT GETDATE()) < '2022-02-11' DELETE FROM #Offers WHERE PublisherID = 2002

		IF (SELECT COUNT(*) FROM #OfferIDs) > 0	--	If a bespoke list of offers has been entrered, delete all remaining offers
			BEGIN
				DELETE o
				FROM #Offers o
				WHERE NOT EXISTS (	SELECT 1
									FROM #OfferIDs oi
									WHERE o.IronOfferID = oi.IronOfferID);

			END

		CREATE CLUSTERED INDEX CIX_OfferDates ON #Offers (IronOfferID, StartDate, EndDate)

	/******************************************************************************
	Load active offers that have members
	******************************************************************************/

		IF OBJECT_ID('tempdb..#OffersWithMembers') IS NOT NULL DROP TABLE #OffersWithMembers
		SELECT	o.PublisherID
			,	o.ClubName
			,	o.RetailerID
			,	o.PartnerID
			,	o.RetailerName
			,	o.OfferID
			,	o.IronOfferID
			,	o.OfferName
			,	o.SegmentName
			,	o.SegmentID
			,	o.StartDate
			,	o.EndDate
		INTO #OffersWithMembers
		FROM #Offers o
		WHERE EXISTS (	SELECT 1
						FROM [Warehouse].[Relational].[IronOfferMember] iom
						WHERE o.IronOfferID = iom.IronOfferID
						AND iom.StartDate <= o.EndDate
						AND (iom.EndDate >= o.StartDate OR iom.EndDate IS NULL));
						
		INSERT INTO #OffersWithMembers
		SELECT	o.PublisherID
			,	o.ClubName
			,	o.RetailerID
			,	o.PartnerID
			,	o.RetailerName
			,	o.OfferID
			,	o.IronOfferID
			,	o.OfferName
			,	o.SegmentName
			,	o.SegmentID
			,	o.StartDate
			,	o.EndDate
		FROM #Offers o
		WHERE EXISTS (	SELECT 1
						FROM [nFI].[Relational].[IronOfferMember] iom
						WHERE o.IronOfferID = iom.IronOfferID
						AND iom.StartDate <= o.EndDate
						AND (iom.EndDate >= o.StartDate OR iom.EndDate IS NULL));
						
		INSERT INTO #OffersWithMembers
		SELECT	o.PublisherID
			,	o.ClubName
			,	o.RetailerID
			,	o.PartnerID
			,	o.RetailerName
			,	o.OfferID
			,	o.IronOfferID
			,	o.OfferName
			,	o.SegmentName
			,	o.SegmentID
			,	o.StartDate
			,	o.EndDate
		FROM #Offers o
		WHERE EXISTS (	SELECT 1
						FROM [WH_Virgin].[Derived].[IronOfferMember] iom
						WHERE o.IronOfferID = iom.IronOfferID
						AND iom.StartDate <= o.EndDate
						AND (iom.EndDate >= o.StartDate OR iom.EndDate IS NULL));
						
		INSERT INTO #OffersWithMembers
		SELECT	o.PublisherID
			,	o.ClubName
			,	o.RetailerID
			,	o.PartnerID
			,	o.RetailerName
			,	o.OfferID
			,	o.IronOfferID
			,	o.OfferName
			,	o.SegmentName
			,	o.SegmentID
			,	o.StartDate
			,	o.EndDate
		FROM #Offers o
		WHERE EXISTS (	SELECT 1
						FROM [WH_Visa].[Derived].[IronOfferMember] iom
						WHERE o.IronOfferID = iom.IronOfferID
						AND iom.StartDate <= o.EndDate
						AND (iom.EndDate >= o.StartDate OR iom.EndDate IS NULL));
						
		INSERT INTO #OffersWithMembers
		SELECT	o.PublisherID
			,	o.ClubName
			,	o.RetailerID
			,	o.PartnerID
			,	o.RetailerName
			,	o.OfferID
			,	o.IronOfferID
			,	o.OfferName
			,	o.SegmentName
			,	o.SegmentID
			,	o.StartDate
			,	o.EndDate
		FROM #Offers o
		WHERE o.PublisherType = 'Card Scheme';


	/******************************************************************************
	- Assign Segment type to each offer
	- Load results into Warehouse.Staging.ControlSetup_OffersSegment_nFI table

	Create table for storing results:

	CREATE TABLE Warehouse.Staging.ControlSetup_OffersSegment_nFI
		(IronOfferID INT
		, OfferName NVARCHAR(200)
		, StartDate DATE
		, EndDate DATE
		, PartnerID INT
		, PublisherID INT
		, PartnerName VARCHAR(100)
		, Segment VARCHAR(50)
		, CONSTRAINT PK_ControlSetup_OffersSegment_nFI PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)
		)
	******************************************************************************/
	 
	TRUNCATE TABLE [Report].[ControlSetup_OffersSegment];
	INSERT INTO [Report].[ControlSetup_OffersSegment] (	RetailerID
													,	PartnerID
													,	RetailerName
													,	PublisherID
													,	PublisherName
													,	OfferID
													,	IronOfferID
													,	OfferName
													,	StartDate
													,	EndDate
													,	SegmentID
													,	SegmentName)
	SELECT	owm.RetailerID
		,	owm.PartnerID
		,	owm.RetailerName
		,	owm.PublisherID
		,	owm.ClubName
		,	owm.OfferID
		,	owm.IronOfferID
		,	owm.OfferName
		,	owm.StartDate
		,	owm.EndDate
		,	COALESCE(owm.SegmentID, 0)
		,	owm.SegmentName
	FROM #OffersWithMembers owm
	ORDER BY	owm.SegmentID
			,	owm.SegmentName
			,	owm.OfferName;

	--	In the case that a IronOFfer has had a change in it's start date or end date since the last crontrol group run, update the OfferCyclesID in [nFI].[Relational].[ironoffercycles]
	--	to prevent a second control group being sest up for the same retailer / segment

	--UPDATE ioc
	--SET ioc.OfferCyclesID = oc2.OfferCyclesID
	--FROM [Report].[ControlSetup_OffersSegment] os
	--INNER JOIN [Report].[IronOfferCycles] ioc
	--	ON os.IronOfferID = ioc.IronOfferID
	--INNER JOIN [Report].[OfferCycles] oc
	--	ON ioc.OfferCyclesID = oc.OfferCyclesID
	--INNER JOIN [Report].[ControlSetup_CycleDates] cd
	--	ON oc.StartDate BETWEEN cd.StartDate AND cd.EndDate
	--INNER JOIN [Report].[OfferCycles] oc2
	--	ON os.StartDate = CONVERT(DATE, oc2.StartDate)
	--	AND os.EndDate = CONVERT(DATE, oc2.EndDate)
	--WHERE 1 = 1
	--AND oc.OfferCyclesID != oc2.OfferCyclesID



	/******************************************************************************
	CHECK POINT: If any entries are blank, check offer name follows naming convention

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_nFINonAAM_Segments
		(PublisherType VARCHAR(50)
		, IronOfferID INT
		, OfferName NVARCHAR(200)
		, StartDate DATE
		, EndDate DATE
		, PartnerID INT
		, PublisherID INT
		, PartnerName VARCHAR(200)
		, Segment VARCHAR(10)
		, CONSTRAINT PK_ControlSetup_Validation_nFINonAAM_Segments PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)  
		)
	******************************************************************************/

	-- Load errors
	
	TRUNCATE TABLE [Report].[ControlSetup_Validation_Segments];
	INSERT INTO [Report].[ControlSetup_Validation_Segments]	(	PublisherType
															,	PublisherID
															,	RetailerID
															,	PartnerID
															,	RetailerName
															,	OfferID
															,	IronOfferID
															,	OfferName
															,	StartDate
															,	EndDate
															,	SegmentID)
	SELECT	PublisherType = o.PublisherType
		,	PublisherID = os.PublisherID
		,	RetailerID = o.RetailerID
		,	PartnerID = o.PartnerID
		,	RetailerName = pa.RetailerName
		,	OfferID = os.OfferID
		,	IronOfferID = os.IronOfferID
		,	OfferName = os.OfferName
		,	StartDate = os.StartDate
		,	EndDate = os.EndDate
		,	SegmentID = os.SegmentID
	FROM [Report].[ControlSetup_OffersSegment] os
	INNER JOIN [Derived].[Offer] o
		ON os.OfferID = o.OfferID
	INNER JOIN [Derived].[Partner] pa
		ON o.PartnerID = pa.PartnerID
	WHERE os.SegmentID IS NULL;

END