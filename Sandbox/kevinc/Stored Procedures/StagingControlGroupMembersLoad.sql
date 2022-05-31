CREATE PROC [kevinc].[StagingControlGroupMembersLoad]
AS

	--IF OBJECT_ID('kevinc.StagingControlGroupMembers') IS NOT NULL
	--	DROP TABLE kevinc.StagingControlGroupMembers
	--CREATE TABLE kevinc.StagingControlGroupMembers(
	--	FanId				INT NOT NULL,
	--	ControlGroupID		INT NOT NULL,
	--	ReportingOfferID	INT NOT NULL,
	--	CINID				INT NOT NULL,
	--	PartnerID			INT NOT NULL,
	--	StartDate			DATETIME2(7) NOT NULL,
	--	EndDate				DATETIME2(7) NOT NULL
	--)

	--CREATE CLUSTERED INDEX StagingControlGroupMembers_CINID ON kevinc.StagingControlGroupMembers(CINID)

	INSERT INTO kevinc.StagingControlGroupMembers([FanId], [ControlGroupID], [ReportingOfferID], [CINID], [PartnerID], [StartDate], [EndDate])
	select distinct CGM.FanID, cgm.COntrolgroupID, cgo.ReportingOfferID, CIN.CINID, ro.PartnerID, ro.StartDate, ro.EndDate
	FROM kevinc.ControlCustomers cgm
	INNER JOIN SLC_Report.DBO.Fan F ON F.ID = cgm.FanID 
	INNER JOIN Warehouse.Relational.CINList CIN ON CIN.CIN = f.SourceUID
	INNER JOIN Sandbox.Kevinc.ControlGroupOffer cgo
		ON cgm.ControlGroupID = cgo.ControlGroupID
	INNER JOIN Sandbox.Kevinc.ReportingOffer ro
		ON cgo.ReportingOfferID = ro.ReportingOfferID



