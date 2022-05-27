-- =============================================
-- Author:		JEA
-- Create date: 29/11/2013
-- Description:	Updates the MI.BPMID table from the staging table
-- =============================================
CREATE PROCEDURE [MI].[BPMID_LoadChanges] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @StartDate DATE, @EndDate DATE

	SET @StartDate = GETDATE()
	SET @EndDate = DATEADD(DAY, -1, @StartDate)

	UPDATE MI.BPMID SET EndDate = @EndDate
	FROM MI.BPMID b
	LEFT OUTER JOIN MI.Staging_BPMID s ON b.OutletID = s.OutletID and b.statusid = s.StatusID
	WHERE b.EndDate IS NULL
	AND s.OutletID IS NULL

	INSERT INTO MI.BPMID(OutletID, MID, StatusID, StartDate)
	SELECT S.OutletID, S.MID, S.StatusID, @StartDate
	FROM MI.Staging_BPMID S
	LEFT OUTER JOIN (SELECT * FROM MI.BPMID WHERE EndDate IS NULL) B on s.OutletID = b.OutletID and s.StatusID = b.StatusID
	WHERE B.OutletID IS NULL

END
