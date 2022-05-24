/******************************************************************************
Author: Jason Shipp
Created: 02/10/2018
Purpose: 
	- Update IsUploaded flag in Archive_Light.dbo.CBP_DirectDebit_FileAWSHistory table once SSIS package has loaded new direct debit files to disk, ready for uploading to S3

------------------------------------------------------------------------------
Modification History


******************************************************************************/
CREATE PROCEDURE AWSFile.CBP_DDTransHistory_UpdateAWSUploadLog (@DownloadStartDateTime datetime)
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE h
	SET h.IsDownloaded = 1
	FROM Archive_Light.dbo.CBP_DirectDebit_FileAWSLog h
	WHERE 
		h.AWSLoadDateStart = @DownloadStartDateTime;

END