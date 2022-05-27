/******************************************************************************
Author: Jason Shipp
Created: 15/03/2018
Purpose:
	- Load new entries INTO [WH_Virgin].[Report].[IronOffer_References] table
	- Load validation of offer types assigned to the new entries
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 28/08/2018
	- Used Warehouse.Relational.IronOfferSegment table AS source of segment codes instead of applying string searches to IronOfferNames
******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_VirginNonAAM_Load_IronOffer_References]

AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Load offer cycles
	******************************************************************************/

	If  object_id ('tempdb..#OCs') IS NOT NULL DROP TABLE #OCs;

	SELECT	DISTINCT
			OfferCyclesID
	INTO #OCs
	FROM [Warehouse].[Staging].[ControlSetup_Cycle_Dates] d
	LEFT JOIN [WH_Virgin].[Report].[OfferCycles] oc
		on	(d.StartDate <= oc.EndDate OR oc.EndDate IS NULL)
		AND d.EndDate > oc.Startdate;

	/******************************************************************************
	Load cashback rules
	******************************************************************************/

	If  object_id ('tempdb..#CashbackRate_nFI') IS NOT NULL DROP TABLE #CashbackRate_nFI;
	
	Select
		IronOfferID
		, MAX(Case
			When MinimumBasketSize IS NULL then CommissionRate
			Else 0
		End) AS CashbackRate
		, MAX(MinimumBasketSize) AS BasketSize
		, MAX(Case
			When MinimumBasketSize > 0 then CommissionRate
			Else NULL
		End) AS SpendStretchCashbackRate
	INTO #CashbackRate_nFI
	FROM [WH_Virgin].[Derived].[IronOffer_PartnerCommissionRule] pcr
	WHERE
		Status = 1
		AND typeid = 1
	GROUP BY
		IronOfferID;

	/******************************************************************************
	Generate entries to be added to [WH_Virgin].[Report].[IronOffer_References] table
	******************************************************************************/

	IF OBJECT_ID ('tempdb..#IronOffer_Ref_Virgin') IS NOT NULL DROP TABLE #IronOffer_Ref_Virgin;

	Select
		i.IronOfferID
		, i.ClubID AS ClubID
		, ioc.IronOfferCyclesID
		, s.SegmentID AS ShopperSegmentID
		, s.OfferTypeID
		, cb.CashbackRate AS CashbackRate
		, cb.BasketSize AS SpendStretch
		, cb.SpendStretchCashbackRate AS SpendStretchRate
	INTO #IronOffer_Ref_Virgin
	FROM [WH_Virgin].[Report].[IronOfferCycles] ioc
	INNER JOIN [WH_Virgin].[Derived].[IronOffer] i
		on ioc.ironofferid = i.IronOfferID
	INNER JOIN #CashbackRate_nFI cb
		on i.IronOfferID = cb.IronOfferID
	INNER JOIN #OCs o
		on o.OfferCyclesID = ioc.OfferCyclesID
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		on i.IronOfferID = s.IronOfferID;

	/******************************************************************************
	Load new entries INTO [WH_Virgin].[Report].[IronOffer_References] table
	******************************************************************************/

	INSERT INTO [WH_Virgin].[Report].[IronOffer_References]
	Select
		i.*
	FROM #IronOffer_Ref_Virgin i
	LEFT JOIN [WH_Virgin].[Report].[IronOffer_References] a
		on i.IronOfferCyclesID = a.IronOfferCyclesID
	WHERE
		a.IronOfferCyclesID IS NULL;

	/******************************************************************************
	CHECK POINT: Validate entries added to [WH_Virgin].[Report].[IronOffer_References] table

	CREATE TABLE for storing validation results

	CREATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginNonAAM_IronOffer_References]
		(PublisherType VARCHAR(50)
		, IronOfferID INT
		, StartDate DATE
		, EndDate DATE
		, ClubID INT
		, IronOfferCyclesID INT
		, ShopperSegmentID INT
		, SegmentName VARCHAR(50)
		, OfferTypeID INT
		, TypeDescription VARCHAR(50)
		, CashbackRate FLOAT
		, SpendStretch FLOAT
		, SpendStretchRate FLOAT
		, OfferCyclesID INT
		, controlgroupid INT
		, IronOfferName NVARCHAR(200)
		, CONSTRAINT PK_ControlSetup_Validation_VirginNonAAM_IronOffer_References PRIMARY KEY CLUSTERED (IronOfferID, StartDate, EndDate)  
		)
	******************************************************************************/

	IF OBJECT_ID ('tempdb..#IORCheckData') IS NOT NULL DROP TABLE #IORCheckData;
	
	Select
		'Virgin' AS PublisherType
		, i.IronOfferID
		, oc.StartDate
		, oc.EndDate
		, i.ClubID
		, i.IronOfferCyclesID
		, i.ShopperSegmentID
		, st.SegmentName
		, i.OfferTypeID
		, ot.TypeDescription
		, i.CashbackRate
		, i.SpendStretch
		, i.SpendStretchRate
		, ioc.OfferCyclesID
		, ioc.controlgroupid
		, o.IronOfferName
	INTO #IORCheckData
	FROM #IronOffer_Ref_Virgin AS i
	LEFT JOIN [WH_Virgin].[Report].[IronOffer_References] AS a
		on i.IronOfferCyclesID = a.IronOfferCyclesID
	LEFT JOIN [WH_Virgin].[Report].[IronOfferCycles] AS ioc
		on i.IronOfferCyclesID = ioc.IronOfferCyclesID
	LEFT JOIN [WH_Virgin].[Report].[OfferCycles] oc
		on ioc.OfferCyclesID = oc.OfferCyclesID
	INNER JOIN [WH_Virgin].[Derived].[IronOffer] AS o
		on i.IronOfferID = o.IronOfferID
	LEFT JOIN nFI.Relational.OfferType ot
		on i.OfferTypeID = ot.ID
	LEFT JOIN nFI.Segmentation.Roc_Shopper_Segment_Types st
		on i.ShopperSegmentID = st.ID
	WHERE
		oc.StartDate >= (SELECT StartDate FROM [Warehouse].[Staging].[ControlSetup_Cycle_Dates]);

	-- Load Iron Offers with incorrect segment type assignment due to incorrect naming convention

	TRUNCATE TABLE [Warehouse].[Staging].[ControlSetup_Validation_VirginNonAAM_IronOffer_References];

	INSERT INTO [Warehouse].[Staging].[ControlSetup_Validation_VirginNonAAM_IronOffer_References]
		(PublisherType
		, IronOfferID
		, StartDate
		, EndDate
		, ClubID
		, IronOfferCyclesID
		, ShopperSegmentID
		, SegmentName
		, OfferTypeID
		, TypeDescription
		, CashbackRate
		, SpendStretch
		, SpendStretchRate
		, OfferCyclesID
		, controlgroupid
		, IronOfferName
		)
	Select
		'Virgin' AS PublisherType
		, d.IronOfferID
		, d.StartDate
		, d.EndDate
		, d.ClubID
		, d.IronOfferCyclesID
		, d.ShopperSegmentID
		, d.SegmentName
		, d.OfferTypeID
		, d.TypeDescription
		, d.CashbackRate
		, d.SpendStretch
		, d.SpendStretchRate
		, d.OfferCyclesID
		, d.controlgroupid
		, d.IronOfferName
	FROM #IORCheckData d
	WHERE
		(d.SegmentName IS NULL AND d.TypeDescription LIKE ('%Launch%') AND d.IronOfferName not LIKE ('%Launch%'))
		or (d.SegmentName IS NULL AND d.TypeDescription LIKE ('%Universal%') AND d.IronOfferName not LIKE ('%Universal%') AND d.IronOfferName not LIKE ('%base%') AND d.IronOfferName not LIKE ('%AllSegments%') AND d.IronOfferName not LIKE ('%Launch%'))
		or (d.SegmentName IS NULL AND d.TypeDescription LIKE ('%Welcome%') AND d.IronOfferName not LIKE ('%Welcome%') AND d.IronOfferName not LIKE ('%NewJoiner%'))
		or (d.SegmentName LIKE ('%Acquisition%') AND d.TypeDescription LIKE ('%ShopperSegment%') AND d.IronOfferName not LIKE ('%Acquisition%') AND d.IronOfferName not LIKE ('%Acquire%') AND d.IronOfferName not LIKE ('%Aquire%'))
		or (d.SegmentName LIKE ('%Grow%') AND d.TypeDescription LIKE ('%ShopperSegment%') AND d.IronOfferName not LIKE ('%Grow%'))
		or (d.SegmentName LIKE ('%Lapsed%') AND d.TypeDescription LIKE ('%ShopperSegment%') AND d.IronOfferName not LIKE ('%Lapsed%') AND d.IronOfferName not LIKE ('%Winback%'))
		or (d.SegmentName LIKE ('%Retain%') AND d.TypeDescription LIKE ('%ShopperSegment%') AND d.IronOfferName not LIKE ('%Retain%'))
		or (d.SegmentName LIKE ('%Shopper%') AND d.TypeDescription LIKE ('%ShopperSegment%') AND d.IronOfferName not LIKE ('%Shopper%') AND d.IronOfferID != 22400 AND d.IronOfferName not LIKE ('%Nursery%') AND d.IronOfferName not LIKE ('%Lapsing%') AND d.IronOfferName not LIKE ('%Retain&Grow%'))
		or (d.SegmentName LIKE ('%Winback%') AND d.TypeDescription LIKE ('%ShopperSegment%') AND d.IronOfferName not LIKE ('%Winback%'))
		or (d.SegmentName LIKE ('%Winback Prime%') AND d.TypeDescription LIKE ('%ShopperSegment%') AND d.IronOfferName not LIKE ('%Winback Prime%') AND d.IronOfferName not LIKE ('%WinbackPrime%'));

END