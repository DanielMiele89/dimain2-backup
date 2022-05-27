/******************************************************************************
Author	  Jason Shipp
Created	  20/02/2018
Purpose 
	- Calculate incremental metrics and refresh the MI.ALS_Members_Report_Data table for the Campaign Cycle ALS Members Report
------------------------------------------------------------------------------
Modification History
*****************************************************************************/

CREATE PROCEDURE Staging.ALS_Campaign_Cycle_Members_Load_Report_Data

AS
BEGIN

	SET NOCOUNT ON;

	/**************************************************************************
	Aggregate exposed results across retailer
	***************************************************************************/

	IF OBJECT_ID('tempdb..#ResultsAgg') IS NOT NULL DROP TABLE #ResultsAgg;

	SELECT
		d.IsRecentActivity
		, d.RetailerID
		, d.AnalysisStartDate
		, d.CycleStartDate
		, d.CycleEndDate
		, d.AnchorSegmentType
		, d.CycleSegmentType
		, SUM(d.CycleMembers) AS CycleMembers
		, SUM(d.Transactions) AS Transactions
		, SUM(d.Spenders) AS Spenders
		, SUM(d.Spend) AS Spend
		, SUM(d.Investment) AS Investment
	INTO #ResultsAgg
	FROM Staging.ALS_Trans_Results d
	WHERE
		d.IsRecentActivity = 1 -- Only most-recent activity per retailer
		-- AND d.PublisherType = 'Warehouse'
	GROUP BY 
		IsRecentActivity
		, d.RetailerID
		, d.AnalysisStartDate
		, d.CycleStartDate
		, d.CycleEndDate
		, d.AnchorSegmentType
		, d.CycleSegmentType;

	/**************************************************************************
	Aggregate control results across retailer
	***************************************************************************/

	IF OBJECT_ID('tempdb..#CResultsAgg') IS NOT NULL DROP TABLE #CResultsAgg;

	SELECT
		d.IsRecentActivity
		, d.RetailerID
		, d.AnalysisStartDate
		, d.CycleStartDate
		, d.CycleEndDate
		, d.AnchorSegmentType
		, SUM(d.CycleMembers) AS CycleMembers
		, SUM(d.Transactions) AS Transactions
		, SUM(d.Spenders) AS Spenders
		, SUM(d.Spend) AS Spend
	INTO #CResultsAgg
	FROM Staging.ALS_Control_Trans_Results d
	WHERE
		d.IsRecentActivity = 1 -- Only most-recent activity per retailer
	GROUP BY 
		IsRecentActivity
		, d.RetailerID
		, d.AnalysisStartDate
		, d.CycleStartDate
		, d.CycleEndDate
		, d.AnchorSegmentType;

	/**************************************************************************
	Load report data holding
	***************************************************************************/

	IF OBJECT_ID('tempdb..#ReportData_Holding') IS NOT NULL DROP TABLE #ReportData_Holding;

	SELECT 
		d.IsRecentActivity	
		, d.RetailerID
		, d.AnalysisStartDate
		, d.CycleStartDate
		, d.CycleEndDate
		, d.AnchorSegmentType
		, d.CycleSegmentType
		, d.CycleMembers
		, d.Transactions
		, d.Spenders
		, d.Spend
		, d.Investment
		, c.CycleMembers AS CycleMembers_C
		, c.Transactions AS Transactions_C
		, c.Spenders AS Spenders_C
		, c.Spend AS Spend_C
		, (CAST(d.Spend AS FLOAT))/NULLIF(d.CycleMembers, 0) AS SPC
		, (CAST(d.Spend AS FLOAT))/NULLIF(d.Spenders, 0) AS SPS
		, (CAST(d.Spenders AS FLOAT))/NULLIF(d.CycleMembers, 0) AS RR
		, (CAST(d.Spend AS FLOAT))/NULLIF(d.Transactions, 0) AS ATV
		, (CAST(d.Transactions AS FLOAT))/NULLIF(d.Spenders, 0) AS ATF
		, (CAST(c.Spend AS FLOAT))/NULLIF(c.CycleMembers, 0) AS SPC_C
		, (CAST(c.Spend AS FLOAT))/NULLIF(c.Spenders, 0) AS SPS_C
		, (CAST(c.Spenders AS FLOAT))/NULLIF(c.CycleMembers, 0) AS RR_C
		, (CAST(c.Spend AS FLOAT))/NULLIF(c.Transactions, 0) AS ATV_C
		, (CAST(c.Transactions AS FLOAT))/NULLIF(c.Spenders, 0) AS ATF_C
		, 1.0 AS AdjustmentFactor
	INTO #ReportData_Holding
	FROM #ResultsAgg d
	LEFT JOIN #CResultsAgg c
		ON d.IsRecentActivity = c.IsRecentActivity
		AND d.RetailerID = c.RetailerID
		AND d.AnalysisStartDate = c.AnalysisStartDate
		AND d.CycleStartDate = c.CycleStartDate
		AND d.CycleEndDate = c.CycleEndDate
		AND d.AnchorSegmentType = c.AnchorSegmentType;

	/**************************************************************************
	Refresh the MI.ALS_Members_Report_Data table

	-- Create table:

	CREATE TABLE MI.ALS_Members_Report_Data
		(ID INT IDENTITY NOT NULL
		, IsRecentActivity BIT
		, RetailerID INT
		, AnalysisStartDate DATE
		, CycleStartDate DATE
		, CycleEndDate DATE
		, AnchorSegmentType VARCHAR(50)
		, CycleSegmentType VARCHAR(50)
		, CycleMembers INT
		, Transactions INT
		, Spenders INT
		, Spend MONEY
		, Investment MONEY
		, CycleMembers_C INT
		, Transactions_C INT
		, Spenders_C INT
		, Spend_C MONEY
		, SPC FLOAT
		, SPS FLOAT
		, RR FLOAT
		, ATV FLOAT
		, ATF FLOAT
		, SPC_C FLOAT
		, SPS_C FLOAT
		, RR_C FLOAT
		, ATV_C FLOAT
		, ATF_C FLOAT
		, AdjustmentFactor FLOAT
		, RR_Uplift FLOAT
		, ATV_Uplift FLOAT
		, ATF_Uplift FLOAT
		, Sales_Uplift FLOAT
		, IncSales MONEY
		, IncSpenders INT
		) 
	ALTER TABLE MI.ALS_Members_Report_Data
	ADD CONSTRAINT PK_ALS_Members_Report_Data PRIMARY KEY CLUSTERED (ID);

	***************************************************************************/

	TRUNCATE TABLE MI.ALS_Members_Report_Data;

	INSERT INTO MI.ALS_Members_Report_Data
		(IsRecentActivity
		, RetailerID
		, AnalysisStartDate
		, CycleStartDate
		, CycleEndDate
		, AnchorSegmentType
		, CycleSegmentType
		, CycleMembers
		, Transactions
		, Spenders
		, Spend
		, Investment
		, CycleMembers_C
		, Transactions_C
		, Spenders_C
		, Spend_C
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
		, AdjustmentFactor
		, RR_Uplift
		, ATV_Uplift
		, ATF_Uplift
		, Sales_Uplift
		, IncSales
		, IncSpenders
		)

	SELECT 
		d.IsRecentActivity	
		, d.RetailerID
		, d.AnalysisStartDate
		, d.CycleStartDate
		, d.CycleEndDate
		, d.AnchorSegmentType
		, d.CycleSegmentType
		, d.CycleMembers
		, d.Transactions
		, d.Spenders
		, d.Spend
		, d.Investment
		, d.CycleMembers_C
		, d.Transactions_C
		, d.Spenders_C
		, d.Spend_C
		, d.SPC
		, d.SPS
		, d.RR
		, d.ATV
		, d.ATF
		, d.SPC_C
		, d.SPS_C
		, d.RR_C
		, d.ATV_C
		, d.ATF_C
		, 1.0 AS AdjustmentFactor
		, CAST((d.RR - d.RR_C) AS FLOAT)/NULLIF((CAST(d.RR_C AS FLOAT)), 0) AS RR_Uplift
		, CAST((d.ATV - d.ATV_C) AS FLOAT)/NULLIF((CAST(d.ATV_C AS FLOAT)), 0) AS ATV_Uplift
		, CAST((d.ATF - d.ATF_C) AS FLOAT)/NULLIF((CAST(d.ATF_C AS FLOAT)), 0) AS ATF_Uplift
		, CAST(((d.RR*d.SPS) - (d.RR_C*d.SPS_C*d.AdjustmentFactor)) AS FLOAT)/NULLIF((CAST((d.RR_C*d.SPS_C*d.AdjustmentFactor) AS FLOAT)), 0) AS Sales_Uplift
		, d.Spend-(d.spend/(CAST((
			1 + (CAST(((d.RR*d.SPS) - (d.RR_C*d.SPS_C*d.AdjustmentFactor)) AS FLOAT)/NULLIF((CAST((d.RR_C*d.SPS_C*d.AdjustmentFactor) AS FLOAT)), 0)) -- 1 + Sales Uplift
		) AS FLOAT))) AS IncSales
		, d.Spenders-(d.spenders/(CAST((
			1 + CAST((d.RR - d.RR_C) AS FLOAT)/NULLIF((CAST(d.RR_C AS FLOAT)), 0) -- 1 + RR Uplift
		) AS FLOAT))) AS IncSpenders
	FROM #ReportData_Holding d;

END