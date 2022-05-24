/******************************************************************************
Author: Jason Shipp
Created: 11/06/2018
Purpose: 
	- Load incentivised cardholder and transaction metrics for a retailer for a specified period
	- Results aggregated by retailer, period, Shopper ALS segment and Offer Type
	- Results stored in Warehouse.Staging.FlashTransactionReport_ReportData table

Notes:
	- Stored procedure triggered by the Warehouse.Staging.FlashTransactionReport_Load_Trigger stored procedure
	- Cardholders returned will not match aggregated cardholders in the Monthly report due to:
		- this query taking distinct customers across all channels per offer segment 
		- the Monthly report taking the sum of the max number of cardholders per Iron Offer where the Iron Offers are across all channels without a spend threshold
	
------------------------------------------------------------------------------
Modification History
	
Jason Shipp 25/06/2018
	-- Expanded process to generate results aggregated at daily and weekly periods, as well as cumulative

Jason Shipp 12/07/2018
	-- Expanded process to load cumulative spenders for each retailer in each analysis period

Jason Shipp 18/07/2018
	-- Added code to allow exposed cardholders to be calculated without referring to the CampaignHistory tables (in case the tables are out of date)

Jason Shipp 08/10/2018
	-- Fixed AMEX exposed-count logic: Sum AMEX click counts over non-Universal Iron Offers, or take Universal click count if higher

Jason Shipp 12/10/2018
	-- Used Warehouse.Relational.IronOfferSegment table as source of segment types

Jason Shipp 31/10/2018
	-- Split Warehouse, nFI and AMEX cardholder queries for optimisation

Jason Shipp 16/11/2018
	-- Optimised cardholder logic using CROSS APPLYs, as suggested by Chris

Jason Shipp 05/03/2019
	- Added ability to identify partners by their PartnerID(s)

03/04/2019 Jason Shipp
    - Referenced PublisherID in nFI.Relational.AmexOffer instead of hardcoding -1
	- Revised AMEX cardholder count logic to account for multiple PublisherIDs

12/08/2019 Jason Shipp
	- Ignored AMEX-type ClickCounts of 0

******************************************************************************/
CREATE PROCEDURE Staging.FlashTransactionReport_Load (
	@RetailerNamePartialName varchar(50) -- String identifying retailer to analyse (enough of retailer name to uniquely identify)
	, @PartnerID varchar(MAX) = NULL -- String of PartnerIDs, separated by commas or newlines: use this if partner needs to be specifically identified by its PartnerIDs, otherwise leave NULL
	, @StartDate date = NULL -- Analysis start date (default to retailer minimum offer setup start date per retailer)
	, @EndDate date = NULL -- Analysis end date (default to yesterday or maximum offer setup end date per retailer)
)
	
AS
BEGIN

	SET NOCOUNT ON;

	----For testing
	--DECLARE @RetailerNamePartialName VARCHAR(50) = 'Waitrose'
	--DECLARE @PartnerID varchar(MAX) = NULL
	--DECLARE @StartDate DATE = '2018-05-24'
	--DECLARE @EndDate DATE = NULL

	DECLARE @Today DATE = CAST(GETDATE() AS date);
	SET @PartnerID = REPLACE(REPLACE(@PartnerID, CHAR(13) + CHAR(10), ','), ', ', ',');

	/******************************************************************************
	Load partner alternates
	******************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;

	SELECT DISTINCT * 
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

	/******************************************************************************
	Load IronOfferCycles to analyse
	******************************************************************************/

	IF OBJECT_ID('tempdb..#IronOffer_References') IS NOT NULL DROP TABLE #IronOffer_References;

	-- nFI
	SELECT DISTINCT
		[io].ID AS IronOfferID
		, CAST(
			COALESCE(@StartDate, [io].StartDate) 
		AS DATE) AS StartDate
		, CAST(
			COALESCE(@EndDate, [io].EndDate) 
		AS DATE) AS EndDate
		, CAST([io].StartDate AS date) AS OfferSetupStartDate
		, CAST([io].EndDate AS date) AS OfferSetupEndDate
		, CAST(cyc.StartDate AS date) AS IOCycleStartDate
		, CAST(cyc.EndDate AS date) AS IOCycleEndDate
		, [io].IronOfferName
		, s.SuperSegmentID
		, s.SuperSegmentName
		, s.OfferTypeID
		, s.OfferTypeDescription AS TypeDescription
		, s.OfferTypeForReports
		, COALESCE(pa.AlternatePartnerID, [io].PartnerID) AS PartnerID
		, p.PartnerName
		, ior.ClubID
		, 0 AS IsWarehouse
		, ioc.offercyclesid AS OfferCyclesID
		, ior.ironoffercyclesid AS IronOfferCyclesID
		, 'Cumulative' AS PeriodType
	INTO #IronOffer_References
	FROM nFI.Relational.IronOffer_References ior
	LEFT JOIN nFI.Relational.IronOffer [io]
		ON ior.IronOfferID = [io].ID
	INNER JOIN nFI.Relational.ironoffercycles ioc
		ON ior.ironoffercyclesid = ioc.ironoffercyclesid
	INNER JOIN nFI.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	LEFT JOIN #PartnerAlternate pa
		ON [io].PartnerID = pa.PartnerID
	LEFT JOIN nFI.Relational.[Partner] p
		ON COALESCE(pa.AlternatePartnerID, [io].PartnerID) = p.PartnerID
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON ior.IronOfferID = s.IronOfferID
	WHERE 
		[io].IsSignedOff = 1
		AND [io].IronOfferName NOT LIKE '%Spare%'
		AND p.PartnerName LIKE '%' + @RetailerNamePartialName + '%'
		AND (@PartnerID IS NULL OR CHARINDEX(',' + CAST(p.PartnerID AS varchar) + ',', ',' + @PartnerID + ',') > 0)
		AND ( -- Offers overlapping analysis period
			([io].StartDate <= @EndDate OR @EndDate IS NULL)
			AND ([io].EndDate >= @StartDate OR [io].EndDate IS NULL OR @StartDate IS NULL)
		)
		AND ( -- Offer cycles overlapping analysis period
			(cyc.StartDate <= @EndDate OR @EndDate IS NULL)
			AND (cyc.EndDate >= @StartDate OR @StartDate IS NULL)
		)

	UNION

	-- Warehouse
	SELECT DISTINCT
		[io].IronOfferID
		, CAST(
			COALESCE(@StartDate, [io].StartDate) 
		AS DATE) AS StartDate
		, CAST(
			COALESCE(@EndDate, [io].EndDate) 
		AS DATE) AS EndDate
		, CAST([io].StartDate AS date) AS OfferSetupStartDate
		, CAST([io].EndDate AS date) AS OfferSetupEndDate
		, CAST(cyc.StartDate AS date) AS IOCycleStartDate
		, CAST(cyc.EndDate AS date) AS IOCycleEndDate
		, ISNULL(CASE WHEN CHARINDEX('/', [io].IronOfferName) > 0 THEN 
		  CASE WHEN [io].PartnerID = 3730 THEN
			 REPLACE(
				RIGHT([io].IronOfferName, CHARINDEX('/', REVERSE([io].IronOfferName), CHARINDEX('/', REVERSE([io].IronOfferName))+1)-1)
				, '/', '-') 
		  WHEN [io].PartnerID <> 3730 THEN
			 REPLACE(
				RIGHT([io].IronOfferName, CHARINDEX('/', REVERSE(io.IronOfferName)))
				, '/', '') 
		  ELSE [io].IronOfferName 
		  END
		END, [io].IronOfferName) AS IronOfferName
		, s.SuperSegmentID
		, s.SuperSegmentName
		, s.OfferTypeID
		, s.OfferTypeDescription AS TypeDescription
		, s.OfferTypeForReports
		, COALESCE(pa.AlternatePartnerID, [io].PartnerID) AS PartnerID
		, p.PartnerName
		, ior.ClubID
		, 1 AS IsWarehouse
		, ioc.offercyclesid AS OfferCyclesID
		, ior.ironoffercyclesid AS IronOfferCyclesID
		, 'Cumulative' AS PeriodType
	FROM Warehouse.Relational.IronOffer_References ior
	LEFT JOIN Warehouse.Relational.IronOffer [io]
		ON ior.IronOfferID = [io].IronOfferID
	INNER JOIN Warehouse.Relational.ironoffercycles ioc
		ON ior.ironoffercyclesid = ioc.ironoffercyclesid
	INNER JOIN Warehouse.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	LEFT JOIN #PartnerAlternate pa
		ON [io].PartnerID = pa.PartnerID
	LEFT JOIN Warehouse.Relational.[Partner] p
		ON COALESCE(pa.AlternatePartnerID, [io].PartnerID) = p.PartnerID
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON ior.IronOfferID = s.IronOfferID
	WHERE 
		[io].IsSignedOff = 1
		AND [io].IronOfferName NOT LIKE '%Spare%'
		AND p.PartnerName LIKE '%' + @RetailerNamePartialName + '%'
		AND (@PartnerID IS NULL OR CHARINDEX(',' + CAST(p.PartnerID AS varchar) + ',', ',' + @PartnerID + ',') > 0)
		AND ( -- Offers overlapping analysis period
			([io].StartDate <= @EndDate OR @EndDate IS NULL)
			AND ([io].EndDate >= @StartDate OR [io].EndDate IS NULL OR @StartDate IS NULL)
		)
		AND ( -- Offer cycles overlapping analysis period
			(cyc.StartDate <= @EndDate OR @EndDate IS NULL)
			AND (cyc.EndDate >= @StartDate OR @StartDate IS NULL)
		)

	UNION

	-- AMEX
	SELECT DISTINCT
		[io].IronOfferID
		, CAST(
			COALESCE(@StartDate, [io].StartDate) 
		AS DATE) AS StartDate
		, CAST(
			COALESCE(@EndDate, [io].EndDate) 
		AS DATE) AS EndDate
		, CAST([io].StartDate AS date) AS OfferSetupStartDate
		, CAST([io].EndDate AS date) AS OfferSetupEndDate
		, CAST(cyc.StartDate AS date) AS IOCycleStartDate
		, CAST(cyc.EndDate AS date) AS IOCycleEndDate
		, [io].TargetAudience AS IronOfferName
		, s.SuperSegmentID
		, s.SuperSegmentName
		, s.OfferTypeID
		, s.OfferTypeDescription AS TypeDescription
		, s.OfferTypeForReports
		, COALESCE(pa.AlternatePartnerID, [io].RetailerID) AS PartnerID
		, p.PartnerName
		, [io].PublisherID AS ClubID -- Jason Shipp 03/04/2019
		, NULL AS IsWarehouse
		, ioc.offercyclesid AS OfferCyclesID
		, NULL AS IronOfferCyclesID
		, 'Cumulative' AS PeriodType
	FROM nFI.Relational.AmexOffer [io]
	INNER JOIN nFI.Relational.AmexIronOfferCycles ioc
		ON [io].IronOfferID = ioc.AmexIronOfferID
	INNER JOIN nFI.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	LEFT JOIN #PartnerAlternate pa
		ON [io].RetailerID = pa.PartnerID
	LEFT JOIN nFI.Relational.[Partner] p
		ON COALESCE(pa.AlternatePartnerID, [io].RetailerID) = p.PartnerID
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON [io].IronOfferID = s.IronOfferID
	WHERE 
		p.PartnerName LIKE '%' + @RetailerNamePartialName + '%'
		AND (@PartnerID IS NULL OR CHARINDEX(',' + CAST(p.PartnerID AS varchar) + ',', ',' + @PartnerID + ',') > 0)
		AND ( -- Offers overlapping analysis period
			([io].StartDate <= @EndDate OR @EndDate IS NULL)
			AND ([io].EndDate >= @StartDate OR [io].EndDate IS NULL OR @StartDate IS NULL)
		)
		AND ( -- Offer cycles overlapping analysis period
			(cyc.StartDate <= @EndDate OR @EndDate IS NULL)
			AND (cyc.EndDate >= @StartDate OR @StartDate IS NULL)
		);

	-- Update analysis start and end dates so one set of dates exists per retailer

	WITH dates AS (
		SELECT 
			ior.PartnerID
			, MIN(ior.StartDate) AS StartDate
			, MAX(
				CASE WHEN ior.EndDate IS NULL OR ior.EndDate > CAST(DATEADD(DAY, -1, @Today) AS DATE)
				THEN CAST(DATEADD(DAY, -1, @Today) AS DATE)
				ELSE ior.EndDate
				END
			) AS EndDate			
		FROM #IronOffer_References ior
		GROUP BY
			ior.PartnerID
	)
	UPDATE ior
	SET
		ior.StartDate = dates.StartDate 
		, ior.EndDate = dates.EndDate
	FROM #IronOffer_References ior
	INNER JOIN dates 
		ON ior.PartnerID = dates.PartnerID;

	/******************************************************************************
	Load calendar table containing daily and weekly start and end dates within the analysis period
	******************************************************************************/

	SET DATEFIRST 1; -- Set Monday as the first day of the week

	DECLARE @MinStartDate date = (SELECT MIN(StartDate) FROM #IronOffer_References);
	DECLARE @MaxEndDate date = (SELECT MAX(EndDate) FROM #IronOffer_References);
	--DECLARE @DaysToReport int = 7;
	--DECLARE @CompleteWeeksToReport int = 3;

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;
	
	WITH 
       E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n))
       , E2 AS (SELECT n = 0 FROM E1 a CROSS JOIN E1 b)
       , Tally AS (SELECT n = 0 UNION ALL SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E2 a CROSS JOIN E2 b) -- Create table of numbers
	   , TallyDates AS (SELECT n, CalDate = DATEADD(day, n, @MinStartDate) FROM Tally WHERE DATEADD(day, n, @MinStartDate) <= @MaxEndDate) -- Create table of consecutive dates
	
	SELECT
		c.CalDate AS StartDate
		, c.CalDate AS EndDate
		, 'Daily' AS PeriodType
	INTO #Calendar
	FROM TallyDates c
	--WHERE 
	--	c.CalDate >= DATEADD(day, -(@DaysToReport-1), @MaxEndDate)
		
	UNION ALL

	SELECT 
		StartDate
		, EndDate
		, PeriodType
	FROM (
		SELECT DISTINCT
			CASE 
				WHEN DATEADD(dd, -(DATEPART(dw, CalDate)-1), CalDate) < @MinStartDate
				THEN @MinStartDate -- Don't let StartDate go before analysis start date
				ELSE DATEADD(dd, -(DATEPART(dw, CalDate)-1), CalDate) 
			END	AS StartDate -- For each calendar date in #Dates, minus days since the most recent Monday  
			, DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate) AS EndDate -- For each calendar date in #Dates, minus days since the most recent Sunday
			, 'Weekly' AS PeriodType
		FROM TallyDates
		WHERE
			DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate) <= CalDate -- Only complete weeks
		--UNION -- Load most recent week (may be partial); don't use UNION ALL to avoid duplication
		--SELECT (DATEADD( -- 
		--	day
		--	, -(DATEPART(dw, DATEADD(day, -1, @Today)))+1
		--	, DATEADD(day, -1, @Today))
		--) AS StartDate
		--, DATEADD(day, -1, @Today) AS EndDate
		--, 'Weekly' AS PeriodType
	) x
	--WHERE 
	--EndDate >= DATEADD(
	--	week
	--	, -(@CompleteWeeksToReport-1)
	--	, (SELECT DATEADD( -- Most recent Sunday
	--		day
	--		, -(DATEPART(dw, @Today))
	--		, @Today)
	--	)
	--);

	/******************************************************************************
	Load IronOfferCycles to analyse, expanded to include daily, weekly and cumulative analysis periods not analysed before
	******************************************************************************/

	IF OBJECT_ID('tempdb..#IronOffer_References_Expanded') IS NOT NULL DROP TABLE #IronOffer_References_Expanded;
	
	-- Cumulative periods
	SELECT
		d.IronOfferID
		, d.StartDate
		, d.EndDate
		, d.OfferSetupStartDate
		, d.OfferSetupEndDate
		, d.IOCycleStartDate
		, d.IOCycleEndDate
		, d.IronOfferName
		, d.SuperSegmentID
		, d.SuperSegmentName
		, d.OfferTypeID
		, d.TypeDescription
		, d.OfferTypeForReports
		, d.PartnerID
		, d.PartnerName
		, d.ClubID
		, d.IsWarehouse
		, d.OfferCyclesID
		, d.IronOfferCyclesID
		, d.PeriodType
	INTO #IronOffer_References_Expanded
	FROM #IronOffer_References d
		
	UNION ALL
	
	-- Daily and weekly periods
	SELECT
		d.IronOfferID
		, cal.StartDate
		, cal.EndDate
		, d.OfferSetupStartDate
		, d.OfferSetupEndDate
		, d.IOCycleStartDate
		, d.IOCycleEndDate
		, d.IronOfferName
		, d.SuperSegmentID
		, d.SuperSegmentName
		, d.OfferTypeID
		, d.TypeDescription
		, d.OfferTypeForReports
		, d.PartnerID
		, d.PartnerName
		, d.ClubID
		, d.IsWarehouse
		, d.OfferCyclesID
		, d.IronOfferCyclesID
		, cal.PeriodType
	FROM #IronOffer_References d
	INNER JOIN #Calendar cal -- Expand table to include all analysis periods in calendar table
		ON cal.StartDate >= d.StartDate
		AND cal.EndDate <= d.EndDate
		AND d.IOCycleStartDate <= cal.EndDate -- Offer cycles overlapping analysis periods
		AND d.IOCycleEndDate >= cal.StartDate;

	CREATE NONCLUSTERED INDEX NIX_IronOffer_References_Expanded ON #IronOffer_References_Expanded (IronOfferCyclesID, IsWarehouse, IronOfferID, StartDate, EndDate);

	/******************************************************************************
	Load distinct Iron Offers to analyse 
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Offer_References') IS NOT NULL DROP TABLE #Offer_References;

	-- Cumulative periods
	SELECT DISTINCT
		ior.IronOfferID
		, ior.StartDate
		, ior.EndDate
		, ior.OfferSetupStartDate
		, ior.OfferSetupEndDate
		, ior.IronOfferName
		, ior.SuperSegmentID
		, ior.SuperSegmentName
		, ior.OfferTypeID
		, ior.TypeDescription
		, ior.OfferTypeForReports
		, ior.PartnerID
		, ior.PartnerName
		, ior.ClubID
		, ior.PeriodType
	INTO #Offer_References
	FROM #IronOffer_References ior
			
	UNION ALL

	-- Daily and weekly periods
	SELECT DISTINCT
		ior.IronOfferID
		, cal.StartDate
		, cal.EndDate
		, ior.OfferSetupStartDate
		, ior.OfferSetupEndDate
		, ior.IronOfferName
		, ior.SuperSegmentID
		, ior.SuperSegmentName
		, ior.OfferTypeID
		, ior.TypeDescription
		, ior.OfferTypeForReports
		, ior.PartnerID
		, ior.PartnerName
		, ior.ClubID
		, cal.PeriodType
	FROM #IronOffer_References ior
	INNER JOIN #Calendar cal -- Expand table to include all analysis periods in calendar table
		ON cal.StartDate >= ior.StartDate
		AND cal.EndDate <= ior.EndDate;

	CREATE NONCLUSTERED INDEX NIX_Offer_References ON #Offer_References (IronOfferID, StartDate, EndDate);

	/******************************************************************************
	Load aggregated transaction data
	******************************************************************************/

	IF OBJECT_ID('tempdb..#TransactionsAgg') IS NOT NULL DROP TABLE #TransactionsAgg;

	SELECT
		x.PartnerID
		, x.PartnerName
		, x.StartDate
		, x.EndDate
		, x.PeriodType
		, x.SuperSegmentID
		, x.SuperSegmentName
		, x.OfferTypeID
		, x.TypeDescription
		, x.OfferTypeForReports
		, SUM(x.Sales) AS Sales
		, SUM(x.Spenders) AS Spenders
		, SUM(x.Transactions) AS Transactions
		, SUM(x.Investment) AS Investment
	INTO #TransactionsAgg
	FROM (
		SELECT
			ior.PartnerID
			, ior.PartnerName
			, ior.StartDate
			, ior.EndDate
			, ior.PeriodType
			, ior.SuperSegmentID
			, ior.SuperSegmentName
			, ior.OfferTypeID
			, ior.TypeDescription
			, ior.OfferTypeForReports
			, SUM(st.Spend) AS Sales
			, COUNT(DISTINCT(st.FanID)) AS Spenders
			, COUNT(st.FanID) AS Transactions
			, SUM(st.Investment) AS Investment
		FROM #Offer_References ior
		LEFT JOIN Warehouse.APW.SchemeTrans_Pipe st
			ON ior.IronOfferID = st.IronOfferID
			AND ior.PartnerID = st.RetailerID
			AND st.TranDate BETWEEN ior.StartDate AND ior.EndDate 
		WHERE
			st.IsRetailerReport = 1
			--AND (st.IsSpendStretch IS NULL OR st.IsSpendStretch = 1) -- Only include above SpendStretch trans if a SpendStretch exists
		GROUP BY
			ior.PartnerID
			, ior.PartnerName
			, ior.StartDate
			, ior.EndDate
			, ior.PeriodType
			, ior.SuperSegmentID
			, ior.SuperSegmentName
			, ior.OfferTypeID
			, ior.TypeDescription
			, ior.OfferTypeForReports
		--UNION ALL -- Add union here to AMEX's transaction bespoke data feed 
	) x
	GROUP BY
		x.PartnerID
		, x.PartnerName
		, x.StartDate
		, x.EndDate
		, x.PeriodType
		, x.SuperSegmentID
		, x.SuperSegmentName
		, x.OfferTypeID
		, x.TypeDescription
		, x.OfferTypeForReports;

	/******************************************************************************
	Load Warehouse CampaignHistory
	******************************************************************************/

	---- Declare iteration variables

	--DECLARE @IOCID int;
	--DECLARE @RowNum int;
	--DECLARE @RowNumMax int;

	---- Load table for iterating over Warehouse IronOfferCyclesIDs

	--IF OBJECT_ID('tempdb..#IronOfferCyclesIDs_Warehouse') IS NOT NULL DROP TABLE #IronOfferCyclesIDs_Warehouse;

	--SELECT 
	--	ironoffercyclesid 
	--	, ROW_NUMBER() OVER (ORDER BY ironoffercyclesid ) AS RowNum
	--	INTO #IronOfferCyclesIDs_Warehouse
	--FROM (
	--	SELECT DISTINCT
	--	ironoffercyclesid 
	--	FROM #IronOffer_References_Expanded
	--	WHERE IsWarehouse = 1
	--) x;

	---- Load table to hold results

	--IF OBJECT_ID('tempdb..#CampaignHistoryWarehouse') IS NOT NULL DROP TABLE #CampaignHistoryWarehouse;

	--CREATE TABLE #CampaignHistoryWarehouse (
	--	ironoffercyclesid int NOT NULL
	--	, FanID int NOT NULL
	--	, CONSTRAINT PK_CampaignHistoryWarehouse PRIMARY KEY CLUSTERED (ironoffercyclesid, FanID)
	--);

	---- Do loop

	--SET @RowNum = 1;
	--SET @RowNumMax = (SELECT MAX(RowNum) FROM #CampaignHistoryWarehouse); 
	
	--While @RowNum <= @RowNumMax
	
	--Begin

	--	SET @IOCID = (SELECT ironoffercyclesid FROM #IronOfferCyclesIDs_Warehouse WHERE RowNum = @RowNum);

	--	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer;
	
	--	SELECT 
	--		ioc.ironoffercyclesid
	--		, ioc.ironofferid
	--		, c.FanID
	--		, c.compositeid
	--		, oc.StartDate
	--		, oc.EndDate
	--	INTO #Customer
	--	FROM Warehouse.relational.ironoffercycles ioc
	--	INNER JOIN Warehouse.Relational.offercycles oc
	--		ON ioc.OfferCyclesID = oc.OfferCyclesID
	--	INNER JOIN Warehouse.relational.Customer c
	--		ON (c.DeactivatedDate > oc.StartDate or c.DeactivatedDate is null)
	--	WHERE
	--		ioc.ironoffercyclesid = @IOCID;

	--	If object_id('tempdb..#CampaignHistoryStaging') is not null drop table #CampaignHistoryStaging;

	--	-- Intermediate table saves on non-indexed customer lookups when joining to slc_report.dbo.IronOfferMember
	--	SELECT DISTINCT
	--		c2.ironoffercyclesid
	--		, c2.FanID
	--	INTO #CampaignHistoryStaging
	--	FROM #Customer c2
	--	INNER JOIN slc_report.dbo.IronOfferMember iom
	--		ON iom.IronOfferID = c2.ironofferid 
	--		AND iom.CompositeID = c2.compositeid
	--		AND iom.StartDate <= c2.EndDate
	--		AND (iom.EndDate >= c2.StartDate or iom.EndDate is null);

	--	-- Writing to final table is more efficient from a temp table	
	--	INSERT INTO #CampaignHistoryWarehouse
	--	SELECT
	--		c3.ironoffercyclesid
	--		, c3.FanID
	--	FROM #CampaignHistoryStaging c3;

	--	SET @RowNum = @RowNum + 1

	--END 

	/******************************************************************************
	Load nFI CampaignHistory
	******************************************************************************/

	---- Load table for iterating over nFI IronOfferCyclesIDs

	--IF OBJECT_ID('tempdb..#IronOfferCyclesIDs_nFI') IS NOT NULL DROP TABLE #IronOfferCyclesIDs_nFI;

	--SELECT 
	--	ironoffercyclesid 
	--	, ROW_NUMBER() OVER (ORDER BY ironoffercyclesid ) AS RowNum
	--	INTO #IronOfferCyclesIDs_nFI
	--FROM (
	--	SELECT DISTINCT
	--	ironoffercyclesid 
	--	FROM #IronOffer_References_Expanded
	--	WHERE IsWarehouse = 0
	--) x;

	---- Load table to hold results

	--IF OBJECT_ID('tempdb..#CampaignHistorynFI') IS NOT NULL DROP TABLE #CampaignHistorynFI;

	--CREATE TABLE #CampaignHistorynFI (
	--	ironoffercyclesid int NOT NULL
	--	, FanID int NOT NULL
	--	, CONSTRAINT PK_CampaignHistorynFI PRIMARY KEY CLUSTERED (ironoffercyclesid, FanID)
	--);

	---- Do loop

	--SET @RowNum = 1;
	--SET @RowNumMax = (SELECT MAX(RowNum) FROM #CampaignHistorynFI); 
	
	--While @RowNum <= @RowNumMax
	
	--Begin

	--	SET @IOCID = (SELECT ironoffercyclesid FROM #IronOfferCyclesIDs_nFI WHERE RowNum = @RowNum)

	--	IF OBJECT_ID('tempdb..#CampaignHistoryStaging2') IS NOT NULL DROP TABLE #CampaignHistoryStaging2;
		
	--	SELECT DISTINCT
	--		ioc.ironoffercyclesid
	--		,f.ID as FanID
	--	INTO #CampaignHistoryStaging2
	--	FROM nFI.relational.ironoffercycles ioc
	--	INNER JOIN slc_report.dbo.IronOfferMember iom
	--		ON ioc.ironofferid = iom.IronOfferID
	--	INNER JOIN slc_report.dbo.Fan f
	--		ON iom.CompositeID = f.compositeid
	--	INNER JOIN nfi.relational.offercycles as oc
	--		ON ioc.OfferCyclesID = oc.OfferCyclesID
	--	WHERE 
	--		ironoffercyclesid = @IOCID
	--		AND iom.StartDate <= oc.EndDate
	--		AND (iom.EndDate >= oc.StartDate or iom.EndDate is null);
			
	--	INSERT INTO #CampaignHistorynFI
	--	SELECT
	--		s.ironoffercyclesid
	--		, s.FanID
	--	FROM #CampaignHistoryStaging2 s;

	--	SET @RowNum = @RowNum + 1;

	--END 
	
	/******************************************************************************
	Load exposed cardholders
	******************************************************************************/

	-- Create table for storing results

	IF OBJECT_ID('tempdb..#Cardholders_Setup') IS NOT NULL DROP TABLE #Cardholders_Setup;

	CREATE TABLE #Cardholders_Setup (
		PartnerID int
		, PartnerName varchar(100)
		, StartDate date
		, EndDate date
		, PeriodType varchar(25)
		, SuperSegmentID int
		, SuperSegmentName varchar(40)
		, OfferTypeID int
		, TypeDescription varchar(25)
		, OfferTypeForReports varchar(100)
		, Cardholders int
	);

	/*********************
	Warehouse exposed
	**********************/

	-- Load #IronOffer_References_Expanded with a grouping ID indicating the final group each row will belong to in the final results table

	IF OBJECT_ID('tempdb..#iorExpandedGrouper_Warehouse') IS NOT NULL DROP TABLE #iorExpandedGrouper_Warehouse;

	SELECT 
		grouper = DENSE_RANK() OVER(ORDER BY o.PartnerID, o.PartnerName, o.OfferTypeID, o.TypeDescription, o.PeriodType, o.StartDate, o.EndDate, o.SuperSegmentID, o.SuperSegmentName, o.OfferTypeForReports)
		, o.PartnerID
		, o.PartnerName
		, o.OfferTypeID
		, o.TypeDescription
		, o.PeriodType
		, o.StartDate
		, o.EndDate
		, o.SuperSegmentID
		, o.SuperSegmentName
		, o.OfferTypeForReports
		, o.IronOfferCyclesID 
	INTO #iorExpandedGrouper_Warehouse
	FROM #IronOffer_References_Expanded o
	WHERE 
		o.IsWarehouse = 1;

	CREATE CLUSTERED INDEX cx_Stuff ON #iorExpandedGrouper_Warehouse (IronOfferCyclesID);

	INSERT INTO #Cardholders_Setup (
		PartnerID
		, PartnerName
		, StartDate
		, EndDate
		, PeriodType
		, SuperSegmentID
		, SuperSegmentName
		, OfferTypeID
		, TypeDescription
		, OfferTypeForReports
		, Cardholders
	)
	SELECT -- Load grouping columns
		o.PartnerID
		, o.PartnerName
		, o.StartDate
		, o.EndDate
		, o.PeriodType
		, o.SuperSegmentID
		, o.SuperSegmentName
		, o.OfferTypeID
		, o.TypeDescription
		, o.OfferTypeForReports
		, x.Cardholders -- Attach grouping columns to cardholders
	FROM (
		   SELECT DISTINCT grouper, PartnerID, PartnerName, OfferTypeID, TypeDescription, PeriodType, StartDate, EndDate, SuperSegmentID, SuperSegmentName, OfferTypeForReports
		   FROM #iorExpandedGrouper_Warehouse -- Grouping columns
	) o
	CROSS APPLY ( -- For each row in final results table, get distinct FanID counts
		SELECT Cardholders = COUNT(*)
		FROM (
			SELECT ix.FanID -- Get distinct FanIDs with the same grouping ID
			FROM #iorExpandedGrouper_Warehouse ior
			CROSS APPLY ( -- Fow each row in #iorExpandedGrouper, get FanIDs
				SELECT FanID FROM Warehouse.Relational.CampaignHistory ch 
				WHERE ch.ironoffercyclesid = ior.IronOfferCyclesID 
				UNION ALL
				SELECT FanID FROM Warehouse.Relational.CampaignHistory_Archive cha 
				WHERE cha.ironoffercyclesid = ior.IronOfferCyclesID
			) ix -- Load FanIDs. Match condition: matching IronOfferCyclesIDs
		WHERE ior.grouper = o.grouper 
		GROUP BY ix.FanID
		) d
	) x; -- Load distinct FanIDs. Match condition: matching grouping IDs
	
	/*********************
	nFI exposed
	**********************/

	-- Load #IronOffer_References_Expanded with a grouping ID indicating the final group each row will belong to in the final results table

	IF OBJECT_ID('tempdb..#iorExpandedGrouper_nFI') IS NOT NULL DROP TABLE #iorExpandedGrouper_nFI;

	SELECT 
		grouper = DENSE_RANK() OVER(ORDER BY o.PartnerID, o.PartnerName, o.OfferTypeID, o.TypeDescription, o.PeriodType, o.StartDate, o.EndDate, o.SuperSegmentID, o.SuperSegmentName, o.OfferTypeForReports)
		, o.PartnerID
		, o.PartnerName
		, o.OfferTypeID
		, o.TypeDescription
		, o.PeriodType
		, o.StartDate
		, o.EndDate
		, o.SuperSegmentID
		, o.SuperSegmentName
		, o.OfferTypeForReports
		, o.IronOfferCyclesID 
	INTO #iorExpandedGrouper_nFI
	FROM #IronOffer_References_Expanded o
	WHERE 
		o.IsWarehouse = 0;

	CREATE CLUSTERED INDEX cx_Stuff ON #iorExpandedGrouper_nFI (IronOfferCyclesID);

	INSERT INTO #Cardholders_Setup (
		PartnerID
		, PartnerName
		, StartDate
		, EndDate
		, PeriodType
		, SuperSegmentID
		, SuperSegmentName
		, OfferTypeID
		, TypeDescription
		, OfferTypeForReports
		, Cardholders
	)
	SELECT -- Load grouping columns
		o.PartnerID
		, o.PartnerName
		, o.StartDate
		, o.EndDate
		, o.PeriodType
		, o.SuperSegmentID
		, o.SuperSegmentName
		, o.OfferTypeID
		, o.TypeDescription
		, o.OfferTypeForReports
		, x.Cardholders -- Attach grouping columns to cardholders
	FROM (
		   SELECT DISTINCT grouper, PartnerID, PartnerName, OfferTypeID, TypeDescription, PeriodType, StartDate, EndDate, SuperSegmentID, SuperSegmentName, OfferTypeForReports
		   FROM #iorExpandedGrouper_nFI -- Grouping columns
	) o
	CROSS APPLY ( -- For each row in final results table, get distinct FanID counts
		SELECT Cardholders = COUNT(*)
		FROM (
			SELECT ix.FanID -- Get distinct FanIDs with the same grouping ID
			FROM #iorExpandedGrouper_nFI ior
			CROSS APPLY ( -- Fow each row in #iorExpandedGrouper, get FanIDs
				SELECT FanID FROM nFI.Relational.CampaignHistory ch 
				WHERE ch.ironoffercyclesid = ior.IronOfferCyclesID 
			) ix -- Load FanIDs. Match condition: matching IronOfferCyclesIDs
		WHERE ior.grouper = o.grouper 
		GROUP BY ix.FanID
		) d
	) x; -- Load distinct FanIDs. Match condition: matching grouping IDs

	/*********************
	Max AMEX exposed (=clicks)
	**********************/

	INSERT INTO #Cardholders_Setup (
		PartnerID
		, PartnerName
		, StartDate
		, EndDate
		, PeriodType
		, SuperSegmentID
		, SuperSegmentName
		, OfferTypeID
		, TypeDescription
		, OfferTypeForReports
		, Cardholders
	)
	SELECT 
		y.PartnerID
		, y.PartnerName
		, y.StartDate
		, y.EndDate
		, y.PeriodType
		, y.SuperSegmentID
		, y.SuperSegmentName
		, y.OfferTypeID
		, y.TypeDescription
		, y.OfferTypeForReports
		, MAX(y.Cardholders) AS Cardholders
	FROM (
		SELECT -- AMEX Non-Universal
			c.PartnerID
			, c.PartnerName
			, c.StartDate
			, c.EndDate
			, c.PeriodType
			, c.SuperSegmentID
			, c.SuperSegmentName
			, c.OfferTypeID
			, c.TypeDescription
			, c.OfferTypeForReports
			, SUM(c.ClickCounts) AS Cardholders
		FROM (
			SELECT DISTINCT 
				ior.PartnerID
				, ior.PartnerName
				, ior.IronOfferID
				, ior.StartDate
				, ior.EndDate
				, ior.PeriodType
				, ior.SuperSegmentID
				, ior.SuperSegmentName
				, ior.OfferTypeID
				, ior.TypeDescription
				, ior.OfferTypeForReports
				, ame.ClickCounts
				, ROW_NUMBER() OVER (PARTITION BY ior.IronOfferID, ior.OfferSetupStartDate, ior.OfferSetupEndDate ORDER BY DATEDIFF(day, ame.ReceivedDate, ior.EndDate) ASC) DateRank
			FROM #IronOffer_References_Expanded ior
			INNER JOIN nFI.Relational.AmexOffer ao
				ON ior.IronOfferID = ao.IronOfferID
			INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
				ON ior.IronOfferID = ame.IronOfferID
				AND DATEADD(day, 1, ame.ReceivedDate) <= ior.OfferSetupEndDate				
			WHERE 
				ao.SegmentID <> 0
				AND ao.SegmentID IS NOT NULL
				AND ame.ClickCounts >0
		) c
		WHERE c.DateRank = 1
		GROUP BY
			c.PartnerID
			, c.PartnerName
			, c.StartDate
			, c.EndDate
			, c.PeriodType
			, c.SuperSegmentID
			, c.SuperSegmentName
			, c.OfferTypeID
			, c.TypeDescription
			, c.OfferTypeForReports
		UNION ALL
		SELECT -- AMEX Universal
			z.PartnerID
			, z.PartnerName
			, z.StartDate
			, z.EndDate
			, z.PeriodType
			, z.SuperSegmentID
			, z.SuperSegmentName
			, z.OfferTypeID
			, z.TypeDescription
			, z.OfferTypeForReports
			, SUM(z.Cardholders) AS Cardholders -- Sum over publishers
		FROM (
			SELECT
				c.PublisherID
				, c.PartnerID
				, c.PartnerName
				, c.StartDate
				, c.EndDate
				, c.PeriodType
				, c.SuperSegmentID
				, c.SuperSegmentName
				, c.OfferTypeID
				, c.TypeDescription
				, c.OfferTypeForReports
				, MAX(c.ClickCounts) AS Cardholders -- Max per partner-publisher
			FROM (
				SELECT DISTINCT
					ao.PublisherID
					, ior.PartnerID
					, ior.PartnerName
					, ior.IronOfferID
					, ior.StartDate
					, ior.EndDate
					, ior.PeriodType
					, ior.SuperSegmentID
					, ior.SuperSegmentName
					, ior.OfferTypeID
					, ior.TypeDescription
					, ior.OfferTypeForReports
					, ame.ClickCounts
					, ROW_NUMBER() OVER (PARTITION BY ior.IronOfferID, ior.OfferSetupStartDate, ior.OfferSetupEndDate ORDER BY DATEDIFF(day, ame.ReceivedDate, ior.EndDate) ASC) DateRank
				FROM #IronOffer_References_Expanded ior
				INNER JOIN nFI.Relational.AmexOffer ao
					ON ior.IronOfferID = ao.IronOfferID
				INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
					ON ior.IronOfferID = ame.IronOfferID
					AND DATEADD(day, 1, ame.ReceivedDate) <= ior.OfferSetupEndDate
				WHERE 
					(ao.SegmentID = 0 OR ao.SegmentID IS NULL)
					AND ame.ClickCounts >0
			) c
			WHERE c.DateRank = 1
			GROUP BY
				c.PublisherID
				, c.PartnerID
				, c.PartnerName
				, c.StartDate
				, c.EndDate
				, c.PeriodType
				, c.SuperSegmentID
				, c.SuperSegmentName
				, c.OfferTypeID
				, c.TypeDescription
				, c.OfferTypeForReports
		) z
		GROUP BY
			z.PartnerID
			, z.PartnerName
			, z.StartDate
			, z.EndDate
			, z.PeriodType
			, z.SuperSegmentID
			, z.SuperSegmentName
			, z.OfferTypeID
			, z.TypeDescription
			, z.OfferTypeForReports			
	) y
	GROUP BY
		y.PartnerID
		, y.PartnerName
		, y.StartDate
		, y.EndDate
		, y.PeriodType
		, y.SuperSegmentID
		, y.SuperSegmentName
		, y.OfferTypeID
		, y.TypeDescription
		, y.OfferTypeForReports;

	IF OBJECT_ID('tempdb..#Cardholders') IS NOT NULL DROP TABLE #Cardholders;

	SELECT 
		x.PartnerID
		, x.PartnerName
		, x.StartDate
		, x.EndDate
		, x.PeriodType
		, x.SuperSegmentID
		, x.SuperSegmentName
		, x.OfferTypeID
		, x.TypeDescription
		, x.OfferTypeForReports
		, SUM(x.Cardholders) AS Cardholders
	INTO #Cardholders
	FROM #Cardholders_Setup x				
	GROUP BY
		x.PartnerID
		, x.PartnerName
		, x.StartDate
		, x.EndDate
		, x.PeriodType
		, x.SuperSegmentID
		, x.SuperSegmentName
		, x.OfferTypeID
		, x.TypeDescription
		, x.OfferTypeForReports;

	/******************************************************************************
	Load merged transaction and Cardholder data and expand metrics
	******************************************************************************/

	IF OBJECT_ID('tempdb..#MergedResults') IS NOT NULL DROP TABLE #MergedResults;

	SELECT 
		t.PartnerID
		, t.PartnerName
		, t.StartDate
		, t.EndDate
		, t.PeriodType
		, t.SuperSegmentID
		, t.SuperSegmentName
		, t.OfferTypeID
		, t.TypeDescription
		, t.OfferTypeForReports
		, c.Cardholders
		, t.Sales
		, t.Spenders
		, t.Transactions
		, t.Investment
		, CAST(t.Sales AS float)/NULLIF(t.Transactions, 0) AS ATV
		, CAST(t.Transactions AS float)/NULLIF(t.Spenders, 0) AS ATF
		, CAST(t.Spenders AS float)/NULLIF(c.Cardholders, 0) AS RR
		, CAST(t.Sales AS float)/NULLIF(t.Spenders, 0) AS SPS
		, CAST(t.Sales AS float)/NULLIF(t.Investment, 0) AS SalesToCostRatio
	INTO #MergedResults
	FROM #TransactionsAgg t
	LEFT JOIN #Cardholders c
		ON t.PartnerID = c.PartnerID
		AND t.StartDate = c.StartDate
		AND t.PeriodType = c.PeriodType
		AND t.EndDate = c.EndDate
		AND (t.SuperSegmentID = c.SuperSegmentID OR t.SuperSegmentID IS NULL AND c.SuperSegmentID IS NULL)
		AND (t.OfferTypeID = c.OfferTypeID OR t.OfferTypeID IS NULL AND c.OfferTypeID IS NULL)
		AND (t.OfferTypeForReports = c.OfferTypeForReports OR t.OfferTypeForReports IS NULL AND c.OfferTypeForReports IS NULL);

	/******************************************************************************
	Load new results into Warehouse.Staging.FlashTransactionReport_ReportData

	-- Create table for storing results:

	CREATE TABLE Warehouse.Staging.FlashTransactionReport_ReportData (
		ID int IDENTITY (1,1)
		, CalculationDate date NOT NULL
		, RetailerID int NOT NULL
		, RetailerName varchar(100) NOT NULL
		, StartDate date NOT NULL
		, EndDate date NOT NULL
		, PeriodType varchar(25) NOT NULL
		, SuperSegmentID int
		, SuperSegmentName varchar(40)
		, OfferTypeID int
		, TypeDescription varchar(25)
		, Cardholders int
		, Sales money
		, Spenders int
		, Transactions int
		, Investment money
		, ATV float
		, ATF float
		, RR float
		, SPS float
		, SalesToCostRatio float
		, CumulativeSpendersInPeriod int
		, OfferTypeForReports varchar(100)
		, CONSTRAINT PK_FlashTransactionReport_ReportData PRIMARY KEY CLUSTERED (ID)
	)
	******************************************************************************/

	INSERT INTO Warehouse.Staging.FlashTransactionReport_ReportData (
		CalculationDate
		, RetailerID
		, RetailerName
		, StartDate
		, EndDate
		, PeriodType
		, SuperSegmentID
		, SuperSegmentName
		, OfferTypeID
		, TypeDescription
		, Cardholders
		, Sales
		, Spenders
		, Transactions
		, Investment
		, ATV
		, ATF
		, RR
		, SPS
		, SalesToCostRatio
		, OfferTypeForReports
		)

	SELECT
		@Today AS CalculationDate
		, r.PartnerID
		, r.PartnerName
		, r.StartDate
		, r.EndDate
		, r.PeriodType
		, r.SuperSegmentID
		, r.SuperSegmentName
		, r.OfferTypeID
		, r.TypeDescription
		, r.Cardholders
		, r.Sales
		, r.Spenders
		, r.Transactions
		, r.Investment
		, r.ATV
		, r.ATF
		, r.RR
		, r.SPS
		, r.SalesToCostRatio
		, r.OfferTypeForReports
	FROM #MergedResults r
	WHERE NOT EXISTS (
		SELECT NULL
		FROM Warehouse.Staging.FlashTransactionReport_ReportData d
		WHERE 
			r.PartnerID = d.RetailerID
			AND r.StartDate = d.StartDate
			AND r.EndDate = d.EndDate
			AND r.PeriodType = d.PeriodType
			AND (r.SuperSegmentID = d.SuperSegmentID OR r.SuperSegmentID IS NULL AND d.SuperSegmentID IS NULL)
			AND (r.OfferTypeID = d.OfferTypeID OR r.OfferTypeID IS NULL AND d.OfferTypeID IS NULL)
			AND (r.OfferTypeForReports = d.OfferTypeForReports OR r.OfferTypeForReports IS NULL AND d.OfferTypeForReports IS NULL)
			AND @Today = d.CalculationDate
	);

	/******************************************************************************
	Load cumulative spenders for each retailer in each analysis period
	******************************************************************************/

	IF OBJECT_ID('tempdb..#CumulativeSpenders') IS NOT NULL DROP TABLE #CumulativeSpenders;

	SELECT
		x.PartnerID
		, x.StartDate
		, x.EndDate
		, x.PeriodType
		, SUM(x.Spenders) AS Spenders
	INTO #CumulativeSpenders
	FROM (
		SELECT
			ior.PartnerID
			, ior.StartDate
			, ior.EndDate
			, ior.PeriodType
			, COUNT(DISTINCT(st.FanID)) AS Spenders
		FROM #Offer_References ior
		LEFT JOIN Warehouse.APW.SchemeTrans_Pipe st
			ON ior.IronOfferID = st.IronOfferID
			AND ior.PartnerID = st.RetailerID
			AND st.TranDate BETWEEN ior.StartDate AND ior.EndDate 
		WHERE
			st.IsRetailerReport = 1
			--AND (st.IsSpendStretch IS NULL OR st.IsSpendStretch = 1) -- Only include above SpendStretch trans if a SpendStretch exists
		GROUP BY
			ior.PartnerID
			, ior.StartDate
			, ior.EndDate
			, ior.PeriodType
		--UNION ALL -- Add union here to AMEX's transaction bespoke data feed 
	) x
	GROUP BY
		x.PartnerID
		, x.StartDate
		, x.EndDate
		, x.PeriodType;

	/******************************************************************************
	Update cumulative spenders in Warehouse.Staging.FlashTransactionReport_ReportData
	******************************************************************************/

	UPDATE d
	SET d.CumulativeSpendersInPeriod = c.Spenders
	FROM Warehouse.Staging.FlashTransactionReport_ReportData d
	INNER JOIN #CumulativeSpenders c
		ON d.RetailerID = c.PartnerID
		AND d.StartDate = c.StartDate
		AND d.EndDate = c.EndDate
		AND d.PeriodType = c.PeriodType
		AND d.CalculationDate = @Today
	WHERE 
		d.CumulativeSpendersInPeriod IS NULL;

END