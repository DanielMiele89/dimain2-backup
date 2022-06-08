-- ============================================================e===================================================
-- Author:		Edmond Eilerts de Haan
-- Create date: 2016-07-18
-- Description: Emails the duplicate offer report
-- Jira Ticket : ROCFIX-54
-- Change Log:

-- =======================================================================================================================
CREATE PROCEDURE [MemberAssociation_EmailDuplicateOfferReport]
	@PublisherName varchar(100),
	@DuplicateFileName VARCHAR(255)
WITH EXECUTE AS OWNER
AS
SET NOCOUNT ON

DECLARE @cmd VARCHAR(1000),
	@gzipfilename VARCHAR(255),
	@EmailSubject VARCHAR(256),
	@EmailBody VARCHAR(1024);

SET @gzipfilename = @DuplicateFileName + '.gz'

SET @EmailSubject = '[' + @@SERVERNAME + '] Overlapping offers in the All offer/ All member files for ' + @PublisherName;
SET @EmailBody = 'In creating the All Offer/ All Member Files for ' + @PublisherName + ', an Overlap of Members and Offers was found. The system has selected the highest priority offer and excluded the rest for the attached instances.'

--Gzip the file
SET @cmd = '""C:\Program Files (x86)\7-Zip\7z.exe" a -tgzip "' + @gzipfilename + '" "' + @DuplicateFileName + '""'
EXEC master..xp_cmdshell @cmd

--Delete the source file
SELECT @cmd = 'DEL ' + @DuplicateFileName
EXEC master..xp_cmdshell @cmd 

--email file to recepient
exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients = 'campaign.operations@rewardinsight.com;DataOperations@rewardinsight.com;rewardlss@rewardinsight.com;devdb@rewardinsight.com',
	@subject = @EmailSubject,
	@body = @EmailBody,
	@body_format = 'TEXT', 
	@importance = 'NORMAL', 
	@file_attachments = @gzipfilename,
	@exclude_query_output = 1	

--delete zip file from local folders
SELECT @cmd = 'DEL ' + @gzipfilename
EXEC master..xp_cmdshell @cmd

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[MemberAssociation_EmailDuplicateOfferReport] TO [GAS]
    AS [dbo];

