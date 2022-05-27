-- =============================================
-- Author:		JEA
-- Create date: 09/07/2014
-- Description:	Rebuilds unique id indexes subsequent to data load
-- =============================================
CREATE PROCEDURE [MI].[SchemeTransUniqueID_Indexes_Rebuild]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	EXEC MI.SchemeTransUniqueID_RemoveDuplicates

	ALTER INDEX IX_MI_SchemeTransUniqueID_MatchID ON MI.SchemeTransUniqueID REBUILD
	ALTER INDEX IX_MI_SchemeTransUniqueID_FileIDRowNum ON MI.SchemeTransUniqueID REBUILD

END
