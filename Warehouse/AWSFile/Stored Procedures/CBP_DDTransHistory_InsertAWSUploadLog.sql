/******************************************************************************
Author: Jason Shipp
Created: 28/09/2018
Purpose: 
	- Add new direct debit FileIDs to AWS-upload log table (Archive_Light.dbo.CBP_DirectDebit_FileAWSHistory)

------------------------------------------------------------------------------
Modification History

Jason Shipp 02/10/2018
	- Added fetch of @DownloadStartDateTime parameter for loading into SSRS

Jason Shipp 12/12/2018
	- Chris optimisation: Used MIN() in a loop to more efficiently fetch distinct FileID, before loading new FileIDs not in the log table

******************************************************************************/
CREATE PROCEDURE AWSFile.CBP_DDTransHistory_InsertAWSUploadLog
	
AS
BEGIN

	/******************************************************************************
	NOTES
	- Partitioned Athena table by date column: one S3 folder per date
	- Upload rows associated with new FileIDs daily
	- For each upload, split rows into text files: each text file represents rows for a date
	- Upload the text files to the matching folders by matching dates: this maintains the partition structure
	******************************************************************************/
	
	SET NOCOUNT ON;

	/******************************************************************************
	Create timestamp
	******************************************************************************/

	DECLARE @DownloadStartDateTime datetime = GETDATE();
	
	/******************************************************************************
	Add new FileIDs to AWS-upload log table (original version)
	******************************************************************************/
	
	--INSERT INTO Archive_Light.dbo.CBP_DirectDebit_FileAWSLog (FileID, AWSLoadDateStart, IsDownloaded)
	--SELECT DISTINCT	
	--	h.FileID
	--	, @DownloadStartDateTime AS AWSLoadDateStart
	--	, 0 AS IsDownloaded
	--FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory h
	--WHERE NOT EXISTS (
	--	SELECT NULL FROM Archive_Light.dbo.CBP_DirectDebit_FileAWSLog fh
	--	WHERE 
	--		h.FileID = fh.FileID
	--)
	--ORDER BY h.FileID ASC;

	/******************************************************************************
	Add new FileIDs to AWS-upload log table (Chris-optimised version)
	******************************************************************************/

	IF OBJECT_ID('tempdb..#CBP_DirectDebit_TransactionHistory') IS NOT NULL DROP TABLE #CBP_DirectDebit_TransactionHistory;

	CREATE TABLE #CBP_DirectDebit_TransactionHistory (FileID INT NOT NULL);

	DECLARE @FileID INT = 0

	WHILE 1 = 1 BEGIN
		SELECT @FileID = MIN(T.FileID) FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory T WHERE FileID > @FileID
		IF @@ROWCOUNT = 0 OR @FileID IS NULL BREAK
		INSERT INTO #CBP_DirectDebit_TransactionHistory (FileID) VALUES (@FileID);
	END

	INSERT INTO Archive_Light.dbo.CBP_DirectDebit_FileAWSLog (FileID, AWSLoadDateStart, IsDownloaded)
	SELECT DISTINCT      
		h.FileID
		, @DownloadStartDateTime AS AWSLoadDateStart
		, 0 AS IsDownloaded
	FROM #CBP_DirectDebit_TransactionHistory h
	WHERE NOT EXISTS (
		SELECT 1 FROM Archive_Light.dbo.CBP_DirectDebit_FileAWSLog fh
		WHERE h.FileID = fh.FileID
	)
	ORDER BY h.FileID ASC;

	/******************************************************************************
	Fetch @UploadStartDateTime parameter as string for loading into SSRS
	******************************************************************************/

	SELECT CONVERT(varchar(25), @DownloadStartDateTime, 121) AS DownloadStartDateTime;
	--SELECT CONVERT(varchar(25), (SELECT MAX(AWSLoadDateStart) FROM Archive_Light.dbo.CBP_DirectDebit_FileAWSLog), 121) AS DownloadStartDateTime; -- Manually fetch @UploadStartDateTime parameter if log table already populated

	/******************************************************************************
	--Create table for logging uploaded FileID data

	CREATE TABLE Archive_Light.dbo.CBP_DirectDebit_FileAWSLog (
		FileID int NOT NULL
		, AWSLoadDateStart datetime NOT NULL
		, IsDownloaded bit NOT NULL
		, CONSTRAINT PK_CBP_DirectDebit_FileAWSLog PRIMARY KEY CLUSTERED (FileID)
	);
	******************************************************************************/

END