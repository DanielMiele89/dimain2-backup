/******************************************************************************
Author: JasON Shipp
Created: 09/03/2018
Purpose: 
	- Assign nFI partner ControlGroupIDs
	- Add entries to [WH_Virgin].[Report].[IronOfferCycles] table
	- Load validatiON of entries added to [WH_Virgin].[Report].[IronOfferCycles]

Note: 
	- The Universal ControlGroupID will be the minimum ControlGroupID associated with the OfferCyclesIDs being setup
		 
------------------------------------------------------------------------------
ModificatiON History

JasON Shipp 11/07/2018
	- Added logic to UPDATE ControlGroupIDs for cases WHERE a ControlGroupID already exists for that retailer segment in that cycle
******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_VirginNonAAM_Load_IronOfferCycles]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Load partner alternates
	******************************************************************************/

		IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;
		SELECT	DISTINCT
				PartnerID
			,	AlternatePartnerID
		INTO #PartnerAlternate
		FROM (	SELECT	PartnerID
					,	AlternatePartnerID
				FROM [Warehouse].[APW].[PartnerAlternate]
				UNION
				SELECT	PartnerID
					,	AlternatePartnerID
				FROM [nFI].[APW].[PartnerAlternate]) pa

	/******************************************************************************
	CREATE TABLE for storing Universal ControlGroupID:

	CREATE TABLE [Warehouse].[Staging].[ControlSetup_UniversalOffer_Virgin] (	UniversalControlGroupID INT
																			,	CONSTRAINT PK_ControlSetup_UniversalOffer_Virgin PRIMARY KEY CLUSTERED (UniversalControlGroupID))

	******************************************************************************/

	-- Clear Staging.ControlSetup_UniversalOffer_nFI table

		TRUNCATE TABLE [Warehouse].[Staging].[ControlSetup_UniversalOffer_Virgin];

	/******************************************************************************
	Load Campaign Cycle dates
	******************************************************************************/

		DECLARE @StartDate DATETIME
			,	@EndDate DATETIME
			,	@UniversalOfferCount INT
			,	@UniversalControlGroupID INT;

		SELECT	@StartDate = MAX(cd.StartDate)
			,	@EndDate = DATEADD(SECOND, -1, (DATEADD(day, 1, (CONVERT(DATETIME, MAX(cd.EndDate))))))
		FROM [Warehouse].[Staging].[ControlSetup_Cycle_Dates] cd;

		;WITH
		ExistingUniversal AS (	SELECT	iof.IronOfferID
									,	CASE
											WHEN @StartDate < iof.StartDate THEN iof.StartDate
											ELSE @StartDate
										END AS StartDate
									,	CASE
											WHEN iof.EndDate < @EndDate THEN iof.EndDate
											ELSE @EndDate
										END AS EndDate
								FROM [WH_Virgin].[Derived].[IronOffer] iof
								INNER JOIN [Warehouse].[Relational].[IronOfferSegment] ios
									ON iof.IronOfferID = ios.IronOfferID
								WHERE iof.StartDate <= @EndDate
								AND (@StartDate < iof.EndDate OR iof.EndDate IS NULL)
								AND iof.IsSignedOff = 1
								AND iof.IronOfferName NOT LIKE 'Spare%'
								AND ios.SegmentCode = 'B')
		
		SELECT	@UniversalControlGroupID = MIN(ControlGroupID)
			,	@UniversalOfferCount = COUNT(*)
		FROM ExistingUniversal eu		
		INNER JOIN [WH_Virgin].[Report].[OfferCycles] oc
			ON CONVERT(DATE, eu.StartDate) = CONVERT(DATE, oc.StartDate)
			AND CONVERT(DATE, eu.EndDate) = CONVERT(DATE, oc.EndDate)
		INNER JOIN [WH_Virgin].[Report].[IronOfferCycles] ioc
			ON eu.IronOfferID = ioc.IronOfferID
			AND oc.OfferCyclesID = ioc.OfferCyclesID

	-- ControlGroupID assignment

		DECLARE @MaxControlGroupID INT;

		SELECT @MaxControlGroupID = COALESCE(MAX(ControlGroupID), 0)
		FROM (	SELECT MAX(ControlGroupID) AS ControlGroupID
				FROM [WH_Virgin].[Report].[IronOfferCycles]
				UNION
				SELECT MAX(ControlGroupID) AS ControlGroupID
				FROM [WH_Virgin].[Report].[ControlGroupMembers]) cgi;

		IF @UniversalControlGroupID IS NULL AND @UniversalOfferCount > 0
			BEGIN
				SELECT	@UniversalControlGroupID = @MaxControlGroupID + 1
					,	@MaxControlGroupID = @MaxControlGroupID + 1

				INSERT INTO [Warehouse].[Staging].[ControlSetup_UniversalOffer_Virgin] (UniversalControlGroupID)
				SELECT @UniversalControlGroupID; -- Store Universal ControlGroupID for later Use
			END
			
		TRUNCATE TABLE [WH_Virgin].[Report].[PartnerControlGroupIDs]; -- Virgin table

		INSERT INTO	[WH_Virgin].[Report].[PartnerControlGroupIDs]
		SELECT	PartnerID
			,	Segment
			,	DENSE_RANK() OVER (ORDER BY PartnerID, Segment ASC) + @MaxControlGroupID -- Used AS ControlGroupID. Duplicated for partner-segments with same retailerID
			,	StartDate
			,	EndDate
		FROM (	SELECT	DISTINCT
						COALESCE(pa.AlternatePartnerID, a.PartnerID) AS PartnerID
					,	a.Segment
				--	,	s.Segment
					,	a.StartDate
					,	a.EndDate
			FROM [Warehouse].[Staging].[ControlSetup_OffersSegment_Virgin] a
			LEFT JOIN #PartnerAlternate pa 
				ON a.PartnerID = pa.PartnerID
			CROSS JOIN (SELECT	DISTINCT
								Segment
						FROM [Warehouse].[Staging].[ControlSetup_OffersSegment_Virgin]) s) a;

	-- UPDATE ControlGroupID for different PartnerIDs that can be associated to the same RetailerID ON Control Group table

		UPDATE pcg
		SET ControlGroupID = pcg2.ControlGroupID
		FROM [WH_Virgin].[Report].[PartnerControlGroupIDs] pcg
		INNER JOIN [Warehouse].[iron].[PrimaryRetailerIdentification] pri
			ON pcg.PartnerID = pri.PartnerID
		INNER JOIN [WH_Virgin].[Report].[PartnerControlGroupIDs] pcg2
			ON pri.PrimaryPartnerID = pcg2.PartnerID
			AND pcg.Segment = pcg2.Segment
			AND pcg.startDate = pcg2.StartDate
			AND pcg.EndDate  = pcg2.Enddate
		WHERE pri.PrimaryPartnerID IS NOT NULL;

	-- UPDATE ControlGroupID for cases WHERE a ControlGroupID already exists for that retailer segment in that cycle 

		IF OBJECT_ID('tempdb..#ExistingControlGroups') IS NOT NULL DROP TABLE #ExistingControlGroups;
		SELECT	ecg.PartnerID
			,	ecg.Segment	
			,	ecg.ControlGroupID 
		INTO #ExistingControlGroups
		FROM (	SELECT	DISTINCT
						COALESCE(pa.AlternatePartnerID, s.PartnerID) AS PartnerID
					,	s.Segment	
					,	ioc.ControlGroupID
					,	Dense_rank() OVER (PartitiON by COALESCE(pa.AlternatePartnerID, s.PartnerID), s.Segment ORDER BY ioc.ControlGroupID ASC) AS ControlGroupIDRank
				FROM [Warehouse].[Staging].[ControlSetup_OffersSegment_Virgin] s
				LEFT JOIN #PartnerAlternate pa 
					ON s.PartnerID = pa.PartnerID
				INNER JOIN [WH_Virgin].[Report].[IronOffer_References] ior
					ON s.IronOfferID = ior.IronOfferID
				INNER JOIN [WH_Virgin].[Report].[IronOfferCycles] ioc
					ON ior.IronOfferCyclesID = ioc.IronOfferCyclesID
				INNER JOIN [WH_Virgin].[Report].[OfferCycles] cyc
					ON ioc.OfferCyclesID = cyc.OfferCyclesID
					AND CONVERT(DATE, s.StartDate) = CONVERT(DATE, cyc.StartDate)
					AND CONVERT(DATE, s.EndDate) = CONVERT(DATE, cyc.EndDate)) ecg
		WHERE ecg.ControlGroupIDRank = 1;

		UPDATE pcg
		SET pcg.ControlGroupID = ecg.ControlGroupID
		FROM [WH_Virgin].[Report].[PartnerControlGroupIDs] pcg
		INNER JOIN #ExistingControlGroups ecg
			ON pcg.PartnerID = ecg.PartnerID
			AND pcg.Segment = ecg.Segment;



	/******************************************************************************
	Add new entries to [WH_Virgin].[Report].[IronOfferCycles]
	******************************************************************************/

		INSERT INTO [WH_Virgin].[Report].[IronOfferCycles]
		SELECT	a.IronOfferID
			,	oc.OfferCyclesID
			,	CASE
					WHEN a.Segment = 'B' THEN (SELECT UniversalControlGroupID FROM [Warehouse].[Staging].[ControlSetup_UniversalOffer_Virgin])
					ELSE PG.ControlGroupID
				END AS ControlGroupID
			,	NULL
		FROM [Warehouse].[Staging].[ControlSetup_OffersSegment_Virgin] a
		LEFT JOIN #PartnerAlternate pa 
			ON a.PartnerID = pa.PartnerID
		LEFT JOIN [WH_Virgin].[Report].[PartnerControlGroupIDs] PG
			ON COALESCE(pa.AlternatePartnerID, a.PartnerID) = PG.PartnerID
			AND a.Segment = PG.Segment
			AND a.StartDate = PG.StartDate
			AND a.EndDate = PG.EndDate
		INNER JOIN [WH_Virgin].[Report].[OfferCycles] oc
			ON a.StartDate = oc.StartDate
			AND a.EndDate = oc.EndDate
		WHERE NOT EXISTS (	SELECT 1
							FROM [WH_Virgin].[Report].[IronOfferCycles] d
							WHERE a.IronOfferID = d.IronOfferID
							AND oc.OfferCyclesID = d.OfferCyclesID);

	/******************************************************************************
	CHECK POINT: Validate entries added to Relational.ironoffercycles

	CREATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginNonAAM_IronOfferCycles] (	ID INT IDENTITY (1,1)
																							,	PublisherType VARCHAR(50)
																							,	PartnerID INT
																							,	Segment VARCHAR(10)
																							,	IronOfferID INT
																							,	IronOfferName NVARCHAR(200)
																							,	ControlGroupID INT
																							,	Error VARCHAR(200)
																							,	CONSTRAINT PK_ControlSetup_Validation_VirginNonAAM_IronOfferCycles PRIMARY KEY CLUSTERED (ID))

	******************************************************************************/

	-- Check base AND launch offers all have the same ControlGroupID (across retailer)
	-- Check ALS-Retailer combinations have unique ControlGroupIDs
	-- Check row count matches rows in [Warehouse].[Staging].[ControlSetup_OffersSegment_Virgin] table

	-- Load new ironoffercycles data

		IF OBJECT_ID ('tempdb..#IOCCheckData') IS NOT NULL DROP TABLE #IOCCheckData;
		SELECT	'Virgin' AS PublisherType
			,	COALESCE(pa.AlternatePartnerID, iof.PartnerID) AS PartnerID
			,	iof.IronOfferID
			,	iof.IronOfferName
			,	pcg.Segment
			,	oc.StartDate
			,	oc.EndDate
			,	ioc.IronOfferCyclesID
			,	ioc.ControlGroupID AS ExistingControlGroupID
			,	pcg.ControlGroupID AS NewControlGroupID
		INTO #IOCCheckData
		FROM [WH_Virgin].[Report].[IronOfferCycles] ioc
		INNER JOIN [WH_Virgin].[Derived].[IronOffer] iof
			ON ioc.IronOfferID = iof.IronOfferID
		INNER JOIN [WH_Virgin].[Report].[OfferCycles] oc
			ON ioc.OfferCyclesID = oc.OfferCyclesID
		LEFT JOIN #PartnerAlternate pa
			ON iof.PartnerID = pa.PartnerID
		LEFT JOIN [WH_Virgin].[Report].[PartnerControlGroupIDs] pcg
			ON ioc.ControlGroupID = pcg.ControlGroupID
		WHERE EXISTS (	SELECT 1
						FROM [Warehouse].[Staging].[ControlSetup_Cycle_Dates] cd
						WHERE oc.StartDate <= cd.EndDate
						AND cd.StartDate < oc.EndDate);
	
	-- Load retailer segments associated with more than 1 control group

		IF OBJECT_ID ('tempdb..#DiffConGroups') IS NOT NULL DROP TABLE #DiffConGroups;
		SELECT	ioc.PublisherType
			,	ioc.PartnerID
			,	seg.Segment
			,	COUNT(DISTINCT(ISNULL(ioc.ExistingControlGroupID, 0))) AS UniqueControlGroups
			,	'Different control groups for base offers' AS Error
		INTO #DiffConGroups
		FROM #IOCCheckData ioc
		LEFT JOIN [Warehouse].[Staging].[ControlSetup_OffersSegment_Virgin] seg
			ON ioc.IronOfferID = seg.IronOfferID
			AND CONVERT(DATE, ioc.StartDate) = CONVERT(DATE, seg.StartDate)
			AND CONVERT(DATE, ioc.EndDate) = CONVERT(DATE, seg.EndDate)
		CROSS JOIN (SELECT MAX(UniversalControlGroupID) AS UniversalControlGroupID
					FROM [Warehouse].[Staging].[ControlSetup_UniversalOffer_Virgin]) u
		WHERE seg.Segment = 'B'
		GROUP BY	ioc.PublisherType
				,	ioc.PartnerID
				,	seg.Segment
		HAVING COUNT(DISTINCT(ioc.ExistingControlGroupID)) > 1

		UNION ALL
		
		SELECT	ioc.PublisherType
			,	ioc.PartnerID
			,	seg.Segment
			,	COUNT(DISTINCT(ISNULL(ioc.ExistingControlGroupID, 0))) AS UniqueControlGroups
			,	'Different control groups per retailer ALS segment' AS Error
		FROM #IOCCheckData ioc
		LEFT JOIN [Warehouse].[Staging].[ControlSetup_OffersSegment_Virgin] seg
			ON ioc.IronOfferID = seg.IronOfferID
			AND CONVERT(DATE, ioc.StartDate) = CONVERT(DATE, seg.StartDate)
			AND CONVERT(DATE, ioc.EndDate) = CONVERT(DATE, seg.EndDate)
		WHERE seg.Segment IN ('A', 'L', 'S')
		GROUP BY	ioc.PublisherType
				,	ioc.PartnerID
				,	seg.Segment
		HAVING COUNT(DISTINCT(ioc.ExistingControlGroupID)) > 1

	-- Load errors

		TRUNCATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginNonAAM_IronOfferCycles];

		INSERT INTO [Warehouse].[Staging].[ControlSetup_Validation_VirginNonAAM_IronOfferCycles] (	PublisherType
																								,	PartnerID
																								,	Segment
																								,	IronOfferID
																								,	IronOfferName
																								,	ControlGroupID
																								,	Error)
		SELECT	d.PublisherType
			,	d.PartnerID
			,	d.Segment
			,	c.IronOfferID
			,	c.IronOfferName
			,	ioc.ControlGroupID	
			,	d.Error		
		FROM #DiffConGroups d
		LEFT JOIN #IOCCheckData c
			ON d.PartnerID = c.PartnerID
			AND d.Segment = COALESCE(c.Segment, 'B')
		LEFT JOIN [WH_Virgin].[Report].[IronOfferCycles] ioc -- Check for multiple control groups associated with the same Iron Offer in IronOfferReferences table
			ON c.IronOfferID = ioc.IronOfferID
		INNER JOIN [WH_Virgin].[Report].[OfferCycles] oc
			ON ioc.OfferCyclesID = oc.OfferCyclesID
		WHERE EXISTS (	SELECT 1
						FROM [Warehouse].[Staging].[ControlSetup_Cycle_Dates] cd
						WHERE cd.StartDate <= oc.StartDate)
	
		UNION ALL

		SELECT	'Virgin' AS PublisherType
			,	seg.PartnerID
			,	seg.Segment
			,	seg.IronOfferID
			,	seg.IronOfferName
			,	NULL AS ControlGroupID	
			,	'No related entry in IronOfferCycles table' AS Error		
		FROM [Warehouse].[Staging].[ControlSetup_OffersSegment_Virgin] seg
		WHERE NOT EXISTS (	SELECT 1
							FROM #IOCCheckData ioc
							WHERE seg.IronOfferID = ioc.IronOfferID
							AND CONVERT(DATE, seg.StartDate) = CONVERT(DATE, ioc.StartDate)
							AND CONVERT(DATE, seg.EndDate) = CONVERT(DATE, ioc.EndDate))
						
END