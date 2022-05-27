-- =============================================
-- Author:		JEA
-- Create date: 09/07/2014
-- Description:	Retrieves the staging unique id data
-- =============================================
CREATE PROCEDURE [Staging].[SchemeTransUniqueID_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT MatchID, FileID, RowNum
	FROM Staging.SchemeTransUniqueID

END
