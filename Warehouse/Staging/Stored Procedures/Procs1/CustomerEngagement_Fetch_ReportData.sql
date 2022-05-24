/******************************************************************************
Author: Jason Shipp
Created: 18/05/2018
Purpose: 
- Fetches report data for the Customer Engagement report
- Data fetched for the most recent segmentation period, and the 2 segmentation periods prior
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.CustomerEngagement_Fetch_ReportData
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- Load segment-colour mapping

	IF OBJECT_ID('tempdb..#SegCol') IS NOT NULL DROP TABLE #SegCol;

	WITH Seg AS (
		SELECT DISTINCT
		EngagementSegment
		FROM Warehouse.Staging.CustomerEngagement_ReportData
		)
	, SegID AS (
		SELECT
		EngagementSegment
		, ROW_NUMBER() OVER (ORDER BY EngagementSegment) AS ID
		FROM Seg
		)
	SELECT 
		s.EngagementSegment
		, col.ColourHexCode
	INTO #SegCol
	FROM SegID s
	INNER JOIN Warehouse.APW.ColourList col
		ON s.ID = col.ID;

	-- Fetch report data

	SELECT 
		DENSE_RANK() OVER (ORDER BY d.SegmentStartDate) AS SegmentationID
		, d.SegmentStartDate
		, d.SegmentEndDate
		, d.EngagementSegment
		, CASE WHEN d.EngagementSegment IN ('Low-Engaged', 'Non-Engaged') THEN d.EngagementSegment ELSE CONCAT('Engaged-', d.EngagementSegment) END AS EngagementSegmentName
		, d.MonthCommencing	
		, d.PercentDebitOnly
		, d.PercentCreditOnly
		, d.PercentDebitCredit	
		, d.PercentLoggedIn
		, d.PercentOpenedEmail
		, d.WLsPerCus
		, d.EOsPerCus
		, d.PercentEarnedOnDDs
		, d.PercentEarnedOnMFs		
		, d.SPC_MFoffers	
		, d.DDearningsPerCus
		, d.CCearningsPerCus
		, d.MFearningsPerCus
		, d.TotalEarningsPerCus
		, col.ColourHexCode AS SegColourHexCode
	FROM Warehouse.Staging.CustomerEngagement_ReportData d
	INNER JOIN (
		SELECT TOP 3
		SegmentStartDate 
		FROM (
			SELECT DISTINCT
			SegmentStartDate
			FROM Warehouse.Staging.CustomerEngagement_ReportData
			) x
		ORDER BY SegmentStartDate DESC
	) y
		ON d.SegmentStartDate = y.SegmentStartDate
	LEFT JOIN #SegCol col
		ON d.EngagementSegment = col.EngagementSegment;

END