/******************************************************************************
Author: Jason Shipp
Created: 23/01/2019
Purpose: 
	- Fetch Merchant Funded Direct Debit Incrementals Report data from Warehouse.Staging.DirectDebitResults table
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 20/02/2019
	- Added Iron Offer name to fetch

Jason Shipp 24/07/2019
	- Updated references to CustomerGroup and DDRankByDateGroup so stored procedure is more adaptable to different retailer incentivisation business rules

Jason Shipp 13/08/2019
	- Updated max report date logic to instead use the max report date associated with each analysis window, to avoid the need to calculate all analysis windows each time the process is run

Jason Shipp 16/09/2019
	- Added fallbacks for customer groups and spendstretches for customers who have only paid a first DD

Jason Shipp 09/03/2020
	- Adjusted joins on IronOfferIDs to exclude suffixes, for cases where retailers have Iron Offer sub-segments (e.g. Sky Mobile) 

******************************************************************************/


CREATE PROCEDURE [Staging].[DirectDebitResults_Fetch_ReportData_Incrementals] (@RetailerID int)
	
AS
BEGIN

	SET NOCOUNT ON;

	--DECLARE @RetailerID int = 4729 -- For testing

	-- Load max report dates associated with each analysis period
	
	IF OBJECT_ID('tempdb..#DirectDebitResults') IS NOT NULL DROP TABLE #DirectDebitResults;
	SELECT *
	INTO #DirectDebitResults	
	FROM [Staging].[DirectDebitResults] d
	WHERE RetailerID = @RetailerID

	IF OBJECT_ID('tempdb..#MaxReportDates') IS NOT NULL DROP TABLE #MaxReportDates;

	SELECT
		r.PeriodType
		, r.StartDate
		, r.EndDate
		, MAX(r.ReportDate) AS ReportDate
	INTO #MaxReportDates
	FROM #DirectDebitResults r WITH (NOLOCK)
	OUTER APPLY (
		SELECT 
		r2.PeriodType
		, r2.StartDate
		, MAX(DATEDIFF(day, r2.StartDate, r2.EndDate)) AS MaxPeriodDays
		FROM #DirectDebitResults r2 WITH (NOLOCK)
		WHERE 
		r.PeriodType = r2.PeriodType
		AND r.StartDate = r2.StartDate
		GROUP BY
		r2.PeriodType
		, r2.StartDate
	) x
	WHERE 
		DATEDIFF(DAY, r.StartDate, r.EndDate) = x.MaxPeriodDays -- Only include most complete view of each analysis period (eg. exclude partial weeks where possible)
	GROUP BY
		r.PeriodType
		, r.StartDate
		, r.EndDate;

	CREATE UNIQUE CLUSTERED INDEX UCIX_MaxReportDates ON #MaxReportDates (PeriodType, StartDate, EndDate);


	-- Load mapping between RetailerID and PartnerName

	IF OBJECT_ID('tempdb..#PartnerNames') IS NOT NULL DROP TABLE #PartnerNames;

	SELECT y.PartnerID, y.PartnerName 
	INTO #PartnerNames
	FROM (
		SELECT x.PartnerID, x.PartnerName, ROW_NUMBER() OVER(PARTITION BY x.PartnerID ORDER BY x.PartnerName) AS NameRank FROM (
			SELECT p.PartnerID, p.PartnerName FROM Warehouse.Relational.[Partner] p
			UNION 
			SELECT p.PartnerID, p.PartnerName FROM nFI.Relational.[Partner] p
		) x
	) y
	WHERE y.NameRank = 1;

	-- Load spend stretch rules

	IF OBJECT_ID('tempdb..#SpendStretchRules') IS NOT NULL DROP TABLE #SpendStretchRules;

	SELECT DISTINCT
		CAST(r.IronOfferID AS varchar(50)) AS IronOfferID
		, CAST(r.MinimumSpend AS money) AS MinimumSpend
		, CAST(LEAD(r.MinimumSpend, 1, NULL) OVER(PARTITION BY r.IronOfferID ORDER BY r.MinimumSpend ASC)-0.0001 AS money) AS MaximumSpend
		, CAST(r.RewardAmount AS money) AS RewardAmount
		, CAST(r.BillingAmount AS money) AS BillingAmount
	INTO #SpendStretchRules
	FROM SLC_Report.dbo.DirectDebitOfferRules r
	INNER JOIN Warehouse.Relational.IronOfferSegment s
		ON r.IronOfferID = s.IronOfferID
	WHERE s.RetailerID = @RetailerID
	UNION ALL
	SELECT DISTINCT
		'Overall' AS IronOfferID
		, CAST(r.MinimumSpend AS money) AS MinimumSpend
		, CAST(LEAD(r.MinimumSpend, 1, NULL) OVER(PARTITION BY r.IronOfferID ORDER BY r.MinimumSpend ASC)-0.0001 AS money) AS MaximumSpend
		, CAST(r.RewardAmount AS money) AS RewardAmount
		, CAST(r.BillingAmount AS money) AS BillingAmount
	FROM SLC_Report.dbo.DirectDebitOfferRules r
	INNER JOIN Warehouse.Relational.IronOfferSegment s
		ON r.IronOfferID = s.IronOfferID
	WHERE s.RetailerID = @RetailerID;

	IF OBJECT_ID('tempdb..#MaxSpendStretch') IS NOT NULL DROP TABLE #MaxSpendStretch;

	SELECT	r.IronOfferID
		,	MAX(r.MinimumSpend) AS SpendStretchMaxRequirement
	INTO #MaxSpendStretch
	FROM #SpendStretchRules r
	GROUP BY	r.IronOfferID;

	-- Load opening DD summary for exposed group members who have paid at least 1 DD (sum over all CustomerGroups) 

	IF OBJECT_ID('tempdb..#OpeningDD_E') IS NOT NULL DROP TABLE #OpeningDD_E;
	SELECT	d.ReportDate
		,	d.RetailerID
		,	d.IronOfferID
		,	d.PeriodType
		,	d.StartDate
		,	d.EndDate
		,	d.DDRankByDateGroup
		,	MAX(d.Cardholders) AS Cardholders
		,	SUM(ISNULL(d.UniqueDDSpenders, 0)) AS UniqueDDSpenders
		,	SUM(ISNULL(d.DDSpend, 0)) AS DDSpend
		,	SUM(ISNULL(d.DDCount, 0)) AS DDCount
		,	ISNULL(SUM(CONVERT(FLOAT, d.UniqueDDSpenders)) / NULLIF(MAX(d.Cardholders), 0), 0) AS RR
		,	ISNULL(SUM(CONVERT(FLOAT, d.DDSpend)) / NULLIF(SUM(d.DDCount), 0), 0) AS ATV
		,	ISNULL(SUM(CONVERT(FLOAT, d.DDSpend)) / NULLIF(SUM(d.UniqueDDSpenders), 0), 0) AS SPS
	INTO #OpeningDD_E
	FROM #DirectDebitResults d
	INNER JOIN #MaxReportDates md
		ON d.PeriodType = md.PeriodType
		AND d.StartDate = md.StartDate
		AND d.EndDate = md.EndDate
		AND d.ReportDate = md.ReportDate
	WHERE d.IsExposed = 1
	AND d.DDRankByDateGroup = 'Opening'
	AND d.IronOfferID != 'Overall'
	GROUP BY	d.ReportDate
			,	d.RetailerID
			,	d.IronOfferID
			,	d.PeriodType
			,	d.StartDate
			,	d.EndDate
			,	d.DDRankByDateGroup;

	-- Load opening DD summary for control group members who have paid at least 1 DD (sum over all CustomerGroups) 

	IF OBJECT_ID('tempdb..#OpeningDD_C') IS NOT NULL DROP TABLE #OpeningDD_C;
	SELECT	d.ReportDate
		,	d.RetailerID
		,	d.IronOfferID
		,	d.PeriodType
		,	d.StartDate
		,	d.EndDate
		,	d.DDRankByDateGroup
		,	MAX(d.Cardholders) AS Cardholders
		,	SUM(ISNULL(d.UniqueDDSpenders, 0)) AS UniqueDDSpenders
		,	SUM(ISNULL(d.DDSpend, 0)) AS DDSpend
		,	SUM(ISNULL(d.DDCount, 0)) AS DDCount
		,	ISNULL(SUM(CONVERT(FLOAT, d.UniqueDDSpenders)) / NULLIF(MAX(d.Cardholders), 0), 0) AS RR
		,	ISNULL(SUM(CONVERT(FLOAT, d.DDSpend)) / NULLIF(SUM(d.DDCount), 0), 0) AS ATV
		,	ISNULL(SUM(CONVERT(FLOAT, d.DDSpend)) / NULLIF(SUM(d.UniqueDDSpenders), 0), 0) AS SPS
	INTO #OpeningDD_C
	FROM #DirectDebitResults d
	INNER JOIN #MaxReportDates md
		ON d.PeriodType = md.PeriodType
		AND d.StartDate = md.StartDate
		AND d.EndDate = md.EndDate
		AND d.ReportDate = md.ReportDate
	WHERE d.IsExposed = 0
	AND d.DDRankByDateGroup = 'Opening'
	AND d.IronOfferID != 'Overall'
	GROUP BY	d.ReportDate
			,	d.RetailerID
			,	d.IronOfferID
			,	d.PeriodType
			,	d.StartDate
			,	d.EndDate
			,	d.DDRankByDateGroup;
			
			
	-- Load incentivised DD summary for exposed group members who have paid more than 1 DD, keeping grouping by CustomerGroup 

	IF OBJECT_ID('tempdb..#IncentivisedDD_E') IS NOT NULL DROP TABLE #IncentivisedDD_E;
	SELECT	d.ReportDate
		,	d.RetailerID
		,	d.IronOfferID
		,	d.PeriodType
		,	d.StartDate
		,	d.EndDate
		,	d.CustomerGroup
		,	CONCAT('Incentivised DD ', CASE WHEN ssr.MinimumSpend <= 0.01 THEN CONCAT('< £', CEILING(ssr.MaximumSpend)) ELSE CONCAT(N'≥ £', ssr.MinimumSpend) END) AS CustomerGroupName
		,	CASE WHEN ssr.MinimumSpend <= 0.01 THEN CEILING(ssr.MaximumSpend) ELSE ssr.MinimumSpend END AS SpendStretchMaxRequirement
		,	ssr.RewardAmount AS OfferCashbackEarnable
		,	ssr.BillingAmount AS Investment
		,	d.DDRankByDateGroup
		,	d.Cardholders
		,	d.UniqueDDSpenders
		,	d.DDSpend
		,	d.DDCount
		,	ISNULL(CONVERT(FLOAT, d.UniqueDDSpenders) / NULLIF(d.Cardholders, 0), 0) AS RR
		,	ISNULL(CONVERT(FLOAT, d.DDSpend) / NULLIF(d.DDCount, 0), 0) AS ATV
		,	ISNULL(CONVERT(FLOAT, d.DDSpend) / NULLIF(d.UniqueDDSpenders, 0), 0) AS SPS
	INTO #IncentivisedDD_E
	FROM #DirectDebitResults d
	INNER JOIN #MaxReportDates md
		ON d.PeriodType = md.PeriodType
		AND d.StartDate = md.StartDate
		AND d.EndDate = md.EndDate
		AND d.ReportDate = md.ReportDate
	INNER JOIN #SpendStretchRules ssr
		ON LEFT(d.IronOfferID, CASE WHEN CHARINDEX('-', d.IronOfferID) = 0 THEN LEN(d.IronOfferID) ELSE (CHARINDEX('-', d.IronOfferID))-1 END) = ssr.IronOfferID
		AND d.CustomerGroupMinSpend = ssr.MinimumSpend
	WHERE d.IsExposed = 1
	AND d.DDRankByDateGroup = 'Incentivised'
	AND d.CustomerGroup NOT LIKE '%OpeningDDOnly%'
	AND d.IronOfferID != 'Overall';


	-- Load incentivised DD summary for control group members who have paid more than 1 DD, keeping grouping by CustomerGroup

	IF OBJECT_ID('tempdb..#IncentivisedDD_C') IS NOT NULL DROP TABLE #IncentivisedDD_C;
	SELECT	d.ReportDate
		,	d.RetailerID
		,	d.IronOfferID
		,	d.PeriodType
		,	d.StartDate
		,	d.EndDate
		,	d.CustomerGroup
		,	d.DDRankByDateGroup
		,	d.Cardholders
		,	d.UniqueDDSpenders
		,	d.DDSpend AS DDSpend
		,	d.DDCount AS DDCount
		,	ISNULL(CONVERT(FLOAT, d.UniqueDDSpenders) / NULLIF(d.Cardholders, 0), 0) AS RR
		,	ISNULL(CONVERT(FLOAT, d.DDSpend) / NULLIF(d.DDCount, 0), 0) AS ATV
		,	ISNULL(CONVERT(FLOAT, d.DDSpend) / NULLIF(d.UniqueDDSpenders, 0), 0) AS SPS
	INTO #IncentivisedDD_C
	FROM #DirectDebitResults d
	INNER JOIN #MaxReportDates md
		ON d.PeriodType = md.PeriodType
		AND d.StartDate = md.StartDate
		AND d.EndDate = md.EndDate
		AND d.ReportDate = md.ReportDate
	WHERE d.IsExposed = 0
	AND d.DDRankByDateGroup = 'Incentivised'
	AND d.CustomerGroup NOT LIKE '%OpeningDDOnly%'
	AND d.IronOfferID != 'Overall';

	-- Load combined results and derive base metrics for calculating incrementals
	
	IF OBJECT_ID('tempdb..#Combined') IS NOT NULL DROP TABLE #Combined;
	SELECT	COALESCE(dd1e.ReportDate, dd2e.ReportDate) AS ReportDate
		,	COALESCE(dd1e.RetailerID, dd2e.RetailerID) AS RetailerID
		,	COALESCE(dd1e.IronOfferID, dd2e.IronOfferID) AS IronOfferID
		,	COALESCE(dd1e.PeriodType, dd2e.PeriodType) AS PeriodType
		,	COALESCE(dd1e.StartDate, dd2e.StartDate) AS StartDate
		,	COALESCE(dd1e.EndDate, dd2e.EndDate) AS EndDate
		,	COALESCE(dd2e.CustomerGroup, 'OpeningDDOnly') AS CustomerGroup
		,	COALESCE(dd2e.CustomerGroupName, 'Opening DD Only') AS CustomerGroupName
		,	dd2e.OfferCashbackEarnable
		,	COALESCE(dd1e.Cardholders, dd2e.Cardholders) AS Cardholders_E
		,	dd1e.UniqueDDSpenders AS UniqueDDSpenders_E_First_NOT_ADDITIVE -- This overarches customer groups, so is duplicated for different customer groups
		,	dd2e.UniqueDDSpenders AS UniqueDDSpenders_E_Second
		,	dd1e.DDSpend AS DDSpend_E_First
		,	dd2e.DDSpend AS DDSpend_E_Second
		,	dd1e.DDCount AS DDCount_E_First
		,	dd2e.DDCount AS DDCount_E_Second
		,	dd2e.OfferCashbackEarnable * dd2e.UniqueDDSpenders AS CashbackEarned
		,	(dd2e.Investment * dd2e.UniqueDDSpenders) - (dd2e.OfferCashbackEarnable * dd2e.UniqueDDSpenders) AS [Override]
		,	dd2e.Investment * dd2e.UniqueDDSpenders AS Investment
		-- Extra metrics for incremental calculations starts here
		,	dd1e.RR AS RR_E_First
		,	dd1c.RR AS RR_C_First
		,	dd2e.RR AS RR_E_Second
		,	dd2c.RR AS RR_C_Second
		,	dd1e.SPS AS SPS_E_First
		,	dd1c.SPS AS SPS_C_First
		,	dd2e.SPS AS SPS_E_Second
		,	dd2c.SPS AS SPS_C_Second
		,	dd2e.ATV AS ATV_E_Second
		,	dd2c.ATV AS ATV_C_Second
		,	mss.SpendStretchMaxRequirement
	INTO #Combined
	FROM #OpeningDD_E dd1e
	LEFT JOIN #OpeningDD_C dd1c
		ON dd1e.ReportDate = dd1c.ReportDate
		AND dd1e.RetailerID = dd1c.RetailerID
		AND dd1e.IronOfferID = dd1c.IronOfferID
		AND dd1e.PeriodType = dd1c.PeriodType
		AND dd1e.StartDate = dd1c.StartDate
		AND dd1e.EndDate = dd1c.EndDate
	FULL OUTER JOIN #IncentivisedDD_E dd2e
		ON dd1e.ReportDate = dd2e.ReportDate
		AND dd1e.RetailerID = dd2e.RetailerID
		AND dd1e.IronOfferID = dd2e.IronOfferID
		AND dd1e.PeriodType = dd2e.PeriodType
		AND dd1e.StartDate = dd2e.StartDate
		AND dd1e.EndDate = dd2e.EndDate
	LEFT JOIN #IncentivisedDD_C dd2c
		ON COALESCE(dd2e.ReportDate, dd1e.ReportDate) = dd2c.ReportDate
		AND COALESCE(dd2e.RetailerID, dd1e.RetailerID) = dd2c.RetailerID
		AND COALESCE(dd2e.IronOfferID, dd1e.IronOfferID) = dd2c.IronOfferID
		AND COALESCE(dd2e.PeriodType, dd1e.PeriodType) = dd2c.PeriodType
		AND COALESCE(dd2e.StartDate, dd1e.StartDate) = dd2c.StartDate
		AND COALESCE(dd2e.EndDate, dd1e.EndDate) = dd2c.EndDate
		AND dd2e.CustomerGroup = dd2c.CustomerGroup
	LEFT JOIN #MaxSpendStretch mss
		ON LEFT(COALESCE(dd1e.IronOfferID, dd2e.IronOfferID), CASE WHEN CHARINDEX('-', COALESCE(dd1e.IronOfferID, dd2e.IronOfferID)) = 0 THEN LEN(COALESCE(dd1e.IronOfferID, dd2e.IronOfferID)) ELSE (CHARINDEX('-', COALESCE(dd1e.IronOfferID, dd2e.IronOfferID)))-1 END) = mss.IronOfferID;
	
	INSERT INTO #Combined
	SELECT	COALESCE(dd1e.ReportDate, dd2e.ReportDate) AS ReportDate
		,	COALESCE(dd1e.RetailerID, dd2e.RetailerID) AS RetailerID
		,	'Overall' AS IronOfferID
		,	COALESCE(dd1e.PeriodType, dd2e.PeriodType) AS PeriodType
		,	COALESCE(dd1e.StartDate, dd2e.StartDate) AS StartDate
		,	COALESCE(dd1e.EndDate, dd2e.EndDate) AS EndDate
		,	COALESCE(dd2e.CustomerGroup, 'OpeningDDOnly') AS CustomerGroup
		,	COALESCE(dd2e.CustomerGroupName, 'Opening DD Only') AS CustomerGroupName
		,	dd2e.OfferCashbackEarnable
		,	SUM(COALESCE(dd1e.Cardholders, dd2e.Cardholders)) AS Cardholders_E
		,	SUM(dd1e.UniqueDDSpenders) AS UniqueDDSpenders_E_First_NOT_ADDITIVE -- This overarches customer groups, so is duplicated for different customer groups
		,	SUM(dd2e.UniqueDDSpenders) AS UniqueDDSpenders_E_Second
		,	SUM(dd1e.DDSpend) AS DDSpend_E_First
		,	SUM(dd2e.DDSpend) AS DDSpend_E_Second
		,	SUM(dd1e.DDCount) AS DDCount_E_First
		,	SUM(dd2e.DDCount) AS DDCount_E_Second
		,	SUM(dd2e.OfferCashbackEarnable * dd2e.UniqueDDSpenders) AS CashbackEarned
		,	SUM((dd2e.Investment * dd2e.UniqueDDSpenders) - (dd2e.OfferCashbackEarnable * dd2e.UniqueDDSpenders)) AS [Override]
		,	SUM(dd2e.Investment * dd2e.UniqueDDSpenders) AS Investment
		-- Extra metrics for incremental calculations starts here
		,	ISNULL(SUM(CONVERT(FLOAT, dd1e.UniqueDDSpenders)) / NULLIF(MAX(dd1e.Cardholders), 0), 0) AS RR_E_First
		,	ISNULL(SUM(CONVERT(FLOAT, dd1c.UniqueDDSpenders)) / NULLIF(MAX(dd1c.Cardholders), 0), 0) AS RR_C_First
		,	ISNULL(SUM(CONVERT(FLOAT, dd2e.UniqueDDSpenders)) / NULLIF(MAX(dd2e.Cardholders), 0), 0) AS RR_E_Second
		,	ISNULL(SUM(CONVERT(FLOAT, dd2c.UniqueDDSpenders)) / NULLIF(MAX(dd2c.Cardholders), 0), 0) AS RR_C_Second
		,	ISNULL(SUM(CONVERT(FLOAT, dd1e.DDSpend)) / NULLIF(SUM(dd1e.UniqueDDSpenders), 0), 0) AS SPS_E_First
		,	ISNULL(SUM(CONVERT(FLOAT, dd1c.DDSpend)) / NULLIF(SUM(dd1c.UniqueDDSpenders), 0), 0) AS SPS_C_First
		,	ISNULL(SUM(CONVERT(FLOAT, dd2e.DDSpend)) / NULLIF(SUM(dd2e.UniqueDDSpenders), 0), 0) AS SPS_E_Second
		,	ISNULL(SUM(CONVERT(FLOAT, dd2c.DDSpend)) / NULLIF(SUM(dd2c.UniqueDDSpenders), 0), 0) AS SPS_C_Second
		,	ISNULL(SUM(CONVERT(FLOAT, dd2e.DDSpend)) / NULLIF(SUM(dd2e.DDCount), 0), 0) AS ATV_E_Second
		,	ISNULL(SUM(CONVERT(FLOAT, dd2c.DDSpend)) / NULLIF(SUM(dd2c.DDCount), 0), 0) AS ATV_C_Second
		,	mss.SpendStretchMaxRequirement
	FROM #OpeningDD_E dd1e
	LEFT JOIN #OpeningDD_C dd1c
		ON dd1e.ReportDate = dd1c.ReportDate
		AND dd1e.RetailerID = dd1c.RetailerID
		AND dd1e.IronOfferID = dd1c.IronOfferID
		AND dd1e.PeriodType = dd1c.PeriodType
		AND dd1e.StartDate = dd1c.StartDate
		AND dd1e.EndDate = dd1c.EndDate
	FULL OUTER JOIN #IncentivisedDD_E dd2e
		ON dd1e.ReportDate = dd2e.ReportDate
		AND dd1e.RetailerID = dd2e.RetailerID
		AND dd1e.IronOfferID = dd2e.IronOfferID
		AND dd1e.PeriodType = dd2e.PeriodType
		AND dd1e.StartDate = dd2e.StartDate
		AND dd1e.EndDate = dd2e.EndDate
	LEFT JOIN #IncentivisedDD_C dd2c
		ON COALESCE(dd2e.ReportDate, dd1e.ReportDate) = dd2c.ReportDate
		AND COALESCE(dd2e.RetailerID, dd1e.RetailerID) = dd2c.RetailerID
		AND COALESCE(dd2e.IronOfferID, dd1e.IronOfferID) = dd2c.IronOfferID
		AND COALESCE(dd2e.PeriodType, dd1e.PeriodType) = dd2c.PeriodType
		AND COALESCE(dd2e.StartDate, dd1e.StartDate) = dd2c.StartDate
		AND COALESCE(dd2e.EndDate, dd1e.EndDate) = dd2c.EndDate
		AND dd2e.CustomerGroup = dd2c.CustomerGroup
	LEFT JOIN #MaxSpendStretch mss
		ON LEFT(COALESCE(dd1e.IronOfferID, dd2e.IronOfferID), CASE WHEN CHARINDEX('-', COALESCE(dd1e.IronOfferID, dd2e.IronOfferID)) = 0 THEN LEN(COALESCE(dd1e.IronOfferID, dd2e.IronOfferID)) ELSE (CHARINDEX('-', COALESCE(dd1e.IronOfferID, dd2e.IronOfferID)))-1 END) = mss.IronOfferID
	GROUP BY	COALESCE(dd1e.ReportDate, dd2e.ReportDate)
			,	COALESCE(dd1e.RetailerID, dd2e.RetailerID)
			,	COALESCE(dd1e.PeriodType, dd2e.PeriodType)
			,	COALESCE(dd1e.StartDate, dd2e.StartDate)
			,	COALESCE(dd1e.EndDate, dd2e.EndDate)
			,	COALESCE(dd2e.CustomerGroup, 'OpeningDDOnly')
			,	COALESCE(dd2e.CustomerGroupName, 'Opening DD Only')
			,	dd2e.OfferCashbackEarnable
			,	mss.SpendStretchMaxRequirement
	





	
	-- Calculate final incremental metrics
	
	DECLARE @MinDateForPlots date = (
		SELECT MIN(x.StartDate) FROM (
			SELECT DISTINCT TOP 6
			d.StartDate
			FROM #DirectDebitResults d
			INNER JOIN #MaxReportDates md
				ON d.PeriodType = md.PeriodType
				AND d.StartDate = md.StartDate
				AND d.EndDate = md.EndDate
				AND d.ReportDate = md.ReportDate
			WHERE
				d.PeriodType <> 'Cumulative'
			ORDER BY 
				StartDate DESC
		) x
	);

	IF OBJECT_ID('tempdb..#Final') IS NOT NULL DROP TABLE #Final;
	SELECT	DISTINCT
			c.ReportDate
		,	c.RetailerID
		,	p.PartnerName AS RetailerName
		,	c.IronOfferID
		,	REPLACE(seg.IronOfferName, 'Sky MFDD Offer 3', 'SKY MFDD Offer') AS IronOfferName
		,	seg.OfferTypeForReports
		,	c.PeriodType
		,	c.StartDate AS ExposureStartDate
		,	c.EndDate AS ExposureEndDate
		,	c.CustomerGroup
		,	c.CustomerGroupName
		,	c.OfferCashbackEarnable
		,	c.Cardholders_E
		,	c.UniqueDDSpenders_E_First_NOT_ADDITIVE -- This overarches customer groups, so is duplicated for different customer groups
		,	c.UniqueDDSpenders_E_Second
		,	c.RR_E_Second AS RedemptionRate_E
		,	c.DDSpend_E_Second
		,	c.ATV_E_Second
		,	c.CashbackEarned
		,	c.[Override]
		,	c.Investment
		,	CAST((c.RR_E_First - c.RR_C_First) AS FLOAT)/NULLIF((CAST(c.RR_C_First AS FLOAT)), 0) AS RR_Uplift_First
		,	CAST((c.RR_E_Second - c.RR_C_Second) AS FLOAT)/NULLIF((CAST(c.RR_C_Second AS FLOAT)), 0) AS RR_Uplift_Second
		,	c.UniqueDDSpenders_E_First_NOT_ADDITIVE-(c.UniqueDDSpenders_E_First_NOT_ADDITIVE/NULLIF((CAST((
			1 + CAST((c.RR_E_First - c.RR_C_First) AS FLOAT)/NULLIF((CAST(c.RR_C_First AS FLOAT)), 0) -- 1 + RR Uplift
		) AS FLOAT)),0)) AS IncDDSpenders_First
		, c.UniqueDDSpenders_E_Second-(c.UniqueDDSpenders_E_Second/NULLIF((CAST((
			1 + CAST((c.RR_E_Second - c.RR_C_Second) AS FLOAT)/NULLIF((CAST(c.RR_C_Second AS FLOAT)), 0) -- 1 + RR Uplift
		) AS FLOAT)),0)) AS IncDDSpenders_Second
		, CAST(((c.RR_E_Second*c.SPS_E_Second) - (c.RR_C_Second*c.SPS_C_Second)) AS FLOAT)/NULLIF((CAST((c.RR_C_Second*c.SPS_C_Second) AS FLOAT)), 0) AS DDSpend_Uplift_Second
		, CAST((c.ATV_E_Second - c.ATV_C_Second) AS FLOAT)/NULLIF((CAST(c.ATV_C_Second AS FLOAT)), 0) AS ATV_Uplift_Second
		, c.DDSpend_E_Second-(c.DDSpend_E_Second/NULLIF((CAST((
			1 + CAST(((c.RR_E_Second*c.SPS_E_Second) - (c.RR_C_Second*c.SPS_C_Second)) AS FLOAT)/NULLIF((CAST((c.RR_C_Second*c.SPS_C_Second) AS FLOAT)), 0) -- 1 + Sales Uplift
		) AS FLOAT)),0)) AS IncDDSpend_Second
		, CASE WHEN (c.PeriodType <> 'Cumulative' AND c.StartDate >= @MinDateForPlots) OR c.PeriodType = 'Cumulative' THEN 1 ELSE 0 END AS IncludeInPlots
		, c.SpendStretchMaxRequirement
	INTO #Final
	FROM #Combined c
	LEFT JOIN [Relational].[IronOfferSegment] seg
		ON LEFT(c.IronOfferID, CASE WHEN CHARINDEX('-', c.IronOfferID) = 0 THEN LEN(c.IronOfferID) ELSE (CHARINDEX('-', c.IronOfferID))-1 END) = CAST(seg.IronOfferID AS varchar(50))
	LEFT JOIN #PartnerNames p
		ON c.RetailerID = p.PartnerID;


	SELECT	ROW_NUMBER() OVER (ORDER BY RetailerID, IronOfferID, PeriodType, ExposureStartDate, ExposureEndDate, CustomerGroup) AS RowNum
		,	*
	FROM #Final

END