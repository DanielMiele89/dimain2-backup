-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Counts total number of transactions in this file
-- =============================================
CREATE PROCEDURE gas.QA_TransCount_Fetch
	
	(
		@FileID int
	)
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT COUNT(1)
	FROM Archive.dbo.NobleTransactionHistory
	WHERE FileID = @FileID
	
END
