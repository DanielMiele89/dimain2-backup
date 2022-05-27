-- =============================================
-- Author:		AJS
-- Create date: 13/06/2014
-- Description:	Updates the [MI].[ReportMID] table from the staging table
-- =============================================
CREATE PROCEDURE [MI].[ReportMID_LoadChanges]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE

	SET @StartDate = GETDATE()
	SET @EndDate = DATEADD(DAY, -1, @StartDate)

	UPDATE MI.ReportMID SET EndDate = @EndDate
	FROM MI.ReportMID b
	LEFT OUTER JOIN MI.ReportMID_Staging_Part2 s ON b.OutletID = s.OutletID AND s.SplitID = b.SplitID AND S.StatusTypeID = B.StatusTypeID AND S.PartnerID = B.PartnerID
	WHERE b.EndDate IS NULL
	AND s.OutletID IS NULL
	AND b.PartnerID IN (SELECT PartnerID from MI.ReportMID_Staging_Partner)
	AND (addedtype IS NULL OR addedtype <>2)

	UPDATE MI.ReportMID SET AddedType = 1
	FROM MI.ReportMID b
	inner JOIN MI.ReportMID_Staging_Part2 s ON b.OutletID = s.OutletID AND s.SplitID = b.SplitID AND S.StatusTypeID = B.StatusTypeID AND S.PartnerID = B.PartnerID
	WHERE 
	s.OutletID IS NOT NULL
	AND b.PartnerID IN (SELECT PartnerID FROM MI.ReportMID_Staging_Partner)
	AND B.addedtype <>1

	INSERT INTO MI.ReportMID(OutletID, MID, SplitID, StatusTypeID, PartnerID, StartDate, AddedType)
	SELECT S.OutletID, S.MID, S.SplitID, S.StatusTypeID, S.PartnerID, @StartDate as StartDate, 1 as addedtype
	FROM MI.ReportMID_Staging_Part2 S
	LEFT OUTER JOIN (SELECT * FROM MI.ReportMID WHERE EndDate IS NULL) B on s.OutletID = b.OutletID AND s.SplitID = b.SplitID AND S.StatusTypeID = B.StatusTypeID AND S.PartnerID = B.PartnerID
	WHERE B.OutletID IS NULL


END