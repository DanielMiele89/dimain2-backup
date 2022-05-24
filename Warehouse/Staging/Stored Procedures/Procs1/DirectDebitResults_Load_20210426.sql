/******************************************************************************
Author: Jason Shipp
Created: 22/01/2019
Purpose: 
	- Load Merchant Funded Direct Debit exposed and control transaction results into Warehouse.Staging.DirectDebitResults table
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 12/02/2019
	- Updated exposed DD transaction metrics load to point to SLC_REPL.dbo.Match instead of Archive_Light.dbo.CBP_DirectDebit_TransactionHistory

Jason Shipp 12/02/2019
	- Updated analysis periods to cycles instead of weeks

Jason Shipp 01/03/2019
	- Updated logic so PartnerID OINs are fetched from Warehouse.Relational.DirectDebit_MFDD_IncentivisedOINs table

Jason Shipp 29/04/2019
	- Updated logic to identify transactions at specific OINs: Use Warehouse.Relational.DirectDebitOriginator table to link OINs to DirectDebitOriginatorIDs
	- Expanded CampaignHistory to include all customers linked to the same bank accounts

Jason Shipp 01/05/2019
	- Updated analysis period logic so transactions per week analysis period are tracked, instead of transactions of customers exposed in cycle analysis periods

Jason Shipp 10/06/2019
	- Added load of transaction data from the Archive_Light.dbo.CBP_DirectDebit_TransactionHistory table into a temp table for more efficient querying for the control groups

Jason Shipp 24/07/2019
	- Added customer group minimum required spend to load
	- Adjusted windows in which control DDs are tracked
	- Adjusted control logic so only DDs up to the second per customer are tracked
	- Changed source of business logic from hard coded figures to SLC_REPL.dbo.DirectDebitOffers and SLC_REPL.dbo.DirectDebitOfferRules tables

Jason Shipp 14/08/2019
	- Changed calendar logic to only include recent complete weeks, based on the max size of the incentivised DD tracking window. In this window, customers can change group in the final results table
	- Data for prior weeks will be taken from previous calculations
	- Direct debit files only contain cleared direct debits from the previous day, so late DD transactions should not be an issue

Jason Shipp 30/08/2019
	- Repointed Warehouse.Relational.DirectDebit_MFDD_IncentivisedOINs to SLC_REPL.dbo.DirectDebitOfferOINs, and removed dependency on OIN start and end dates
	- Repointed Warehouse.Relational.DirectDebitOriginator to SLC_REPL.dbo.DirectDebitOriginator

Jason Shipp 09/03/2020
	- Updated link between OINs and Iron Offers to use PartnerCommissionRuleID when joining to the SLC_REPL.dbo.Match table
	- For the "Overall" results, added logic to avoid doubling-up Iron Offers for cases where an OIN can be linked to multiple Iron Offers
	- Added logic to include sub-Iron Offer segment grouping to the exposed cardholder counts results and exposed transaction results- this is incorporated into the "Customer Group" 

Jason Shipp 03/04/2020
	- Adapted joins to #Rules temp table to cope with OINs being linked to multiple Iron Offers 

Rory Francis 29/06/2020
	- Adapted joins to #Rules temp table to cope with OINs being linked to multiple Iron Offers 
	
******************************************************************************/

CREATE PROCEDURE [Staging].[DirectDebitResults_Load_20210426] (@RetailerID int, @DateFirst int, @MinStartDate date, @SplitIronOfferTargeting bit)
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Declare variables
	******************************************************************************/

	---- For testing 
	--DECLARE @RetailerID int = 4729; -- Sky primary PartnerID
	--DECLARE @DateFirst int = 5; -- For setting Friday as the first day of the week
	--DECLARE @MinStartDate date = '2019-04-11'; -- Sky go live date
	--DECLARE @SplitIronOfferTargeting bit = 0; -- 1 if retailer has sub-Iron Offer segment targeting

	SET DATEFIRST @DateFirst; -- Set Friday as the first day of the week
	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @MaxEndDate date = DATEADD(day, -1, @Today);
	
	/******************************************************************************
	Load PartnerIDs
	******************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs;

	SELECT @RetailerID AS PartnerID, @RetailerID AS RetailerID -- Primary PartnerID
	INTO #PartnerIDs

	UNION

	SELECT -- Alternate PartnerIDs
	PartnerID, @RetailerID AS RetailerID
	FROM Warehouse.APW.PartnerAlternate 
	WHERE AlternatePartnerID = @RetailerID

	UNION 

	SELECT 
	PartnerID, @RetailerID AS RetailerID
	FROM nFI.APW.PartnerAlternate 
	WHERE AlternatePartnerID = @RetailerID;

	CREATE CLUSTERED INDEX CIX_PartnerIDs ON #PartnerIDs (PartnerID);

	/******************************************************************************
	Load direct debit identification numbers (OINs) 
	******************************************************************************/

	IF OBJECT_ID('tempdb..#DDSuppliers') IS NOT NULL DROP TABLE #DDSuppliers;

	--SELECT DISTINCT
	--	ds.SupplierID
	--	, ds.SupplierName
	--	, d.OIN
	--	, o.ID AS DirectDebitOriginatorID
	--INTO #DDSuppliers
	--FROM Warehouse.Relational.DD_DataDictionary d
	--INNER JOIN Warehouse.Relational.DD_DataDictionary_Suppliers ds
	--	ON d.SupplierID = ds.SupplierID
	--INNER JOIN SLC_REPL.dbo.DirectDebitOriginator o
	--	ON d.OIN = o.OIN 
	--WHERE 
	--	ds.SupplierName LIKE '%' + @RetailerNamePartial + '%';

	SELECT DISTINCT
		s.PartnerID
		, oin.OIN
		, o.ID AS DirectDebitOriginatorID
		, NULL AS StartDate
		, NULL AS EndDate
	INTO #DDSuppliers
	FROM SLC_REPL.dbo.DirectDebitOfferOINs oin -- Repoint to Warehouse.Relational.DirectDebit_MFDD_IncentivisedOINs if OINs start starting/ending whilst offers are active
	INNER JOIN SLC_REPL.dbo.DirectDebitOriginator o 
		ON oin.OIN = o.OIN
	INNER JOIN Warehouse.Relational.IronOfferSegment s
		ON oin.IronOfferID = s.IronOfferID
	WHERE
		s.PartnerID IN (SELECT PartnerID FROM #PartnerIDs);

	CREATE CLUSTERED INDEX CIX_DDSuppliers ON #DDSuppliers (DirectDebitOriginatorID, StartDate, EndDate);
	CREATE NONCLUSTERED INDEX IX_DDSuppliers ON #DDSuppliers (OIN);

	/******************************************************************************
	Load business rules
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Rules') IS NOT NULL DROP TABLE #Rules;

	SELECT  
		ddo.ID AS DirectDebitOriginatorID
		, ddo.OIN
		, CAST(oin.IronOfferID AS VARCHAR(50)) AS IronOfferID
		, pcr.ID AS PartnerCommissionRuleID
		, o2.StartDate AS OfferStartDate
		, o2.EndDate AS OfferEndDate
		, o.EarnOnDDCount
		, o.MaximumEarningsCount
		, o.MinimumFirstDDDelay
		, o.MaximumFirstDDDelay
		, o.MaximumEarningDDDelay
		, o.ActivationDays
		, DATEADD(day, o.MinimumFirstDDDelay, o2.StartDate) AS PassiveWindowEndDate
		, DATEADD(day, o.MaximumFirstDDDelay, o2.EndDate) AS OpeningDDWindowEndDate
		, DATEADD(day, o.MaximumEarningDDDelay, o2.EndDate) AS IncentivisedDDWindowEndDate
		, CASE WHEN ROW_NUMBER() OVER (PARTITION BY ddo.OIN ORDER BY oin.IronOfferID DESC) > 1 THEN 0 ELSE 1 END AS IncludeInOverall -- Add flag to avoid duplicating Overall results due to OINs that are linked to multiple Iron Offers 
	INTO #Rules
	FROM SLC_REPL.dbo.DirectDebitOfferOINs oin
	INNER JOIN SLC_REPL.dbo.DirectDebitOriginator ddo
		ON oin.OIN = ddo.OIN
	INNER JOIN SLC_REPL.dbo.DirectDebitOffers o
		ON oin.IronOfferID = o.IronOfferID
	INNER JOIN Warehouse.Relational.IronOffer o2
		ON oin.IronOfferID = o2.IronOfferID
		AND o2.PartnerID = @RetailerID
	INNER JOIN #DDSuppliers dds
		ON ddo.OIN = dds.OIN
	LEFT JOIN SLC_REPL.dbo.PartnerCommissionRule pcr
		ON oin.IronOfferID = pcr.RequiredIronOfferID
		AND pcr.TypeID = 2;

	UPDATE #Rules
	SET IncludeInOverall = 1
	WHERE @RetailerID = 4729
	AND IronOfferID = 16535
	
	CREATE CLUSTERED INDEX CIX_Rules ON #Rules (DirectDebitOriginatorID, PartnerCommissionRuleID);
	CREATE NONCLUSTERED INDEX IX_Rules ON #Rules (IronOfferID);
	CREATE NONCLUSTERED INDEX UIX_Rules ON #Rules (OIN);

	IF OBJECT_ID('tempdb..#SpendThresholds') IS NOT NULL DROP TABLE #SpendThresholds;

	SELECT 
		CAST(r.IronOfferID AS VARCHAR(50)) AS IronOfferID
		, r.MinimumSpend
		, LEAD(r.MinimumSpend, 1, NULL) OVER(PARTITION BY r.IronOfferID ORDER BY r.MinimumSpend ASC)-0.0001 AS MaximumSpend
		, r.RewardAmount AS Cashback
		, r.BillingAmount AS Investment
	INTO #SpendThresholds
	FROM SLC_REPL.dbo.DirectDebitOfferRules r
	WHERE
		r.IronOfferID IN (SELECT DISTINCT CAST(IronOfferID AS int) FROM #Rules);

	CREATE UNIQUE CLUSTERED INDEX UCIX_SpendThresholds ON #SpendThresholds (IronOfferID, MinimumSpend);
	CREATE NONCLUSTERED INDEX IX_SpendThresholds ON #SpendThresholds (IronOfferID);

	/******************************************************************************
	Load calendar table containing start and end dates within the analysis period
	******************************************************************************/

	DECLARE @PastWeeksToCalculate int = (SELECT CEILING(MAX(MaximumEarningDDDelay)/CAST(7 AS float)) FROM #Rules); -- Weeks over which to analyse. Weeks before this should not change, so can be taken from previous calculations

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;
	
	-- For weekly analysis periods

	WITH 
		E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n))
		, E2 AS (SELECT n = 0 FROM E1 a CROSS JOIN E1 b)
		, Tally AS (SELECT n = 0 UNION ALL SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E2 a CROSS JOIN E2 b) -- Create table of numbers
		, TallyDates AS (SELECT n, CalDate = DATEADD(day, n, @MinStartDate) FROM Tally WHERE DATEADD(day, n, @MinStartDate) <= @MaxEndDate) -- Create table of consecutive dates
	
	SELECT 
		StartDate
		, EndDate
		, PeriodType
	INTO #Calendar
	FROM (
		SELECT DISTINCT
			CASE 
				WHEN DATEADD(dd, -(DATEPART(dw, CalDate)-1), CalDate) < @MinStartDate
				THEN @MinStartDate -- Don't let StartDate go before analysis start date
				ELSE DATEADD(dd, -(DATEPART(dw, CalDate)-1), CalDate) 
			END	AS StartDate -- For each calendar date in #Dates, minus days since the most recent Monday  
			, CASE
				WHEN DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate) > @MaxEndDate
				THEN @MaxEndDate
				ELSE DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate)
			END AS EndDate -- For each calendar date in #Dates, minus days since the most recent Sunday
			, 'Weekly' AS PeriodType
		FROM TallyDates
		WHERE
			CalDate >= (DATEADD(week, -@PastWeeksToCalculate, @Today)) -- Only include the x most recent complete weeks, where x is the number of weeks in the Incentivised DD tracking window. Within this window, customers can change CustomerGroup
		--	AND DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate) <= CalDate -- Only include complete weeks
	) x
	UNION ALL
	SELECT
		@MinStartDate AS StartDate
		, @MaxEndDate AS EndDate
		, 'Cumulative' AS PeriodType;

	-- For Campaign cycle analysis periods

	--DECLARE @OriginCycleStartDate DATE = '2010-01-14'; -- Random Campaign Report cycle start date
		
	--CREATE TABLE #Calendar (
	--	StartDate date
	--	, EndDate date
	--	, PeriodType varchar(50)
	--);

	--WITH cte AS
	--	(SELECT @OriginCycleStartDate AS CycleStartDate -- anchor member
	--	UNION ALL
	--	SELECT CAST((DATEADD(week, 4, CycleStartDate)) AS DATE) --  Campaign Cycle start date: recursive member
	--	FROM   cte
	--	WHERE CAST((DATEADD(week, 4, CycleStartDate)) AS DATE) < @Today -- terminator
	--	)
	--INSERT INTO #Calendar (
	--	StartDate
	--	, EndDate
	--	, PeriodType
	--)
	--SELECT
	--	CASE WHEN cte.CycleStartDate <= @MinStartDate THEN @MinStartDate ELSE cte.CycleStartDate END AS StartDate
	--	, CASE WHEN DATEADD(day, -1, (DATEADD(week, 4, cte.CycleStartDate))) >= @MaxEndDate THEN @MaxEndDate ELSE DATEADD(DAY, -1, (DATEADD(week, 4, cte.CycleStartDate))) END AS EndDate 
	--	, 'Cycle' AS PeriodType
	--FROM cte
	--WHERE DATEADD(DAY, -1, (DATEADD(week, 4, cte.CycleStartDate))) >= @MinStartDate
	--UNION ALL
	--SELECT
	--	@MinStartDate AS StartDate
	--	, @MaxEndDate AS EndDate
	--	, 'Cumulative' AS PeriodType		
	--OPTION (MAXRECURSION 10000);	

	CREATE CLUSTERED INDEX CIX_Calendar ON #Calendar (StartDate, EndDate);

	/******************************************************************************
	Load IronOfferID sub-segments for DD partners set up like this (identified by @SplitIronOfferTargeting parameter)
	******************************************************************************/

	IF OBJECT_ID('tempdb..#IronOfferSubSegments') IS NOT NULL DROP TABLE #IronOfferSubSegments;

	CREATE TABLE #IronOfferSubSegments (SubSegmentID int NOT NULL, LastSpendMonth int NOT NULL);

	IF @SplitIronOfferTargeting = 1
		INSERT INTO #IronOfferSubSegments (SubSegmentID, LastSpendMonth)
		SELECT 7, Acquire FROM Segmentation.PartnerSettings_DD WHERE PartnerID = @RetailerID AND Acquire >0
		UNION
		SELECT 8, Lapsed FROM Segmentation.PartnerSettings_DD WHERE PartnerID = @RetailerID AND Lapsed >0
		UNION
		SELECT 9, Shopper FROM Segmentation.PartnerSettings_DD WHERE PartnerID = @RetailerID AND Shopper >0;

	/******************************************************************************
	Load IronOffer References (IronOfferCycles and ControlGroupIDs)
	******************************************************************************/

	IF OBJECT_ID('tempdb..#IronOfferReferences') IS NOT NULL DROP TABLE #IronOfferReferences;

	SELECT 
		p.RetailerID
		, cal.PeriodType
		, cal.StartDate
		, cal.EndDate
		, CAST(o.IronOfferID AS VARCHAR(50)) AS IronOfferID
		, ioc.controlgroupid
		, ioc.ironoffercyclesid
		, CAST(o.StartDate AS date) AS OfferStartDate
		, CAST(o.EndDate AS date) AS OfferEndDate
	INTO #IronOfferReferences
	FROM Warehouse.Relational.IronOffer o
	INNER JOIN #Calendar cal -- Offers overlapping analysis period
		ON (o.StartDate <= cal.EndDate OR cal.EndDate IS NULL)
		AND (o.EndDate >= @MinStartDate OR o.EndDate IS NULL OR cal.StartDate IS NULL) -- Jason Shipp 01/05/2019- Used @MinStartDate as anchor for determining all exposed/control members to date
	INNER JOIN (SELECT IronOfferID, MAX(MaximumEarningDDDelay) AS MaximumEarningDDDelay FROM #Rules GROUP BY IronOfferID) r
		ON CAST(o.IronOfferID AS VARCHAR(50)) = r.IronOfferID
	INNER JOIN (
			SELECT 
			ioc.ironofferid
			, ioc.ironoffercyclesid
			, ioc.controlgroupid
			, oc.StartDate
			, oc.EndDate
			FROM Warehouse.Relational.ironoffercycles ioc
			INNER JOIN Warehouse.Relational.OfferCycles oc
				ON ioc.offercyclesid= oc.OfferCyclesID
			) ioc
		ON o.ironofferid = ioc.ironofferid
		AND (ioc.StartDate <= cal.EndDate OR cal.EndDate IS NULL) -- Offer cycles overlapping analysis period
		AND (ioc.EndDate >= DATEADD(day, -r.MaximumEarningDDDelay, cal.StartDate) OR cal.StartDate IS NULL) -- Jason Shipp 01/05/2019- Used start of window as anchor for determining all exposed/control members to date who could spend
	INNER JOIN #PartnerIDs p
		ON o.PartnerID = p.PartnerID
	WHERE 
		o.IsSignedOff = 1
		AND o.IronOfferName NOT LIKE '%Spare%';

	CREATE NONCLUSTERED INDEX IX_IronOfferReferences ON #IronOfferReferences (StartDate, EndDate, IronOfferID) INCLUDE (ironoffercyclesid, controlgroupid);

	/******************************************************************************
	Load exposed cardholder counts grouped by IronOfferID 
	******************************************************************************/

	-- Create table for storing results

	IF OBJECT_ID('tempdb..#Cardholders_E') IS NOT NULL DROP TABLE #Cardholders_E;

	CREATE TABLE #Cardholders_E (
		RetailerID int
		, PeriodType varchar(50)
		, StartDate date
		, EndDate date
		, IronOfferID varchar(50)
		, SubSegmentID int
		, Cardholders int
	);

	-- Load #IronOfferReferences with a grouping ID indicating the final group each row will belong to in the final results table

	IF OBJECT_ID('tempdb..#IronOfferReferencesGrouper_E') IS NOT NULL DROP TABLE #IronOfferReferencesGrouper_E;

	SELECT DISTINCT
		grouper = DENSE_RANK() OVER(ORDER BY o.RetailerID, o.PeriodType, o.StartDate, o.EndDate, o.IronOfferID, oss.SubSegmentID)
		, o.RetailerID
		, o.PeriodType
		, o.StartDate
		, o.EndDate
		, o.IronOfferID
		, oss.SubSegmentID
		, o.ironoffercyclesid
	INTO #IronOfferReferencesGrouper_E
	FROM #IronOfferReferences o
	LEFT JOIN #IronOfferSubSegments oss 
		ON 1=1; -- Like a "Left" cross join

	CREATE NONCLUSTERED INDEX cx_Stuff ON #IronOfferReferencesGrouper_E (IronOfferCyclesID, SubSegmentID);

	INSERT INTO #Cardholders_E (
		RetailerID
		, PeriodType
		, StartDate
		, EndDate
		, IronOfferID
		, SubSegmentID
		, Cardholders
	)
	SELECT -- Load grouping columns
		o.RetailerID
		, o.PeriodType
		, o.StartDate
		, o.EndDate
		, o.IronOfferID
		, o.SubSegmentID
		, x.Cardholders -- Attach grouping columns to cardholders
	FROM (
			SELECT DISTINCT grouper, RetailerID, PeriodType, StartDate, EndDate, IronOfferID, SubSegmentID
			FROM #IronOfferReferencesGrouper_E -- Grouping columns
	) o
	CROSS APPLY ( -- For each row in final results table, get distinct FanID counts
		SELECT COUNT(*) AS Cardholders
		FROM (
			SELECT ix.FanID -- Get distinct FanIDs with the same grouping ID
			FROM #IronOfferReferencesGrouper_E ior
			CROSS APPLY ( -- Fow each row in #iorExpandedGrouper_E, get FanIDs
				SELECT ch.FanID FROM Warehouse.Relational.CampaignHistory ch 
				LEFT JOIN Warehouse.Segmentation.CustomerSegment_DD cs ON ch.FanID = cs.FanID AND cs.PartnerID = @RetailerID
				WHERE ior.IronOfferCyclesID = ch.ironoffercyclesid
				AND (ior.SubSegmentID = cs.ShopperSegmentTypeID OR @SplitIronOfferTargeting = 0)
				UNION ALL
				SELECT cha.FanID FROM Warehouse.Relational.CampaignHistory_Archive cha
				LEFT JOIN Warehouse.Segmentation.CustomerSegment_DD cs ON cha.FanID = cs.FanID AND cs.PartnerID = @RetailerID
				WHERE ior.IronOfferCyclesID = cha.ironoffercyclesid
				AND (ior.SubSegmentID = cs.ShopperSegmentTypeID OR @SplitIronOfferTargeting = 0)
			) ix -- Load FanIDs. Match condition: matching IronOfferCyclesIDs
		WHERE ior.grouper = o.grouper 
		GROUP BY ix.FanID
		) d
	) x; -- Load distinct FanIDs. Match condition: matching grouping IDs

	/******************************************************************************
	Load overall exposed cardholder counts (not grouped by IronOfferID)
	******************************************************************************/

	-- Load #IronOfferReferences with a grouping ID indicating the final group each row will belong to in the final results table

	IF OBJECT_ID('tempdb..#IronOfferReferencesGrouper_E2') IS NOT NULL DROP TABLE #IronOfferReferencesGrouper_E2;

	SELECT DISTINCT
		grouper = DENSE_RANK() OVER(ORDER BY o.RetailerID, o.PeriodType, o.StartDate, o.EndDate, oss.SubSegmentID)
		, o.RetailerID
		, o.PeriodType
		, o.StartDate
		, o.EndDate
		, oss.SubSegmentID
		, o.ironoffercyclesid
	INTO #IronOfferReferencesGrouper_E2
	FROM #IronOfferReferences o
	LEFT JOIN #IronOfferSubSegments oss
		ON 1=1 -- Like a "Left" cross join;

	CREATE NONCLUSTERED INDEX cx_Stuff ON #IronOfferReferencesGrouper_E2 (IronOfferCyclesID, SubSegmentID);

	INSERT INTO #Cardholders_E (
		RetailerID
		, PeriodType
		, StartDate
		, EndDate
		, IronOfferID
		, SubSegmentID
		, Cardholders
	)
	SELECT -- Load grouping columns
		o.RetailerID
		, o.PeriodType
		, o.StartDate
		, o.EndDate
		, 'Overall' AS IronOfferID
		, o.SubSegmentID
		, x.Cardholders -- Attach grouping columns to cardholders
	FROM (
			SELECT DISTINCT grouper, RetailerID, PeriodType, StartDate, EndDate, SubSegmentID
			FROM #IronOfferReferencesGrouper_E2 -- Grouping columns
	) o
	CROSS APPLY ( -- For each row in final results table, get distinct FanID counts
		SELECT COUNT(*) AS Cardholders
		FROM (
			SELECT ix.FanID -- Get distinct FanIDs with the same grouping ID
			FROM #IronOfferReferencesGrouper_E2 ior
			CROSS APPLY ( -- Fow each row in #iorExpandedGrouper_E, get FanIDs
				SELECT ch.FanID FROM Warehouse.Relational.CampaignHistory ch
				LEFT JOIN Warehouse.Segmentation.CustomerSegment_DD cs ON ch.FanID = cs.FanID AND cs.PartnerID = @RetailerID
				WHERE ior.IronOfferCyclesID = ch.ironoffercyclesid
				AND (ior.SubSegmentID = cs.ShopperSegmentTypeID OR @SplitIronOfferTargeting = 0)
				UNION ALL
				SELECT cha.FanID FROM Warehouse.Relational.CampaignHistory_Archive cha 
				LEFT JOIN Warehouse.Segmentation.CustomerSegment_DD cs ON cha.FanID = cs.FanID AND cs.PartnerID = @RetailerID
				WHERE ior.IronOfferCyclesID = cha.ironoffercyclesid
				AND (ior.SubSegmentID = cs.ShopperSegmentTypeID OR @SplitIronOfferTargeting = 0)
			) ix -- Load FanIDs. Match condition: matching IronOfferCyclesIDs
		WHERE ior.grouper = o.grouper 
		GROUP BY ix.FanID
		) d
	) x; -- Load distinct FanIDs. Match condition: matching grouping IDs

	/******************************************************************************
	Load control cardholder counts grouped by IronOfferID 
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Cardholders_C') IS NOT NULL DROP TABLE #Cardholders_C;

	CREATE TABLE #Cardholders_C (
		RetailerID int
		, PeriodType varchar(50)
		, StartDate date
		, EndDate date
		, IronOfferID varchar(50)
		, SubSegmentID int
		, Cardholders int
	);

	-- Load #IronOfferReferences with a grouping ID indicating the final group each row will belong to in the final results table

	IF OBJECT_ID('tempdb..#IronOfferReferencesGrouper_C') IS NOT NULL DROP TABLE #IronOfferReferencesGrouper_C;

	SELECT DISTINCT
		grouper = DENSE_RANK() OVER(ORDER BY o.RetailerID, o.PeriodType, o.StartDate, o.EndDate, o.IronOfferID)
		, o.RetailerID
		, o.PeriodType
		, o.StartDate
		, o.EndDate
		, o.IronOfferID
		, o.controlgroupid
	INTO #IronOfferReferencesGrouper_C
	FROM #IronOfferReferences o;

	CREATE CLUSTERED INDEX cx_Stuff ON #IronOfferReferencesGrouper_C (controlgroupid);

	INSERT INTO #Cardholders_C (
		RetailerID
		, PeriodType
		, StartDate
		, EndDate
		, IronOfferID
		, SubSegmentID
		, Cardholders
	)
	SELECT -- Load grouping columns
		o.RetailerID
		, o.PeriodType
		, o.StartDate
		, o.EndDate
		, o.IronOfferID
		, NULL AS SubSegmentID
		, x.Cardholders -- Attach grouping columns to cardholders
	FROM (
			SELECT DISTINCT grouper, RetailerID, PeriodType, StartDate, EndDate, IronOfferID
			FROM #IronOfferReferencesGrouper_C -- Grouping columns
	) o
	CROSS APPLY ( -- For each row in final results table, get distinct FanID counts
		SELECT COUNT(*) AS Cardholders
		FROM (
			SELECT ix.FanID -- Get distinct FanIDs with the same grouping ID
			FROM #IronOfferReferencesGrouper_C ior
			CROSS APPLY ( -- Fow each row in #iorExpandedGrouper_C, get FanIDs
				SELECT FanID FROM Warehouse.Relational.controlgroupmembers cm 
				WHERE ior.controlgroupid = cm.controlgroupid
			) ix -- Load FanIDs. Match condition: matching ControlGroupIDs
		WHERE ior.grouper = o.grouper 
		GROUP BY ix.FanID
		) d
	) x; -- Load distinct FanIDs. Match condition: matching grouping IDs

	/******************************************************************************
	Load overall control cardholder counts (not grouped by IronOfferID)
	******************************************************************************/

	-- Load #IronOfferReferences with a grouping ID indicating the final group each row will belong to in the final results table

	IF OBJECT_ID('tempdb..#IronOfferReferencesGrouper_C2') IS NOT NULL DROP TABLE #IronOfferReferencesGrouper_C2;

	SELECT DISTINCT
		grouper = DENSE_RANK() OVER(ORDER BY o.RetailerID, o.PeriodType, o.StartDate, o.EndDate)
		, o.RetailerID
		, o.PeriodType
		, o.StartDate
		, o.EndDate
		, o.controlgroupid
	INTO #IronOfferReferencesGrouper_C2
	FROM #IronOfferReferences o;

	CREATE CLUSTERED INDEX cx_Stuff ON #IronOfferReferencesGrouper_C2 (controlgroupid);

	INSERT INTO #Cardholders_C (
		RetailerID
		, PeriodType
		, StartDate
		, EndDate
		, IronOfferID
		, SubSegmentID
		, Cardholders
	)
	SELECT -- Load grouping columns
		o.RetailerID
		, o.PeriodType
		, o.StartDate
		, o.EndDate
		, 'Overall' AS IronOfferID
		, NULL AS SubSegmentID
		, x.Cardholders -- Attach grouping columns to cardholders
	FROM (
			SELECT DISTINCT grouper, RetailerID, PeriodType, StartDate, EndDate
			FROM #IronOfferReferencesGrouper_C2 -- Grouping columns
	) o
	CROSS APPLY ( -- For each row in final results table, get distinct FanID counts
		SELECT COUNT(*) AS Cardholders
		FROM (
			SELECT ix.FanID -- Get distinct FanIDs with the same grouping ID
			FROM #IronOfferReferencesGrouper_C2 ior
			CROSS APPLY ( -- Fow each row in #iorExpandedGrouper_C, get FanIDs
				SELECT FanID FROM Warehouse.Relational.controlgroupmembers cm 
				WHERE ior.controlgroupid = cm.controlgroupid
			) ix -- Load FanIDs. Match condition: matching ControlGroupIDs
		WHERE ior.grouper = o.grouper 
		GROUP BY ix.FanID
		) d
	) x; -- Load distinct FanIDs. Match condition: matching grouping IDs
		








	/******************************************************************************
	Load exposed and control DD transactions
	******************************************************************************/

	-- Load distinct references to iterate over

	IF OBJECT_ID('tempdb..#IterationTable') IS NOT NULL DROP TABLE #IterationTable;

	SELECT 
		ior.RetailerID
		, ior.IronOfferID
		, ior.OfferStartDate
		, ior.OfferEndDate
		, ior.StartDate
		, ior.EndDate
		, ROW_NUMBER() OVER (ORDER BY ior.RetailerID, ior.IronOfferID, ior.StartDate, ior.EndDate) AS RowNum
	INTO #IterationTable
	FROM (-- Grouped by Iron Offer analysis date
		SELECT DISTINCT
			RetailerID
			, CAST(IronOfferID AS varchar(50)) AS IronOfferID
			, OfferStartDate
			, OfferEndDate
			, StartDate
			, EndDate		
		FROM #IronOfferReferences
		UNION ALL
		-- Grouped by analysis date only
		SELECT DISTINCT
			RetailerID
			, 'Overall' AS IronOfferID
			, MIN(OfferStartDate) OfferStartDate -- Take min and max offer-active dates
			, CASE WHEN MAX(CASE WHEN OfferEndDate IS NULL THEN 1 ELSE 0 END) = 0 THEN MAX(OfferEndDate) ELSE NULL END AS OfferEndDate
			, StartDate
			, EndDate	
		FROM #IronOfferReferences
		GROUP BY
			RetailerID
			, StartDate
			, EndDate	
	) ior;



	/******************************************************************************
	Load transaction data from Archive_Light.dbo.CBP_DirectDebit_TransactionHistory into a temp table for more efficient querying for the control groups
	******************************************************************************/

	-- Load FileIDs that contain DD data for the period we are interested in

	IF OBJECT_ID('tempdb..#FileIDs') IS NOT NULL DROP TABLE #FileIDs;

	CREATE TABLE #FileIDs (FileID int NOT NULL);
	INSERT INTO #FileIDs
	SELECT	ID
	FROM [SLC_REPL].[dbo].[NobleFiles] nf
	WHERE FileType = 'DDTRN'
	AND DATEADD(MONTH, -1, @MinStartDate) < nf.InDate
	AND EXISTS (SELECT 1
				FROM [Archive_Light].[dbo].[CBP_DirectDebit_TransactionHistory] th
				WHERE nf.ID = th.FileID)

/* RF Removed 2020-06-29

-- Load FileIDs to iterate over

	IF OBJECT_ID('tempdb..#FileIDsIteration') IS NOT NULL DROP TABLE #FileIDsIteration;

	SELECT 
		FileID
		, ROW_NUMBER() OVER (ORDER BY FileID ASC) AS RowNum
	INTO #FileIDsIteration
	FROM #FileIDs;

	-- Load data from Archive_Light.dbo.CBP_DirectDebit_TransactionHistory (looping over FileIDs) so we don't need to hit this table again for control groups

	IF OBJECT_ID('tempdb..#TransactionHistoryData') IS NOT NULL DROP TABLE #TransactionHistoryData;

	CREATE TABLE #TransactionHistoryData (
		FanID int
		, [Date] date
		, Amount float
		, OIN int
	);	

	DECLARE @RowNumber1 int;
	DECLARE @MaxRowNumber1 int;
	DECLARE @FileID int;

	SET @RowNumber1 = 1;
	SET @MaxRowNumber1 = (SELECT MAX(RowNum) FROM #FileIDsIteration);

	WHILE @RowNumber1 <= @MaxRowNumber1

	BEGIN
	
		SET @FileID = (SELECT FileID FROM #FileIDsIteration WHERE RowNum = @RowNumber1);

		INSERT INTO #TransactionHistoryData (
			FanID
			, [Date] 
			, Amount
			, OIN
		)
		SELECT 
			dd.FanID
			, dd.[Date]
			, dd.Amount
			, dd.OIN
		FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory dd
		WHERE
			dd.FileID = @FileID
			AND EXISTS (
				SELECT NULL FROM #DDSuppliers dds
				WHERE dd.OIN = dds.OIN
				--AND (dd.[Date] >= dds.StartDate OR dds.StartDate IS NULL) -- Use this if OINs start starting/ending whilst offers are active
				--AND (dd.[Date] <= dds.EndDate OR dds.EndDate IS NULL)
			);

		SET @RowNumber1 = @RowNumber1 + 1;

	END

RF Removed 2020-06-29 */


		IF OBJECT_ID('tempdb..#GroupIDs_Control') IS NOT NULL DROP TABLE #GroupIDs_Control;
		SELECT	DISTINCT
				controlgroupid AS GroupID
		INTO #GroupIDs_Control
		FROM #IronOfferReferences ior
		WHERE EXISTS (	SELECT 1
						FROM #IterationTable it
						WHERE (ior.IronOfferID = it.IronOfferID OR it.IronOfferID = 'Overall')
						AND ior.StartDate = it.StartDate
						AND ior.EndDate = it.EndDate);

		CREATE UNIQUE CLUSTERED INDEX CIX_GroupIDs ON #GroupIDs_Control (GroupID);
		
		IF OBJECT_ID('tempdb..#ControlGroupMembers_All') IS NOT NULL DROP TABLE #ControlGroupMembers_All;
		SELECT	DISTINCT 
				c.FanID
		INTO #ControlGroupMembers_All
		FROM Warehouse.Relational.controlgroupmembers c
		WHERE EXISTS (	SELECT 1
						FROM #GroupIDs_Control it
						WHERE c.controlgroupid = it.GroupID);
			



	IF OBJECT_ID('tempdb..#TransactionHistoryData') IS NOT NULL DROP TABLE #TransactionHistoryData;

	CREATE TABLE #TransactionHistoryData (
		FanID int
		, [Date] date
		, Amount float
		, OIN int
	);	


	INSERT INTO #TransactionHistoryData (
		FanID
		, [Date] 
		, Amount
		, OIN
	)
	SELECT 
		ct.FanID
		, ct.TranDate
		, ct.Amount
		, cc.OIN
	FROM [Relational].[ConsumerTransaction_DD] ct
	INNER JOIN [Relational].[ConsumerCombination_DD] cc
		ON ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD
	WHERE 1 = 1
	AND EXISTS (	SELECT 1
					FROM #FileIDs fi
					WHERE ct.FileID = fi.FileID)
	AND EXISTS (	SELECT 1
					FROM #ControlGroupMembers_All cgm
					WHERE ct.FanID = cgm.FanID)
	AND EXISTS (	SELECT 1
					FROM #DDSuppliers dds
					WHERE cc.OIN = dds.OIN);


	CREATE CLUSTERED INDEX CIX_OIN ON #TransactionHistoryData (OIN)




	-- Declare iteration variables

	DECLARE @RowNumber int;
	DECLARE @MaxRowNumber int;
	DECLARE @IronOfferID varchar(50);
	DECLARE @StartDate date;
	DECLARE @EndDate date;
	DECLARE @DD1WindowStartDate date;
	DECLARE @DD1WindowEndDate date;
	DECLARE @DD2WindowEndDate date;

	SET @RowNumber = 1;
	SET @MaxRowNumber = (SELECT MAX(RowNum) FROM #IterationTable);

	-- Create table for storing results

	IF OBJECT_ID('tempdb..#ExposedControlAggResults') IS NOT NULL DROP TABLE #ExposedControlAggResults;

	CREATE TABLE #ExposedControlAggResults(
		IronOfferID varchar(50) NOT NULL
		, SubSegmentID int
		, StartDate date NOT NULL
		, EndDate date NOT NULL
		, IsExposed bit NOT NULL
		, CustomerGroup varchar(50) NOT NULL
		, CustomerGroupMinSpend money
		, DDRankByDateGroup varchar(50) NOT NULL
		, DDs int
		, UniqueDDCustomers int
		, DDSpend money
	);

	
	IF OBJECT_ID('tempdb..#FanLinkTable') IS NOT NULL DROP TABLE #FanLinkTable;
	SELECT DISTINCT 
		   f.ID AS InitialFanID
		 , f2.ID AS FanID
	INTO #FanLinkTable
	FROM [SLC_REPL].[dbo].[Fan] f
	INNER JOIN [SLC_REPL].[dbo].[IssuerCustomer] ic 
		ON f.SourceUID = ic.SourceUID
	INNER JOIN [SLC_REPL].[dbo].[IssuerBankAccount] iba
		ON  ic.ID = iba.IssuerCustomerID
	INNER JOIN [SLC_REPL].[dbo].[IssuerBankAccount] iba2 -- Expand bank accounts to include all FanIDs associated with the same bank accounts 
		ON iba.BankAccountID = iba2.BankAccountID
	INNER JOIN [SLC_REPL].[dbo].[IssuerCustomer] ic2
		ON iba2.IssuerCustomerID = ic2.ID
	INNER JOIN [SLC_REPL].[dbo].[Fan] f2
		ON ic2.SourceUID = f2.SourceUID
		
	CREATE CLUSTERED INDEX CIX_InitialFanID ON #FanLinkTable (InitialFanID, FanID);
	

	IF OBJECT_ID('tempdb..#Match') IS NOT NULL DROP TABLE #Match;
	SELECT fa.ID AS FanID
		 , ru.IronOfferID
		 , iba.BankAccountID
		 , CONVERT(DATE, ma.TransactionDate) AS TransactionDate
		 , ma.Amount
		 , ma.AffiliateCommissionAmount
		 , ma.RewardStatus AS DDRankByDateGroup
	INTO #Match
	FROM [SLC_REPL].[dbo].[Match] ma
	INNER JOIN [SLC_REPL].[dbo].[IssuerBankAccount] iba 
		ON ma.IssuerBankAccountID = iba.ID
	INNER JOIN [SLC_REPL].[dbo].[IssuerCustomer] ic 
		ON iba.IssuerCustomerID = ic.ID
	INNER JOIN [SLC_REPL].[dbo].[Fan] fa
		ON ic.SourceUID = fa.SourceUID
	INNER JOIN #Rules ru
		ON ma.DirectDebitOriginatorID = ru.DirectDebitOriginatorID
		AND (ma.PartnerCommissionRuleID = ru.PartnerCommissionRuleID OR (ma.PartnerCommissionRuleID IS NULL AND ru.PartnerCommissionRuleID IS NULL)) -- Join on PartnerCommissionRuleID where available, to handle cases where an OIN is linked to multiple Iron Offers
	WHERE ma.[Status] = 1 -- Valid transactions
	AND ma.[RewardStatus] IN (1, 15) -- 15 = insufficient prior DD transactions for incentivisation, 1 = incentivised DD transaction
	AND ma.VectorID = 40 -- RBS DDs
	AND EXISTS (	SELECT 1
					FROM #DDSuppliers dds
					WHERE ma.DirectDebitOriginatorID = dds.DirectDebitOriginatorID)
					--AND (m.TransactionDate >= dds.StartDate OR dds.StartDate IS NULL) #DDSuppliers -- Use this if OINs start starting/ending whilst offers are active
					--AND (m.TransactionDate <= dds.EndDate OR dds.EndDate IS NULL))
		
	CREATE CLUSTERED INDEX CIX_FanIDIronOfferID ON #Match (FanID, IronOfferID);


	WHILE @RowNumber <= @MaxRowNumber
	BEGIN

		-- Set iteration variables

		SET @IronOfferID = (SELECT IronOfferID FROM #IterationTable WHERE RowNum = @RowNumber);
		SET @StartDate = (SELECT StartDate FROM #IterationTable WHERE RowNum = @RowNumber);
		SET @EndDate = (SELECT EndDate FROM #IterationTable WHERE RowNum = @RowNumber);
	
		-- Load ControlGroupIDs and IronOfferCyclesIDs associated with iteration number

		IF OBJECT_ID('tempdb..#GroupIDs') IS NOT NULL DROP TABLE #GroupIDs;

		SELECT DISTINCT
			ironoffercyclesid AS GroupID
			, 1 AS IsExposed
		INTO #GroupIDs
		FROM #IronOfferReferences
		WHERE 
			(IronOfferID = @IronOfferID OR @IronOfferID = 'Overall')
			AND StartDate = @StartDate
			AND EndDate = @EndDate

		UNION ALL

		SELECT DISTINCT
			controlgroupid AS GroupID
			, 0 AS IsExposed
		FROM #IronOfferReferences
		WHERE 
			(IronOfferID = @IronOfferID OR @IronOfferID = 'Overall')
			AND StartDate = @StartDate
			AND EndDate = @EndDate;

		CREATE UNIQUE CLUSTERED INDEX CIX_GroupIDs ON #GroupIDs (GroupID, IsExposed);

		-- Load CampaignHistory, expanded to include all FanIDs associated with the bank accounts linked to the FanIDs in CampaignHistory
		
		IF OBJECT_ID('tempdb..#CampaignHistoryExpanded') IS NOT NULL DROP TABLE #CampaignHistoryExpanded;
		SELECT DISTINCT 
			   flt.FanID AS FanID
		INTO #CampaignHistoryExpanded
		FROM (
			SELECT ch.FanID FROM Warehouse.Relational.CampaignHistory ch WHERE ch.ironoffercyclesid IN (SELECT GroupID FROM #GroupIDs WHERE IsExposed = 1)
			UNION ALL
			SELECT cha.fanid FROM Warehouse.Relational.CampaignHistory_Archive cha WHERE cha.ironoffercyclesid IN (SELECT GroupID FROM #GroupIDs WHERE IsExposed = 1)
		) ch
		INNER JOIN #FanLinkTable flt
			ON ch.fanid = flt.InitialFanID
		OPTION(RECOMPILE);

		CREATE UNIQUE CLUSTERED INDEX UCIX_CampaignHistoryExpanded ON #CampaignHistoryExpanded (FanID);

		-- Load aggregated exposed data 
			   		 
		WITH GroupedByFirstSecondDD AS (
			SELECT ma.FanID
				 , ma.IronOfferID
				 , cs.ShopperSegmentTypeID AS SubSegmentID
				 , ma.BankAccountID
				 , ma.TransactionDate
				 , ma.Amount
				 , ma.AffiliateCommissionAmount
				 , ma.DDRankByDateGroup
			FROM #Match ma
			INNER JOIN #CampaignHistoryExpanded che
				ON ma.FanID = che.FanID
			LEFT JOIN Warehouse.Segmentation.CustomerSegment_DD cs
				ON che.FanID = cs.FanID 
				AND cs.PartnerID = @RetailerID
				AND @SplitIronOfferTargeting = 1 -- If @SplitIronOfferTargeting = 0, SubSegmentID will be returned as NULL
			WHERE (ma.IronOfferID = @IronOfferID OR @IronOfferID = 'Overall')
		)
		, With2ndDDSubGroup AS (
			SELECT
			dd.FanID
			, dd.IronOfferID
			, dd.SubSegmentID
			, dd.BankAccountID
			, dd.TransactionDate
			, dd.Amount
			, dd.DDRankByDateGroup
			, MAX(CASE WHEN DDRankByDateGroup = 1 THEN dd.Amount ELSE NULL END) OVER (PARTITION BY dd.FanID, dd.IronOfferID) AS MaxIncentivisedDDAmount
			FROM GroupedByFirstSecondDD dd
		)
		INSERT INTO #ExposedControlAggResults (
			IronOfferID
			, SubSegmentID
			, StartDate
			, EndDate
			, IsExposed
			, CustomerGroup
			, CustomerGroupMinSpend
			, DDRankByDateGroup
			, DDs
			, UniqueDDCustomers
			, DDSpend
		)
		SELECT
			@IronOfferID
			, dd.SubSegmentID
			, @StartDate
			, @EndDate
			, 1 AS IsExposed
			, CASE -- Identify customer group- this will update as new DD data arrives
				WHEN sth.IronOfferID IS NULL 
				THEN 'OpeningDDOnly' 
				ELSE CONCAT('IncentivisedDDOver', sth.MinimumSpend)
			END AS CustomerGroup
			, sth.MinimumSpend AS CustomerGroupMinSpend
			, CASE -- Identify DD type
				WHEN dd.DDRankByDateGroup = 15 THEN 'Opening'
				WHEN dd.DDRankByDateGroup = 1 THEN 'Incentivised'
				ELSE NULL
			END AS DDRankByDateGroup
			, COUNT(1) AS DDs
			, COUNT(DISTINCT(dd.BankAccountID)) AS UniqueDDCustomers
			, SUM(dd.Amount) AS DDSpend
		FROM With2ndDDSubGroup dd
		LEFT JOIN #SpendThresholds sth
			ON dd.IronOfferID = sth.IronOfferID
			AND dd.MaxIncentivisedDDAmount BETWEEN sth.MinimumSpend AND COALESCE(sth.MaximumSpend, dd.MaxIncentivisedDDAmount)
		WHERE
			dd.TransactionDate BETWEEN @StartDate AND @EndDate -- Jason Shipp 01/05/2019- Update to track transactions per analysis period, instead of transactions of customers exposed in analysis period
		GROUP BY
			dd.SubSegmentID
			, CASE
				WHEN sth.IronOfferID IS NULL 
				THEN 'OpeningDDOnly' 
				ELSE CONCAT('IncentivisedDDOver', sth.MinimumSpend)
			END
			, sth.MinimumSpend
			, CASE
				WHEN dd.DDRankByDateGroup = 15 THEN 'Opening'
				WHEN dd.DDRankByDateGroup = 1 THEN 'Incentivised'
				ELSE NULL
			END
		OPTION(RECOMPILE);	

		-- Load aggregated control data
		
		IF OBJECT_ID('tempdb..#ControlGroupMembers') IS NOT NULL DROP TABLE #ControlGroupMembers;

		SELECT DISTINCT 
			c.FanID
		INTO #ControlGroupMembers
		FROM Warehouse.Relational.controlgroupmembers c
		WHERE 
			c.controlgroupid IN (SELECT GroupID FROM #GroupIDs WHERE IsExposed = 0);

		CREATE UNIQUE CLUSTERED INDEX UCIX_ControlGroupMembers ON #ControlGroupMembers (FanID);

		WITH GroupedByFirstSecondDD AS (
			SELECT
			dd.FanID
			, r.IronOfferID
			, r.OfferStartDate
			, r.OfferEndDate
			, dd.[Date]
			, dd.Amount
			, DENSE_RANK() OVER (PARTITION BY dd.FanID, r.IronOfferID ORDER BY dd.[Date] ASC) AS DDRankByDateGroup
			, r.EarnOnDDCount
			, r.MinimumFirstDDDelay
			, r.MaximumFirstDDDelay
			, r.MaximumEarningDDDelay
			, r.OpeningDDWindowEndDate
			, r.IncentivisedDDWindowEndDate
			FROM #TransactionHistoryData dd
			INNER JOIN #Rules r -- Duplication due to OINs being linked to multiple Iron Offers resolved in WHERE clause
				ON dd.OIN = r.OIN
			WHERE dd.[Date] >= r.PassiveWindowEndDate -- Exclude passive spend
			AND EXISTS (	SELECT 1
							FROM #ControlGroupMembers cgm
							WHERE dd.FanID = cgm.FanID)
			AND (r.IronOfferID = @IronOfferID OR (@IronOfferID = 'Overall' AND r.IncludeInOverall = 1)) -- This will handle cases where OINs are linked to multiple Iron Offers
		)
		, GroupedByDay AS (
			SELECT
			dd.FanID
			, dd.IronOfferID
			, dd.[Date]
			, dd.DDRankByDateGroup
			, dd.EarnOnDDCount
			, SUM(dd.Amount) AS Amount -- Multiple customer DDs in a day are counted as 1 DD
			FROM GroupedByFirstSecondDD dd
			WHERE 
				(dd.DDRankByDateGroup < dd.EarnOnDDCount AND (dd.[Date] <= dd.OpeningDDWindowEndDate OR dd.OpeningDDWindowEndDate IS NULL)) -- Opening DDs only counted if they occur within window of offer end date
				OR (dd.DDRankByDateGroup = dd.EarnOnDDCount AND (dd.[Date] <= dd.IncentivisedDDWindowEndDate OR dd.IncentivisedDDWindowEndDate IS NULL)) -- Incentivised DDs only counted if they occur within window of offer end date
			GROUP BY
				dd.FanID
				, dd.IronOfferID
				, dd.[Date]
				, dd.DDRankByDateGroup
				, dd.EarnOnDDCount
		)
		, With2ndDDSubGroup AS (
			SELECT
			dd.FanID
			, dd.IronOfferID
			, dd.[Date]
			, dd.Amount
			, dd.DDRankByDateGroup
			, dd.EarnOnDDCount
			, CASE WHEN MAX(dd.DDRankByDateGroup) OVER (PARTITION BY dd.FanID, dd.IronOfferID) < dd.EarnOnDDCount THEN NULL ELSE -- Use NULL if FanID only has an opening DD
				MAX(CASE WHEN dd.DDRankByDateGroup = dd.EarnOnDDCount THEN dd.Amount ELSE NULL END) OVER (PARTITION BY dd.FanID, dd.IronOfferID) -- Otherwise get FanID's incentivised DD amount
			END AS MaxIncentivisedDDAmount
			FROM GroupedByDay dd
		)
		INSERT INTO #ExposedControlAggResults (
			IronOfferID
			, SubSegmentID
			, StartDate
			, EndDate
			, IsExposed
			, CustomerGroup
			, CustomerGroupMinSpend
			, DDRankByDateGroup
			, DDs
			, UniqueDDCustomers
			, DDSpend
		)
		SELECT
			@IronOfferID
			, oss.SubSegmentID
			, @StartDate
			, @EndDate
			, 0 AS IsExposed
			, CASE -- Identify customer group- this will update as new DD data arrives
				WHEN sth.IronOfferID IS NULL 
				THEN 'OpeningDDOnly' 
				ELSE CONCAT('IncentivisedDDOver', sth.MinimumSpend)
			END AS CustomerGroup
			, sth.MinimumSpend AS CustomerGroupMinSpend
			, CASE -- Identify DD type
				WHEN dd.DDRankByDateGroup < dd.EarnOnDDCount THEN 'Opening'
				WHEN dd.DDRankByDateGroup = dd.EarnOnDDCount THEN 'Incentivised'
				ELSE NULL
			END AS DDRankByDateGroup
			, COUNT(1) AS DDs
			, COUNT(DISTINCT(dd.FanID)) AS UniqueDDCustomers
			, SUM(dd.Amount) AS DDSpend
		FROM With2ndDDSubGroup dd
		LEFT JOIN #SpendThresholds sth
			ON dd.IronOfferID = sth.IronOfferID
			AND dd.MaxIncentivisedDDAmount BETWEEN sth.MinimumSpend AND COALESCE(sth.MaximumSpend, dd.MaxIncentivisedDDAmount)
		LEFT JOIN #IronOfferSubSegments oss
			ON 1=1 -- Like a "Left" cross join
		WHERE
			dd.[Date] BETWEEN @StartDate AND @EndDate -- Jason Shipp 01/05/2019- Update to track transactions per analysis period, instead of transactions of customers exposed in analysis period
		GROUP BY
			oss.SubSegmentID
			, CASE 
				WHEN sth.IronOfferID IS NULL 
				THEN 'OpeningDDOnly' 
				ELSE CONCAT('IncentivisedDDOver', sth.MinimumSpend)
			END
			, sth.MinimumSpend
			, CASE
				WHEN dd.DDRankByDateGroup < dd.EarnOnDDCount THEN 'Opening'
				WHEN dd.DDRankByDateGroup = dd.EarnOnDDCount THEN 'Incentivised'
				ELSE NULL
			END
	
			OPTION(RECOMPILE);	

		SET @RowNumber = @RowNumber + 1;

	END

	/******************************************************************************
	Load combined results into Warehouse.Staging.DirectDebitResults

	-- Create table for storing results:

	CREATE TABLE Warehouse.Staging.DirectDebitResults (
		ID int IDENTITY (1,1) NOT NULL
		, ReportDate date NOT NULL
		, RetailerID int NOT NULL
		, PeriodType varchar(50) NOT NULL
		, StartDate date
		, EndDate date
		, IronOfferID varchar(50) NOT NULL
		, IsExposed bit NOT NULL
		, CustomerGroup varchar(50) NOT NULL
		, DDRankByDateGroup varchar(50) NOT NULL
		, Cardholders int
		, DDCount int
		, UniqueDDSpenders int
		, DDSpend money
		, CustomerGroupMinSpend money
		, CONSTRAINT PK_DirectDebitResults PRIMARY KEY CLUSTERED (ID) 
	);
	******************************************************************************/
	
	DECLARE @Today2 DATE = CAST(GETDATE() AS DATE);

	INSERT INTO Warehouse.Staging.DirectDebitResults (
		ReportDate
		, RetailerID
		, PeriodType
		, StartDate
		, EndDate
		, IronOfferID
		, IsExposed
		, CustomerGroup
		, DDRankByDateGroup
		, Cardholders
		, DDCount
		, UniqueDDSpenders
		, DDSpend
		, CustomerGroupMinSpend
	)
	SELECT 
		@Today2 AS ReportDate
		, ior.RetailerID
		, cal.PeriodType
		, cal.StartDate
		, cal.EndDate
		, CONCAT(ior.IronOfferID, CASE agg4.SubSegmentID WHEN 7 THEN '-Acquire' WHEN 8 THEN '-Lapsed' WHEN 9 THEN '-Shopper' ELSE '' END) AS IronOfferID
		, agg1.IsExposed
		, agg2.CustomerGroup AS CustomerGroup
		, agg3.DDRankByDateGroup
		, ch.Cardholders
		, r.DDs AS DDCount
		, r.UniqueDDCustomers AS UniqueDDSpenders
		, r.DDSpend
		, agg2.CustomerGroupMinSpend
	FROM #Calendar cal
	CROSS JOIN (SELECT DISTINCT RetailerID, IronOfferID FROM #IterationTable) ior
	CROSS JOIN (SELECT DISTINCT IsExposed FROM #ExposedControlAggResults) agg1
	CROSS JOIN (SELECT DISTINCT CustomerGroup, CustomerGroupMinSpend FROM #ExposedControlAggResults) agg2
	CROSS JOIN (SELECT DISTINCT DDRankByDateGroup FROM #ExposedControlAggResults) agg3
	LEFT JOIN #IronOfferSubSegments agg4
		ON 1 = 1 -- Like a "Left" cross join
	LEFT JOIN (SELECT *, 1 AS IsExposed FROM #Cardholders_E UNION ALL SELECT *, 0 AS IsExposed FROM #Cardholders_C) ch
		ON cal.StartDate = ch.StartDate
		AND cal.EndDate = ch.EndDate
		AND cal.PeriodType = ch.PeriodType
		AND ior.RetailerID = ch.RetailerID
		AND ior.IronOfferID = ch.IronOfferID
		AND agg1.IsExposed = ch.IsExposed
		AND (agg4.SubSegmentID = ch.SubSegmentID OR agg4.SubSegmentID IS NULL AND ch.SubSegmentID IS NULL)
	LEFT JOIN #ExposedControlAggResults r
		ON cal.StartDate = r.StartDate
		AND cal.EndDate = r.EndDate
		AND ior.IronOfferID = r.IronOfferID
		AND agg1.IsExposed = r.IsExposed
		AND agg2.CustomerGroup = r.CustomerGroup
		AND (agg2.CustomerGroupMinSpend = r.CustomerGroupMinSpend OR agg2.CustomerGroupMinSpend IS NULL AND r.CustomerGroupMinSpend IS NULL)
		AND agg3.DDRankByDateGroup = r.DDRankByDateGroup
		AND (agg4.SubSegmentID = r.SubSegmentID OR agg4.SubSegmentID IS NULL AND r.SubSegmentID IS NULL)
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.DirectDebitResults x
		WHERE 
			ior.RetailerID = x.RetailerID
			AND cal.PeriodType = x.PeriodType
			AND cal.StartDate = x.StartDate
			AND cal.EndDate = x.EndDate
			AND CONCAT(ior.IronOfferID, CASE agg4.SubSegmentID WHEN 7 THEN '-Acquire' WHEN 8 THEN '-Lapsed' WHEN 9 THEN '-Shopper' ELSE '' END) = x.IronOfferID
			AND agg1.IsExposed = x.IsExposed
			AND agg2.CustomerGroup = x.CustomerGroup
			AND (agg2.CustomerGroupMinSpend = x.CustomerGroupMinSpend OR agg2.CustomerGroupMinSpend IS NULL AND x.CustomerGroupMinSpend IS NULL)
			AND agg3.DDRankByDateGroup = x.DDRankByDateGroup
			AND @Today2 = x.ReportDate
	)
	AND EXISTS (SELECT 1
				FROM #IterationTable it
				WHERE ior.IronOfferID = it.IronOfferID
				AND cal.StartDate = it.StartDate);

	/******************************************************************************
	Update results to reflect post-throttling exposed counts (ie. full customer base or cap)
	******************************************************************************/

	--UPDATE Warehouse.Staging.DirectDebitResults
	--SET Cardholders = Cardholders + (((2040000 - Cardholders)/1000)*1000) -- Cardholders plus delta from full base. True delta from full base is probably a multiple of 1000, so estimate by dividing by 1000 to get value is 1000s rounded down and then multiply again by 1000
	--WHERE
	--	ReportDate = @Today
	--	AND RetailerID = 4729 -- Sky
	--	AND IsExposed = 1;

	--UPDATE Warehouse.Staging.DirectDebitResults
	--SET Cardholders = Cardholders + (((2303665 - Cardholders)/1000)*1000)
	--WHERE
	--	ReportDate = @Today
	--	AND RetailerID = 4755 -- E.ON
	--	AND IsExposed = 1;

END