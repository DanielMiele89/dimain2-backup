/******************************************************************************
Author	  Jason Shipp
Created	  19/01/2018
Purpose	  
	- Modified copy of Staging.ALS_Member_Counts_Per_Campaign_Cycle_Insert stored procedure fore testing
	- This stored procedure will not be maintained
------------------------------------------------------------------------------
Modification History
******************************************************************************/

CREATE PROCEDURE [MI].[ALS_Member_Counts_Per_Campaign_Cycle_Insert] 
	(@PartnerID INT = NULL)

AS
BEGIN

	SET NOCOUNT ON;

	/**************************************************************************
	Declare Vaiables
	***************************************************************************/

	DECLARE @OriginCycleStartDate DATE = '2010-01-14'; -- Random Campaign Report cycle start date
	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	
	/**************************************************************************
	Create temp table of cycle dates from the @OriginCycleStartDate to date
	***************************************************************************/

	-- Populate #Cycles table with cycle dates 

	IF OBJECT_ID('tempdb..#Cycles') IS NOT NULL DROP TABLE #Cycles;

	CREATE TABLE #Cycles
		(CycleStartDate DATE
		, CycleEndDate DATE
		);

	WITH cte AS
		(SELECT @OriginCycleStartDate AS CycleStartDate -- anchor member
		UNION ALL
		SELECT CAST((DATEADD(WEEK, 4, CycleStartDate)) AS DATE) --  Campaign Cycle start date: recursive member
		FROM   cte
		WHERE DATEADD(DAY, -1, (DATEADD(WEEK, 8, cte.CycleStartDate))) <= @Today -- terminator: last complete cycle end date
		)
	INSERT INTO #Cycles 
		(CycleStartDate
		, CycleEndDate
		)
	SELECT
		cte.CycleStartDate
		, DATEADD(DAY, -1, (DATEADD(WEEK, 4, cte.CycleStartDate))) AS CycleEndDate
	FROM cte
	OPTION (MAXRECURSION 1000);

	CREATE CLUSTERED INDEX cix_cycles ON #Cycles (CycleStartDate, CycleEndDate);

	/**************************************************************************
	Create temp table containing analysis periods per retailer
	***************************************************************************/

	-- Fetch minimum offer start date per retailer for nFI and Warehouse, for each retailer's most recent block of activity

	IF OBJECT_ID('tempdb..#MinOfferStart') IS NOT NULL DROP TABLE #MinOfferStart;

	WITH OffersStart AS 
		
		(SELECT -- Fetch nFI offers
			'nFI' AS PublisherType
			, PartnerID
			, ID AS IronOfferID
			, CAST(StartDate AS DATE) StartDate
			, CAST(EndDate AS DATE) AS EndDate
			, DATEDIFF(
				DAY
				, (LAG(CAST(EndDate AS DATE), 1, NULL) OVER (PARTITION BY PartnerID ORDER BY EndDate)) -- Fetch end date of previous offer
				, CAST(StartDate AS DATE)
			) AS DaysFromPrevOfferEnd
		FROM nFI.Relational.IronOffer

		UNION ALL

		SELECT -- Fetch RBS offers
			'Warehouse' AS 'PublisherType'
			, PartnerID
			, IronOfferID
			, CAST(StartDate AS DATE) StartDate
			, CAST(EndDate AS DATE) AS EndDate
			, DATEDIFF(
				day
				, (LAG(CAST(EndDate AS DATE), 1, NULL) OVER (PARTITION BY PartnerID ORDER BY EndDate)) -- Fetch end date of previous offer
				, CAST(StartDate AS DATE)
			) AS DaysFromPrevOfferEnd
		FROM Warehouse.Relational.IronOffer
		)

	SELECT 
		PublisherType
		, PartnerID
		, MIN(StartDate) AS RecentActivityStartDate -- Fetch most recent activity-period start date
	INTO #MinOfferStart
	FROM OffersStart
	WHERE 
		(DaysFromPrevOfferEnd IS NULL OR DaysFromPrevOfferEnd > 28) -- Activity-periods identified as being offer periods following no gap or a gap without active offers of at least 28 days
		AND StartDate IS NOT NULL
	GROUP BY 
		PublisherType
		, PartnerID;

	-- Fetch minimum ALS membership start date per retailer for nFI and Warehouse

	IF OBJECT_ID('tempdb..#MinALSStart') IS NOT NULL DROP TABLE #MinALSStart;

	SELECT
	PublisherType
	, PartnerID		
	, ALSStartDate
	INTO #MinALSStart
	FROM
		(SELECT 
			'nFI' AS PublisherType
			, PartnerID
			, MIN(CAST(StartDate AS DATE)) AS ALSStartDate
		FROM nFI.Segmentation.ROC_Shopper_Segment_Members
		GROUP BY PartnerID
		
		UNION ALL

		SELECT 
			'Warehouse' AS PublisherType
			, PartnerID
			, MIN(CAST(StartDate AS DATE)) AS ALSStartDate
		FROM Warehouse.Segmentation.Roc_Shopper_Segment_Members
		GROUP BY PartnerID
		) ALSStart;

	-- Fetch the latter of the minimum offer start date and ALS membership start date per retailer for nFI and Warehouse 

	IF OBJECT_ID('tempdb..#AnalysisStart') IS NOT NULL DROP TABLE #AnalysisStart;

	SELECT 
	os.PublisherType
	, os.PartnerID
	, CASE WHEN ALSStartDate > os.RecentActivityStartDate
		THEN ALSStartDate
		ELSE os.RecentActivityStartDate
	END AS AnalysisStartDate
	INTO #AnalysisStart	
	FROM #MinOfferStart os
	INNER JOIN #MinALSStart alss
		ON os.PartnerID	= alss.PartnerID
		AND os.PublisherType = alss.PublisherType;

	-- Fetch the Campaign cycles overlapping-and-after the analysis start date identified for each retailer for nFI and Warehouse

	IF OBJECT_ID('tempdb..#RetailerCycles') IS NOT NULL DROP TABLE #RetailerCycles;

	SELECT 
		s.PublisherType
		, s.PartnerID
		, s.AnalysisStartDate
		, cyc.CycleStartDate
		, cyc.CycleEndDate
	INTO #RetailerCycles
	FROM #AnalysisStart s
	INNER JOIN #Cycles cyc 
		ON cyc.CycleStartDate >= s.AnalysisStartDate -- Campaign cycles after analysis start date;

	CREATE CLUSTERED INDEX cix_RetailerCycles ON #RetailerCycles (PartnerID, CycleStartDate, CycleEndDate);

	/**************************************************************************
	Create temp table containing the first analysis periods per retailer
	***************************************************************************/

	IF OBJECT_ID('tempdb..#FirstRetailerCycles') IS NOT NULL DROP TABLE #FirstRetailerCycles;

	WITH FirstRetailerCycles AS
		(SELECT
			PublisherType
			, PartnerID
			, MIN(AnalysisStartDate) AS AnalysisStartDate
			, (CAST(DATEDIFF(DAY, @OriginCycleStartDate, MIN(AnalysisStartDate)) AS INT))/28 AS CompleteCyclesElapsed -- Complete cycles elapsed since @OriginCycleStartDate
		FROM #RetailerCycles
		GROUP BY 
			PublisherType
			, PartnerID
		)

	SELECT
		PublisherType
		, PartnerID
		, AnalysisStartDate
		, CASE WHEN AnalysisStartDate = DATEADD(DAY, CompleteCyclesElapsed*28, @OriginCycleStartDate)
			THEN AnalysisStartDate
			ELSE DATEADD(DAY, (CompleteCyclesElapsed+1)*28, @OriginCycleStartDate)
		END AS MinCycleStartDate -- First cycle start date on or after AnalysisStartDate
		, DATEADD(DAY, 27
			, (CASE WHEN AnalysisStartDate = DATEADD(DAY, CompleteCyclesElapsed*28, @OriginCycleStartDate)
				THEN AnalysisStartDate
				ELSE DATEADD(DAY, (CompleteCyclesElapsed+1)*28, @OriginCycleStartDate)
			END
			)
		) AS MinCycleEndDate -- First cycle end date on or after AnalysisStartDate
	INTO #FirstRetailerCycles
	FROM FirstRetailerCycles;	

	CREATE CLUSTERED INDEX cix_FirstRetailerCycles ON #FirstRetailerCycles (PartnerID, MinCycleEndDate, AnalysisStartDate);

	/**************************************************************************
	Create table of segement types
	***************************************************************************/

	IF OBJECT_ID('tempdb..#SegmentTypes') IS NOT NULL DROP TABLE #SegmentTypes;

	SELECT
	t.ID
	, sst.SuperSegmentName
	INTO #SegmentTypes
	FROM nFI.Segmentation.ROC_Shopper_Segment_Types t
	INNER JOIN nFI.Segmentation.ROC_Shopper_Segment_Super_Types sst
			ON t.SuperSegmentTypeID = sst.ID;

	CREATE CLUSTERED INDEX cix_SegmentTypes ON #SegmentTypes (ID);

	/**************************************************************************
	Fetch ALS offer members for nFI offers that ended in: the earliest cycle in #FirstRetailerCycles
	***************************************************************************/

	IF OBJECT_ID('tempdb..#AnchorCycleMembersNFI') IS NOT NULL DROP TABLE #AnchorCycleMembersNFI;

	SELECT DISTINCT
		io.ClubID AS PublisherID
		, io.PartnerID
		, iom.FanID
		, st.SuperSegmentName
	INTO #AnchorCycleMembersNFI
	FROM #FirstRetailerCycles cyc
	INNER JOIN nFI.Relational.IronOffer io -- Get offers
		ON cyc.PartnerID = io.PartnerID
	INNER JOIN nFI.Relational.IronOfferMember iom WITH(NOLOCK) -- Get offer members
		ON io.ID = iom.IronOfferID
		AND (CAST(io.EndDate AS DATE) >= CAST(iom.StartDate AS DATE) OR io.EndDate IS NULL) -- Offer ends on or after customer is active
		AND (CAST(io.StartDate AS DATE) <= CAST(iom.EndDate AS DATE) OR iom.EndDate IS NULL) -- Offer starts on or before after customer is active
	INNER JOIN nFI.Segmentation.ROC_Shopper_Segment_Members sm -- Get Segments at end of cycle
		ON iom.FanID = sm.FanID
		AND io.PartnerID = sm.PartnerID
		AND cyc.MinCycleEndDate BETWEEN sm.StartDate AND ISNULL(sm.EndDate, cyc.MinCycleEndDate) -- Customer segment allocation at end of cycle
	INNER JOIN #SegmentTypes st
		ON sm.ShopperSegmentTypeID = st.ID
	WHERE
		(CAST(io.StartDate AS DATE) <= cyc.MinCycleEndDate) -- Offers overlapping cycle
		AND (CAST(io.EndDate AS DATE) >= cyc.AnalysisStartDate OR io.EndDate IS NULL) -- Include offers ending after the analysis start date and cycle start date 
		AND cyc.PublisherType = 'nFI'
		AND (io.PartnerID = @PartnerID OR @PartnerID IS NULL);

	CREATE CLUSTERED INDEX cix_AnchorCycleMembersNFI ON #AnchorCycleMembersNFI (PartnerID);	
	CREATE NONCLUSTERED INDEX ix_AnchorCycleMembersNFI ON #AnchorCycleMembersNFI (FanID);

	/**************************************************************************
	Fetch ALS offer members for RBS offers that ended in: the earliest cycle in #FirstRetailerCycles
	***************************************************************************/
	
	--IF OBJECT_ID('tempdb..#AnchorCycleMembersWarehouse') IS NOT NULL DROP TABLE #AnchorCycleMembersWarehouse;

	--SELECT DISTINCT
	--	io.PartnerID
	--	, sm.FanID
	--	, st.SuperSegmentName
	--INTO #AnchorCycleMembersWarehouse
	--FROM #FirstRetailerCycles cyc
	--INNER JOIN Warehouse.Relational.IronOffer io -- Get offers
	--	ON cyc.PartnerID = io.PartnerID
	--INNER JOIN Warehouse.Relational.IronOfferMember iom WITH(NOLOCK) -- Get offer members
	--	ON io.IronOfferID = iom.IronOfferID
	--	AND (CAST(io.EndDate AS DATE) >= CAST(iom.StartDate AS DATE) OR io.EndDate IS NULL) -- Offer ends on or after customer is active
	--	AND (CAST(io.StartDate AS DATE) <= CAST(iom.EndDate AS DATE) OR iom.EndDate IS NULL) -- Offer starts on or before after customer is active
	--INNER JOIN Warehouse.Relational.Customer cust
	--	ON iom.CompositeID = cust.CompositeID
	--INNER JOIN Warehouse.Segmentation.Roc_Shopper_Segment_Members sm -- Get Segments at end of cycle
	--	ON cust.FanID = sm.FanID
	--	AND io.PartnerID = sm.PartnerID
	--	AND cyc.MinCycleEndDate BETWEEN sm.StartDate AND ISNULL(sm.EndDate, cyc.MinCycleEndDate) -- Customer segment allocation at end of cycle
	--INNER JOIN #SegmentTypes st
	--	ON sm.ShopperSegmentTypeID = st.ID
	--WHERE
	--	(CAST(io.StartDate AS DATE) <= cyc.MinCycleEndDate) -- Offers overlapping cycle
	--	AND (CAST(io.EndDate AS DATE) >= cyc.AnalysisStartDate OR io.EndDate IS NULL) -- Include offers ending after the analysis start date and cycle start date
	--	AND cyc.PublisherType = 'Warehouse' 
	--	AND (io.PartnerID = @PartnerID OR @PartnerID IS NULL);

	--CREATE CLUSTERED INDEX cix_AnchorCycleMembersWarehouse ON #AnchorCycleMembersWarehouse (PartnerID);	
	--CREATE NONCLUSTERED INDEX ix_AnchorCycleMembersWarehouse ON #AnchorCycleMembersWarehouse (FanID);

	/**************************************************************************
	Fetch distinct member counts per cycle per retailer per ALS segment for members in #AnchorCycleMembersNFI and #AnchorCycleMembersWarehouse
	***************************************************************************/	
	
	IF OBJECT_ID('tempdb..#ALSReportDataHolding') IS NOT NULL DROP TABLE #ALSReportDataHolding;

	SELECT * 
	INTO #ALSReportDataHolding
	FROM
		(SELECT 
			'nFI' AS PublisherType
			, anc.PublisherID
			, sm.PartnerID
			, cyc.AnalysisStartDate
			, cyc.CycleStartDate
			, cyc.CycleEndDate
			, anc.SuperSegmentName AS AnchorSegmentType -- ShopperSegmentType from Slowly Changing Dimension
			, st.SuperSegmentName AS CycleSegmentType
			, COUNT(DISTINCT(sm.FanID)) AS CycleMembers
		FROM #AnchorCycleMembersNFI anc
		LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Members sm WITH(NOLOCK)
			ON anc.PartnerID = sm.PartnerID
			AND anc.FanID = sm.FanID
		INNER JOIN #RetailerCycles cyc
			ON anc.PartnerID = cyc.PartnerID
			AND cyc.CycleEndDate BETWEEN sm.StartDate AND ISNULL(sm.EndDate, cyc.CycleEndDate) -- Customer segment allocation at end of cycle
			AND cyc.PublisherType = 'nFI'
		INNER JOIN #SegmentTypes st
			ON sm.ShopperSegmentTypeID = st.ID
		GROUP BY 
			anc.PublisherID
			, sm.PartnerID
			, cyc.CycleStartDate
			, cyc.CycleEndDate
			, cyc.AnalysisStartDate
			, anc.SuperSegmentName
			, st.SuperSegmentName
		
		--UNION ALL

		--SELECT 
		--	'Warehouse' AS PublisherType
		--	, 132 AS PublisherID
		--	, sm.PartnerID
		--	, cyc.AnalysisStartDate
		--	, cyc.CycleStartDate
		--	, cyc.CycleEndDate
		--	, anc.SuperSegmentName AS AnchorSegmentType -- ShopperSegmentType from Slowly Changing Dimension
		--	, st.SuperSegmentName AS CycleSegmentType
		--	, COUNT(DISTINCT(sm.FanID)) AS CycleMembers
		--FROM #AnchorCycleMembersWarehouse anc
		--LEFT JOIN Warehouse.Segmentation.Roc_Shopper_Segment_Members sm WITH(NOLOCK)
		--	ON anc.PartnerID = sm.PartnerID
		--	AND anc.FanID = sm.FanID
		--RIGHT JOIN #RetailerCycles cyc
		--	ON anc.PartnerID = cyc.PartnerID
		--	AND cyc.CycleEndDate BETWEEN sm.StartDate AND ISNULL(sm.EndDate, cyc.CycleEndDate) -- Customer segment allocation at end of cycle
		--	AND cyc.PublisherType = 'Warehouse' 
		--INNER JOIN #SegmentTypes st
		--	ON sm.ShopperSegmentTypeID = st.ID
		--GROUP BY 
		--	sm.PartnerID
		--	, cyc.CycleStartDate
		--	, cyc.CycleEndDate
		--	, cyc.AnalysisStartDate
		--	, anc.SuperSegmentName
		--	, st.SuperSegmentName
		) x; 

	SELECT
		1 AS IsPublisherTypeRecentActivity
		, PublisherType
		, PublisherID
		, PartnerID
		, AnalysisStartDate
		, CycleStartDate
		, CycleEndDate
		, AnchorSegmentType
		, CycleSegmentType
		, CycleMembers
	FROM #ALSReportDataHolding rh;
		
END