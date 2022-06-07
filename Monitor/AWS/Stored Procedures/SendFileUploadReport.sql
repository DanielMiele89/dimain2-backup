/******************************************************************************/
--Creation Date: 2018-10-08; Created By: Edmond Eilerts de Haan; Part of the Cloud Archive project. Reports on files uploaded to AWS.
CREATE PROC [AWS].[SendFileUploadReport]
	@ProcessID INT
AS
SET NOCOUNT ON;

DECLARE 
	@EmailBody VARCHAR(MAX),
	@EmailSubject NVARCHAR(255) = '[' + @@SERVERNAME + '] AWS Upload Process',
	@EmailBodyFormat VARCHAR(20) = 'HTML',
--	@EmailRecipients VARCHAR(MAX) = 'bob@rewardinsight.com',
	@EmailRecipients VARCHAR(MAX) = 'devdb@rewardinsight.com;',
	@EmailImportance VARCHAR(6) = 'Normal',
	@EventCount INT,
	@NonReadableCount INT;

CREATE TABLE #UploadEvents (EventTime VARCHAR(23), ServerName VARCHAR(256), FileName VARCHAR(256), EventMessage VARCHAR(1000));

INSERT INTO #UploadEvents (EventTime, ServerName, FileName, EventMessage)
SELECT CONVERT(VARCHAR(23), l.UploadedDate, 121) as EventTime, l.ServerName, l.FileName, 'Upload successful' as EventMessage
FROM AWS.FileUploadProcessRun p
INNER JOIN AWS.FileUploadLog l on l.ProcessRunID = p.ID
WHERE p.ID = @ProcessID
AND l.UploadedDate >= p.StartTime AND l.UploadedDate < p.EndTime
UNION
SELECT CONVERT(VARCHAR(23), e.ExceptionDate, 121), l.ServerName, l.FileName, e.ErrorDescription
FROM AWS.FileUploadProcessRun p
INNER JOIN AWS.FileUploadLog l on l.ProcessRunID = p.ID
INNER JOIN AWS.FileUploadExceptions e on e.FileLogID = l.ID
WHERE p.ID = @ProcessID
AND e.ExceptionDate >= p.StartTime AND e.ExceptionDate < p.EndTime;

--Compare the total number of events with the number of "non-readable" files
SELECT @EventCount = COUNT(*) FROM #UploadEvents;
SELECT @NonReadableCount = COUNT(*) FROM #UploadEvents e
WHERE e.EventMessage like '%' + CAST(e.FileName as varchar) + '%'
AND e.EventMessage like 'warning: Skipping file %'
AND e.EventMessage like '%. File/Directory is not readable.%';

IF (@EventCount > 0 AND @EventCount > @NonReadableCount)
BEGIN
	
	SELECT 
		@EmailBody = '<h3>AWS Upload Process</h3>';

	SET @EmailBody = @EmailBody + 
	'<table border="1">
		<tr>
			<th>Event Time</th>
			<th>Server</th>
			<th>File Path</th>
			<th>Event Message</th>
		</tr>
	'
	+
	CONVERT(VARCHAR(MAX),
		(
		SELECT EventTime as 'td', '',
			ServerName as 'td', '',
			FileName as 'td', '',
			EventMessage as 'td', ''
		FROM #UploadEvents 
		ORDER BY EventTime asc
		FOR XML PATH('tr')
		)
	)
	+
	'</table>'

	--Email
	EXEC msdb..sp_send_dbmail 
		@profile_name = 'Administrator', 
		@recipients= @EmailRecipients,
		@subject = @EmailSubject,
		@body= @EmailBody,
		@body_format = @EmailBodyFormat, 
		@importance = @EmailImportance, 
		@exclude_query_output = 1;
END


