/******************************************************************************
Author: Jason Shipp
Created: 24/05/2018
Purpose:
	- Loads SchemeTrans transaction results, merges to debit card only transaction results and loads combined results at IronOffer level into Warehouse.Staging.FlashOfferReport_ReportData
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 09/07/2018
	- Updated calendar logic to cope with multiple retailers

Jason Shipp 19/07/2018
	- Moved cardholder logic to this stored procedure to ensure IronOffers without ConsumerTrans/MatchTrans metrics are not missed out

24/01/2019 Jason Shipp
    - Referenced PublisherID in nFI.Relational.AmexOffer instead of hardcoding -1

12/08/2019 Jason Shipp
	- Ignored AMEX-type ClickCounts of 0

******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_Load_Combined_Metrics
 
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Load calendar table containing daily and weekly start and end dates within the analysis period
	******************************************************************************/
	
	SET DATEFIRST 1; -- Set Monday as the first day of the week

	-- Declare variables

	DECLARE @Today date = CAST(GETDATE() AS DATE);
	--DECLARE @DaysToReport int = 7;
	--DECLARE @CompleteWeeksToReport int = 1;

	-- Load min and max dates to analyse per retailer

	IF OBJECT_ID('tempdb..#RetailerDateRange') IS NOT NULL DROP TABLE #RetailerDateRange;

	SELECT
		PartnerID
		, MIN(StartDate) AS MinStartDate
		, MAX(EndDate) AS MaxEndDate
	INTO #RetailerDateRange
	FROM Warehouse.Staging.FlashOfferReport_All_Offers
	GROUP BY
		PartnerID;

	-- Load tally table and calendar

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;
	
	WITH
		E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n))
		, E2 AS (SELECT n = 0 FROM E1 a CROSS JOIN E1 b)
		, Tally AS (SELECT n = 0 UNION ALL SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E2 a CROSS JOIN E2 b) -- Create table of numbers
		, TallyDates AS (
			SELECT 
				r.PartnerID
				, t.n
				, CalDate = DATEADD(day, n, r.MinStartDate)
				, r.MinStartDate
				, r.MaxEndDate
			FROM Tally t
			CROSS JOIN #RetailerDateRange r
			WHERE DATEADD(day, n, r.MinStartDate) <= r.MaxEndDate
		) -- Create table of consecutive dates
	
	-- Daily periods
	SELECT
		c.PartnerID
		, c.CalDate AS StartDate
		, c.CalDate AS EndDate
		, 'Daily' AS PeriodType
	INTO #Calendar
	FROM TallyDates c
	--WHERE -- Logic for only including @DaysToReport days
	--	c.CalDate >= DATEADD(day, -(@DaysToReport-1), c.MaxEndDate)

	UNION ALL

	-- Weekly periods
	SELECT
		PartnerID
		, StartDate
		, EndDate
		, PeriodType
	FROM (
		SELECT DISTINCT
			PartnerID
			, CASE 
				WHEN DATEADD(dd, -(DATEPART(dw, CalDate)-1), CalDate) < MinStartDate
				THEN MinStartDate -- Don't let StartDate go before analysis start date
				ELSE DATEADD(dd, -(DATEPART(dw, CalDate)-1), CalDate) 
			END	AS StartDate -- For each calendar date in #Dates, minus days since the most recent Monday  
			, DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate) AS EndDate -- For each calendar date in TallyDates, minus days since the most recent Sunday
			, 'Weekly' AS PeriodType
		FROM TallyDates
		WHERE
			DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate) <= CalDate -- Only complete weeks
		UNION -- Load most recent week (may be partial); don't use UNION ALL to avoid duplication
		SELECT
		PartnerID 
		, (DATEADD( 
			day
			, -(DATEPART(dw, DATEADD(day, -1, @Today)))+1
			, DATEADD(day, -1, @Today))
		) AS StartDate
		, DATEADD(day, -1, @Today) AS EndDate
		, 'Weekly' AS PeriodType
		FROM #RetailerDateRange
		WHERE 
		(DATEADD( 
			day
			, -(DATEPART(dw, DATEADD(day, -1, @Today)))+1
			, DATEADD(day, -1, @Today))
		) >= MinStartDate -- Check retailer was active in most recent week
	) x
	--WHERE -- Logic for only including @CompleteWeeksToReport weeks
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
	Load distinct Iron Offer periods to analyse 
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Offer_References') IS NOT NULL DROP TABLE #Offer_References;

	-- Cumulative periods
	SELECT DISTINCT
		ior.IronOfferID
		, ior.StartDate
		, ior.EndDate
		, ior.OfferSetupStartDate
		, ior.OfferSetupEndDate
		, ior.PeriodType
		, ior.IronOfferName
		, ior.PartnerID
		, ior.SubPartnerID
		, ior.PartnerName
		, ior.ClubID
		, ior.IsWarehouse
		, ior.SpendStretch
		, ior.ControlGroupTypeID
	INTO #Offer_References
	FROM Warehouse.Staging.FlashOfferReport_All_Offers ior
	WHERE
		ior.PeriodType = 'Cumulative'
		
	UNION ALL
	
	-- Daily and weekly periods
	SELECT DISTINCT
		ior.IronOfferID
		, cal.StartDate
		, cal.EndDate
		, ior.OfferSetupStartDate
		, ior.OfferSetupEndDate
		, cal.PeriodType
		, ior.IronOfferName
		, ior.PartnerID
		, ior.SubPartnerID
		, ior.PartnerName
		, ior.ClubID
		, ior.IsWarehouse
		, ior.SpendStretch
		, ior.ControlGroupTypeID
	FROM Warehouse.Staging.FlashOfferReport_All_Offers ior
	INNER JOIN #Calendar cal -- Expand table to include all analysis periods in calendar table
		ON cal.StartDate >= ior.StartDate
		AND cal.EndDate <= ior.EndDate
		AND ior.PartnerID = cal.PartnerID
	WHERE
		ior.PeriodType = 'Cumulative'; -- Expand to daily and weekly from cumulative data range
		
	CREATE NONCLUSTERED INDEX NIX_Offer_References ON #Offer_References (IronOfferID, StartDate, EndDate);

	/******************************************************************************
	Load SchemeTrans results
	******************************************************************************/

	IF OBJECT_ID('tempdb..#SchemeTrans_Results') IS NOT NULL DROP TABLE #SchemeTrans_Results;

	SELECT
		o.IronOfferID
		, o.StartDate
		, o.EndDate
		, o.OfferSetupStartDate
		, o.OfferSetupEndDate
		, o.PeriodType
		, o.PartnerID
		, st.PublisherID
		, o.isWarehouse
		, o.ControlGroupTypeID
		, NULL AS Channel
		, NULL AS Threshold
		, SUM(st.Spend) AS Sales
		, COUNT(st.FanID) AS Trans
		, COUNT(DISTINCT st.FanID) AS Spenders	
		, SUM(st.Investment) AS Investment
		, NULL AS Cardholders_E
		, NULL AS Cardholders_C
	INTO #SchemeTrans_Results
	FROM #Offer_References o
	LEFT JOIN Warehouse.APW.SchemeTrans_Pipe st
		ON st.IronOfferID = o.IronOfferID
		AND st.TranDate BETWEEN o.StartDate AND o.EndDate
		AND st.RetailerID = o.PartnerID
	WHERE 
		st.IsRetailerReport = 1
		--AND (st.IsSpendStretch IS NULL OR st.IsSpendStretch = 1) -- Only include above SpendStretch trans if a SpendStretch exists
	GROUP BY
		o.IronOfferID
		, o.StartDate
		, o.EndDate
		, o.OfferSetupStartDate
		, o.OfferSetupEndDate
		, o.PeriodType
		, o.PartnerID
		, st.PublisherID
		, o.isWarehouse
		, o.ControlGroupTypeID;	

	/******************************************************************************
	Load cardholder counts
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Cardholder_Counts') IS NOT NULL DROP TABLE #Cardholder_Counts;

	SELECT -- Control nFI/Warehouse/AMEX
		o.IronOfferID
		, c.Exposed
		, c.IsWarehouse
		, o.StartDate
		, o.EndDate
		, o.PeriodType
		, c.ControlGroupTypeID
		, COUNT(DISTINCT c.FanID) AS Cardholders
	INTO #Cardholder_Counts
	FROM Warehouse.Staging.FlashOfferReport_All_Offers o 
	LEFT JOIN Warehouse.Staging.FlashOfferReport_ExposedControlCustomers c
		ON o.ControlGroupID = c.GroupID
		AND o.ControlGroupTypeID = c.ControlGroupTypeID
	   	AND (
			o.isWarehouse = c.isWarehouse
			OR o.isWarehouse IS NULL AND c.isWarehouse IS NULL
		)
	WHERE 
		c.Exposed = 0
	GROUP BY
		o.IronOfferID
		, c.Exposed
		, c.isWarehouse
		, o.StartDate
		, o.EndDate
		, o.PeriodType
		, c.ControlGroupTypeID

	UNION ALL

	SELECT -- Exposed nFI/Warehouse
		o.IronOfferID
		, c.Exposed
		, c.IsWarehouse
		, o.StartDate
		, o.EndDate
		, o.PeriodType
		, c.ControlGroupTypeID
		, COUNT(DISTINCT c.FanID) AS Cardholders
	FROM Warehouse.Staging.FlashOfferReport_All_Offers o 
	LEFT JOIN Warehouse.Staging.FlashOfferReport_ExposedControlCustomers c
		ON o.IronOfferCyclesID = c.GroupID 
	   	AND (
			o.isWarehouse = c.isWarehouse
		)
	WHERE 
		c.Exposed = 1
		AND o.ControlGroupTypeID = 0
		AND o.IsWarehouse IS NOT NULL
	GROUP BY
		o.IronOfferID
		, c.Exposed
		, c.isWarehouse
		, o.StartDate
		, o.EndDate
		, o.PeriodType
		, c.ControlGroupTypeID

	UNION ALL

	SELECT -- Exposed AMEX
		x.IronOfferID
		, CAST(1 AS bit) AS Exposed
		, NULL AS isWarehouse 
		, x.StartDate
		, x.EndDate
		, x.PeriodType
		, NULL AS ControlGroupTypeID
		, x.ClickCounts AS Cardholders
    FROM (
		SELECT DISTINCT
			ame.IronOfferID
			, ame.ClickCounts
			, o.StartDate
			, o.EndDate
			, o.PeriodType
			, ROW_NUMBER() OVER (PARTITION BY o.IronOfferID, o.OfferSetupStartDate, o.OfferSetupEndDate ORDER BY DATEDIFF(day, ame.ReceivedDate, o.EndDate) ASC) DateRank
		FROM Warehouse.Staging.FlashOfferReport_All_Offers o
		INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
			ON ame.IronOfferID = o.IronOfferID
			AND DATEADD(day, 1, ame.ReceivedDate) <= o.OfferSetupEndDate
			AND ame.ClickCounts >0
	) x
	WHERE x.DateRank = 1;

	/******************************************************************************
	Update cardholder counts 
	******************************************************************************/

	-- Exposed cardholders
	UPDATE t1
	SET t1.Cardholders_E = t2.Cardholders
	FROM #SchemeTrans_Results t1
	INNER JOIN #Cardholder_Counts t2
		ON (t1.isWarehouse = t2.isWarehouse OR t1.isWarehouse IS NULL AND t2.isWarehouse IS NULL)
		AND t1.IronOfferID = t2.IronOfferID
		AND t1.StartDate = t2.StartDate
		AND t1.EndDate = t2.EndDate
		AND t1.PeriodType = t2.PeriodType
	WHERE
		t2.Exposed = 1
		AND t2.ControlGroupTypeID IS NULL;

	-- Control cardholders
	UPDATE t1
	SET t1.Cardholders_C = t2.Cardholders
	FROM #SchemeTrans_Results t1
	INNER JOIN #Cardholder_Counts t2
		ON (t1.isWarehouse = t2.isWarehouse OR t1.isWarehouse IS NULL AND t2.isWarehouse IS NULL)
		AND t1.IronOfferID = t2.IronOfferID
		AND t1.StartDate = t2.StartDate
		AND t1.EndDate = t2.EndDate
		AND t1.PeriodType = t2.PeriodType
	WHERE
		t2.Exposed = 0
		AND t2.ControlGroupTypeID IS NOT NULL;

	/******************************************************************************
	Reshape, combine and load SchemeTrans and debit card only results at IronOffer level
	******************************************************************************/

	IF OBJECT_ID('tempdb..#ReportData1') IS NOT NULL DROP TABLE #ReportData1;

	SELECT 
		st.IronOfferID
		, st.StartDate
		, st.EndDate
		, st.OfferSetupStartDate
		, st.OfferSetupEndDate
		, st.PeriodType
		, st.PartnerID
		, st.PublisherID
		, st.isWarehouse
		, st.ControlGroupTypeID
		, st.Channel
		, st.Threshold
		, st.Cardholders_E
		, st.Cardholders_C
		, st.Sales
		, ex.Sales AS Sales_E
		, c.Sales AS Sales_C
		, st.Trans
		, ex.Trans AS Trans_E
		, c.Trans AS Trans_C
		, st.Spenders
		, ex.Spenders AS Spenders_E
		, c.Spenders AS Spenders_C
		, st.Investment
	INTO #ReportData1
	FROM #SchemeTrans_Results st
	LEFT JOIN (
		SELECT * FROM Warehouse.Staging.FlashOfferReport_Metrics 
		WHERE Exposed = 0 AND CalculationDate = (SELECT MAX(CalculationDate) FROM Warehouse.Staging.FlashOfferReport_Metrics)
	) c
		ON st.IronOfferID = c.IronOfferID 
		AND CAST(st.ControlGroupTypeID AS int) = CAST(c.ControlGroupTypeID AS int)
		AND st.isWarehouse = c.IsWarehouse
		AND st.StartDate = c.StartDate
		AND st.EndDate = c.EndDate
		AND st.PeriodType = c.PeriodType
	LEFT JOIN (
		SELECT * FROM Warehouse.Staging.FlashOfferReport_Metrics 
		WHERE Exposed = 1 AND CalculationDate = (SELECT MAX(CalculationDate) FROM Warehouse.Staging.FlashOfferReport_Metrics)
	) ex
		ON c.IronOfferID = ex.IronOfferID
		AND c.IsWarehouse = ex.isWarehouse
		AND c.StartDate = ex.StartDate
		AND c.EndDate = ex.EndDate
		AND c.PeriodType = ex.PeriodType 
	LEFT JOIN (
		SELECT IronOfferID, 132 AS ClubID FROM Warehouse.Relational.IronOffer
		UNION ALL
		SELECT ID AS IronOfferID, ClubID FROM nFI.Relational.IronOffer
		UNION ALL
		SELECT IronOfferID, PublisherID AS ClubID FROM nFI.Relational.AmexOffer -- Jason Shipp 24/01/2019 point to PublisherID column instead of hard coding -1
	) p
	ON c.IronOfferID = p.IronOfferID;

	/******************************************************************************
	Load extra metrics
	******************************************************************************/

	IF OBJECT_ID('tempdb..#ReportData2') IS NOT NULL DROP TABLE #ReportData2;

	SELECT 
		d1.IronOfferID
		, d1.StartDate
		, d1.EndDate
		, d1.OfferSetupStartDate
		, d1.OfferSetupEndDate
		, d1.PeriodType
		, d1.PartnerID
		, d1.PublisherID
		, d1.isWarehouse
		, d1.ControlGroupTypeID
		, d1.Channel
		, d1.Threshold
		, d1.Cardholders_E
		, d1.Cardholders_C
		, d1.Sales
		, d1.Sales_E
		, d1.Sales_C
		, d1.Trans
		, d1.Trans_E
		, d1.Trans_C
		, d1.Spenders
		, d1.Spenders_E
		, d1.Spenders_C
		, d1.Investment
		, (CAST(d1.Sales AS FLOAT))/NULLIF(d1.Cardholders_E, 0) AS SPC
		, (CAST(d1.Sales AS FLOAT))/NULLIF(d1.Spenders, 0) AS SPS
		, (CAST(d1.Spenders AS FLOAT))/NULLIF(d1.Cardholders_E, 0) AS RR
		, (CAST(d1.Sales AS FLOAT))/NULLIF(d1.Trans, 0) AS ATV
		, (CAST(d1.Trans AS FLOAT))/NULLIF(d1.Spenders, 0) AS ATF
		, (CAST(d1.Sales_C AS FLOAT))/NULLIF(d1.Cardholders_C, 0) AS SPC_C
		, (CAST(d1.Sales_C AS FLOAT))/NULLIF(d1.Spenders_C, 0) AS SPS_C
		, (CAST(d1.Spenders_C AS FLOAT))/NULLIF(d1.Cardholders_C, 0) AS RR_C
		, (CAST(d1.Sales_C AS FLOAT))/NULLIF(d1.Trans_C, 0) AS ATV_C
		, (CAST(d1.Trans_C AS FLOAT))/NULLIF(d1.Spenders_C, 0) AS ATF_C
		, (CAST(d1.Sales_E AS FLOAT))/NULLIF(d1.Cardholders_E, 0) AS SPC_E
		, (CAST(d1.Sales_E AS FLOAT))/NULLIF(d1.Spenders_E, 0) AS SPS_E
		, (CAST(d1.Spenders_E AS FLOAT))/NULLIF(d1.Cardholders_E, 0) AS RR_E
		, (CAST(d1.Sales_E AS FLOAT))/NULLIF(d1.Trans_E, 0) AS ATV_E
		, (CAST(d1.Trans_E AS FLOAT))/NULLIF(d1.Spenders_E, 0) AS ATF_E
		, (CAST(d1.Sales AS float))/NULLIF(d1.Investment, 0) AS SalesToCostRatio
	INTO #ReportData2
	FROM #ReportData1 d1;

	/******************************************************************************
	Load incremental metrics 

	-- Create table for storing results:

	CREATE TABLE Warehouse.Staging.FlashOfferReport_ReportData (
		IronOfferID int NOT NULL
		, StartDate date NOT NULL
		, EndDate date NOT NULL
		, OfferSetupStartDate date NOT NULL
		, OfferSetupEndDate date NOT NULL
		, PeriodType varchar(25) NOT NULL
		, RetailerID int
		, PublisherID int
		, isWarehouse bit
		, ControlGroupTypeID int
		, Channel bit
		, Threshold bit
		, Cardholders_E int
		, Cardholders_C int
		, Sales money
		, Sales_E money
		, Sales_C money
		, Trans int
		, Trans_E int
		, Trans_C int
		, Spenders int
		, Spenders_E int
		, Spenders_C int
		, Investment money
		, SPC float
		, SPS float
		, RR float
		, ATV float
		, ATF float
		, SPC_C float
		, SPS_C float
		, RR_C float
		, ATV_C float
		, ATF_C float
		, SPC_E float
		, SPS_E float
		, RR_E float
		, ATV_E float
		, ATF_E float
		, RR_Uplift float
		, ATV_Uplift float
		, ATF_Uplift float
		, Sales_Uplift float
		, IncSales money
		, IncSpenders int
		, SalesToCostRatio float
		, CalculationDate date NOT NULL
		, CONSTRAINT PK_FlashOfferReport_ReportData PRIMARY KEY CLUSTERED (IronOfferID, ControlGroupTypeID, StartDate, EndDate, PeriodType, CalculationDate)
	);
	******************************************************************************/

	INSERT INTO Warehouse.Staging.FlashOfferReport_ReportData (
		IronOfferID
		, StartDate
		, EndDate
		, OfferSetupStartDate
		, OfferSetupEndDate
		, PeriodType
		, RetailerID
		, PublisherID
		, isWarehouse
		, ControlGroupTypeID
		, Channel
		, Threshold
		, Cardholders_E
		, Cardholders_C
		, Sales
		, Sales_E
		, Sales_C
		, Trans
		, Trans_E
		, Trans_C
		, Spenders
		, Spenders_E
		, Spenders_C
		, Investment
		, SPC
		, SPS
		, RR
		, ATV
		, ATF
		, SPC_C
		, SPS_C
		, RR_C
		, ATV_C
		, ATF_C
		, SPC_E
		, SPS_E
		, RR_E
		, ATV_E
		, ATF_E
		, RR_Uplift
		, ATV_Uplift
		, ATF_Uplift
		, Sales_Uplift
		, IncSales
		, IncSpenders
		, SalesToCostRatio
		, CalculationDate
	)

	SELECT 
		d2.IronOfferID
		, d2.StartDate
		, d2.EndDate
		, d2.OfferSetupStartDate
		, d2.OfferSetupEndDate
		, d2.PeriodType
		, d2.PartnerID
		, d2.PublisherID
		, d2.isWarehouse
		, d2.ControlGroupTypeID
		, d2.Channel
		, d2.Threshold
		, d2.Cardholders_E
		, d2.Cardholders_C
		, d2.Sales
		, d2.Sales_E
		, d2.Sales_C
		, d2.Trans
		, d2.Trans_E
		, d2.Trans_C
		, d2.Spenders
		, d2.Spenders_E
		, d2.Spenders_C
		, d2.Investment
		, d2.SPC
		, d2.SPS
		, d2.RR
		, d2.ATV
		, d2.ATF
		, d2.SPC_C
		, d2.SPS_C
		, d2.RR_C
		, d2.ATV_C
		, d2.ATF_C
		, d2.SPC_E
		, d2.SPS_E
		, d2.RR_E
		, d2.ATV_E
		, d2.ATF_E
		, CAST((d2.RR_E - d2.RR_C) AS FLOAT)/NULLIF((CAST(d2.RR_C AS FLOAT)), 0) AS RR_Uplift
		, CAST((d2.ATV_E - d2.ATV_C) AS FLOAT)/NULLIF((CAST(d2.ATV_C AS FLOAT)), 0) AS ATV_Uplift
		, CAST((d2.ATF_E - d2.ATF_C) AS FLOAT)/NULLIF((CAST(d2.ATF_C AS FLOAT)), 0) AS ATF_Uplift
		, CAST(((d2.RR_E*d2.SPS_E) - (d2.RR_C*d2.SPS_C)) AS FLOAT)/NULLIF((CAST((d2.RR_C*d2.SPS_C) AS FLOAT)), 0) AS Sales_Uplift
		, d2.Sales-(d2.Sales/NULLIF((CAST((
			1 + CAST(((d2.RR_E*d2.SPS_E) - (d2.RR_C*d2.SPS_C)) AS FLOAT)/NULLIF((CAST((d2.RR_C*d2.SPS_C) AS FLOAT)), 0) -- 1 + Sales Uplift
		) AS FLOAT)),0)) AS IncSales
		, d2.Spenders-(d2.spenders/NULLIF((CAST((
			1 + CAST((d2.RR_E - d2.RR_C) AS FLOAT)/NULLIF((CAST(d2.RR_C AS FLOAT)), 0) -- 1 + RR Uplift
		) AS FLOAT)),0)) AS IncSpenders
		, d2.SalesToCostRatio
		, CAST(GETDATE() AS DATE) AS CalculationDate
	FROM #ReportData2 d2
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.FlashOfferReport_ReportData x
		WHERE 
			d2.IronOfferID = x.IronOfferID
			AND d2.ControlGroupTypeID = x.ControlGroupTypeID 
			AND d2.StartDate = x.StartDate
			AND d2.EndDate = x.EndDate
			AND d2.PeriodType = x.PeriodType
			AND CAST(GETDATE() AS DATE) = x.CalculationDate
	);

END