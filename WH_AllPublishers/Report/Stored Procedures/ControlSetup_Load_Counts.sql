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

CREATE PROCEDURE [Report].[ControlSetup_Load_Counts]
AS
BEGIN
	
	SET NOCOUNT ON;

	/*******************************************************************************************************************************************
		1.	Load Campaign Cycle dates
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates;
		SELECT	MAX(cd.StartDate) AS StartDate
			,	MAX(DATEADD(SECOND, -1, (DATEADD(day, 1, (CONVERT(DATETIME, CONVERT(DATE, cd.EndDate))))))) AS EndDate
		INTO #Dates
		FROM [Report].[ControlSetup_CycleDates] cd;

		DECLARE @StartDate DATETIME
			,	@EndDate DATETIME
		
		SELECT	@StartDate = StartDate
			,	@EndDate = EndDate
		FROM #Dates

	/*******************************************************************************************************************************************
		2.	Load [Report].[ControlSetup_Counts]
	*******************************************************************************************************************************************/
		
		DECLARE @MinControlMemberCount int = NULL;

		TRUNCATE TABLE [Report].[ControlSetup_Counts];

		INSERT INTO [Report].[ControlSetup_Counts] (PublisherType
												,	PartnerID 
												,	OfferTypeForReports
												,	InIronOfferCycles
												,	ControlGroupID
												,	NumberofFanIDs
												,	StartDate
												,	ControlGroupTypeID
												,	ReportDate)

		SELECT	DISTINCT
				PublisherType = 'All'
			,	PartnerID = COALESCE(orpi.PartnerID, orpo.PartnerID, 0)
			,	OfferTypeForReports = MAX(seg.OfferTypeForReports) OVER (PARTITION BY cgmc.ControlGroupID)
			,	InIronOfferCycles =	CASE
										WHEN orpi.OfferReportingPeriodsID IS NOT NULL THEN 1
										WHEN orpo.OfferReportingPeriodsID IS NOT NULL THEN 1
										ELSE 0
									END
			,	ControlGroupID = cgmc.ControlGroupID
			,	NumberofFanIDs = cgmc.Customers
			,	StartDate = cgmc.StartDate
			,	ControlGroupTypeID = 0
			,	ReportDate = CAST(GETDATE() AS date)
		FROM [Report].[OfferReport_ControlGroupMembers_Counts] cgmc
		LEFT JOIN [Report].[OfferReport_OfferReportingPeriods] orpi
			ON cgmc.ControlGroupID = orpi.ControlGroupID_InProgramme
		LEFT JOIN [Report].[OfferReport_OfferReportingPeriods] orpo
			ON cgmc.ControlGroupID = orpo.ControlGroupID_OutOfProgramme
		LEFT JOIN Warehouse.Relational.IronOfferSegment seg
			ON COALESCE(orpi.IronOfferID, orpo.IronOfferID) = seg.IronOfferID
			AND seg.OfferTypeForReports IS NOT NULL
		LEFT JOIN Warehouse.Relational.[Partner] p
			ON COALESCE(orpi.PartnerID, orpo.PartnerID, 0) = p.PartnerID
		LEFT JOIN Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers bcr
			ON COALESCE(orpi.PartnerID, orpo.PartnerID, 0) = bcr.RetailerID
		WHERE cgmc.StartDate >= @StartDate
		AND (cgmc.Customers < @MinControlMemberCount OR @MinControlMemberCount IS NULL)
		ORDER BY	PublisherType DESC
				,	COALESCE(orpi.PartnerID, orpo.PartnerID, 0)
				,	cgmc.Customers DESC;

END