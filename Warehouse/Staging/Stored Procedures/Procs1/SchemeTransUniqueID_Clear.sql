-- =============================================
-- Author:		JEA
-- Create date: 09/07/2014
-- Description:	Clears the trans Unique ID staging table
-- =============================================
CREATE PROCEDURE [Staging].[SchemeTransUniqueID_Clear] 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE Staging.SchemeTransUniqueID

	UPDATE MI.SchemeTransUniqueID SET MatchID = a.MatchID
	FROM MI.SchemeTransUniqueID s
	INNER JOIN Relational.AdditionalCashbackAward a ON s.FileID = a.FileID AND s.RowNum = a.RowNum
	WHERE a.MatchID IS NOT NULL AND s.MatchID IS NULL

	UPDATE MI.SchemeTransUniqueID SET MatchID = NULL
	FROM MI.SchemeTransUniqueID s
	INNER JOIN Relational.AdditionalCashbackAward a ON s.FileID = a.FileID AND s.RowNum = a.RowNum
	WHERE a.MatchID IS NULL AND s.MatchID IS NOT NULL

END
