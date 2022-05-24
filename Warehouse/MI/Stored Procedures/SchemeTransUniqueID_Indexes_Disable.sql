-- =============================================
-- Author:		JEA
-- Create date: 09/07/2014
-- Description:	Disables unique id indexes prior to data load
-- =============================================
CREATE PROCEDURE [MI].[SchemeTransUniqueID_Indexes_Disable]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	ALTER INDEX IX_MI_SchemeTransUniqueID_MatchID ON MI.SchemeTransUniqueID DISABLE
	ALTER INDEX IX_MI_SchemeTransUniqueID_FileIDRowNum ON MI.SchemeTransUniqueID DISABLE

END