/******************************************************************************
Author	  Jason Shipp
Created	  13/02/2018
Purpose	  
	1. For each retailer, find the earliest Campaign cycle starting after the retailer's most recent offer/ALS-membership active period
	2. Identify Iron Offer control groups to get members for, using the following Hierarchical logic:
		First: Iron Offer cycles overlapping min analysis period
		Fallback 1: Iron Offers close to min analysis period (min 20% by days diff)
		Fallback 2: Iron Offers for incomplete retailers for which missing ALS segments need to be extrapolated 
	2. Fetch and combine all unique Warehouse and nFI Iron Offer control members for each retailer, for the Iron Offers identified above
	3. Refresh the Staging.ALS_Anchor_Cycle_Control_Member table with the above control members

Modification History

******************************************************************************/

CREATE PROCEDURE Staging.ALS_Campaign_Cycle_Members_Load_Control_Members

AS
BEGIN

	SET NOCOUNT ON;

	/**************************************************************************
	Declare Vaiables
	***************************************************************************/

	DECLARE @OriginCycleStartDate DATE = '2010-01-14'; -- Random Campaign Report cycle start date
	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @SupSegments INT = (SELECT COUNT(DISTINCT(SuperSegmentTypeID)) FROM nFI.Segmentation.ROC_Shopper_Segment_Types) -- For checking ALS coverage per retailer

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
	Create table of nFI control groups to get control members for
	***************************************************************************/

	-- Get all nFI partner Iron Offers related to a control group

	IF OBJECT_ID('tempdb..#nFI_IOs_All') IS NOT NULL DROP TABLE #nFI_IOs_All;

	SELECT
		cyc.PartnerID
		, cyc.AnalysisStartDate
		, cyc.MinCycleStartDate
		, cyc.MinCycleEndDate
		, io.ID AS IronOfferID
		, z.ID AS FakeSuperSegmentTypeID
		, st.SuperSegmentTypeID AS SuperSegmentTypeID
		, CAST(io.StartDate AS DATE) AS OfferStartDate
		, CAST(io.EndDate AS DATE) AS OfferEndDate
		, CAST(oc.StartDate AS DATE) AS OfferCycleStartDate
		, CAST(oc.EndDate AS DATE) AS OfferCycleEndDate
		, ioc.controlgroupid
	INTO #nFI_IOs_All
	FROM #FirstRetailerCycles cyc -- Get min analysis dates and partner IDs
	CROSS JOIN (SELECT DISTINCT ID FROM nFI.Segmentation.ROC_Shopper_Segment_Super_Types) z -- Get all possible segemnt types
	LEFT JOIN nFI.Relational.IronOffer io -- Get all Iron Offers associated with retailers
		ON cyc.PartnerID = io.PartnerID
	LEFT JOIN nFI.Relational.IronOffer_References ior -- Get all cycles associated with Iron Offers
		ON io.ID = ior.IronOfferID
	LEFT JOIN nFI.Relational.ironoffercycles ioc -- Get control groups associated with Iron Offers and Iron Offer cycles
		ON ior.ironoffercyclesid = ioc.ironoffercyclesid
	LEFT JOIN nFI.Relational.OfferCycles oc -- Get Iron Offer cycle dates
		ON ioc.offercyclesid = oc.OfferCyclesID
	LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types st -- Get segment types associated with Iron Offers and Iron Offer cycles
		ON ior.ShopperSegmentTypeID = st.ID
		AND z.ID = st.SuperSegmentTypeID -- Important! For identifying actual Iron Offer segment types
	WHERE 
		ioc.controlgroupid IS NOT NULL; -- Only keep Iron Offer - Iron Offer cycles assoctaed with control groups

	-- Identify retailers with incomplete ALS coverage

	IF OBJECT_ID('tempdb..#nFI_Retailer_ALS_Coverage') IS NOT NULL DROP TABLE #nFI_Retailer_ALS_Coverage;

	SELECT 
	PartnerID
	, CASE 
		WHEN COUNT(DISTINCT(SuperSegmentTypeID)) = @SupSegments
		THEN 1
		ELSE 0 
	END AS RetailerComplete
	INTO #nFI_Retailer_ALS_Coverage
	FROM #nFI_IOs_All
	GROUP BY PartnerID;

	-- CTE: Add derived columns to help identify which control groups to get members for

	IF OBJECT_ID('tempdb..#nFI_IOs_Control') IS NOT NULL DROP TABLE #nFI_IOs_Control;

	WITH nFI_IOs_All_Extended AS
		(SELECT 
			io.PartnerID
			, io.AnalysisStartDate
			, io.MinCycleStartDate
			, io.MinCycleEndDate
			, io.IronOfferID
			, io.SuperSegmentTypeID
			, io.OfferStartDate
			, io.OfferEndDate
			, io.OfferCycleStartDate
			, io.OfferCycleEndDate
			, io.controlgroupid
			, CASE WHEN 
				rc.RetailerComplete = 1 AND cyc.PartnerID IS NOT NULL THEN 1 ELSE 0
			END AS IO_Overlaps_Analsysis_Start -- Which Iron Offers to analyse? Iron Offer cycles overlapping min analysis period
			, CASE WHEN rc.RetailerComplete = 1 THEN
				NTILE(5) OVER(
					PARTITION BY io.PartnerID, io.SuperSegmentTypeID
					ORDER BY ABS(DATEDIFF(DAY, io.OfferStartDate, io.AnalysisStartDate)) 
				) 
			ELSE NULL END AS RetailerSegQuartileByDaysAfterOfferStart -- Which Iron Offers to analyse? Fallback: Iron Offers close to min analysis period (min 20% by days diff)
			, CASE WHEN 
				rc.RetailerComplete = 0 
				AND MIN(io.SuperSegmentTypeID) OVER (PARTITION BY io.PartnerID, io.IronOfferID) IS NOT NULL -- Iron Offers with at least one segment related to a control group
				THEN io.FakeSuperSegmentTypeID
				ELSE NULL END
			AS BackupSuperSegmentTypeID -- Which Iron Offers to analyse? Fallback 2: Iron Offers for incomplete retailers for which missing ALS segments need to be extrapolated 
		FROM
		#nFI_IOs_All io
		LEFT JOIN #FirstRetailerCycles cyc
			ON io.PartnerID = cyc.PartnerID
			AND (io.OfferCycleStartDate <= cyc.MinCycleEndDate) -- Iron offer cycle overlapping min report cycle
			AND (io.OfferCycleEndDate >= cyc.AnalysisStartDate OR io.OfferCycleEndDate IS NULL) -- Include Iron Offer cycles ending after: the analysis start date and min report cycle start date
		LEFT JOIN #nFI_Retailer_ALS_Coverage rc
			ON io.PartnerID = rc.PartnerID
		WHERE( -- Filter out Iron Offer - segment type combinations not to include in analysis
				(CASE WHEN
					rc.RetailerComplete = 0 
					THEN io.FakeSuperSegmentTypeID
					ELSE NULL END
				) IS NOT NULL 
			OR io.SuperSegmentTypeID IS NOT NULL
			)
		)
	-- Store nFI partner control groups to get control members for
	SELECT DISTINCT
		io2.PartnerID
		, io2.AnalysisStartDate
		, io2.MinCycleStartDate
		, io2.MinCycleEndDate
		, COALESCE(BackupSuperSegmentTypeID, io2.SuperSegmentTypeID) AS SuperSegmentTypeID
		, io2.controlgroupid
	INTO #nFI_IOs_Control
	FROM nFI_IOs_All_Extended io2
	WHERE(
			io2.BackupSuperSegmentTypeID IS NOT NULL 
			OR io2.IO_Overlaps_Analsysis_Start = 1
			OR RetailerSegQuartileByDaysAfterOfferStart = 1
		);

	CREATE CLUSTERED INDEX CIX_nFI_IOs_Control ON #nFI_IOs_Control (controlgroupid);

	/**************************************************************************
	Create table of Warehouse control groups to get control members for
	***************************************************************************/

	-- Get all Warehouse partner Iron Offers related to a control group

	IF OBJECT_ID('tempdb..#Warehouse_IOs_All') IS NOT NULL DROP TABLE #Warehouse_IOs_All;

	SELECT
		cyc.PartnerID
		, cyc.AnalysisStartDate
		, cyc.MinCycleStartDate
		, cyc.MinCycleEndDate
		, io.IronOfferID
		, z.ID AS FakeSuperSegmentTypeID
		, st.SuperSegmentTypeID AS SuperSegmentTypeID
		, CAST(io.StartDate AS DATE) AS OfferStartDate
		, CAST(io.EndDate AS DATE) AS OfferEndDate
		, CAST(oc.StartDate AS DATE) AS OfferCycleStartDate
		, CAST(oc.EndDate AS DATE) AS OfferCycleEndDate
		, ioc.controlgroupid
	INTO #Warehouse_IOs_All
	FROM #FirstRetailerCycles cyc -- Get min analysis dates and partner IDs
	CROSS JOIN (SELECT DISTINCT ID FROM nFI.Segmentation.ROC_Shopper_Segment_Super_Types) z -- Get all possible segemnt types
	LEFT JOIN Warehouse.Relational.IronOffer io -- Get all Iron Offers associated with retailers
		ON cyc.PartnerID = io.PartnerID
	LEFT JOIN Warehouse.Relational.IronOffer_References ior -- Get all cycles associated with Iron Offers
		ON io.IronOfferID = ior.IronOfferID
	LEFT JOIN Warehouse.Relational.ironoffercycles ioc -- Get control groups associated with Iron Offers and Iron Offer cycles
		ON ior.ironoffercyclesid = ioc.ironoffercyclesid
	LEFT JOIN Warehouse.Relational.OfferCycles oc -- Get Iron Offer cycle dates
		ON ioc.offercyclesid = oc.OfferCyclesID
	LEFT JOIN nFI.Segmentation.ROC_Shopper_Segment_Types st -- Get segment types associated with Iron Offers and Iron Offer cycles
		ON ior.ShopperSegmentTypeID = st.ID
		AND z.ID = st.SuperSegmentTypeID -- Important! For identifying actual Iron Offer segment types
	WHERE 
		ioc.controlgroupid IS NOT NULL; -- Only keep Iron Offer - Iron Offer cycles assoctaed with control groups

	-- Identify retailers with incomplete ALS coverage

	IF OBJECT_ID('tempdb..#Warehouse_Retailer_ALS_Coverage') IS NOT NULL DROP TABLE #Warehouse_Retailer_ALS_Coverage;

	SELECT 
	PartnerID
	, CASE 
		WHEN COUNT(DISTINCT(SuperSegmentTypeID)) = @SupSegments
		THEN 1
		ELSE 0 
	END AS RetailerComplete
	INTO #Warehouse_Retailer_ALS_Coverage
	FROM #Warehouse_IOs_All
	GROUP BY PartnerID;

	-- CTE: Add derived columns to help identify which control groups to get members for

	IF OBJECT_ID('tempdb..#Warehouse_IOs_Control') IS NOT NULL DROP TABLE #Warehouse_IOs_Control;

	WITH Warehouse_IOs_All_Extended AS
		(SELECT 
			io.PartnerID
			, io.AnalysisStartDate
			, io.MinCycleStartDate
			, io.MinCycleEndDate
			, io.IronOfferID
			, io.SuperSegmentTypeID
			, io.OfferStartDate
			, io.OfferEndDate
			, io.OfferCycleStartDate
			, io.OfferCycleEndDate
			, io.controlgroupid
			, CASE WHEN 
				rc.RetailerComplete = 1 AND cyc.PartnerID IS NOT NULL THEN 1 ELSE 0
			END AS IO_Overlaps_Analsysis_Start -- Which Iron Offers to analyse? Iron Offer cycles overlapping min analysis period
			, CASE WHEN rc.RetailerComplete = 1 THEN
				NTILE(5) OVER(
					PARTITION BY io.PartnerID, io.SuperSegmentTypeID
					ORDER BY ABS(DATEDIFF(DAY, io.OfferStartDate, io.AnalysisStartDate)) 
				) 
			ELSE NULL END AS RetailerSegQuartileByDaysAfterOfferStart -- Which Iron Offers to analyse? Fallback: Iron Offers close to min analysis period (min 20% by days diff)
			, CASE WHEN 
				rc.RetailerComplete = 0
				AND MIN(io.SuperSegmentTypeID) OVER (PARTITION BY io.PartnerID, io.IronOfferID) IS NOT NULL -- Iron Offers with at least one segment related to a control group
				THEN io.FakeSuperSegmentTypeID
				ELSE NULL END
			AS BackupSuperSegmentTypeID -- Which Iron Offers to analyse? Fallback 2: Iron Offers for incomplete retailers for which missing ALS segments need to be extrapolated 
		FROM
		#Warehouse_IOs_All io
		LEFT JOIN #FirstRetailerCycles cyc
			ON io.PartnerID = cyc.PartnerID
			AND (io.OfferCycleStartDate <= cyc.MinCycleEndDate) -- Iron offer cycle overlapping min report cycle
			AND (io.OfferCycleEndDate >= cyc.AnalysisStartDate OR io.OfferCycleEndDate IS NULL) -- Include Iron Offer cycles ending after: the analysis start date and min report cycle start date
		LEFT JOIN #Warehouse_Retailer_ALS_Coverage rc
			ON io.PartnerID = rc.PartnerID
		WHERE( -- Filter out Iron Offer - segment type combinations not to include in analysis
				(CASE WHEN
					rc.RetailerComplete = 0 
					THEN io.FakeSuperSegmentTypeID
					ELSE NULL END
				) IS NOT NULL 
			OR io.SuperSegmentTypeID IS NOT NULL
			)
		)
	-- Store Warehouse partner control groups to get control members for
	SELECT DISTINCT
		io2.PartnerID
		, io2.AnalysisStartDate
		, io2.MinCycleStartDate
		, io2.MinCycleEndDate
		, COALESCE(BackupSuperSegmentTypeID, io2.SuperSegmentTypeID) AS SuperSegmentTypeID
		, io2.controlgroupid
	INTO #Warehouse_IOs_Control
	FROM Warehouse_IOs_All_Extended io2
	WHERE(
			io2.BackupSuperSegmentTypeID IS NOT NULL 
			OR io2.IO_Overlaps_Analsysis_Start = 1
			OR RetailerSegQuartileByDaysAfterOfferStart = 1
		);

	CREATE CLUSTERED INDEX CIX_Warehouse_IOs_Control ON #Warehouse_IOs_Control (controlgroupid);

	/**************************************************************************
	Refresh Staging.ALS_Anchor_Cycle_Control_Member table with retailer segment control members to get transaction data for
	
	Create table for storing results:

	CREATE TABLE Staging.ALS_Anchor_Cycle_Control_Member
		(ID INT IDENTITY (1,1) NOT NULL
		, PartnerID INT
		, SuperSegmentTypeID INT
		, FanID INT
		, CONSTRAINT PK_ALS_Anchor_Cycle_Control_Member PRIMARY KEY CLUSTERED (ID)  
		)
	***************************************************************************/

	IF  EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'IX_ALS_Anchor_Cycle_Control_Member') 
		DROP INDEX IX_ALS_Anchor_Cycle_Control_Member ON Staging.ALS_Anchor_Cycle_Control_Member;

	TRUNCATE TABLE Staging.ALS_Anchor_Cycle_Control_Member;
	
	WITH ALS_Anchor_Cycle_Control_Member_nFI AS
		(SELECT DISTINCT
			ioc.PartnerID
			, ioc.SuperSegmentTypeID
			, con.fanid
		FROM #nFI_IOs_Control ioc
		INNER JOIN nFI.Relational.controlgroupmembers con -- Get control group members
			ON ioc.controlgroupid = con.controlgroupid
		)
	, ALS_Anchor_Cycle_Control_Member_Warehouse AS
		(SELECT DISTINCT
			ioc.PartnerID
			, ioc.SuperSegmentTypeID
			, con.fanid
		FROM #Warehouse_IOs_Control ioc
		INNER JOIN Warehouse.Relational.controlgroupmembers con -- Get control group members
			ON ioc.controlgroupid = con.controlgroupid
		)
	INSERT INTO Staging.ALS_Anchor_Cycle_Control_Member
		(PartnerID
		, SuperSegmentTypeID
		, FanID
		)
	SELECT DISTINCT	-- Store distinct control members
	 x.PartnerID
	, x.SuperSegmentTypeID
	, x.fanid
	FROM
		(SELECT 
			nfi.PartnerID
			, nfi.SuperSegmentTypeID
			, nfi.fanid
		FROM ALS_Anchor_Cycle_Control_Member_nFI nfi
		UNION ALL
		SELECT 
			w.PartnerID
			, w.SuperSegmentTypeID
			, w.fanid
		FROM ALS_Anchor_Cycle_Control_Member_Warehouse w
		) x;

	IF  NOT EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'IX_ALS_Anchor_Cycle_Control_Member')
		CREATE NONCLUSTERED INDEX IX_ALS_Anchor_Cycle_Control_Member ON Staging.ALS_Anchor_Cycle_Control_Member (PartnerID, FanID)
		INCLUDE (SuperSegmentTypeID);
	
END