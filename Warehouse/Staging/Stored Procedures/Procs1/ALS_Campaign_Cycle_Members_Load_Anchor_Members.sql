/******************************************************************************
Author	  Jason Shipp
Created	  31/01/2018
Purpose	  
	1. For each retailer, find the earliest Campaign cycle starting after the retailer's most recent offer/ALS-membership active period
	2. Fetch all unique ALS Warehouse and nFI offer members in the above cycle for each retailer, for all offers overlapping the above cycle
	3. Refresh the Staging.ALS_Anchor_Cycle_Member_nFI and Staging.ALS_Anchor_Cycle_Member_Warehouse tables with the above members  
	NOTE: Change cyc.AnalysisStartDate to cyc.CycleStartDate in WHERE clause of fetch clauses for earliest NFI/Warehouse cycle members, if using a bespoke start cycle 

Modification History

12/02/2018 Jason Shipp
	- Removed analysis start date dependency on publisher type
******************************************************************************/

CREATE PROCEDURE [Staging].[ALS_Campaign_Cycle_Members_Load_Anchor_Members] 
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
	Create temp table containing the first analysis periods per retailer
	***************************************************************************/

	IF OBJECT_ID('tempdb..#FirstRetailerCycles') IS NOT NULL DROP TABLE #FirstRetailerCycles;

	WITH FirstRetailerCycles AS
		(SELECT
			PartnerID
			, MIN(AnalysisStartDate) AS AnalysisStartDate
			, (CAST(DATEDIFF(DAY, @OriginCycleStartDate, MIN(AnalysisStartDate)) AS INT))/28 AS CompleteCyclesElapsed -- Complete cycles elapsed since @OriginCycleStartDate
		FROM Warehouse.Staging.ALS_Retailer_Cycle
		GROUP BY 
			PartnerID
		)

	SELECT
		PartnerID
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
	Refresh Staging.ALS_Anchor_Cycle_Member_nFI table with unique nFI cycle members for offers that ended in: the earliest cycle in #FirstRetailerCycles
	
	Create table for storing results:

	CREATE TABLE Staging.ALS_Anchor_Cycle_Member_nFI
		(ID INT IDENTITY (1,1) NOT NULL
		, PublisherID INT
		, PartnerID INT
		, FanID INT
		, SuperSegmentName VARCHAR(50)
		, CONSTRAINT PK_ALS_Anchor_Cycle_Member_nFI PRIMARY KEY CLUSTERED (ID)  
		)
	***************************************************************************/

	TRUNCATE TABLE Staging.ALS_Anchor_Cycle_Member_nFI;

	IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'IX_ALS_AnchorCycleMemberNFI') 
		DROP INDEX IX_ALS_AnchorCycleMemberNFI ON Staging.ALS_Anchor_Cycle_Member_nFI;

	INSERT INTO Staging.ALS_Anchor_Cycle_Member_nFI
		(PublisherID
		, PartnerID
		, FanID
		, SuperSegmentName
		)
	SELECT DISTINCT
		x.PublisherID
		, x.PartnerID
		, x.FanID
		, x.SuperSegmentName
	FROM
		(SELECT
			io.ClubID AS PublisherID
			, io.PartnerID
			, iom.IronOfferID
			, iom.FanID
			, st.SuperSegmentName
			, sm.StartDate AS SegmentStartDate
			, MIN(sm.StartDate) OVER (PARTITION BY io.ClubID, io.PartnerID, iom.FanID) AS MinFanSegmentStartDate
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
			AND (io.PartnerID = @PartnerID OR @PartnerID IS NULL)
		) x
	WHERE x.SegmentStartDate = x.MinFanSegmentStartDate;
	
	/**************************************************************************
	Refresh Staging.ALS_Anchor_Cycle_Member_Warehouse table with unique RBS cycle members for offers that ended in: the earliest cycle in #FirstRetailerCycles
	
	Create table for storing results:

	CREATE TABLE Staging.ALS_Anchor_Cycle_Member_Warehouse
		(ID INT IDENTITY (1,1) NOT NULL
		, PublisherID INT
		, PartnerID INT
		, FanID INT
		, SuperSegmentName VARCHAR(50)
		, CONSTRAINT PK_ALS_Anchor_Cycle_Member_Warehouse PRIMARY KEY CLUSTERED (ID)  
		)
	***************************************************************************/

	TRUNCATE TABLE Staging.ALS_Anchor_Cycle_Member_Warehouse;

	IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'IX_ALS_AnchorCycleMemberWarehouse') 
		DROP INDEX IX_ALS_AnchorCycleMemberWarehouse ON Staging.ALS_Anchor_Cycle_Member_Warehouse;

	INSERT INTO Staging.ALS_Anchor_Cycle_Member_Warehouse
		(PublisherID
		, PartnerID
		, FanID
		, SuperSegmentName
		)
	SELECT DISTINCT
		132 AS PublisherID
		, x.PartnerID
		, x.FanID
		, x.SuperSegmentName
	FROM
		(SELECT
			io.PartnerID
			, sm.FanID
			, st.SuperSegmentName
			, sm.StartDate AS SegmentStartDate
			, MIN(sm.StartDate) OVER (PARTITION BY io.PartnerID, sm.FanID) AS MinFanSegmentStartDate
		FROM #FirstRetailerCycles cyc
		INNER JOIN Warehouse.Relational.IronOffer io -- Get offers
			ON cyc.PartnerID = io.PartnerID
		INNER JOIN Warehouse.Relational.IronOfferMember iom WITH(NOLOCK) -- Get offer members
			ON io.IronOfferID = iom.IronOfferID
			AND (CAST(io.EndDate AS DATE) >= CAST(iom.StartDate AS DATE) OR io.EndDate IS NULL) -- Offer ends on or after customer is active
			AND (CAST(io.StartDate AS DATE) <= CAST(iom.EndDate AS DATE) OR iom.EndDate IS NULL) -- Offer starts on or before after customer is active
		INNER JOIN Warehouse.Relational.Customer cust
			ON iom.CompositeID = cust.CompositeID
		INNER JOIN Warehouse.Segmentation.Roc_Shopper_Segment_Members sm -- Get Segments at end of cycle
			ON cust.FanID = sm.FanID
			AND io.PartnerID = sm.PartnerID
			AND cyc.MinCycleEndDate BETWEEN sm.StartDate AND ISNULL(sm.EndDate, cyc.MinCycleEndDate) -- Customer segment allocation at end of cycle
		INNER JOIN #SegmentTypes st
			ON sm.ShopperSegmentTypeID = st.ID
		WHERE
			(CAST(io.StartDate AS DATE) <= cyc.MinCycleEndDate) -- Offers overlapping cycle
			AND (CAST(io.EndDate AS DATE) >= cyc.AnalysisStartDate OR io.EndDate IS NULL) -- Include offers ending after the analysis start date and cycle start date
			AND (io.PartnerID = @PartnerID OR @PartnerID IS NULL)
		) x
	WHERE x.SegmentStartDate = x.MinFanSegmentStartDate;

END