/******************************************************************************
Author: Jason Shipp
Created: 28/09/2018
Purpose: 
	- Fetch dates associated with new FileIDs in direct debit data AWS-log table (Archive_Light.dbo.CBP_DirectDebit_FileAWSHistory)
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE AWSFile.CBP_DDTransHistory_FetchDates (@DownloadStartDateTime datetime)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT DISTINCT
		h.[Date]
	FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory h
	WHERE 
		h.FileID IN (SELECT FileID FROM Archive_Light.dbo.CBP_DirectDebit_FileAWSLog WHERE IsDownloaded = 0)
		AND NOT EXISTS (
			SELECT NULL FROM Archive_Light.dbo.CBP_DirectDebit_DatesLoadedToFileLog l
			WHERE 
				@DownloadStartDateTime = l.AWSLoadDateStart
				AND h.[Date] = l.DateValueLoadedToFile
		)
	ORDER BY h.[Date] ASC;

END