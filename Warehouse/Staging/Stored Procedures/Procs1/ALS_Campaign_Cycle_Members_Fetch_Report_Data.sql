/******************************************************************************
Author	  Jason Shipp
Created	  20/02/2018
Purpose	  
	- Fetch data from MI.ALS_Members_Report_Data table for Campaign Cycle ALS Members Report
	- Table populated by Staging.ALS_Campaign_Cycle_Members_Load_Report_Data stored procedure
NOTES
	- Exclude CycleMembers with a CycleSegmentType of "No ALS Segment" to match up results with Warehouse.Staging.Campaign_Cycle_ALS_Segment_Members table
------------------------------------------------------------------------------
Modification History
	
*****************************************************************************/

CREATE PROCEDURE Staging.ALS_Campaign_Cycle_Members_Fetch_Report_Data
	(@RetailerID INT = NULL)

AS
BEGIN

	SET NOCOUNT ON;

	/**************************************************************************
	Create Retailer-colour map
	***************************************************************************/

	IF OBJECT_ID('tempdb..#ColMap') IS NOT NULL DROP TABLE #ColMap;

	WITH 
	[Retailer] AS

		(SELECT DISTINCT
		d.RetailerName
		, d.RetailerID
		, (((ROW_NUMBER() OVER(ORDER BY d.RetailerName))-1)/18) +1 AS Group18 -- Returns sequential numbers in groups of 18
		FROM 
			(SELECT DISTINCT
			d1.RetailerID
			, p.RetailerName
			FROM MI.ALS_Members_Report_Data d1 -- Report data
			LEFT JOIN 
				(SELECT DISTINCT PartnerName AS RetailerName, PartnerID FROM Warehouse.Relational.[Partner]) p -- Fetch Retailer names
					ON d1.RetailerID = p.PartnerID
			) d
		)

	, RetailerID AS

		(SELECT 
			RetailerName
			, RetailerID
			, ROW_NUMBER() OVER(PARTITION BY Group18 ORDER BY RetailerName) AS ColourID
		FROM [Retailer]
		)

	, ColourList AS
		(SELECT
			ID AS ColourID
			, ColourHexCode
			, ROW_NUMBER() OVER(ORDER BY ID) AS MatchID
		FROM Warehouse.APW.ColourList 
		)

	SELECT DISTINCT
		p.RetailerName
		, p.RetailerID
		, c.ColourID
		, c.ColourHexCode
		, x.AnchorSegmentType 
		, y.CycleSegmentType 
		, z.CycleStartDate
		, z.CycleEndDate
	INTO #ColMap
	FROM RetailerID p
	INNER JOIN ColourList c
		ON p.ColourID = c.MatchID
	CROSS JOIN (SELECT DISTINCT SuperSegmentName AS AnchorSegmentType FROM nFI.Segmentation.ROC_Shopper_Segment_Super_Types) x -- Add cross joins to complete data for SSRS matrix (for alternate row colours)
	CROSS JOIN (
		SELECT DISTINCT SuperSegmentName AS CycleSegmentType FROM nFI.Segmentation.ROC_Shopper_Segment_Super_Types
		UNION ALL
		SELECT 'No ALS Segment' AS CycleSegmentType		
	) y
	CROSS JOIN (SELECT DISTINCT CycleStartDate, CycleEndDate FROM MI.ALS_Members_Report_Data
		WHERE RetailerID = @RetailerID OR @RetailerID IS NULL) z;

	/**************************************************************************
	Fetch report data
	***************************************************************************/

	WITH MinCycleMembers AS
		(SELECT 
			d.RetailerID
			, d.CycleStartDate
			, d.CycleEndDate
			, d.AnchorSegmentType 
			, d.CycleSegmentType 
				-- Fetch ALS members associated with the first Campaign Cycle being analysed per retailer:
			, CASE WHEN d.CycleStartDate = 
				MIN(CASE WHEN d.CycleMembers IS NULL THEN NULL ELSE d.CycleStartDate END) OVER (PARTITION BY d.RetailerID, d.AnchorSegmentType) 
			THEN d.CycleMembers ELSE 0 END AS MinCycleMembers
				-- Fetch ALS members per Retailer per anchor segment type per Campaign Cycle (not grouped by cycle segment type):
			, SUM(d.CycleMembers) OVER (PARTITION BY d.RetailerID, d.CycleStartDate, d.CycleEndDate, d.AnchorSegmentType) AS GroupedCycleMembers
		FROM MI.ALS_Members_Report_Data d
		)
	, MinCycleAnchorMembers AS 
		(SELECT DISTINCT
			d.RetailerID
			, d.CycleStartDate
			, d.CycleEndDate
			, d.AnchorSegmentType 
				-- Sum ALS members associated with the first Campaign Cycle being analysed per retailer per anchor segment type:
			, SUM(d.MinCycleMembers) OVER (PARTITION BY d.RetailerID, d.AnchorSegmentType) AS MinCycleAnchorMembers
			, d.GroupedCycleMembers
		FROM MinCycleMembers d
		)

	SELECT
		col.RetailerName
		, col.RetailerID
		, col.CycleStartDate
		, col.CycleEndDate
		, col.AnchorSegmentType
		, col.CycleSegmentType
		, CASE WHEN col.CycleSegmentType = 'No ALS Segment' THEN
			m.MinCycleAnchorMembers - m.GroupedCycleMembers
		ELSE d.CycleMembers END AS CycleMembers -- Fetch cycle members; include logic for members who do not fall into an ALS segment
		, LAG(d.CycleMembers, 1, NULL) OVER(
			PARTITION BY 
				col.RetailerID
				, col.RetailerName
				, col.AnchorSegmentType
				, col.CycleSegmentType
			ORDER BY d.CycleStartDate, d.CycleEndDate
		) 
		AS CycleMembersLagged -- Fetch previous value in group for SSRS text formatting logic
		, d.Spend
		, LAG(d.Spend, 1, NULL) OVER(
			PARTITION BY 
				col.RetailerID
				, col.RetailerName
				, col.AnchorSegmentType
				, col.CycleSegmentType
			ORDER BY d.CycleStartDate, d.CycleEndDate
		) 
		AS SpendLagged
		, d.Spenders
		, LAG(d.Spenders, 1, NULL) OVER(
			PARTITION BY 
				col.RetailerID
				, col.RetailerName
				, col.AnchorSegmentType
				, col.CycleSegmentType
			ORDER BY d.CycleStartDate, d.CycleEndDate
		) 
		AS SpendersLagged
		, d.Transactions
		, LAG(d.Transactions, 1, NULL) OVER(
			PARTITION BY 
				col.RetailerID
				, col.RetailerName
				, col.AnchorSegmentType
				, col.CycleSegmentType
			ORDER BY d.CycleStartDate, d.CycleEndDate
		) 
		AS TransactionsLagged
		, d.Investment
		, LAG(d.Investment, 1, NULL) OVER(
			PARTITION BY 
				col.RetailerID
				, col.RetailerName
				, col.AnchorSegmentType
				, col.CycleSegmentType
			ORDER BY d.CycleStartDate, d.CycleEndDate
		) 
		AS InvestmentLagged
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
		, d.AdjustmentFactor
		, d.RR_Uplift
		, d.ATV_Uplift
		, d.ATF_Uplift
		, d.Sales_Uplift
		, d.IncSales
		, d.IncSpenders
		, col.ColourHexCode
	FROM #ColMap col
	LEFT JOIN MI.ALS_Members_Report_Data d
		ON col.RetailerID = d.RetailerID
		AND col.AnchorSegmentType = d.AnchorSegmentType
		AND col.CycleSegmentType = d.CycleSegmentType
		AND col.CycleStartDate = d.CycleStartDate
		AND col.CycleEndDate = d.CycleEndDate
	LEFT JOIN MinCycleAnchorMembers m
		ON col.RetailerID = m.RetailerID
		AND col.AnchorSegmentType = m.AnchorSegmentType
		AND col.CycleStartDate = m.CycleStartDate
		AND col.CycleEndDate = m.CycleEndDate
		AND col.CycleSegmentType = 'No ALS Segment'
	WHERE col.RetailerID = @RetailerID OR @RetailerID IS NULL
	ORDER BY col.RetailerName, col.CycleStartDate, col.CycleEndDate, col.AnchorSegmentType, col.CycleSegmentType;

	/**************************************************************************
	-- Fetch simple report data for doing analysis on

	SELECT
		d.*
		, p.PartnerName AS RetailerName
	FROM MI.ALS_Members_Report_Data d
	LEFT JOIN Warehouse.Relational.[Partner] p
		ON d.RetailerID = p.PartnerID
	ORDER BY
		p.PartnerName
		, d.CycleStartDate
		, d.CycleEndDate
		, d.AnchorSegmentType
		, d.CycleSegmentType;
	***************************************************************************/

END