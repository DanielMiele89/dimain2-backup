/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Uses package log table to send success email of latest run
				to necessary parties

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Monitor].[Email_Success]
(
	@PackageID uniqueidentifier
)
AS
BEGIN
	SET NOCOUNT ON;


	DECLARE @PackageBody VARCHAR(MAX) -- HTML table for high level details
		  , @FullBody VARCHAR(MAX) -- HTML table for full display of log
		  , @AttachmentSep VARCHAR(1) = ',' -- Seperator to use for CSV attachment
		  , @Subject VARCHAR(100) -- if NULL, will use the package name


	----------------------------------------------------------------------
	-- Build Log Table
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..##ToEmail_Perturbation') IS NOT NULL
		DROP TABLE ##ToEmail_Perturbation

	SELECT
		CAST(vpl.ID AS VARCHAR(10))							  AS ID
	  , CAST(vpl.RunID AS VARCHAR(10))						  AS RunID
	  , [vpl].[PackageID]
	  , [vpl].[SourceID]
	  , vpl.SourceName
	  , FORMAT(vpl.RunStartDateTime, 'dd/MM/yyyy hh\:mm\:ss') AS RunStartDateTime
	  , FORMAT(vpl.RunEndDateTime, 'dd/MM/yyyy hh\:mm\:ss')	  AS RunEndDateTime
	  , ISNULL(CAST(vpl.RowCnt AS VARCHAR(10)), '')			  AS RowCnt
	  , RIGHT(vpl.[DD HH:MM:SS], 8)							  AS [DD HH:MM:SS]
	  , CAST(vpl.SecondsDuration AS VARCHAR(10))			  AS SecondsDuration
	  , CAST(vpl.SourceTypeID AS VARCHAR(10))				  AS SourceTypeID
	  , vpl.SourceType
	  , vpl.ErrorDetails
	INTO ##ToEmail_Perturbation
	FROM [Monitor].vw_PackageLog_Latest vpl
	WHERE [vpl].[PackageID] = @PackageID

	SELECT @Subject = COALESCE(@Subject, ##ToEmail_Perturbation.[SourceName] + ' Completed')
	FROM ##ToEmail_Perturbation
	WHERE ##ToEmail_Perturbation.[SourceID] = ##ToEmail_Perturbation.[PackageID]

	----------------------------------------------------------------------
	-- Build HTML Tables
		-- wrap columns in <td><tr>Column</tr><tr>Column2</tr></td>
	----------------------------------------------------------------------

	SET @PackageBody = CAST(
	(
		SELECT
			'<td>'
			+ [vpl].[SourceType] + '</td><td>'
			+ [vpl].[SourceName] + '</td><td>'
			+ vpl.RunStartDateTime + '</td><td>'
			+ vpl.RunEndDateTime + '</td><td>'
			+ ISNULL(vpl.RowCnt, '') + '</td><td>'
			+ vpl.[DD HH:MM:SS] + '</td>'
		FROM ##ToEmail_Perturbation vpl
		WHERE [vpl].[SourceTypeID] IN (1, 2)
		ORDER BY [vpl].[ID]
		FOR XML PATH ('tr'), TYPE
	)
	AS VARCHAR(MAX)
	)

	SET @FullBody = CAST(
	(
		SELECT
			'<td>'
			+ [vpl].[SourceType] + '</td><td>'
			+ [vpl].[SourceName] + '</td><td>'
			+ vpl.RunStartDateTime + '</td><td>'
			+ vpl.RunEndDateTime + '</td><td>'
			+ ISNULL(vpl.RowCnt, '') + '</td><td>'
			+ vpl.[DD HH:MM:SS] + '</td>'
		FROM ##ToEmail_Perturbation vpl
		ORDER BY [vpl].[ID]
		FOR XML PATH ('tr'), TYPE
	)
	AS VARCHAR(MAX)
	)

	----------------------------------------------------------------------
	-- Build HTML Tables
		-- Wrap previous results in <table> with the appropriate headings
	----------------------------------------------------------------------
	SET @PackageBody = '<table cellpadding="1" cellspacing="2" border="1" width="50%">'
	+ '<tr>'
	+ '<th>Source Type</th><th>Source Name</th><th>Run Start</th><th>Run End</th><th>Row Count</th><th>Duration</th>'
	+ '</tr>'
	+ REPLACE(REPLACE(REPLACE(@PackageBody, '&lt;', '<'), '&gt;', '>'), '&amp;', '&')
	+ '</table>'


	SET @FullBody = '<table cellpadding="1" cellspacing="2" border="1" width="50%">'
	+ '<tr>'
	+ '<th>Source Type</th><th>Source Name</th><th>Run Start</th><th>Run End</th><th>Row Count</th><th>Duration</th>'
	+ '</tr>'
	+ REPLACE(REPLACE(REPLACE(@FullBody, '&lt;', '<'), '&gt;', '>'), '&amp;', '&')
	+ '</table>'

	----------------------------------------------------------------------
	-- Formalise body
	----------------------------------------------------------------------
	DECLARE
		@Body VARCHAR(MAX)

	SET @Body = 'Hi<br /><br />'
	+ 'The package ran successfully <br /><br />'

	+ '<b>Package/Container Details:</b><br />'
	+ @PackageBody + '<br /><br />'

	+ '<b>Full Package Details:</b><br />'
	+ @FullBody + '<br /><br />'

	+ 'Regards,'

	----------------------------------------------------------------------
	-- Create CSV Attachment Query
		-- To pull this off, the seperator needs to be explicitly set at the top of the file
			-- this then requires that the column names are also explicitly set for the headers of the file
	----------------------------------------------------------------------

	DECLARE @AttachmentConfig VARCHAR(50) = 'sep=' + @AttachmentSep + CHAR(13) + CHAR(10)
		  , @FirstCol VARCHAR(30) = 'SourceType'
		  , @AttachmentQuery VARCHAR(MAX)

	SET @AttachmentConfig += @FirstCol + ''

	SET @AttachmentQuery = 'SET NOCOUNT ON; '
	+ 'SELECT ''' + @AttachmentConfig + ''',''' + REPLACE('SourceName, RunStartDateTime, RunEndDateTime, RowCnt, [DD HH:MM:SS], SecondsDuration, SourceTypeID', ', ', ''', ''') + ''''
	+ ' UNION ALL '
	+ 'SELECT ' + @FirstCol + ',SourceName, RunStartDateTime, RunEndDateTime, RowCnt, [DD HH:MM:SS], SecondsDuration, SourceTypeID FROM ##ToEmail_Perturbation'

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
							   , @query_attachment_filename = 'log_output.csv'
							   , @query_result_separator = @AttachmentSep
							   , @query_result_no_padding = 1
							   , @query_result_header = 0
							   , @query_result_width = 32767

	IF OBJECT_ID('tempdb..##ToEmail_Perturbation') IS NOT NULL
		DROP TABLE ##ToEmail_Perturbation

END
