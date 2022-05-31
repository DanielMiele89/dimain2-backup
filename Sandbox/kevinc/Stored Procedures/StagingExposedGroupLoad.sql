CREATE PROC [kevinc].[StagingExposedGroupLoad]
AS
	SET NOCOUNT ON;

	--IF OBJECT_ID('kevinc.StagingExposedGroup') IS NOT NULL
	--DROP TABLE kevinc.StagingExposedGroup;
	--CREATE TABLE kevinc.StagingExposedGroup(
	--	FanID				INT NOT NULL,
	--  ReportingOfferID	INT NOT NULL,
	--	CINID				INT NOT NULL,
	--)

	--CREATE CLUSTERED INDEX StagingExposedGroup_PartnerId_StartDate_EndDate ON kevinc.StagingExposedGroup(FanID)

	INSERT INTO kevinc.StagingExposedGroup(FanId, ReportingOfferId, CINID)
	SELECT [FanID], [ReportingOfferID], [CINID]
	FROM Sandbox.kevinc.ExposedCustomers ec
	INNER JOIN SLC_Report.DBO.Fan F ON F.ID = ec.FanID 
	INNER JOIN Warehouse.Relational.CINList CIN ON CIN.CIN = f.SourceUID
	/*Add in clause so that we don't pull offers taht have already been reported.*/

