-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Enters QA results into QA Log table
-- =============================================
CREATE PROCEDURE gas.QA_Results_Insert
	(
		@FileID int
		, @FileCount int
		, @MatchedCount int
		, @UnmatchedCount int
		, @NoCINCount int
		, @PositiveCount int
	)
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO Staging.CardTransaction_QA (FileID, FileCount, MatchedCount, UnmatchedCount, NoCINCount, PositiveCount)
	VALUES(@FileID,@FileCount,@MatchedCount,@UnmatchedCount,@NoCINCount,@PositiveCount)
	
END