-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Logs the QA stats for the current file
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_QAStats_Set]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    INSERT INTO Staging.CardTransaction_QA(FileID, FileCount, MatchedCount, UnmatchedCount, NoCINCount, PositiveCount)
	SELECT FileID
		, COUNT(1) AS FileCount
		, SUM(CASE WHEN ConsumerCombinationID IS NULL THEN 0 ELSE 1 END) AS MatchedCount
		, SUM(CASE WHEN ConsumerCombinationID IS NULL THEN 1 ELSE 0 END) AS UnmatchedCount
		, SUM(CASE WHEN CINID IS NULL THEN 0 ELSE 1 END) AS NoCINCount
		, SUM(CASE WHEN IsRefund = 0 THEN 1 ELSE 0 END) AS PositiveCount
	FROM Staging.CTLoad_InitialStage
	GROUP BY FileID

END
