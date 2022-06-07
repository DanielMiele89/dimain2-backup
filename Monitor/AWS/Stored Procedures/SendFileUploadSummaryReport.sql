/******************************************************************************/
--Creation Date: 2019-05-22; Created By: Edmond Eilerts de Haan; Part of the Cloud Archive project. Reports on files uploaded to AWS.
CREATE PROC [AWS].[SendFileUploadSummaryReport]
AS
SET NOCOUNT ON;

DECLARE @StartDate DATETIME,
	@EndDate DATETIME

DECLARE 
	@EmailBody VARCHAR(MAX),
	@EmailSubject NVARCHAR(255) = '[' + @@SERVERNAME + '] AWS Upload Summary',
	@EmailBodyFormat VARCHAR(20) = 'HTML',
--	@EmailRecipients VARCHAR(MAX) = 'bob@rewardinsight.com',
	@EmailRecipients VARCHAR(MAX) = 'devdb@rewardinsight.com;',
	@EmailImportance VARCHAR(6) = 'Normal';

SET @EndDate = CAST(GETDATE() as date);
SET @StartDate = DATEADD(dd, -1, @EndDate);

SET @EmailBody = '<h3>AWS Upload Summary</h3>
For ' + CONVERT(VARCHAR(10), @StartDate, 120) + '<br><br>';


SET @EmailBody = @EmailBody + 
'<table border="1"><tr>
	<th>Server Name</th>
	<th>Files Logged</th>
	<th>Files Uploaded</th>
</tr>
'
+
CONVERT(VARCHAR(MAX),
	(
	SELECT ServerName as 'td', '',
		SUM(CASE WHEN l.LoggedDate >= @StartDate AND l.LoggedDate < @EndDate THEN 1 ELSE 0 END) as 'td', '',
		SUM(CASE WHEN l.UploadedDate >= @StartDate AND l.UploadedDate < @EndDate THEN 1 ELSE 0 END) as 'td', ''
	FROM AWS.FileUploadLog l
	WHERE (l.LoggedDate >= @StartDate AND l.LoggedDate < @EndDate)
	OR (l.UploadedDate >= @StartDate AND l.UploadedDate < @EndDate)
	GROUP BY ServerName
	ORDER BY ServerName ASC
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
