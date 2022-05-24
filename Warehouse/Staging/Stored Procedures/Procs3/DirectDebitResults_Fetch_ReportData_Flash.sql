﻿/******************************************************************************
Author: Jason Shipp
Created: 22/01/2019
Purpose: 
	- Fetch Merchant Funded Direct Debit Flash Report data from Warehouse.Staging.DirectDebitResults table
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 20/02/2019
	- Added Iron Offer name to fetch

Jason Shipp 02/04/2019
	- Added Spend, Investment and ATV to 2nd DD over/under £50 fetch

Jason Shipp 24/07/2019
	- Updated references to CustomerGroup and DDRankByDateGroup so stored procedure is more adaptable to different retailer incentivisation business rules

Jason Shipp 13/08/2019
	- Updated max report date logic to instead use the max report date associated with each analysis window, to avoid the need to calculate all analysis windows each time the process is run

Jason Shipp 16/09/2019
	- Added fallbacks for customer groups and spendstretches for customers who have only paid a first DD

Jason Shipp 09/03/2020
	- Adjusted joins on IronOfferIDs to exclude suffixes, for cases where retailers have Iron Offer sub-segments (e.g. Sky Mobile)

******************************************************************************/

CREATE PROCEDURE [Staging].[DirectDebitResults_Fetch_ReportData_Flash] (@RetailerID int, @PeriodType VARCHAR(10))
	
AS
BEGIN

	SET NOCOUNT ON;

	--DECLARE @RetailerID int = 4913 -- Hearst primary PartnerID
	--DECLARE @PeriodType VARCHAR(10) = 'Weekly'; -- Hearst primary PartnerID

	-- Load max report dates associated with each analysis period

	IF OBJECT_ID('tempdb..#DirectDebitResults') IS NOT NULL DROP TABLE #DirectDebitResults;
	SELECT *
	INTO #DirectDebitResults
	FROM Warehouse.Staging.DirectDebitResults
	WHERE RetailerID = @RetailerID
	AND PeriodType IN (@PeriodType, 'Cumulative')

	IF OBJECT_ID('tempdb..#MaxReportDates') IS NOT NULL DROP TABLE #MaxReportDates;

	SELECT
		r.PeriodType
		, r.StartDate
		, r.EndDate
		, MAX(r.ReportDate) AS ReportDate
	INTO #MaxReportDates
	FROM #DirectDebitResults r
	OUTER APPLY (
		SELECT 
		r2.PeriodType
		, r2.StartDate
		, MAX(DATEDIFF(day, r2.StartDate, r2.EndDate)) AS MaxPeriodDays
		FROM #DirectDebitResults r2
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

	-- Load date from which to include in plots

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
				AND d.RetailerID = @RetailerID
			ORDER BY 
				StartDate DESC
		) x
	);

	-- Load spend stretch rules

	IF OBJECT_ID('tempdb..#SpendStretchRules') IS NOT NULL DROP TABLE #SpendStretchRules;

	SELECT DISTINCT
		CAST(r.IronOfferID AS varchar(50)) AS IronOfferID
		, CAST(r.MinimumSpend AS money) AS MinimumSpend
		, CAST(LEAD(r.MinimumSpend, 1, NULL) OVER(PARTITION BY r.IronOfferID ORDER BY r.MinimumSpend ASC)-0.0001 AS money) AS MaximumSpend
		, CAST(ISNULL(r.RewardAmount, 0) AS money) AS RewardAmount
		, CAST(ISNULL(r.RewardPercent, 0) AS float) / 100 AS RewardPercent
		, CAST(ISNULL(r.BillingAmount, 0) AS money) AS BillingAmount
		, CAST(ISNULL(r.BillingPercent, 0) AS float) / 100 AS BillingPercent
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
		, CAST(ISNULL(r.RewardAmount, 0) AS money) AS RewardAmount
		, CAST(ISNULL(r.RewardPercent, 0) AS float) / 100 AS RewardPercent
		, CAST(ISNULL(r.BillingAmount, 0) AS money) AS BillingAmount
		, CAST(ISNULL(r.BillingPercent, 0) AS float) / 100 AS BillingPercent
	FROM SLC_Report.dbo.DirectDebitOfferRules r
	INNER JOIN Warehouse.Relational.IronOfferSegment s
		ON r.IronOfferID = s.IronOfferID
	WHERE s.RetailerID = @RetailerID;

	IF OBJECT_ID('tempdb..#MaxSpendStretch') IS NOT NULL DROP TABLE #MaxSpendStretch;

	SELECT DISTINCT
		r.IronOfferID
		, MAX(r.MinimumSpend) AS SpendStretchMaxRequirement
	INTO #MaxSpendStretch
	FROM #SpendStretchRules r
	GROUP BY 
		r.IronOfferID;

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

	-- Load opening DD summary (FanIDs are unique between CustomerGroups so can just add up to get unique spenders)

	IF OBJECT_ID('tempdb..#OpeningDD') IS NOT NULL DROP TABLE #OpeningDD;

	SELECT 
		d.ReportDate
		, d.RetailerID
		, d.IronOfferID
		, d.PeriodType
		, d.StartDate
		, d.EndDate
		, d.DDRankByDateGroup
		, MAX(d.Cardholders) AS Cardholders
		, SUM(ISNULL(d.UniqueDDSpenders, 0)) AS UniqueDDSpenders
		, ISNULL((CAST(SUM(d.UniqueDDSpenders) AS FLOAT))/NULLIF(MAX(d.Cardholders), 0), 0) AS RR
		, SUM(ISNULL(d.DDCount, 0)) AS DDCount
		, SUM(ISNULL(d.DDSpend, 0)) AS DDSpend
		, ISNULL((CAST(SUM(d.DDSpend) AS FLOAT))/NULLIF(SUM(d.DDCount), 0), 0) AS ATV
	INTO #OpeningDD
	FROM #DirectDebitResults d
	INNER JOIN #MaxReportDates md
		ON d.PeriodType = md.PeriodType
		AND d.StartDate = md.StartDate
		AND d.EndDate = md.EndDate
		AND d.ReportDate = md.ReportDate
	WHERE 
		d.RetailerID = @RetailerID
		AND d.IsExposed = 1
		AND d.DDRankByDateGroup = 'Opening'
	GROUP BY
		d.RetailerID
		, d.IronOfferID
		, d.PeriodType
		, d.StartDate
		, d.EndDate
		, d.DDRankByDateGroup
		, d.ReportDate;

	-- Load incentivised DD summary (FanIDs are unique between CustomerGroups so can just add up to get unique spenders)

	IF OBJECT_ID('tempdb..#IncentivisedDD') IS NOT NULL DROP TABLE #IncentivisedDD;

	SELECT 
		d.ReportDate
		, d.RetailerID
		, d.IronOfferID
		, d.PeriodType
		, d.StartDate
		, d.EndDate
		, d.DDRankByDateGroup
		, MAX(d.Cardholders) AS Cardholders
		, SUM(ISNULL(d.UniqueDDSpenders, 0)) AS UniqueDDSpenders
		, ISNULL((CAST(SUM(d.UniqueDDSpenders) AS FLOAT))/NULLIF(MAX(d.Cardholders), 0), 0) AS RR
		, SUM(ISNULL(d.DDCount, 0)) AS DDCount
		, SUM(ISNULL(d.DDSpend, 0)) AS DDSpend
		, ISNULL((CAST(SUM(d.DDSpend) AS FLOAT))/NULLIF(SUM(d.DDCount), 0), 0) AS ATV
	INTO #IncentivisedDD
	FROM #DirectDebitResults d
	INNER JOIN #MaxReportDates md
		ON d.PeriodType = md.PeriodType
		AND d.StartDate = md.StartDate
		AND d.EndDate = md.EndDate
		AND d.ReportDate = md.ReportDate
	WHERE 
		d.RetailerID = @RetailerID
		AND d.IsExposed = 1
		AND d.DDRankByDateGroup = 'Incentivised'
	GROUP BY
		d.RetailerID
		, d.IronOfferID
		, d.PeriodType
		, d.StartDate
		, d.EndDate
		, d.DDRankByDateGroup
		, d.ReportDate;
		
	-- Load proportion of incentivised DDs over maximum spend stretch

	IF OBJECT_ID('tempdb..#DDProportions') IS NOT NULL DROP TABLE #DDProportions;
	WITH
	SecondDDCustomersOverMax AS (	SELECT	d.ReportDate
										,	d.RetailerID
										,	d.IronOfferID
										,	d.PeriodType
										,	d.StartDate
										,	d.EndDate
										,	d.CustomerGroup
										,	d.DDRankByDateGroup
										,	d.UniqueDDSpenders AS UniqueDDSpenders
										,	d.DDCount
										,	d.DDSpend
										,	CASE
												WHEN ssr.BillingPercent = 0 THEN ssr.BillingAmount * d.DDCount
												WHEN ssr.BillingAmount = 0 THEN ssr.BillingPercent * d.DDSpend
											END AS Investment
									--	,	ssr.BillingAmount * d.UniqueDDSpenders AS Investment
										,	ISNULL(d.DDSpend/(NULLIF(CAST(d.DDCount AS float),0)), 0) AS ATV
										,	mss.SpendStretchMaxRequirement
									FROM #DirectDebitResults d
									INNER JOIN #MaxReportDates md
										ON d.PeriodType = md.PeriodType
										AND d.StartDate = md.StartDate
										AND d.EndDate = md.EndDate
										AND d.ReportDate = md.ReportDate
									INNER JOIN #MaxSpendStretch mss
										ON LEFT(d.IronOfferID, CASE WHEN CHARINDEX('-', d.IronOfferID) = 0 THEN LEN(d.IronOfferID) ELSE (CHARINDEX('-', d.IronOfferID))-1 END) = mss.IronOfferID
										AND d.CustomerGroupMinSpend = mss.SpendStretchMaxRequirement
										AND d.CustomerGroup NOT LIKE '%OpeningDDOnly%'
									INNER JOIN #SpendStretchRules ssr
										ON LEFT(d.IronOfferID, CASE WHEN CHARINDEX('-', d.IronOfferID) = 0 THEN LEN(d.IronOfferID) ELSE (CHARINDEX('-', d.IronOfferID))-1 END) = ssr.IronOfferID
										AND d.CustomerGroupMinSpend = ssr.MinimumSpend
									WHERE d.RetailerID = @RetailerID
										AND d.IsExposed = 1
										AND d.DDRankByDateGroup = 'Incentivised'
										AND d.IronOfferID != 'Overall'),
	
	SecondDDCustomersUnderMax AS (	SELECT	d.ReportDate
										,	d.RetailerID
										,	d.IronOfferID
										,	d.PeriodType
										,	d.StartDate
										,	d.EndDate
										,	d.CustomerGroup
										,	d.DDRankByDateGroup
										,	d.UniqueDDSpenders AS UniqueDDSpenders
										,	d.DDCount
										,	d.DDSpend
										,	CASE
												WHEN ssr.BillingPercent = 0 THEN ssr.BillingAmount * d.DDCount
												WHEN ssr.BillingAmount = 0 THEN ssr.BillingPercent * d.DDSpend
											END AS Investment
									--	,	ssr.BillingAmount * d.UniqueDDSpenders AS Investment -- Cashback + Override
										,	ISNULL(d.DDSpend/(NULLIF(CAST(d.DDCount AS float),0)), 0) AS ATV
									FROM #DirectDebitResults d
									INNER JOIN #MaxReportDates md
										ON d.PeriodType = md.PeriodType
										AND d.StartDate = md.StartDate
										AND d.EndDate = md.EndDate
										AND d.ReportDate = md.ReportDate
									INNER JOIN #MaxSpendStretch mss
										ON LEFT(d.IronOfferID, CASE WHEN CHARINDEX('-', d.IronOfferID) = 0 THEN LEN(d.IronOfferID) ELSE (CHARINDEX('-', d.IronOfferID))-1 END) = mss.IronOfferID
										AND ISNULL(d.CustomerGroupMinSpend, 0) < mss.SpendStretchMaxRequirement
										AND d.CustomerGroup NOT LIKE '%OpeningDDOnly%'
									INNER JOIN #SpendStretchRules ssr
										ON LEFT(d.IronOfferID, CASE WHEN CHARINDEX('-', d.IronOfferID) = 0 THEN LEN(d.IronOfferID) ELSE (CHARINDEX('-', d.IronOfferID))-1 END) = ssr.IronOfferID
										AND d.CustomerGroupMinSpend = ssr.MinimumSpend
									WHERE 
										d.RetailerID = @RetailerID
										AND d.IsExposed = 1
										AND d.DDRankByDateGroup = 'Incentivised'
										AND d.IronOfferID != 'Overall')

	SELECT	o.ReportDate
		,	o.RetailerID
		,	o.IronOfferID
		,	o.PeriodType
		,	o.StartDate
		,	o.EndDate
		,	o.SpendStretchMaxRequirement
		,	o.UniqueDDSpenders AS UniqueDDSpenders_Second_OverMax
		,	u.UniqueDDSpenders AS UniqueDDSpenders_Second_UnderMax
		,	o.DDCount AS DDCount_Second_OverMax
		,	u.DDCount AS DDCount_Second_UnderMax
		,	o.DDSpend AS DDSpend_Second_OverMax
		,	u.DDSpend AS DDSpend_Second_UnderMax
		,	o.Investment AS Investment_Second_OverMax
		,	u.Investment AS Investment_Second_UnderMax
		,	o.ATV AS ATV_Second_OverMax
		,	u.ATV AS ATV_Second_UnderMax
		,	ISNULL((CAST(o.UniqueDDSpenders AS FLOAT))/NULLIF(o.UniqueDDSpenders+u.UniqueDDSpenders, 0), 0) AS ProportionSecondDDSpendersOverMaxSpend
	INTO #DDProportions
	FROM SecondDDCustomersOverMax o
	FULL OUTER JOIN SecondDDCustomersUnderMax u
		ON o.ReportDate = u.ReportDate
		AND o.RetailerID = u.RetailerID
		AND o.IronOfferID = u.IronOfferID
		AND o.PeriodType = u.PeriodType
		AND o.StartDate = u.StartDate
		AND o.EndDate = u.EndDate;

	INSERT INTO #DDProportions
	SELECT	ReportDate
		,	RetailerID
		,	'Overall' AS IronOfferID
		,	PeriodType
		,	StartDate
		,	EndDate
		,	SpendStretchMaxRequirement
		,	SUM(UniqueDDSpenders_Second_OverMax) AS UniqueDDSpenders_Second_OverMax
		,	SUM(UniqueDDSpenders_Second_UnderMax) AS UniqueDDSpenders_Second_UnderMax
		,	SUM(DDCount_Second_OverMax) AS DDCount_Second_OverMax
		,	SUM(DDCount_Second_UnderMax) AS DDCount_Second_UnderMax
		,	SUM(DDSpend_Second_OverMax) AS DDSpend_Second_OverMax
		,	SUM(DDSpend_Second_UnderMax) AS DDSpend_Second_UnderMax
		,	SUM(Investment_Second_OverMax) AS Investment_Second_OverMax
		,	SUM(Investment_Second_UnderMax) AS Investment_Second_UnderMax
		,	ISNULL(SUM(DDSpend_Second_OverMax) / (NULLIF(CONVERT(FLOAT, SUM(DDCount_Second_OverMax)), 0)), 0) AS ATV_Second_OverMax
		,	ISNULL(SUM(DDSpend_Second_UnderMax) / (NULLIF(CONVERT(FLOAT, SUM(DDCount_Second_UnderMax)), 0)), 0) AS ATV_Second_UnderMax
		,	ISNULL((CONVERT(FLOAT, SUM(UniqueDDSpenders_Second_OverMax))) / NULLIF(SUM(UniqueDDSpenders_Second_OverMax) + SUM(UniqueDDSpenders_Second_UnderMax), 0), 0) AS ProportionSecondDDSpendersOverMaxSpend
	FROM #DDProportions
	GROUP BY ReportDate
		,	RetailerID
		,	PeriodType
		,	StartDate
		,	EndDate
		,	SpendStretchMaxRequirement

	-- Fetch combined results
	
	IF OBJECT_ID('tempdb..#CombinedResults') IS NOT NULL DROP TABLE #CombinedResults;
	SELECT	DISTINCT
			COALESCE(dd1.ReportDate, dd2.ReportDate) AS ReportDate
		,	COALESCE(dd1.RetailerID, dd2.RetailerID) AS RetailerID
		,	p.PartnerName AS RetailerName
		,	COALESCE(dd1.IronOfferID, dd2.IronOfferID) AS IronOfferID
		,	REPLACE(seg.IronOfferName, 'Sky MFDD Offer 3', 'SKY MFDD Offer') AS IronOfferName
		,	seg.OfferTypeForReports
		,	COALESCE(dd1.PeriodType, dd2.PeriodType) AS PeriodType
		,	COALESCE(dd1.StartDate, dd2.StartDate) AS ExposureStartDate
		,	COALESCE(dd1.EndDate, dd2.EndDate) AS ExposureEndDate
		,	COALESCE(dd1.Cardholders, dd2.Cardholders) AS Cardholders
		,	dd1.UniqueDDSpenders AS UniqueDDSpenders_First
		,	dd1.RR AS RR_First
		,	dd1.DDCount AS DDCount_First
		,	dd1.DDSpend AS DDSpend_First
		,	dd1.ATV AS ATV_First
		,	dd2.UniqueDDSpenders AS UniqueDDSpenders_Second
		,	dd2.RR AS RR_Second
		,	dd2.DDCount AS DDCount_Second
		,	dd2.DDSpend AS DDSpend_Second
		,	dd2.ATV AS ATV_Second
		,	mss.SpendStretchMaxRequirement
		,	ddp.ProportionSecondDDSpendersOverMaxSpend
		,	ddp.UniqueDDSpenders_Second_OverMax
		,	ddp.UniqueDDSpenders_Second_UnderMax
		,	ddp.DDCount_Second_OverMax
		,	ddp.DDCount_Second_UnderMax
		,	ddp.DDSpend_Second_OverMax
		,	ddp.DDSpend_Second_UnderMax
		,	ddp.Investment_Second_OverMax
		,	ddp.Investment_Second_UnderMax
		,	ddp.ATV_Second_OverMax
		,	ddp.ATV_Second_UnderMax
		,	CASE WHEN (COALESCE(dd1.PeriodType, dd2.PeriodType) <> 'Cumulative' AND COALESCE(dd1.StartDate, dd2.StartDate) >= @MinDateForPlots) OR COALESCE(dd1.PeriodType, dd2.PeriodType) = 'Cumulative' THEN 1 ELSE 0 END AS IncludeInPlots
	INTO #CombinedResults
	FROM #OpeningDD dd1
	FULL OUTER JOIN #IncentivisedDD dd2
		ON dd1.ReportDate = dd1.ReportDate
		AND dd1.RetailerID = dd2.RetailerID
		AND dd1.IronOfferID = dd2.IronOfferID
		AND dd1.PeriodType = dd2.PeriodType
		AND dd1.StartDate = dd2.StartDate
		AND dd1.EndDate = dd2.EndDate
	LEFT JOIN #DDProportions ddp
		ON COALESCE(dd1.ReportDate, dd2.ReportDate) = ddp.ReportDate
		AND COALESCE(dd1.RetailerID, dd2.RetailerID) = ddp.RetailerID
		AND COALESCE(dd1.IronOfferID, dd2.IronOfferID) = ddp.IronOfferID
		AND COALESCE(dd1.PeriodType, dd2.PeriodType) = ddp.PeriodType
		AND COALESCE(dd1.StartDate, dd2.StartDate) = ddp.StartDate
		AND COALESCE(dd1.EndDate, dd2.EndDate) = ddp.EndDate
	LEFT JOIN #PartnerNames p
		ON COALESCE(dd1.RetailerID, dd2.RetailerID) = p.PartnerID
	LEFT JOIN Warehouse.Relational.IronOfferSegment seg
		ON LEFT(COALESCE(dd1.IronOfferID, dd2.IronOfferID), CASE WHEN CHARINDEX('-', COALESCE(dd1.IronOfferID, dd2.IronOfferID)) = 0 THEN LEN(COALESCE(dd1.IronOfferID, dd2.IronOfferID)) ELSE (CHARINDEX('-', COALESCE(dd1.IronOfferID, dd2.IronOfferID)))-1 END) = CAST(seg.IronOfferID AS varchar(50))
	LEFT JOIN #MaxSpendStretch mss
		ON LEFT(COALESCE(dd1.IronOfferID, dd2.IronOfferID), CASE WHEN CHARINDEX('-', COALESCE(dd1.IronOfferID, dd2.IronOfferID)) = 0 THEN LEN(COALESCE(dd1.IronOfferID, dd2.IronOfferID)) ELSE (CHARINDEX('-', COALESCE(dd1.IronOfferID, dd2.IronOfferID)))-1 END) = mss.IronOfferID;
		
	
	UPDATE #CombinedResults
	SET IronOfferName = REPLACE(IronOfferName, 'Sky MFDD Offer 3', 'SKY MFDD Offer')
	
	UPDATE #CombinedResults
	SET IronOfferName = REPLACE(IronOfferName, 'Sky MFDD Offer 4', 'SKY MFDD Offer')

	SELECT	ROW_NUMBER() OVER (ORDER BY RetailerID, IronOfferID, PeriodType, ExposureStartDate, ExposureEndDate) AS RowNum
		,	ReportDate
		,	RetailerID
		,	RetailerName
		,	IronOfferID
		,	IronOfferName
		,	OfferTypeForReports
		,	PeriodType
		,	ExposureStartDate
		,	ExposureEndDate
		,	Cardholders
		,	UniqueDDSpenders_First
		,	ISNULL((CONVERT(FLOAT, UniqueDDSpenders_First))/ NULLIF(Cardholders, 0), 0) AS RR_First
		,	DDCount_First
		,	DDSpend_First
		,	ISNULL(DDSpend_First / (NULLIF(CONVERT(FLOAT, DDCount_First), 0)), 0) AS ATV_First
		,	UniqueDDSpenders_Second
		,	ISNULL((CONVERT(FLOAT, UniqueDDSpenders_Second))/ NULLIF(Cardholders, 0), 0) AS RR_Second
		,	DDCount_Second
		,	DDSpend_Second
		,	ISNULL(DDSpend_Second / (NULLIF(CONVERT(FLOAT, DDCount_Second), 0)), 0) AS ATV_Second
		,	SpendStretchMaxRequirement
		,	ISNULL((CONVERT(FLOAT, UniqueDDSpenders_Second_OverMax)) / NULLIF(UniqueDDSpenders_Second_OverMax + UniqueDDSpenders_Second_UnderMax, 0), 0) AS ProportionSecondDDSpendersOverMaxSpend
		,	UniqueDDSpenders_Second_OverMax
		,	UniqueDDSpenders_Second_UnderMax
		,	DDCount_Second_OverMax
		,	DDCount_Second_UnderMax
		,	DDSpend_Second_OverMax
		,	DDSpend_Second_UnderMax
		,	Investment_Second_OverMax
		,	Investment_Second_UnderMax
		,	ISNULL(DDSpend_Second_OverMax / (NULLIF(CONVERT(FLOAT, DDCount_Second_OverMax), 0)), 0) AS ATV_Second_OverMax
		,	ISNULL(DDSpend_Second_UnderMax / (NULLIF(CONVERT(FLOAT, DDCount_Second_UnderMax), 0)), 0) AS ATV_Second_UnderMax
		,	IncludeInPlots
	FROM	(SELECT	ReportDate
				,	RetailerID
				,	RetailerName
				,	MAX(IronOfferID) AS IronOfferID
				,	IronOfferName
				,	OfferTypeForReports
				,	PeriodType
				,	ExposureStartDate
				,	ExposureEndDate
				,	MAX(Cardholders) AS Cardholders
				,	SUM(UniqueDDSpenders_First) AS UniqueDDSpenders_First
				,	AVG(RR_First) AS RR_First
				,	SUM(DDCount_First) AS DDCount_First
				,	SUM(DDSpend_First) AS DDSpend_First
				,	AVG(ATV_First) AS ATV_First
				,	SUM(UniqueDDSpenders_Second) AS UniqueDDSpenders_Second
				,	AVG(RR_Second) AS RR_Second
				,	SUM(DDCount_Second) AS DDCount_Second
				,	SUM(DDSpend_Second) AS DDSpend_Second
				,	AVG(ATV_Second) AS ATV_Second
				,	SpendStretchMaxRequirement
				,	AVG(ProportionSecondDDSpendersOverMaxSpend) AS ProportionSecondDDSpendersOverMaxSpend
				,	SUM(UniqueDDSpenders_Second_OverMax) AS UniqueDDSpenders_Second_OverMax
				,	SUM(UniqueDDSpenders_Second_UnderMax) AS UniqueDDSpenders_Second_UnderMax
				,	SUM(DDCount_Second_OverMax) AS DDCount_Second_OverMax
				,	SUM(DDCount_Second_UnderMax) AS DDCount_Second_UnderMax
				,	SUM(DDSpend_Second_OverMax) AS DDSpend_Second_OverMax
				,	SUM(DDSpend_Second_UnderMax) AS DDSpend_Second_UnderMax
				,	SUM(Investment_Second_OverMax) AS Investment_Second_OverMax
				,	SUM(Investment_Second_UnderMax) AS Investment_Second_UnderMax
				,	AVG(ATV_Second_OverMax) AS ATV_Second_OverMax
				,	AVG(ATV_Second_UnderMax) AS ATV_Second_UnderMax
				,	IncludeInPlots
			FROM #CombinedResults
			GROUP BY	ReportDate
					,	RetailerID
					,	RetailerName
					,	IronOfferName
					,	OfferTypeForReports
					,	PeriodType
					,	ExposureStartDate
					,	ExposureEndDate
					,	SpendStretchMaxRequirement
					,	IncludeInPlots) a
	ORDER BY RetailerID, IronOfferID, PeriodType, ExposureStartDate, ExposureEndDate

	/******************************************************************************
	-- Script to check base results
	
	USE [SLC_Report]

	SELECT 
		CAST(m.TransactionDate AS date) AS TransactionDate
		, SUM(CASE WHEN m.RewardStatus = 17 THEN 1 ELSE 0 END) as NewPassiveMarker
		, SUM(CASE WHEN m.RewardStatus = 15 THEN 1 ELSE 0 END) as NewFirstTransaction
		, SUM(CASE WHEN m.RewardStatus = 1 and m.Amount <50 THEN 1 ELSE 0 END) as NewIncentivisedEarnersUnder50
		, SUM(CASE WHEN m.RewardStatus = 1 and m.Amount >=50 THEN 1 ELSE 0 END) as NewIncentivisedEarnersOver50
		, SUM(CASE WHEN m.RewardStatus = 16 THEN 1 ELSE 0 END) as NewLaterTransaction
	FROM SLC_Report.dbo.Match m
	WHERE 
		m.DirectDebitOriginatorID IN (312, 822, 1085)
		AND m.AddedDate >= '2019-04-11'
		AND m.VectorID = 40
	GROUP BY 
		CAST(m.TransactionDate AS date)
	ORDER BY 
		CAST(m.TransactionDate AS date) ASC;
	******************************************************************************/

END