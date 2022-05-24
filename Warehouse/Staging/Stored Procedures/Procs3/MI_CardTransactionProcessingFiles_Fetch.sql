-- =============================================
-- Author:		JEA
-- Create date: 27/11/2012
-- Description:	Returns the processing characteristics
-- of all files processed into the card transaction tables
-- over the last day
-- =============================================
CREATE PROCEDURE [Staging].[MI_CardTransactionProcessingFiles_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @PackageStartTime DATETIME, @PackageEndTime DATETIME

		--Get the most recent package run time.
	SELECT @PackageEndTime = MAX(ActionDate) FROM MI.ProcessLog WHERE ActionName = 'Complete' AND ProcessName = 'ConsumerTransactionHoldingLoad'
	SELECT @PackageStartTime = MAX(ActionDate) FROM MI.ProcessLog WHERE ActionName = 'Started' AND ProcessName = 'ConsumerTransactionHoldingLoad'

    SELECT Q.FileID
		, Q.FileCount
		, Q.MatchedCount
		, Q.UnmatchedCount
		, Q.NoCINCount
		, Q.PositiveCount
    FROM Staging.CardTransaction_QA Q
	WHERE Q.QADate BETWEEN @PackageStartTime AND @PackageEndTime
    
END