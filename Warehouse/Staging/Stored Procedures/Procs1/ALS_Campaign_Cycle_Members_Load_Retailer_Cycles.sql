/******************************************************************************
Author	  Jason Shipp
Created	  31/01/2018
Purpose	  
	For each retailer, load the Campaign cycles on or after the most recent offer/ALS-membership active period
	Use results to refresh the Warehouse.Staging.ALS_Retailer_Cycle table

Modification History
	12/02/2018 Jason Shipp
		- Added logic to account for multiple breaks in a retailer's activity
		- Changed logic so if a retailer has had different activity start dates on Warehouse/nFI, the latter of the two is used
******************************************************************************/

CREATE PROCEDURE [Staging].[ALS_Campaign_Cycle_Members_Load_Retailer_Cycles]

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
	Create temp table of calendar dates from the @OriginCycleStartDate to date
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates;

	CREATE TABLE #Dates
		(CalDate DATE
		);

	WITH cte AS
		(SELECT @OriginCycleStartDate AS StartDate -- anchor member
		UNION ALL
		SELECT CAST((DATEADD(DAY, 1, StartDate)) AS DATE) --  Calendar date: recursive member
		FROM   cte
		WHERE CAST((DATEADD(DAY, 2, StartDate)) AS DATE) <= @Today -- terminator: yesterday
		)
	INSERT INTO #Dates 
		(CalDate
		)
	SELECT
		cte.StartDate
	FROM cte
	OPTION (MAXRECURSION 10000);

	/**************************************************************************
	Fetch minimum offer start date per retailer, for each retailer's most recent block of activity
	***************************************************************************/

	-- Fetch dates per retailer on which at least one offer was active, for nFI

	IF OBJECT_ID('tempdb..#ActDatesWithLag_nFI') IS NOT NULL DROP TABLE #ActDatesWithLag_nFI;

	WITH ActDates1 AS
		(SELECT DISTINCT
			p.PartnerID
			, d.CalDate
		FROM #Dates d
		CROSS JOIN (SELECT DISTINCT PartnerID FROM nFI.Relational.IronOffer) p
		INNER JOIN nFI.Relational.IronOffer o
			ON d.CalDate BETWEEN CAST(o.StartDate AS DATE) AND CAST(ISNULL(o.EndDate, d.CalDate) AS DATE)
			AND p.PartnerID = o.PartnerID
		)
	SELECT 
		ad.PartnerID
		, ad.CalDate AS OfferActDate
		, DATEDIFF(DAY 
			, LAG(ad.CalDate, 1, NULL) OVER (PARTITION BY ad.PartnerID ORDER BY ad.CalDate)
			, ad.CalDate
		) AS LagFromPrevOfferActDate
	INTO #ActDatesWithLag_nFI
	FROM ActDates1 ad;

	-- Fetch dates per retailer on which at least one offer was active, for Warehouse

	IF OBJECT_ID('tempdb..#ActDatesWithLag_Warehouse') IS NOT NULL DROP TABLE #ActDatesWithLag_Warehouse;

	WITH ActDates2 AS
		(SELECT DISTINCT
			p.PartnerID
			, d.CalDate
		FROM #Dates d
		CROSS JOIN (SELECT DISTINCT PartnerID FROM Warehouse.Relational.IronOffer) p
		INNER JOIN Warehouse.Relational.IronOffer o
			ON d.CalDate BETWEEN CAST(o.StartDate AS DATE) AND CAST(ISNULL(o.EndDate, d.CalDate) AS DATE)
			AND p.PartnerID = o.PartnerID
		)
	SELECT 
		ad.PartnerID
		, ad.CalDate AS OfferActDate
		, DATEDIFF(DAY 
			, LAG(ad.CalDate, 1, NULL) OVER (PARTITION BY ad.PartnerID ORDER BY ad.CalDate)
			, ad.CalDate
		) AS LagFromPrevOfferActDate
	INTO #ActDatesWithLag_Warehouse
	FROM ActDates2 ad;

	-- Fetch minimum offer start date per retailer, for each retailers' most recent block of activity

	IF OBJECT_ID('tempdb..#MinOfferStart') IS NOT NULL DROP TABLE #MinOfferStart;

	WITH MinDateAfterLag AS
		(	SELECT -- Latest offer start date after activity gap, per nFI retailer
			'nFI' AS PublisherType
			, PartnerID
			, MAX(OfferActDate) AS RecentActivityStartDate1
			FROM #ActDatesWithLag_nFI
			WHERE LagFromPrevOfferActDate > 28
			GROUP BY PartnerID
		UNION ALL
			SELECT -- Latest offer start date after activity gap, per Warehouse retailer
			'Warehouse' AS PublisherType
			, PartnerID
			, MAX(OfferActDate) AS RecentActivityStartDate1
			FROM #ActDatesWithLag_Warehouse
			WHERE LagFromPrevOfferActDate > 28
			GROUP BY PartnerID
		)
	, MinDateExcludeLag AS
		(	SELECT -- Minimum offer start date per nFI retailer, assuming no break in retailer activity
			'nFI' AS PublisherType
			, PartnerID
			, MIN(OfferActDate) AS RecentActivityStartDate2
			FROM #ActDatesWithLag_nFI
			WHERE
			(LagFromPrevOfferActDate IS NULL
			OR LagFromPrevOfferActDate <= 28)
			GROUP BY PartnerID
		UNION ALL
			SELECT -- Minimum offer start date per Warehouse retailer, assuming no break in retailer activity
			'Warehouse' AS PublisherType
			, PartnerID
			, MIN(OfferActDate) AS RecentActivityStartDate2
			FROM #ActDatesWithLag_Warehouse
			WHERE
			(LagFromPrevOfferActDate IS NULL
			OR LagFromPrevOfferActDate <= 28)
			GROUP BY PartnerID		
		)
	, MinDateCombinedPubType AS -- Coalesce results per retailer and publisher type
		(SELECT 
		el.PublisherType
		, el.PartnerID
		, COALESCE(RecentActivityStartDate1, RecentActivityStartDate2) AS RecentActivityStartDate
		FROM MinDateExcludeLag el
		LEFT JOIN MinDateAfterLag al
			ON el.PartnerID = al.PartnerID
			AND el.PublisherType = al.PublisherType
		)
	SELECT -- Store most recent offer start date per retailers' publisher types
	PartnerID
	, MAX(RecentActivityStartDate) AS RecentActivityStartDate
	INTO #MinOfferStart
	FROM MinDateCombinedPubType
	GROUP BY PartnerID;

	/**************************************************************************
	Fetch minimum ALS membership start date per retailer, for each retailer's most recent block of activity
	***************************************************************************/

	IF OBJECT_ID('tempdb..#MinALSStart') IS NOT NULL DROP TABLE #MinALSStart;

	SELECT
	PartnerID		
	, MAX(ALSStartDate) AS ALSStartDate  -- Store most recent ALS start date per retailers' publisher types
	INTO #MinALSStart
	FROM
		(SELECT -- Minimum ALS start date per nFI retailer, assuming no break in ALS activity
			'nFI' AS PublisherType 
			, PartnerID
			, MIN(CAST(StartDate AS DATE)) AS ALSStartDate
		FROM nFI.Segmentation.ROC_Shopper_Segment_Members
		GROUP BY PartnerID

		UNION ALL

		SELECT -- Minimum ALS start date per Warehouse retailer, assuming no break in ALS activity
			'Warehouse' AS PublisherType
			, PartnerID
			, MIN(CAST(StartDate AS DATE)) AS ALSStartDate
		FROM Warehouse.Segmentation.Roc_Shopper_Segment_Members
		GROUP BY PartnerID
		) ALSStart
	GROUP BY PartnerID;

	/**************************************************************************
	Use the analysis periods per retailer to refresh the Warehouse.Staging.ALS_Retailer_Cycle table

	Create table for storing results:

	CREATE TABLE Warehouse.Staging.ALS_Retailer_Cycle
		(ID INT IDENTITY (1,1) NOT NULL
		, PartnerID INT
		, AnalysisStartDate DATE
		, CycleStartDate DATE
		, CycleEndDate DATE
		, CONSTRAINT PK_ALS_Retailer_Cycle PRIMARY KEY CLUSTERED (ID)  
		) 

	CREATE NONCLUSTERED INDEX IX_ALS_Retailer_Cycle ON Warehouse.Staging.ALS_Retailer_Cycle (PartnerID, CycleStartDate, CycleEndDate);
	***************************************************************************/

	-- Fetch the latter of the minimum offer start date and ALS membership start date per retailer for nFI and Warehouse

	IF OBJECT_ID('tempdb..#AnalysisStart') IS NOT NULL DROP TABLE #AnalysisStart;

	SELECT 
	os.PartnerID
	, CASE WHEN ALSStartDate > os.RecentActivityStartDate
		THEN ALSStartDate
		ELSE os.RecentActivityStartDate
	END AS AnalysisStartDate
	INTO #AnalysisStart	
	FROM #MinOfferStart os
	INNER JOIN #MinALSStart alss
		ON os.PartnerID	= alss.PartnerID;

	-- Load PartnerID - RetailerID mapping

	IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;

	SELECT
	DISTINCT * 
	INTO #PartnerAlternate
	FROM 
		(SELECT 
		PartnerID
		, AlternatePartnerID
		FROM Warehouse.APW.PartnerAlternate

		UNION ALL 

		SELECT 
		PartnerID
		, AlternatePartnerID
		FROM nFI.APW.PartnerAlternate
		) x;

	-- Refresh the Warehouse.Staging.ALS_Retailer_Cycle table with the Campaign cycles overlapping-and-after the analysis start date identified for each retailer

	TRUNCATE TABLE Warehouse.Staging.ALS_Retailer_Cycle;

	INSERT INTO Warehouse.Staging.ALS_Retailer_Cycle
		(PartnerID
		, AnalysisStartDate
		, CycleStartDate
		, CycleEndDate
		)
	SELECT 
		s.PartnerID
		, s.AnalysisStartDate
		, cyc.CycleStartDate
		, cyc.CycleEndDate
	FROM #AnalysisStart s
	INNER JOIN #Cycles cyc 
		ON cyc.CycleStartDate >= s.AnalysisStartDate -- Campaign cycles after analysis start date
	LEFT JOIN #PartnerAlternate pa
		ON s.PartnerID = pa.PartnerID
	WHERE( 
			(
				NOT EXISTS( -- Exclude cycles per retailer that are already in the results table (for analysis start dates already in the results table)
					SELECT NULL 
					FROM Staging.ALS_Trans_Results rd
					WHERE
						COALESCE(pa.AlternatePartnerID, s.PartnerID) = rd.RetailerID
						AND cyc.CycleStartDate = rd.CycleStartDate
						AND cyc.CycleEndDate = rd.CycleEndDate
				) AND EXISTS
					(SELECT NULL FROM Staging.ALS_Trans_Results rd WHERE s.AnalysisStartDate = rd.AnalysisStartDate) 
			)
		OR NOT EXISTS( -- Exclude all cycles associated with analysis start dates that are already in the results table (to include analysis for new analysis start dates)
			SELECT NULL 
			FROM Staging.ALS_Trans_Results rd
			WHERE
				s.AnalysisStartDate = rd.AnalysisStartDate
		)
	)
	AND s.PartnerID IN (4654, 4092); -- For testing

END