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
	- Used Warehouse.Relational.IronOfferSegment table as source of segment codes instead of applying string searches to IronOfferNames

Jason Shipp 22/04/2020
	- Parameterised query to add control over whether to run for all retailers or just retailers requiring flash reports

Jason Shipp 04/05/2020
	- Added parameterisation control whether to include a bespoke list of IronOfferIDs

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_Load_Segments]	@OnlyRunForFlashReportRetailers BIT
													,	@IronOfferIDList VARCHAR(MAX)
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- For testing
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
	
		SELECT	@StartDate = MAX(d.StartDate)
			,	@EndDate = DATEADD(SECOND, -1, (DATEADD(day, 1, (CAST(MAX(d.EndDate) AS DATETIME)))))
		FROM [Warehouse].[Staging].[ControlSetup_Cycle_Dates] d;


	/******************************************************************************
	Load Iron Offers active during period that are not already in nFI.Relational.ironoffercycles
	******************************************************************************/

		IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers;
		SELECT	o.ClubID
			,	ClubName = cl.Name
			,	pa.PartnerID
			,	pa.PartnerName
			,	o.OfferID AS OfferID
			,	IronOfferID = COALESCE(oi.IronOfferID, iof.IronOfferID, o.SourceID)
			,	IronOfferName = o.OfferName
			,	CASE
					WHEN o.StartDateTime > @StartDate THEN o.StartDateTime
					ELSE @StartDate
				END AS StartDate
			,	CASE
					WHEN o.EndDateTime < @EndDate THEN o.EndDateTime
					ELSE @EndDate
				END AS EndDate
		INTO #Offers
		FROM [WH_AllPublishers].[dbo].[Offer] o
		LEFT JOIN [WH_AllPublishers].[Derived].[OfferIDs] oi
			ON o.SourceID = oi.OfferCode
		LEFT JOIN [WH_Virgin].[Derived].[IronOffer] iof
			ON CONVERT(VARCHAR(64), o.SourceID) = CONVERT(VARCHAR(64), iof.HydraOfferID)
		INNER JOIN [SLC_REPL].[dbo].[Club] cl
			ON	o.ClubID = cl.ID
		INNER JOIN #Partner pa
			ON	o.PartnerID = pa.PartnerID
		WHERE o.StartDateTime <= @StartDate
		AND (o.EndDateTime > @StartDate OR o.EndDateTime IS NULL)
		AND o.OfferName NOT LIKE 'Spare%' -- Exclude spare offers
		AND o.PartnerID NOT IN (4497, 4498, 4782, 4785, 4786, 4642) -- Exclude "Credit Supermarket 1%" and "Spend 0.5%"
		AND o.ClubID != 138

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
		SELECT	o.ClubID
			,	o.ClubName
			,	o.PartnerID
			,	o.PartnerName
			,	o.OfferID
			,	o.IronOfferID
			,	o.IronOfferName
			,	o.StartDate
			,	o.EndDate
		INTO #OffersWithMembers
		FROM #Offers o
		WHERE EXISTS (	SELECT 1
						FROM [SLC_Report].[dbo].[IronOfferMember] iom
						WHERE o.IronOfferID = iom.IronOfferID
						AND iom.StartDate <= o.EndDate
						AND (iom.EndDate >= o.StartDate OR iom.EndDate IS NULL));
						
		INSERT INTO #OffersWithMembers
		SELECT	o.ClubID
			,	o.ClubName
			,	o.PartnerID
			,	o.PartnerName
			,	o.OfferID
			,	o.IronOfferID
			,	o.IronOfferName
			,	o.StartDate
			,	o.EndDate
		FROM #Offers o
		WHERE EXISTS (	SELECT 1
						FROM [WH_Virgin].[Derived].[IronOfferMember] iom
						WHERE o.IronOfferID = iom.IronOfferID
						AND iom.StartDate <= o.EndDate
						AND (iom.EndDate >= o.StartDate OR iom.EndDate IS NULL));
						
		INSERT INTO #OffersWithMembers
		SELECT	o.ClubID
			,	o.ClubName
			,	o.PartnerID
			,	o.PartnerName
			,	o.OfferID
			,	o.IronOfferID
			,	o.IronOfferName
			,	o.StartDate
			,	o.EndDate
		FROM #Offers o
		WHERE EXISTS (	SELECT 1
						FROM [WH_Visa].[Derived].[IronOfferMember] iom
						WHERE o.IronOfferID = iom.IronOfferID
						AND iom.StartDate <= o.EndDate
						AND (iom.EndDate >= o.StartDate OR iom.EndDate IS NULL));

	/******************************************************************************
	Add entries to OfferCycles table (if new dates)
	******************************************************************************/

		INSERT INTO [Report].[OfferCycles]
		SELECT	DISTINCT
				owm.StartDate
			,	owm.EndDate
		FROM #OffersWithMembers owm
		WHERE NOT EXISTS (	SELECT 1
							FROM [Report].[OfferCycles] oc
							WHERE owm.StartDate = oc.StartDate
							AND owm.EndDate = oc.EndDate);

	/******************************************************************************
	- Assign Segment type to each offer
	- Load results into Warehouse.Staging.ControlSetup_OffersSegment_nFI table

	Create table for storing results:

	CREATE TABLE Warehouse.Staging.ControlSetup_OffersSegment_nFI
		(IronOfferID INT
		, IronOfferName NVARCHAR(200)
		, StartDate DATE
		, EndDate DATE
		, PartnerID INT
		, ClubID INT
		, PartnerName VARCHAR(100)
		, Segment VARCHAR(50)
		, CONSTRAINT PK_ControlSetup_OffersSegment_nFI PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)
		)
	******************************************************************************/
	 
	TRUNCATE TABLE [Report].[ControlSetup_OffersSegment];
	INSERT INTO [Report].[ControlSetup_OffersSegment] (	PartnerID
													,	PartnerName
													,	ClubID
													,	ClubName
													,	OfferID
													,	IronOfferID
													,	IronOfferName
													,	StartDate
													,	EndDate
													,	Segment)
	SELECT	owm.PartnerID
		,	owm.PartnerName
		,	owm.ClubID
		,	owm.ClubName
		,	owm.OfferID
		,	owm.IronOfferID
		,	owm.IronOfferName
		,	owm.StartDate
		,	owm.EndDate
		,	ios.SegmentCode as Segment
	FROM #OffersWithMembers owm
	LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] ios
		on owm.IronOfferID = ios.IronOfferID;

	--	In the case that a IronOFfer has had a change in it's start date or end date since the last crontrol group run, update the OfferCyclesID in [nFI].[Relational].[ironoffercycles]
	--	to prevent a second control group being sest up for the same retailer / segment

	UPDATE ioc
	SET ioc.OfferCyclesID = oc2.OfferCyclesID
	FROM [Report].[ControlSetup_OffersSegment] os
	INNER JOIN [Report].[IronOfferCycles] ioc
		ON os.IronOfferID = ioc.IronOfferID
	INNER JOIN [Report].[OfferCycles] oc
		ON ioc.OfferCyclesID = oc.OfferCyclesID
	INNER JOIN [Staging].[ControlSetup_Cycle_Dates] cd
		ON oc.StartDate BETWEEN cd.StartDate AND cd.EndDate
	INNER JOIN [Report].[OfferCycles] oc2
		ON os.StartDate = CONVERT(DATE, oc2.StartDate)
		AND os.EndDate = CONVERT(DATE, oc2.EndDate)
	WHERE 1 = 1
	AND oc.OfferCyclesID != oc2.OfferCyclesID



	/******************************************************************************
	CHECK POINT: If any entries are blank, check offer name follows naming convention

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_nFINonAAM_Segments
		(PublisherType VARCHAR(50)
		, IronOfferID INT
		, IronOfferName NVARCHAR(200)
		, StartDate DATE
		, EndDate DATE
		, PartnerID INT
		, ClubID INT
		, PartnerName VARCHAR(200)
		, Segment VARCHAR(10)
		, CONSTRAINT PK_ControlSetup_Validation_nFINonAAM_Segments PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)  
		)
	******************************************************************************/

	-- Load errors
	
	TRUNCATE TABLE [Report].[ControlSetup_Validation_Segments];
	INSERT INTO [Report].[ControlSetup_Validation_Segments]	(	PublisherType
															,	OfferID
															,	IronOfferID
															,	IronOfferName
															,	StartDate
															,	EndDate
															,	PartnerID
															,	ClubID
															,	PartnerName
															,	Segment)
	SELECT	PublisherType = CASE
								WHEN os.ClubID = 132 THEN 'Warehouse'
								WHEN os.ClubID = 166 THEN 'Virgin'
								WHEN os.ClubID = 180 THEN 'Visa Barclaycard'
								WHEN os.ClubID IN (165, 169, 2001, 2002, -2, -4, -1, -3) THEN 'Amex'
								ELSE 'nFI'
							END
		,	os.OfferID
		,	os.IronOfferID
		,	os.IronOfferName
		,	os.StartDate
		,	os.EndDate
		,	os.PartnerID
		,	os.ClubID
		,	os.PartnerName
		,	os.Segment
	FROM [Report].[ControlSetup_OffersSegment] os
	WHERE Segment = ''
	OR Segment IS NULL;

END



SELECT *
FROM [Report].[ControlSetup_OffersSegment]