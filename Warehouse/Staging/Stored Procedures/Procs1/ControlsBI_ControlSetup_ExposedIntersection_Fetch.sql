/******************************************************************************
Author: Jason Shipp
Created: 13/09/2018
Purpose:
	- Part of KPMG BI Controls
	- Fetch counts of Iron Offer control group members who are also in the exposed group in the same Campaign Cycle 

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.ControlsBI_ControlSetup_ExposedIntersection_Fetch
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MaxReportDate date = (SELECT MAX(ReportDate) FROM Warehouse.Staging.ControlsBI_ControlSetup_ExposedIntersection);

	SELECT
		d.ID
		, d.StartDate
		, d.PublisherType
		, d.IronOfferID
		, d.OfferTypeForReports
		, d.PartnerID
		, p.PartnerName AS RetailerName
		, d.ControlGroupID
		, d.ControlGroupTypeID
		, d.IronOfferCyclesID
		, d.ControlMembers
		, d.ExposedMembers
		, d.ControlExposedMembers
		, d.ControlExposedMembersProportion
		, d.ReportDate
	FROM Warehouse.Staging.ControlsBI_ControlSetup_ExposedIntersection d
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
		, d.ControlExposedMembersProportion DESC;
			
END