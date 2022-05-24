-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Counts total number of Unmatched transactions in this file
-- =============================================
CREATE PROCEDURE gas.QA_UnmatchedCount_Fetch
	(
		@FileID int
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT COUNT(1)
	FROM Staging.CardTransactionHoldingNoBrandMIDID
	WHERE FileID = @FileID
	
END
