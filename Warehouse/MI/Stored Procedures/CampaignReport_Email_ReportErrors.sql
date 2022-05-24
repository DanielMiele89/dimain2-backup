
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Email Flagged information for campaign to Insight Analysts after 
	an automated calculation in a HTML formatted table

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Email_ReportErrors]
AS
BEGIN
	SET NOCOUNT ON;
	

DECLARE @body VARCHAR(MAX)

declare @recip nvarchar(500)
select @recip = [MI].[CampaignReport_Recipients]()

declare @names nvarchar(500)
exec MI.CampaignReport_Email_GetNames @names = @names OUTPUT

-- Create string for table rows for data
-- FORMAT used to format values into strings
SET @body = CAST
( 
	(
		SELECT DISTINCT '<td>'
			+ m.ClientServicesRef + '</td><td>'
			+ FORMAT(m.StartDate, 'dd/MM/yyyy', 'en-GB') + '</td><td>'
			+ CAST(ExtendedPeriod as varchar) + '</td><td>'
			+ Status + '</td>'
		FROM MI.CampaignReportLog m
		WHERE ReportDate is null and isError = 0 and Status = 'Calculation Completed'
		FOR XML PATH ('tr'), TYPE 
	) AS VARCHAR(MAX)
)

 -- Creates table settings and headings
SET @body = '<table cellpadding="1" cellspacing="2" border="1">'
				+ '<tr>'
				+'<th>Client Services Ref</th><th>Start Date</th><th>Extended Period</th><th>Status</th>'
				+'</tr>'
				+ REPLACE(REPLACE( REPLACE( @body, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&')
				+ '</table>'

	
-- Creates email with introduction and instructions 
SET @body = 'Hi<br /><br />'
			+ 'These are the campaigns where an error occurred during the measurement procedure. <br /><br />'
			+ @body + '<br /><br />' -- @body holds the table of data
			
			+ 'If you have any queries, problems or suggestions, please inform '+@names+ ' or a member of the BI Team<br /><br />'

			+ 'Regards,'			

DECLARE @subject varchar(60) = 'Campaign Calculation - Report Errors'

SET @subject = case when ISNULL(@body, '0') = '0' then @subject + ' (No Issues)' else @subject end

set @subject = @subject + ''


set @body = ISNULL(@body, 'Hi<br /><br />All reports were successfully generated &#x2713;.<br /><br />If you believe this is an error please inform ' + @names + ' or a member of the BI Team<br /><br />Regards,')

EXEC msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients= @recip,
	@subject = @subject,
	@reply_to= @recip,
	@body= @body,
	@body_format = 'HTML', 
	@importance = 'HIGH'



END