/******************************************************************************
Author: Jason Shipp
Created: 13/09/2018
Purpose:
	- Part of KPMG BI Controls
	- Fetch count of control group members spending after the ALS threshold date for the associated retailer settings

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlsBI_ControlSetup_SegmentationTransDates_Fetch]
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MaxReportDate date = (SELECT MAX(ReportDate) FROM Warehouse.Staging.ControlsBI_ControlSetup_SegmentationTransDates);

	-- Load ControlGroupIDs

	IF OBJECT_ID('tempdb..#ControlGroups') IS NOT NULL DROP TABLE #ControlGroups;

	SELECT DISTINCT
		d.PublisherType
		, d.controlgroupid
	INTO #ControlGroups
	FROM Warehouse.Staging.ControlsBI_ControlSetup_SegmentationTransDates d
	WHERE 
		d.ReportDate = @MaxReportDate;

	CREATE CLUSTERED INDEX CIX_ControlGroups ON #ControlGroups (controlgroupid, PublisherType);

	-- Load control group member counts

	IF OBJECT_ID('tempdb..#ControlMemCounts') IS NOT NULL DROP TABLE #ControlMemCounts;

	CREATE TABLE #ControlMemCounts (
		PublisherType varchar(40)
		, ControlGroupID int
		, ControlGroupMembers int
	)

	-- Warehouse
	INSERT INTO #ControlMemCounts (PublisherType, ControlGroupID, ControlGroupMembers)
	SELECT 
		'Warehouse' AS PublisherType
		, cg.ControlGroupID
		, COUNT(*) AS ControlGroupMembers
	FROM #ControlGroups cg
	INNER JOIN Warehouse.Relational.controlgroupmembers cm
		ON cg.controlgroupid = cm.controlgroupid
	WHERE 
		cg.PublisherType = 'Warehouse'
	GROUP BY 
		cg.ControlGroupID;

	-- nFI
	INSERT INTO #ControlMemCounts (PublisherType, ControlGroupID, ControlGroupMembers)
	SELECT 
		'nFI' AS PublisherType
		, cg.ControlGroupID
		, COUNT(*) AS ControlGroupMembers
	FROM #ControlGroups cg
	INNER JOIN nFI.Relational.controlgroupmembers cm
		ON cg.controlgroupid = cm.controlgroupid
	WHERE 
		cg.PublisherType = 'nFI'
	GROUP BY 
		cg.ControlGroupID;

	-- Virgin
	INSERT INTO #ControlMemCounts (PublisherType, ControlGroupID, ControlGroupMembers)
	SELECT 
		'Virgin' AS PublisherType
		, cg.ControlGroupID
		, COUNT(*) AS ControlGroupMembers
	FROM #ControlGroups cg
	INNER JOIN [WH_Virgin].[Report].[ControlGroupMembers] cm
		ON cg.controlgroupid = cm.controlgroupid
	WHERE 
		cg.PublisherType = 'Virgin'
	GROUP BY 
		cg.ControlGroupID;

	-- AMEX
	INSERT INTO #ControlMemCounts (PublisherType, ControlGroupID, ControlGroupMembers)
	SELECT 
		'AMEX' AS PublisherType
		, cg.ControlGroupID
		, COUNT(*) AS ControlGroupMembers
	FROM #ControlGroups cg
	INNER JOIN nFI.Relational.AmexControlGroupMembers cm
		ON cg.controlgroupid = cm.AmexControlgroupID
	WHERE 
		cg.PublisherType = 'AMEX'
	GROUP BY 
		cg.ControlGroupID;

	-- Fetch results

	SELECT
		d.ID
		, d.StartDate
		, d.PublisherType
		, d.PartnerID
		, p.PartnerName AS RetailerName
		, d.ControlGroupID
		, d.ControlGroupTypeID
		, d.ControlGroupSuperSegment
		, d.MaxSpendDateForSegment
		, ISNULL(n.ControlGroupMembers, 0) AS ControlGroupMembers
		, ISNULL(d.SpendersOverSegThresholdDate, 0) AS SpendersOverSegThresholdDate
		, ISNULL(CAST(d.SpendersOverSegThresholdDate AS float)/NULLIF(n.ControlGroupMembers, 0), 0) AS SpendersOverSegThresholdDateProportion
		, d.ReportDate
	FROM Warehouse.Staging.ControlsBI_ControlSetup_SegmentationTransDates d
	LEFT JOIN #ControlMemCounts n
		ON d.controlgroupid = n.ControlGroupID
		AND d.PublisherType = n.PublisherType
	LEFT JOIN 
			(SELECT PartnerID, AlternatePartnerID FROM Warehouse.APW.PartnerAlternate 
			UNION 
			SELECT PartnerID, AlternatePartnerID FROM nFI.APW.PartnerAlternate
			) pa
		ON d.PartnerID = pa.PartnerID
	LEFT JOIN 
			(SELECT DISTINCT PartnerID, MIN(PartnerName) OVER (PARTITION BY PartnerID) AS PartnerName -- Handle different partner names in Warehouse/nFI Partner tables
			FROM 
				(SELECT PartnerID, PartnerName FROM Warehouse.Relational.[Partner]
				UNION 
				SELECT PartnerID, PartnerName FROM nFI.Relational.[Partner]
				) x 
			) p
		ON COALESCE(pa.AlternatePartnerID, d.PartnerID) = p.PartnerID
	WHERE 
		d.ReportDate = @MaxReportDate
	ORDER BY
		d.PublisherType
		, SpendersOverSegThresholdDateProportion DESC;

END