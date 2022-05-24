-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Retrieves list of CBP customers with long sourceUIDs
-- =============================================
CREATE PROCEDURE MI.CBP_SourceUIDLength_Check 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT f.ID AS FanID, f.SourceUID
	FROM SLC_Report.dbo.Fan f
	LEFT OUTER JOIN MI.CBP_ExclusionList e ON f.ID = e.FanID
	WHERE ClubID IN (132,138)
	AND LEN(SourceUID) > 10
	AND e.FanID IS NULL

END