-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Updates the ID and date of the last file processed
-- =============================================
CREATE PROCEDURE gas.CardTransaction_LastFileProcessed_Update
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE staging.CardTransaction_LastFileProcessed
	SET fileid = (SELECT MAX(FileID) FROM Relational.CardTransaction)
	, ProcessDate = GetDate()
	
END
