/******************************************************************************
Author: Jason Shipp
Created: 13/09/2018
Purpose:
	- Part of KPMG BI Controls
	- Fetch control groups with fewer than a set number of members 

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.ControlsBI_ControlSetup_Counts_Fetch
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MinControlMemberCount int = NULL;
	DECLARE @MaxReportDate date = (SELECT MAX(ReportDate) FROM Warehouse.Staging.ControlsBI_ControlSetup_Counts);

	SELECT
		d.ID
		, d.PublisherType
		, d.PartnerID
		, COALESCE(p.PartnerName, 'UNIVERSAL - Across Partner') AS RetailerName
		, d.OfferTypeForReports
		, d.InIronOfferCycles
		, d.ControlGroupID
		, d.NumberofFanIDs
		, d.StartDate
		, d.ControlGroupTypeID
		, d.ReportDate
	FROM Warehouse.Staging.ControlsBI_ControlSetup_Counts d
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
		AND (d.NumberofFanIDs < @MinControlMemberCount OR @MinControlMemberCount IS NULL)
	ORDER BY
		d.PublisherType
		, d.NumberofFanIDs ASC;

END