/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Uses package log table to send error email of latest run
				to necessary parties

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Monitor].[Email_Failure] (
	@PackageID uniqueidentifier
)
AS
BEGIN
	SET NOCOUNT ON;


	----------------------------------------------------------------------
	-- Config Vars
	----------------------------------------------------------------------
	DECLARE @FailedTaskBody VARCHAR(MAX) -- HTML table for the task that failed
		  , @TracebackBody VARCHAR(MAX) -- HTML table for the task that failed and any parents
		  , @FullBody VARCHAR(MAX) -- HTML table for a full log of the run
		  , @AttachmentSep VARCHAR(1) = ',' -- Seperator to use for CSV attachment
		  , @Subject VARCHAR(100) -- Subject to put on email, if null, defaults to the package name


	----------------------------------------------------------------------
	-- Build Log table
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..##ErrorEmail_Perturbation') IS NOT NULL
		DROP TABLE ##ErrorEmail_Perturbation

	-- Due to this being a string manipulation exercise, ensure all columns are varchars
	SELECT
		CAST(vpl.ID AS VARCHAR(10))							  AS ID
	  , CAST(vpl.RunID AS VARCHAR(10))						  AS RunID
	  , PackageID
	  , SourceID
	  , vpl.SourceName
	  , FORMAT(vpl.RunStartDateTime, 'dd/MM/yyyy hh\:mm\:ss') AS RunStartDateTime
	  , FORMAT(vpl.RunEndDateTime, 'dd/MM/yyyy hh\:mm\:ss')	  AS RunEndDateTime
	  , ISNULL(CAST(vpl.RowCnt AS VARCHAR(10)), '')			  AS RowCnt
	  , RIGHT(vpl.[DD HH:MM:SS], 8)							  AS [DD HH:MM:SS]
	  , CAST(vpl.SecondsDuration AS VARCHAR(10))			  AS SecondsDuration
	  , CAST(vpl.SourceTypeID AS VARCHAR(10))				  AS SourceTypeID
	  , vpl.SourceType
	  , ISNULL(vpl.ErrorDetails, '')						  AS ErrorDetails
	  , CAST(vpl.traceHasError AS VARCHAR(1))				  AS traceHasError
	  , CAST(vpl.sourceHasError AS VARCHAR(1))				  AS sourceHasError
	INTO ##ErrorEmail_Perturbation
	FROM Monitor.vw_PackageLog_Latest vpl
	WHERE @PackageID = @PackageID

	-- Default subject if NULL
	SELECT @Subject = COALESCE(@Subject, SourceName + ' Failed')
	FROM ##ErrorEmail_Perturbation
	WHERE SourceID = PackageID

	----------------------------------------------------------------------
	-- Build HTML Tables
		-- wrap columns in <td><tr>Column</tr><tr>Column2</tr></td>
	----------------------------------------------------------------------
	SET @FailedTaskBody = CAST(
	(
		SELECT
			'<td>'
			+ SourceType + '</td><td>'
			+ SourceName + '</td><td>'
			+ vpl.RunStartDateTime + '</td><td>'
			+ vpl.RunEndDateTime + '</td><td>'
			+ vpl.[DD HH:MM:SS] + '</td><td>'
			+ vpl.ErrorDetails + '</td>'
		FROM ##ErrorEmail_Perturbation vpl
		WHERE vpl.sourceHasError = 1
		ORDER BY ID
		FOR XML PATH ('tr'), TYPE
	)
	AS VARCHAR(MAX)
	)

	SET @TracebackBody = CAST(
	(
		SELECT
			'<td>'
			+ SourceType + '</td><td>'
			+ SourceName + '</td><td>'
			+ vpl.RunStartDateTime + '</td><td>'
			+ vpl.RunEndDateTime + '</td><td>'
			+ vpl.[DD HH:MM:SS] + '</td><td>'
			+ vpl.ErrorDetails + '</td>'
		FROM ##ErrorEmail_Perturbation vpl
		WHERE vpl.traceHasError = 1
		ORDER BY ID
		FOR XML PATH ('tr'), TYPE
	)
	AS VARCHAR(MAX)
	)


	SET @FullBody = CAST(
	(
		SELECT
			'<td>'
			+ SourceType + '</td><td>'
			+ SourceName + '</td><td>'
			+ vpl.RunStartDateTime + '</td><td>'
			+ vpl.RunEndDateTime + '</td><td>'
			+ vpl.RowCnt + '</td><td>'
			+ vpl.[DD HH:MM:SS] + '</td><td>'
			+ vpl.ErrorDetails + '</td>'
		FROM ##ErrorEmail_Perturbation vpl
		ORDER BY ID
		FOR XML PATH ('tr'), TYPE
	)
	AS VARCHAR(MAX)
	)

	SET @FailedTaskBody = ISNULL(@FailedTaskBody, '')
	SET @TracebackBody = ISNULL(@TracebackBody, '')
	SET @FullBody = ISNULL(@FullBody, '')

	----------------------------------------------------------------------
	-- Build HTML Tables
		-- Wrap previous results in <table> with the appropriate headings
	----------------------------------------------------------------------
	SET @FailedTaskBody = '<table cellpadding="1" cellspacing="2" border="1" width="65%">'
	+ '<tr>'
	+ '<th>Source Type</th><th>Source Name</th><th>Run Start</th><th>Run End</th><th>Duration</th><th>Error Details</th>'
	+ '</tr>'
	+ REPLACE(REPLACE(REPLACE(@FailedTaskBody, '&lt;', '<'), '&gt;', '>'), '&amp;', '&') -- XML means that some special characters get changed and mess up the html
	+ '</table>'


	SET @TracebackBody = '<table cellpadding="1" cellspacing="2" border="1" width="65%">'
	+ '<tr>'
	+ '<th>Source Type</th><th>Source Name</th><th>Run Start</th><th>Run End</th><th>Duration</th><th>Error Details </th>'
	+ '</tr>'
	+ REPLACE(REPLACE(REPLACE(@TracebackBody, '&lt;', '<'), '&gt;', '>'), '&amp;', '&')
	+ '</table>'

	SET @FullBody = '<table cellpadding="1" cellspacing="2" border="1" width="65%">'
	+ '<tr>'
	+ '<th>Source Type</th><th>Source Name</th><th>Run Start</th><th>Run End</th><th>Row Count</th><th>Duration</th><th>Error Details </th>'
	+ '</tr>'
	+ REPLACE(REPLACE(REPLACE(@FullBody, '&lt;', '<'), '&gt;', '>'), '&amp;', '&')
	+ '</table>'


	----------------------------------------------------------------------
	-- Formalise Body of email
	----------------------------------------------------------------------
	DECLARE 
		 @Body VARCHAR(MAX) 

	SET @Body = 'Hi<br /><br />'
	+ 'The package failed. <br /><br />'

	+ '<b>Failed Task Details:</b><br />'
	+ @FailedTaskBody + '<br /><br />'

	+ '<b>Traceback Details:</b><br />'
	+ @TracebackBody + '<br /><br />'

	+ '<b>Full Run Details:</b><br />'
	+ @FullBody + '<br /><br />'

	+ 'Regards,'
	
	select @Body

	----------------------------------------------------------------------
	-- Create CSV Attachment Query
		-- To pull this off, the seperator needs to be explicitly set at the top of the file
			-- this then requires that the column names are also explicitly set for the headers of the file
	----------------------------------------------------------------------

	DECLARE @AttachmentConfig VARCHAR(50) = 'sep=' + @AttachmentSep + CHAR(13) + CHAR(10) -- set the seperator and then put a newline; this appears at the top of the csv
		  , @FirstCol VARCHAR(30) = 'SourceType'
		  , @AttachmentQuery VARCHAR(MAX)

	SET @AttachmentConfig += @FirstCol + ''

	SET @AttachmentQuery = 'SET NOCOUNT ON; '
	+ 'SELECT ''' + @AttachmentConfig + ''',''' + REPLACE('SourceName, RunStartDateTime, RunEndDateTime, RowCnt, [DD HH:MM:SS], SecondsDuration, SourceTypeID, ErrorDetails, traceHasError, sourceHasError', ', ', ''', ''') + ''''
	+ ' UNION ALL '
	+ 'SELECT ' + @FirstCol + ',SourceName, RunStartDateTime, RunEndDateTime, RowCnt, [DD HH:MM:SS], SecondsDuration, SourceTypeID, ErrorDetails, traceHasError, sourceHasError FROM ##ErrorEmail_Perturbation'


	----------------------------------------------------------------------
	-- Send Email
	----------------------------------------------------------------------

	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Administrator'
							   , @recipients = 'diprocesscheckers@rewardinsight.com; hayden.reid@rewardinsight.com'
							   , @Subject = @Subject
							   , @Body = @Body
							   , @body_format = 'HTML'
							   , @query = @AttachmentQuery
							   , @attach_query_result_as_file = 1
							   , @query_attachment_filename = 'result.csv'
							   , @query_result_separator = @AttachmentSep
							   , @query_result_no_padding = 1
							   , @query_result_header = 0
							   , @query_result_width = 32767

	IF OBJECT_ID('tempdb..##ErrorEmail_Perturbation') IS NOT NULL
		DROP TABLE ##ErrorEmail_Perturbation

END
