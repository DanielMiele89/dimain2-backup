-- =============================================
-- Author:		AJS
-- Create date: 13/06/2014
-- Description:	Updates the [MI].[ReportMID] table from the staging table
-- =============================================
CREATE PROCEDURE [MI].[ReportMID_LoadNotOnimportChanges]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE

	SET @StartDate = GETDATE()
	SET @EndDate = DATEADD(DAY, -1, @StartDate)

	insert into MI.ReportMID(OutletID, MID, SplitID, StatusTypeID, PartnerID, StartDate, AddedType)
	SELECT S.OutletID, S.MID, S.SplitID, S.StatusTypeID, S.PartnerID, @StartDate as StartDate, 2 as addedtype
	FROM MI.ReportMID_Staging_Part4 S
	LEFT OUTER JOIN (SELECT * FROM MI.ReportMID WHERE EndDate IS NULL) B on s.OutletID = b.OutletID and s.SplitID = b.SplitID and S.StatusTypeID = B.StatusTypeID and S.PartnerID = B.PartnerID
	WHERE B.OutletID IS NULL

	UPDATE MI.ReportMID SET EndDate = @EndDate
	FROM MI.ReportMID b
	LEFT OUTER JOIN MI.ReportMID_Staging_Part4 s ON b.OutletID = s.OutletID and s.SplitID = b.SplitID and S.StatusTypeID = B.StatusTypeID and S.PartnerID = B.PartnerID
	WHERE b.EndDate IS NULL
	AND s.OutletID IS NULL
	And b.PartnerID in (Select PartnerID from MI.ReportMID_Staging_Partner)
	and Addedtype =2

	UPDATE MI.ReportMID SET AddedType = 1
	FROM MI.ReportMID b
	inner JOIN MI.ReportMID_Staging_Part4 s ON b.OutletID = s.OutletID and s.SplitID = b.SplitID and S.StatusTypeID = B.StatusTypeID and S.PartnerID = B.PartnerID
	WHERE 
	s.OutletID IS not NULL
	And b.PartnerID in (Select PartnerID from MI.ReportMID_Staging_Partner)
	and B.addedtype <>2

END