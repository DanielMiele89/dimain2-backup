/******************************************************************************
Author: Jason Shipp
Created: 03/09/2018
Purpose:
	- Part of KPMG BI Controls
	- Load control groups with fewer than a set number of members

------------------------------------------------------------------------------
Modification History

Jason Shipp 23/04/2020
	Marked Iron Offers of retailers in the Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers table as in-programme

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlsBI_ControlSetup_Counts_Load]
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @SDate DATE = (SELECT StartDate FROM Warehouse.Staging.ControlSetup_Cycle_Dates);
	DECLARE @MinControlMemberCount int = NULL;

	/******************************************************************************
	Fetch and load Warehouse, nFI and AMEX control group member counts into Warehouse.Staging.ControlsBI_ControlSetup_Counts table

	Create table for storing results:

	CREATE TABLE Warehouse.Staging.ControlsBI_ControlSetup_Counts (
		ID int IDENTITY (1,1) NOT NULL
		, PublisherType varchar(40)
		, PartnerID int 
		, OfferTypeForReports varchar(100)
		, InIronOfferCycles bit
		, ControlGroupID int
		, NumberofFanIDs int
		, StartDate date
		, ControlGroupTypeID int
		, ReportDate date
		, CONSTRAINT PK_ControlsBI_ControlSetup_Counts PRIMARY KEY CLUSTERED (ID)
	);
	******************************************************************************/

	TRUNCATE TABLE Warehouse.Staging.ControlsBI_ControlSetup_Counts;

	INSERT INTO Warehouse.Staging.ControlsBI_ControlSetup_Counts (
		PublisherType
		, PartnerID 
		, OfferTypeForReports
		, InIronOfferCycles
		, ControlGroupID
		, NumberofFanIDs
		, StartDate
		, ControlGroupTypeID
		, ReportDate
	)

	SELECT DISTINCT
		'Warehouse' AS PublisherType
		, NULLIF(mc.PartnerID, 0) AS PartnerID
		, MAX(seg.OfferTypeForReports) OVER (PARTITION BY mc.ControlGroupID) AS OfferTypeForReports
		, CASE WHEN ioc.ironoffercyclesid IS NULL THEN 0 ELSE 1 END AS InIronOfferCycles
		, mc.ControlGroupID
		, mc.NumberofFanIDs
		, mc.StartDate AS StartDate
		, CASE WHEN bcr.RetailerID IS NOT NULL THEN 1 ELSE ioc.ControlGroupTypeID END AS ControlGroupTypeID
		, CAST(GETDATE() AS date) AS ReportDate
	FROM Warehouse.Relational.ControlGroupMember_Counts mc
	LEFT JOIN (
			SELECT ioc.IronOfferID, ioc.ironoffercyclesid, ioc.controlgroupid, 0 AS ControlGroupTypeID FROM Warehouse.Relational.ironoffercycles ioc
			UNION
			SELECT ioc.ironofferid, ioc.ironoffercyclesid, sec.ControlGroupID, 1 AS ControlGroupTypeID
			FROM Warehouse.Relational.SecondaryControlGroups sec
			LEFT JOIN Warehouse.Relational.ironoffercycles ioc
				ON sec.IronOfferCyclesID = ioc.ironoffercyclesid
			) ioc
		ON mc.ControlGroupID = ioc.controlgroupid
		AND ioc.controlgroupid IS NOT NULL
	LEFT JOIN Warehouse.Relational.IronOfferSegment seg
		ON ioc.ironofferid = seg.IronOfferID
		AND seg.OfferTypeForReports IS NOT NULL
	LEFT JOIN Warehouse.Relational.[Partner] p
		ON mc.PartnerID = p.PartnerID
	LEFT JOIN Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers bcr
		ON mc.PartnerID = bcr.RetailerID
	WHERE
		mc.StartDate >= @SDate
		AND (NumberofFanIDs < @MinControlMemberCount OR @MinControlMemberCount IS NULL)

	UNION ALL

	SELECT DISTINCT
		'nFI' AS PublisherType
		, NULLIF(mc.PartnerID, 0) AS PartnerID
		, MAX(seg.OfferTypeForReports) OVER (PARTITION BY mc.ControlGroupID) AS OfferTypeForReports
		, CASE WHEN ioc.ironoffercyclesid IS NULL THEN 0 ELSE 1 END AS InIronOfferCycles
		, mc.ControlGroupID
		, mc.NumberofFanIDs
		, mc.StartDate AS StartDate
		, CASE WHEN bcr.RetailerID IS NOT NULL THEN 1 ELSE ioc.ControlGroupTypeID END AS ControlGroupTypeID
		, CAST(GETDATE() AS date) AS ReportDate
	FROM nFI.Relational.ControlGroupMember_Counts mc
	LEFT JOIN (
			SELECT ioc.IronOfferID, ioc.ironoffercyclesid, ioc.controlgroupid, 0 AS ControlGroupTypeID FROM nFI.Relational.ironoffercycles ioc
			UNION
			SELECT ioc.ironofferid, ioc.ironoffercyclesid, sec.ControlGroupID, 1 AS ControlGroupTypeID
			FROM nFI.Relational.SecondaryControlGroups sec
			LEFT JOIN nFI.Relational.ironoffercycles ioc
				ON sec.IronOfferCyclesID = ioc.ironoffercyclesid
			) ioc
		ON mc.ControlGroupID = ioc.controlgroupid
		AND ioc.controlgroupid IS NOT NULL
	LEFT JOIN Warehouse.Relational.IronOfferSegment seg
		ON ioc.ironofferid = seg.IronOfferID
		AND seg.OfferTypeForReports IS NOT NULL
	LEFT JOIN nFI.Relational.[Partner] p
		ON mc.PartnerID = p.PartnerID
	LEFT JOIN Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers bcr
		ON mc.PartnerID = bcr.RetailerID
	WHERE
		mc.StartDate >= @SDate
		AND (NumberofFanIDs < @MinControlMemberCount OR @MinControlMemberCount IS NULL)

	UNION ALL

	SELECT DISTINCT
		'Virgin' AS PublisherType
		, NULLIF(mc.PartnerID, 0) AS PartnerID
		, MAX(seg.OfferTypeForReports) OVER (PARTITION BY mc.ControlGroupID) AS OfferTypeForReports
		, CASE WHEN ioc.ironoffercyclesid IS NULL THEN 0 ELSE 1 END AS InIronOfferCycles
		, mc.ControlGroupID
		, mc.NumberofFanIDs
		, mc.StartDate AS StartDate
		, CASE WHEN bcr.RetailerID IS NOT NULL THEN 1 ELSE ioc.ControlGroupTypeID END AS ControlGroupTypeID
		, CAST(GETDATE() AS date) AS ReportDate
	FROM [WH_Virgin].[Report].[ControlGroupMember_Counts] mc
	LEFT JOIN (
			SELECT ioc.IronOfferID, ioc.ironoffercyclesid, ioc.controlgroupid, 0 AS ControlGroupTypeID FROM [WH_Virgin].[Report].[IronOfferCycles] ioc
			UNION
			SELECT ioc.ironofferid, ioc.ironoffercyclesid, sec.ControlGroupID, 1 AS ControlGroupTypeID
			FROM nFI.Relational.SecondaryControlGroups sec
			LEFT JOIN [WH_Virgin].[Report].[IronOfferCycles] ioc
				ON sec.IronOfferCyclesID = ioc.ironoffercyclesid
			WHERE 1 = 2
			) ioc
		ON mc.ControlGroupID = ioc.controlgroupid
		AND ioc.controlgroupid IS NOT NULL
	LEFT JOIN Warehouse.Relational.IronOfferSegment seg
		ON ioc.ironofferid = seg.IronOfferID
		AND seg.OfferTypeForReports IS NOT NULL
	LEFT JOIN [WH_Virgin].[Derived].[Partner] p
		ON mc.PartnerID = p.PartnerID
	LEFT JOIN Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers bcr
		ON mc.PartnerID = bcr.RetailerID
	WHERE
		mc.StartDate >= @SDate
		AND (NumberofFanIDs < @MinControlMemberCount OR @MinControlMemberCount IS NULL)

	UNION ALL

	SELECT DISTINCT
		'AMEX' AS PublisherType
		, NULLIF(mc.PartnerID, 0) AS PartnerID
		, MAX(seg.OfferTypeForReports) OVER (PARTITION BY mc.AmexControlGroupID) AS OfferTypeForReports
		, CASE WHEN ioc.AmexIronOfferID IS NULL THEN 0 ELSE 1 END AS InIronOfferCycles
		, mc.AmexControlGroupID AS ControlGroupID
		, mc.NumberofFanIDs
		, mc.StartDate AS StartDate
		, 0 AS ControlGroupTypeID
		, CAST(GETDATE() AS date) AS ReportDate
	FROM nFI.Relational.AmexControlGroupMember_Counts mc
	LEFT JOIN nFI.Relational.AmexIronOfferCycles ioc
		ON mc.AmexControlGroupID = ioc.AmexControlGroupID
		AND ioc.AmexControlGroupID IS NOT NULL
	LEFT JOIN Warehouse.Relational.IronOfferSegment seg
		ON ioc.AmexIronOfferID = seg.IronOfferID
		AND seg.OfferTypeForReports IS NOT NULL
	LEFT JOIN nFI.Relational.[Partner] p
		ON mc.PartnerID = p.PartnerID
	WHERE
		mc.StartDate >= @SDate
		AND (NumberofFanIDs < @MinControlMemberCount OR @MinControlMemberCount IS NULL)
	ORDER BY 
		PublisherType DESC
		, NULLIF(mc.PartnerID, 0)
		, mc.NumberofFanIDs DESC;

END