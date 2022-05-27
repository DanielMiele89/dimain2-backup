/******************************************************************************
Author: Jason Shipp
Created: 28/09/2018
Purpose: 
	- Fetch direct debit transaction data for a date for new FileIDs in AWS-log table (Archive_Light.dbo.CBP_DirectDebit_FileAWSHistory), for uploading to AWS
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE AWSFile.CBP_DDTransHistory_FetchForAWSUpload (@Date date)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT
		h.FileID AS fileid
		, h.SourceUID AS sourceuid
		, cl.CINID AS cinid
		, h.OIN AS oin
		, h.Amount AS amount
		, h.Narrative AS narrative
	FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory h
	INNER JOIN Warehouse.Relational.CINList cl
		ON h.SourceUID = cl.CIN
	WHERE 
		h.FileID IN (SELECT FileID FROM Archive_Light.dbo.CBP_DirectDebit_FileAWSLog WHERE IsDownloaded = 0)
		AND h.[Date] = @Date;
END