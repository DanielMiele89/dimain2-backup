/******************************************************************************
Author: Jason Shipp
Created: 23/08/2018
Purpose:
	- Add new Iron Offers to the Warehouse.Relational.IronOfferSegment table
	- Assign Segment types, Super Segment types and Offer types to the new Iron Offers using naming convention logic 
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 04/09/2018
	- Updated segment assignment logic to prioritise ALS segment strings at the end of Iron Offer names

Jason Shipp 05/12/2018
	- Updated segment assignment logic for Launch offers

Jason Shipp 07/12/2018
	- Added PartnerIDs, RetailerIDs, OfferStartDates and OfferEndDates to table inserts
	- Added update of offer start and end dates and CS Refs that have changed in base tables

Jason Shipp 12/12/2018
	- Added logic to exclude Iron Offers without a start date

Jason Shipp 28/03/2019
	- Added logic to exclude spaces from Iron Offers names before determining offer types

Jason Shipp 14/05/2020
	- Added Virgin offers to load and updates, to the main table and to a separate Virgin-only table: WH_Virgin.Derived.IronOfferSegment (code currently commented out)
	
	- Because Virgin IronOfferIDs are strings (not ints), the WH_Virgin.Derived.IronOfferSegment table is additionally loaded
	- The IronOfferID column is varchar here
	- This table feeds the Virgin ETL (SQLServerToS3.py script - see Confluence)
	- When we eventually make IronOfferIDs varchar everywhere, this second table should not be needed- the Virgin ETL SQLServerToS3.py script can be re-pointed to the main table (Warehouse.Relational.IronOfferSegment)

******************************************************************************/
CREATE PROCEDURE [Staging].[IronOfferSegment_Update]

AS
BEGIN
	
	SET NOCOUNT ON;DECLARE @Today date = CAST(GETDATE() AS DATE);

	/******************************************************************************
	Load partner alternates
	******************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;
 
	SELECT 
		PartnerID
		, AlternatePartnerID
	INTO #PartnerAlternate
	FROM Warehouse.APW.PartnerAlternate

	UNION 

	SELECT 
		PartnerID
		, AlternatePartnerID
	FROM nFI.APW.PartnerAlternate;

	/******************************************************************************
	Load new Iron Offers
	******************************************************************************/

	IF  OBJECT_ID ('tempdb..#NewIronOffers') IS NOT NULL DROP TABLE #NewIronOffers;

	SELECT	o.IronOfferID
		,	o.PartnerID
		,	CAST(o.StartDate AS date) AS OfferStartDate
		,	CAST(o.EndDate AS date) AS OfferEndDate
		,	o.IronOfferName
		,	NULL AS SegmentName
		,	132 AS PublisherID
		,	1 AS PublisherGroupID -- From Warehouse.Relational.PublisherGroup
		,	'RBS' AS PublisherGroupName
		,	@Today AS DateAdded
	INTO #NewIronOffers
	FROM Warehouse.Relational.IronOffer o
	WHERE 
		o.IssignedOff = 1
		AND o.StartDate IS NOT NULL
		AND o.IronOfferName NOT LIKE 'Spare%'
		AND NOT EXISTS (
			SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
			WHERE 
				o.IronOfferID = x.IronOfferID
				AND x.PublisherGroupName = 'RBS'
		)

	UNION ALL

	SELECT 
		o.ID AS IronOfferID
		, o.PartnerID
		, CAST(o.StartDate AS date) AS OfferStartDate
		, CAST(o.EndDate AS date) AS OfferEndDate
		, o.IronOfferName
		,	NULL AS SegmentName
		, o.ClubID AS PublisherID
		, 2 AS PublisherGroupID
		, 'nFI' AS PublisherGroupName -- From Warehouse.Relational.PublisherGroup
		, @Today AS DateAdded
	FROM nFI.Relational.IronOffer o
	WHERE 
		o.IssignedOff = 1
		AND o.StartDate IS NOT NULL
		AND o.IronOfferName NOT LIKE 'Spare%'
		AND NOT EXISTS (
			SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
			WHERE 
				o.ID = x.IronOfferID
				AND x.PublisherGroupName = 'nFI'
		)

	UNION ALL

	SELECT 
		o.IronOfferID
		, o.RetailerID AS PartnerID
		, CAST(o.StartDate AS date) AS OfferStartDate
		, CAST(o.EndDate AS date) AS OfferEndDate
		, o.TargetAudience AS IronOfferName
		,	NULL AS SegmentName
		, o.PublisherID
		, 3 AS PublisherGroupID -- From Warehouse.Relational.PublisherGroup
		, 'AMEX' AS PublisherGroupName
		, @Today AS DateAdded
	FROM nFI.Relational.AmexOffer o
	WHERE 
		o.StartDate IS NOT NULL
		AND NOT EXISTS (
		SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
		WHERE 
			o.IronOfferID = x.IronOfferID
			AND x.PublisherGroupName = 'AMEX'
	)

	UNION ALL

	SELECT	o.IronOfferID
		,	o.PartnerID
		,	CAST(o.StartDate AS date) AS OfferStartDate
		,	CAST(o.EndDate AS date) AS OfferEndDate
		,	o.IronOfferName
		,	o.SegmentName
		,	ClubID AS PublisherID
		,	4 AS PublisherGroupID
		,	'Virgin' AS PublisherGroupName
		,	@Today AS DateAdded
	FROM WH_Virgin.Derived.IronOffer o
	WHERE 
		o.IssignedOff = 1
		AND o.StartDate IS NOT NULL
		AND o.IronOfferName NOT LIKE 'Spare%'
		AND NOT EXISTS (
			SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
			WHERE 
				o.IronOfferID = x.IronOfferID
				AND x.PublisherGroupName = 'Virgin'
		)

	UNION ALL

	SELECT	o.IronOfferID
		,	o.PartnerID
		,	CAST(o.StartDate AS date) AS OfferStartDate
		,	CAST(o.EndDate AS date) AS OfferEndDate
		,	o.IronOfferName
		,	o.SegmentName
		,	ClubID AS PublisherID
		,	5 AS PublisherGroupID
		,	'Visa Barclaycard' AS PublisherGroupName
		,	@Today AS DateAdded
	FROM WH_Visa.Derived.IronOffer o
	WHERE 
		o.IssignedOff = 1
		AND o.StartDate IS NOT NULL
		AND o.IronOfferName NOT LIKE 'Spare%'
		AND NOT EXISTS (
			SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
			WHERE 
				o.IronOfferID = x.IronOfferID
				AND x.PublisherGroupName = 'Visa Barclaycard'
		)

	UNION ALL

	SELECT	o.IronOfferID
		,	o.PartnerID
		,	CAST(o.StartDate AS date) AS OfferStartDate
		,	CAST(o.EndDate AS date) AS OfferEndDate
		,	o.IronOfferName
		,	o.SegmentName
		,	ClubID AS PublisherID
		,	6 AS PublisherGroupID
		,	'Virgin PCA' AS PublisherGroupName
		,	@Today AS DateAdded
	FROM [WH_VirginPCA].[Derived].[IronOffer] o
	WHERE 
		o.IssignedOff = 1
		AND o.StartDate IS NOT NULL
		AND o.IronOfferName NOT LIKE 'Spare%'
		AND NOT EXISTS (
			SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
			WHERE 
				o.IronOfferID = x.IronOfferID
				AND x.PublisherGroupName = 'Virgin PCA'
		);

	

	/******************************************************************************
	Assign Segment types and Offer types
	******************************************************************************/

	IF  OBJECT_ID ('tempdb..#NewIronOfferTypes_Staging') IS NOT NULL DROP TABLE #NewIronOfferTypes_Staging;

	SELECT
		o.IronOfferID
		, o.PartnerID
		, o.OfferStartDate
		, o.OfferEndDate
		, o.IronOfferName
		, o.PublisherID
		, o.PublisherGroupID
		, o.PublisherGroupName
		, CASE
			WHEN o.IronOfferID = 20705 THEN 7
			WHEN o.IronOfferID = 21135 THEN 7
			WHEN o.IronOfferID = 19637 THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperRiskOfLapsing%' THEN 10
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperRiskOfLapsing%' THEN 10
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperGrow%' THEN 11
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Acquire' THEN 7 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsed' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Shopper' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Aqcuire' THEN 7 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%/Shopper%SOW%' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%/Shopper%Trial%' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Nursery' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsing' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Acqui%' THEN 7
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Aqui%' THEN 7
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Acquire_LowInterest' THEN 7
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsed' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsers' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsed/%' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lasped%' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Welcome' THEN NULL
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Homemover' THEN NULL
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Birthday' THEN NULL
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Shopper' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Shopper/%' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Existing' THEN 9	
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Retain%' THEN 6
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Retain_Grow' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%RetainDebit%' THEN 6
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%RetainCredit%' THEN 6
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Grow%' THEN 5
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%GrowCredit%' THEN 5
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%GrowDebit%' THEN 5
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperDebit' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperCredit' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperDebit&Credit' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%LapsedDebit' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%LapsedCredit' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%LapsedDebit&Credit' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Prime%' THEN 4
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%WinBack%' THEN 3
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%WinbackPrime_Winback' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%LowInterest%' THEN 1
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Sky%MFDD%' THEN 7
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Europcar%MFDD%' THEN 7
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%AllSegments%' THEN NULL
			ELSE NULL
		END AS SegmentID
		, CASE 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperRiskOfLapsing%' THEN 19 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperGrow%' THEN 20
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Acquire' THEN 14 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsed' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsers' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Shopper' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Welcome' THEN 10
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Acquire%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsed%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lasped%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsed/%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Homemove%' THEN 16
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Birthda%' THEN 15
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Aqcuire' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Nursery' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsing' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Shopper%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Shopper/%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Retain%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Grow%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Launch%' THEN 11
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Core%' THEN 17 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Base%' THEN 17
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Joiner%' THEN 10
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Sky%MFDD%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Europcar%MFDD%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%AllSegments%' THEN 17
		ELSE 14 END AS OfferTypeID
		, o.DateAdded
	INTO #NewIronOfferTypes_Staging
	FROM #NewIronOffers o
	WHERE 
		o.PublisherGroupName IN ('RBS', 'Virgin', 'Virgin PCA', 'Visa Barclaycard')

	UNION ALL

	SELECT
		o.IronOfferID
		, o.PartnerID
		, o.OfferStartDate
		, o.OfferEndDate
		, o.IronOfferName
		, o.PublisherID
		, o.PublisherGroupID
		, o.PublisherGroupName
		, CASE
			WHEN o.IronOfferID = 20705 THEN 7
			WHEN o.IronOfferID = 21135 THEN 7
			WHEN o.IronOfferID = 19637 THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperRiskOfLapsing%' THEN 10
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperGrow%' THEN 11
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Acquire' THEN 7 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsed' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Shopper' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Acqui%' THEN 7
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsed%' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsed/%' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lasped%' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsers' THEN 8
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Welcome' THEN NULL
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Homemover' THEN NULL
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Birthday' THEN NULL
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Shopper%' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Shopper/%' THEN 9
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Existing' THEN 9			
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Retain%' THEN 6
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Grow%' THEN 5
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Prime%' THEN 4
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%WinBack%' THEN 3
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%LowInterest%' THEN 1
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Sky%MFDD%' THEN 7	
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Europcar%MFDD%' THEN 7
			ELSE NULL
		END AS SegmentID
		, CASE 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperRiskOfLapsing%' THEN 19 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%ShopperGrow%' THEN 20
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Acquire' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsed' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lasped%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Lapsers' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Shopper' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Welcome%' THEN 10
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Core%' THEN 17 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Base%' THEN 17
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Joiner%' THEN 10
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Homemove%' THEN 16
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Birthda%' THEN 15
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Retain%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Grow%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Launch%' THEN 11
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Universal%' THEN 17
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%American Golf Offer' THEN 17
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Sky%MFDD%' THEN 14
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Europcar%MFDD%' THEN 14
		ELSE 14 END AS OfferTypeID
		, o.DateAdded
	FROM #NewIronOffers o
	WHERE 
		o.PublisherGroupName IN ('nFI')

	UNION ALL

	SELECT
		o.IronOfferID
		, o.PartnerID
		, o.OfferStartDate
		, o.OfferEndDate
		, o.IronOfferName
		, o.PublisherID
		, o.PublisherGroupID
		, o.PublisherGroupName
		, NULLIF(ao.SegmentID, 0) AS SegmentID
		, CASE 
			WHEN ao.SegmentID = 0 OR ao.SegmentID IS NULL THEN 17 -- Universal
			WHEN ao.SegmentID = 10 THEN 19 -- Shopper Risk Of Lapsing
			WHEN ao.SegmentID = 11 THEN 20 -- Shopper Grow
			ELSE 14 -- ShopperSegment
	     END AS OfferTypeID
		 , o.DateAdded
	FROM #NewIronOffers o
	LEFT JOIN nFI.Relational.AmexOffer ao
		ON o.IronOfferID = ao.IronOfferID
	WHERE 
		o.PublisherGroupName IN ('AMEX');


	/******************************************************************************
	Assign Segment codes, Super Segment types, all type names and RetailerIDs
	******************************************************************************/

	IF  OBJECT_ID ('tempdb..#NewIronOfferTypes') IS NOT NULL DROP TABLE #NewIronOfferTypes;

	SELECT
		o.IronOfferID
		, o.PartnerID
		, COALESCE(pa.AlternatePartnerID, o.PartnerID) AS RetailerID
		, o.OfferStartDate
		, o.OfferEndDate
		, o.IronOfferName
		, o.PublisherID
		, o.PublisherGroupID
		, o.PublisherGroupName
		, o.SegmentID
		, rss.SegmentName
		, CASE 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Welcome%' THEN 'A'
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Launch%' AND (
					RTRIM(REPLACE(o.IronOfferName, '	', '')) NOT LIKE '%Shopper%'
					AND RTRIM(REPLACE(o.IronOfferName, '	', '')) NOT LIKE '%Acquire%'
					AND RTRIM(REPLACE(o.IronOfferName, '	', '')) NOT LIKE '%Lapse%'
					AND RTRIM(REPLACE(o.IronOfferName, '	', '')) NOT LIKE '%Laspe%'
					AND RTRIM(REPLACE(o.IronOfferName, '	', '')) NOT LIKE '%Retain%'
					AND RTRIM(REPLACE(o.IronOfferName, '	', '')) NOT LIKE '%Grow%'
				) THEN 'B' 
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Base%' THEN 'B'
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Birthday' THEN 'B'
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%HomeMover' THEN 'B'
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%Universal%' THEN 'B'
			WHEN RTRIM(REPLACE(o.IronOfferName, '	', '')) LIKE '%American Golf Offer%' THEN 'B'
			ELSE rss.SegmentCode
		END AS SegmentCode
		, rst.ID AS SuperSegmentID
		, rst.SuperSegmentName
		, o.OfferTypeID
		, COALESCE(wot.TypeDescription, nfot.TypeDescription) AS OfferTypeDescription
		, COALESCE(
			CASE 
				WHEN o.OfferTypeID = 14 THEN rst.SuperSegmentName
				WHEN o.OfferTypeID >= 19 THEN COALESCE(wot.TypeDescription, nfot.TypeDescription)
				ELSE rst.SuperSegmentName
			 END
			 , COALESCE(wot.TypeDescription, nfot.TypeDescription)
			 , 'None' -- Set as 'Legacy' for old offers in IronOfferSegment table. Going forward, set as 'None'- these cases should be checked
		) AS OfferTypeForReports
		, o.DateAdded
	INTO #NewIronOfferTypes
	FROM #NewIronOfferTypes_Staging o
	LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types rss 
		ON o.SegmentID = rss.ID
	LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Super_Types rst 
		ON rss.SuperSegmentTypeID = rst.ID 
	LEFT JOIN Warehouse.Relational.OfferType wot
		ON o.OfferTypeID = wot.ID
		AND o.PublisherGroupName NOT IN ('nFI', 'AMEX')
	LEFT JOIN nFI.Relational.OfferType nfot
		ON o.OfferTypeID = nfot.ID
		AND o.PublisherGroupName IN ('nFI', 'AMEX')
	LEFT JOIN #PartnerAlternate pa
		ON o.PartnerID = pa.PartnerID;
		

	/******************************************************************************
	Load IronOfferID-ClientServicesRef mapping
	******************************************************************************/

	IF OBJECT_ID ('tempdb..#CSRefs') IS NOT NULL DROP TABLE #CSRefs;

	SELECT -- RBS
		IronOfferID
		, ClientServicesRef
	INTO #CSRefs
	FROM Warehouse.Relational.IronOffer_Campaign_HTM
	UNION
	SELECT -- nFI
		IronOfferID
		, MAX(ClientServicesRef) AS ClientServicesRef 
	FROM nFI.Relational.IronOffer_Campaign_HTM 
	GROUP BY
		IronOfferID
	UNION -- AMEX
	SELECT
		IronOfferID
		, AmexOfferID AS ClientServicesRef
	FROM nFI.Relational.AmexOffer
	UNION
	SELECT -- Virgin
		IronOfferID
		, ClientServicesRef
	FROM WH_Virgin.Derived.IronOffer_Campaign_HTM
	UNION
	SELECT -- Virgin PCA
		IronOfferID
		, ClientServicesRef
	FROM [WH_VirginPCA].[Derived].[IronOffer_Campaign_HTM]
	UNION
	SELECT -- Visa Barclaycard
		IronOfferID
		, ClientServicesRef
	FROM WH_Visa.Derived.IronOffer_Campaign_HTM;

	/******************************************************************************
	Insert new entries into Warehouse.Relational.IronOfferSegment
	******************************************************************************/

	INSERT INTO Warehouse.Relational.IronOfferSegment (
		IronOfferID
		, OfferStartDate
		, OfferEndDate
		, PartnerID
		, RetailerID
		, IronOfferName
		, PublisherID
		, PublisherGroupID
		, PublisherGroupName
		, SegmentID
		, SegmentName
		, SegmentCode
		, SuperSegmentID
		, SuperSegmentName
		, OfferTypeID
		, OfferTypeDescription
		, OfferTypeForReports
		, ClientServicesRef
		, DateAdded
	)
	SELECT 
		o.IronOfferID
		, o.OfferStartDate
		, o.OfferEndDate
		, o.PartnerID 
		, o.RetailerID
		, RTRIM(
			CASE 
				WHEN ao.OfferDefinition <> '' AND ao.OfferDefinition IS NOT NULL
				THEN REPLACE(ao.OfferDefinition, '"', '')
				ELSE o.IronOfferName END
		) AS IronOfferName -- Use AMEX OfferDefinition as the IronOfferName
		, o.PublisherID
		, o.PublisherGroupID
		, o.PublisherGroupName
		, o.SegmentID
		, o.SegmentName
		, o.SegmentCode
		, o.SuperSegmentID
		, o.SuperSegmentName
		, o.OfferTypeID
		, o.OfferTypeDescription
		, o.OfferTypeForReports
		, csr.ClientServicesRef
		, o.DateAdded
	FROM #NewIronOfferTypes o
	LEFT JOIN nFI.Relational.AmexOffer ao
		ON o.IronOfferID = ao.IronOfferID
	LEFT JOIN #CSRefs csr
		ON o.IronOfferID = csr.IronOfferID
	WHERE NOT EXISTS ( -- Shouldn't need this but can't hurt!
		SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
		WHERE 
			o.IronOfferID = x.IronOfferID
	);

	-- Separate insert into Virgin table (used in Virgin ETL)

	INSERT INTO WH_Virgin.Derived.IronOfferSegment (
		IronOfferID
		, OfferStartDate
		, OfferEndDate
		, PartnerID
		, RetailerID
		, IronOfferName
		, PublisherID
		, PublisherGroupID
		, PublisherGroupName
		, SegmentID
		, SegmentName
		, SegmentCode
		, SuperSegmentID
		, SuperSegmentName
		, OfferTypeID
		, OfferTypeDescription
		, OfferTypeForReports
		, ClientServicesRef
		, DateAdded
	)
	SELECT 
		o.IronOfferID
		, o.OfferStartDate
		, o.OfferEndDate
		, o.PartnerID 
		, o.RetailerID
		, RTRIM(
			CASE 
				WHEN ao.OfferDefinition <> '' AND ao.OfferDefinition IS NOT NULL
				THEN REPLACE(ao.OfferDefinition, '"', '')
				ELSE o.IronOfferName END
		) AS IronOfferName -- Use AMEX OfferDefinition as the IronOfferName
		, o.PublisherID
		, o.PublisherGroupID
		, o.PublisherGroupName
		, o.SegmentID
		, o.SegmentName
		, o.SegmentCode
		, o.SuperSegmentID
		, o.SuperSegmentName
		, o.OfferTypeID
		, o.OfferTypeDescription
		, o.OfferTypeForReports
		, csr.ClientServicesRef
		, o.DateAdded
	FROM #NewIronOfferTypes o
	LEFT JOIN nFI.Relational.AmexOffer ao
		ON o.IronOfferID = ao.IronOfferID
	LEFT JOIN #CSRefs csr
		ON o.IronOfferID = csr.IronOfferID
	WHERE NOT EXISTS (
		SELECT NULL FROM WH_Virgin.Derived.IronOfferSegment x
		WHERE 
			o.IronOfferID = x.IronOfferID
	)
	AND o.PublisherGroupName = 'Virgin';
	
	/******************************************************************************
	Update offer start and end dates that have changed in base tables
	******************************************************************************/

	IF  OBJECT_ID ('tempdb..#NewIronOfferDates') IS NOT NULL DROP TABLE #NewIronOfferDates;

	SELECT -- RBS
		o.IronOfferID
		, CAST(o.StartDate AS date) AS OfferStartDate
		, CAST(o.EndDate AS date) AS OfferEndDate
	INTO #NewIronOfferDates
	FROM Warehouse.Relational.IronOffer o
	WHERE EXISTS (
		SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
		WHERE 
			o.IronOfferID = x.IronOfferID
			AND (
				((CAST(o.StartDate AS date) <> x.OfferStartDate) OR (o.StartDate IS NULL AND x.OfferStartDate IS NOT NULL))
				OR
				((CAST(o.EndDate AS date) <> x.OfferEndDate) OR (o.EndDate IS NULL AND x.OfferEndDate IS NOT NULL) OR (o.EndDate IS NOT NULL AND x.OfferEndDate IS NULL))
			)
	)

	UNION

	SELECT -- nFI
		o.ID AS IronOfferID
		, CAST(o.StartDate AS date) AS OfferStartDate
		, CAST(o.EndDate AS date) AS OfferEndDate
	FROM nFI.Relational.IronOffer o
	WHERE EXISTS (
		SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
		WHERE 
			o.ID = x.IronOfferID
			AND (
				((CAST(o.StartDate AS date) <> x.OfferStartDate) OR (o.StartDate IS NULL AND x.OfferStartDate IS NOT NULL))
				OR
				((CAST(o.EndDate AS date) <> x.OfferEndDate) OR (o.EndDate IS NULL AND x.OfferEndDate IS NOT NULL) OR (o.EndDate IS NOT NULL AND x.OfferEndDate IS NULL))
			)
	)

	UNION

	SELECT -- AMEX
		o.IronOfferID
		, CAST(o.StartDate AS date) AS OfferStartDate
		, CAST(o.EndDate AS date) AS OfferEndDate
	FROM nFI.Relational.AmexOffer o
	WHERE EXISTS (
		SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
		WHERE 
			o.IronOfferID = x.IronOfferID
			AND (
				((CAST(o.StartDate AS date) <> x.OfferStartDate) OR (o.StartDate IS NULL AND x.OfferStartDate IS NOT NULL))
				OR
				((CAST(o.EndDate AS date) <> x.OfferEndDate) OR (o.EndDate IS NULL AND x.OfferEndDate IS NOT NULL) OR (o.EndDate IS NOT NULL AND x.OfferEndDate IS NULL))
			)
	)

	UNION

	SELECT -- Virgin
		o.IronOfferID
		, CAST(o.StartDate AS date) AS OfferStartDate
		, CAST(o.EndDate AS date) AS OfferEndDate
	FROM WH_Virgin.Derived.IronOffer o
	WHERE (
		EXISTS (
			SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
			WHERE 
				o.IronOfferID = x.IronOfferID
				AND (
					((CAST(o.StartDate AS date) <> x.OfferStartDate) OR (o.StartDate IS NULL AND x.OfferStartDate IS NOT NULL))
					OR
					((CAST(o.EndDate AS date) <> x.OfferEndDate) OR (o.EndDate IS NULL AND x.OfferEndDate IS NOT NULL) OR (o.EndDate IS NOT NULL AND x.OfferEndDate IS NULL))
				)
		)
		OR 
		EXISTS (
			SELECT NULL FROM WH_Virgin.Derived.IronOfferSegment x2
			WHERE 
				o.IronOfferID = x2.IronOfferID
				AND (
					((CAST(o.StartDate AS date) <> x2.OfferStartDate) OR (o.StartDate IS NULL AND x2.OfferStartDate IS NOT NULL))
					OR
					((CAST(o.EndDate AS date) <> x2.OfferEndDate) OR (o.EndDate IS NULL AND x2.OfferEndDate IS NOT NULL) OR (o.EndDate IS NOT NULL AND x2.OfferEndDate IS NULL))
				)
		)
	)

	UNION

	SELECT -- Virgin PCA
		o.IronOfferID
		, CAST(o.StartDate AS date) AS OfferStartDate
		, CAST(o.EndDate AS date) AS OfferEndDate
	FROM [WH_VirginPCA].[Derived].[IronOffer] o
	WHERE (
		EXISTS (
			SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
			WHERE 
				o.IronOfferID = x.IronOfferID
				AND (
					((CAST(o.StartDate AS date) <> x.OfferStartDate) OR (o.StartDate IS NULL AND x.OfferStartDate IS NOT NULL))
					OR
					((CAST(o.EndDate AS date) <> x.OfferEndDate) OR (o.EndDate IS NULL AND x.OfferEndDate IS NOT NULL) OR (o.EndDate IS NOT NULL AND x.OfferEndDate IS NULL))
				)
		)
		OR 
		EXISTS (
			SELECT NULL FROM [WH_VirginPCA].Derived.IronOfferSegment x2
			WHERE 
				o.IronOfferID = x2.IronOfferID
				AND (
					((CAST(o.StartDate AS date) <> x2.OfferStartDate) OR (o.StartDate IS NULL AND x2.OfferStartDate IS NOT NULL))
					OR
					((CAST(o.EndDate AS date) <> x2.OfferEndDate) OR (o.EndDate IS NULL AND x2.OfferEndDate IS NOT NULL) OR (o.EndDate IS NOT NULL AND x2.OfferEndDate IS NULL))
				)
		)
	)

	UNION

	SELECT -- Visa Barclaycard
		o.IronOfferID
		, CAST(o.StartDate AS date) AS OfferStartDate
		, CAST(o.EndDate AS date) AS OfferEndDate
	FROM WH_Visa.Derived.IronOffer o
	WHERE (
		EXISTS (
			SELECT NULL FROM Warehouse.Relational.IronOfferSegment x
			WHERE 
				o.IronOfferID = x.IronOfferID
				AND (
					((CAST(o.StartDate AS date) <> x.OfferStartDate) OR (o.StartDate IS NULL AND x.OfferStartDate IS NOT NULL))
					OR
					((CAST(o.EndDate AS date) <> x.OfferEndDate) OR (o.EndDate IS NULL AND x.OfferEndDate IS NOT NULL) OR (o.EndDate IS NOT NULL AND x.OfferEndDate IS NULL))
				)
		)
		OR 
		EXISTS (
			SELECT NULL FROM WH_Visa.Derived.IronOfferSegment x2
			WHERE 
				o.IronOfferID = x2.IronOfferID
				AND (
					((CAST(o.StartDate AS date) <> x2.OfferStartDate) OR (o.StartDate IS NULL AND x2.OfferStartDate IS NOT NULL))
					OR
					((CAST(o.EndDate AS date) <> x2.OfferEndDate) OR (o.EndDate IS NULL AND x2.OfferEndDate IS NOT NULL) OR (o.EndDate IS NOT NULL AND x2.OfferEndDate IS NULL))
				)
		)
	);

	UPDATE s
		SET s.OfferStartDate = d.OfferStartDate
		, s.OfferEndDate = d.OfferEndDate
	FROM Warehouse.Relational.IronOfferSegment s
	INNER JOIN #NewIronOfferDates d
		ON s.IronOfferID = d.IronOfferID;

	-- Separate update on Virgin table (used in Virgin ETL)

	UPDATE s
		SET s.OfferStartDate = d.OfferStartDate
		, s.OfferEndDate = d.OfferEndDate
	FROM WH_Virgin.Derived.IronOfferSegment s
	INNER JOIN #NewIronOfferDates d
		ON s.IronOfferID = d.IronOfferID;

	-- Separate update on Visa Barclaycard table (used in Visa Barclaycard ETL)

	UPDATE s
		SET s.OfferStartDate = d.OfferStartDate
		, s.OfferEndDate = d.OfferEndDate
	FROM WH_Visa.Derived.IronOfferSegment s
	INNER JOIN #NewIronOfferDates d
		ON s.IronOfferID = d.IronOfferID;

	/******************************************************************************
	Update ClientServicesRefs that have changed in base tables
	******************************************************************************/

	UPDATE s
		SET s.ClientServicesRef = csr.ClientServicesRef
	FROM Warehouse.Relational.IronOfferSegment s
	INNER JOIN #CSRefs csr
		ON s.IronOfferID = csr.IronOfferID
	WHERE 
		s.ClientServicesRef <> csr.ClientServicesRef
		OR (s.ClientServicesRef IS NULL AND csr.ClientServicesRef IS NOT NULL);

	-- Separate update on Virgin table (used in Virgin ETL)

	UPDATE s
		SET s.ClientServicesRef = csr.ClientServicesRef
	FROM WH_Virgin.Derived.IronOfferSegment s
	INNER JOIN #CSRefs csr
		ON s.IronOfferID = csr.IronOfferID
	WHERE 
		s.ClientServicesRef <> csr.ClientServicesRef
		OR (s.ClientServicesRef IS NULL AND csr.ClientServicesRef IS NOT NULL);

	-- Separate update on Virgin table (used in Virgin ETL)

	UPDATE s
		SET s.ClientServicesRef = csr.ClientServicesRef
	FROM WH_VirginPCA.Derived.IronOfferSegment s
	INNER JOIN #CSRefs csr
		ON s.IronOfferID = csr.IronOfferID
	WHERE 
		s.ClientServicesRef <> csr.ClientServicesRef
		OR (s.ClientServicesRef IS NULL AND csr.ClientServicesRef IS NOT NULL);

	-- Separate update on Visa Barclaycard table (used in Visa Barclaycard ETL)

	UPDATE s
		SET s.ClientServicesRef = csr.ClientServicesRef
	FROM WH_Visa.Derived.IronOfferSegment s
	INNER JOIN #CSRefs csr
		ON s.IronOfferID = csr.IronOfferID
	WHERE 
		s.ClientServicesRef <> csr.ClientServicesRef
		OR (s.ClientServicesRef IS NULL AND csr.ClientServicesRef IS NOT NULL);

	/******************************************************************************
	-- Create table for storing results

	CREATE TABLE Warehouse.Relational.IronOfferSegment (
		IronOfferID int NOT NULL
		, OfferStartDate date NOT NULL
		, OfferEndDate date NULL
		, PartnerID int NOT NULL
		, RetailerID int NOT NULL
		, IronOfferName nvarchar(200) NOT NULL
		, PublisherID int NOT NULL
		, PublisherGroupID int NOT NULL
		, PublisherGroupName varchar(40) NOT NULL
		, SegmentID int
		, SegmentName varchar(50)
		, SegmentCode varchar(10)
		, SuperSegmentID int 
		, SuperSegmentName varchar(40)
		, OfferTypeID int 
		, OfferTypeDescription varchar(50)
		, OfferTypeForReports varchar(100) NOT NULL
		, ClientServicesRef varchar(40)
		, DateAdded date NOT NULL
		, CONSTRAINT PK_IronOfferSegment PRIMARY KEY CLUSTERED (IronOfferID)
	);
	******************************************************************************/

END