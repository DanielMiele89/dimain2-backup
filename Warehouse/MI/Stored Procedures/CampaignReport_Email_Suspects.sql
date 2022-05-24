
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Email Flagged information for campaign to Insight Analysts after 
	an automated calculation in a HTML formatted table

	======================= Change Log =======================

	26/08/2015	- Added .csv attachment of results to email

	01/09/2015	- General wording and improved instructions
					- Added deadline
					- Updated querying instructions to include new [Archived] column

    16/11/2015		- Added function to hold email recipients and stored procedure to return names

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Email_Suspects]
AS
BEGIN
	SET NOCOUNT ON;

	
DECLARE @body VARCHAR(MAX)
DECLARE @Deadline nvarchar(50) = DATEADD(WK, DATEDIFF(WK, 0, GETDATE()), 4) -- Set to end of week (Friday) or insert date required
DECLARE @AttachName nvarchar(100)

declare @recip nvarchar(500)
select @recip = [MI].[CampaignReport_Recipients]()

declare @names nvarchar(500)
exec MI.CampaignReport_Email_GetNames @names = @names OUTPUT


SET @AttachName = 'Campaign Calculation Checks - Interim'

-- Create string for table rows for data
-- FORMAT used to format values into strings
SET @body = CAST
( 
	(
		SELECT DISTINCT '<td>'
			+ c.clientservicesref + '</td><td>' 
			+ CampaignName + '</td><td>' 
			+ FORMAT(c.startDate, 'dd/MM/yyyy', 'en-GB') + '</td><td>' 
			+ FORMAT(c.MaxEndDate,  'dd/MM/yyyy', 'en-GB') + '</td><td>' 
			+ [InternalControlGroup] + '</td><td>' 
			+ [ExternalControlGroup] + '</td><td align="right">'
			+ FORMAT(Cardholders, 'N00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT([InternalControlGroupSize], 'N00', 'en-GB' ) + '</td><td align="right">' 
			+ FORMAT([ExternalControlGroupSize], 'N00', 'en-GB' ) + '</td><td align="right">' 
			+ FORMAT(sales, 'C00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(commission, 'C00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT([InternalSalesUplift], 'P00', 'en-GB') + '</td><td>' 
			+ [InternalSignificantUpliftSPC] + '</td><td align="right">' 
			+ FORMAT([externalsalesuplift], 'P00', 'en-GB') + '</td><td>'
			+ [ExternalSignificantUpliftSPC] + '</td><td align ="center">' 
			+ CASE WHEN MAX(salesCheck)<> '-' THEN '&#x2717;' ELSE MAX(SalesCheck) END + '</td><td align="center">' 
			+ CASE WHEN MAX(upliftcheck) <> '-' THEN '&#x2717;' ELSE MAX(upliftCheck) END + '</td><td align="center">' 
			+ CASE WHEN MAX(AdjFactorCapCheck) <> '-' THEN '&#x2717;' ELSE MAX(AdjFactorCapCheck) END  + '</td><td align="center">'
			+ CASE WHEN MAX(IncrementalSalesCheck) <> '-' THEN '&#x2717;' ELSE MAX(IncrementalSalesCheck) END  + '</td>'
		FROM MI.CampaignReport_CheckFlags c
		INNER JOIN MI.campaignreportlog r ON r.ClientServicesRef = c.ClientServicesRef and r.StartDate = c.StartDate
		WHERE r.ExtendedPeriod = 0 AND CAST(CalcDate AS DATE) >= CAST(DATEADD(d, 0, GETDATE()) as DATE) and r.IsError = 0 and c.Archived = 0
		GROUP BY c.ClientServicesRef, CampaignName, c.StartDate, c.MaxEndDate, InternalControlGroup, ExternalControlGroup,
			Cardholders, InternalControlGroupSize, ExternalControlGroupSize, Sales, Commission, InternalSalesUplift,
			InternalSignificantUpliftSPC, ExternalSalesUplift, ExternalSignificantUpliftSPC
		FOR XML PATH ('tr'), TYPE 
	) AS VARCHAR(MAX)
)
 
 -- Creates table settings and headings
SET @body = '<table cellpadding="1" cellspacing="2" border="1">'
				+ '<tr>'
				+ '<th colspan=6>Details</th><th colspan=3>Volumes</th><th colspan=2>Sales</th><th colspan=2>Internal</th><th colspan=2>External</th><th colspan=4>Checks</th>'
				+ '</tr>'
				+ '<tr>'
				+'<th>Client Services Ref</th><th>Campaign Name</th><th>Start Date</th><th>End Date</th><th>Internal Control Group</th><th>External Control Group</th><th>Cardholders</th>'
				+'<th>Internal Control Group</th><th>External Control Group</th><th>Sales</th><th>Commission</th><th>Sales Uplift</th><th>Significance</th><th>Sales Uplift</th>'
				+'<th>Significance</th><th>Sales</th><th>Uplift</th><th>AdjFactorCap</th><th>IncrementalSales</th>'
				+'</tr>'
				+ REPLACE(REPLACE( REPLACE( @body, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&')
				+ '</table>'

-- Creates email with introduction and instructions 
SET @Deadline = DATENAME(dw, @deadline) + ' ' + DATENAME(dd, @Deadline) + 'th ' + DATENAME(mm, @Deadline)
--SET @Deadline = 'Wednesday 9th September'
SET @body = 'Hi<br /><br />'

			--+ '<b>This email has been resent because BS051 had an error that has been corrected and has now been added to the list below.</b> <br /> <br />'

			+ 'These are the campaigns that were measured and any automated checks that flagged an error. <br /><br />'

			+ 'Please note that the deadline for this QA is on <b>'+@Deadline+'.</b> <br /><br />'

			+ 'A check that has a " - " indicates that the campaign passed that test successfully otherwise a &#x2717; is diplayed <br /><br />' 

			+ @body + '<br /><br />' -- @body holds the table of data

			+ '<b><u>Check Explanations -- Possible Issue:</u></b><br /><br />'

			+ '<b>Sales:</b> If sales in the PureSales table is more than +/- 5% difference of the sales in the Workings table -- Issue with SchemeUpliftTrans (e.g. not refreshed), Significant amount of Credit Card transactions <br /><br />'

			+ '<b>Uplift:</b> If Uplift is more than 50% or less than 0% -- Outliers, wrong control group selected, noise<br /><br />'

			+ '<b>AdjFactor:</b> If the AdjFactor is set to capped -- Wrong control group selected, noise <br /><br />'

			+ '<b>IncrementalSales:</b> If total incremental sales is not equal to the sum of incremental sales in SoW (Segment/BespokeCell if applicable) -- Imbalanced control group, decide what aggregation level to store<br /><br /><br />'

			+ '<b><u>Table Querying</u></b><br /><br />'

			+ 'If you would like further information on the errors produced, use MI.CampaignReport_CheckFlags using the ClientServicesRef, StartDate and Archived = 0. <br />'
			
			+ 'If you have any suggestions or problems, please email '+@names+' with "Campaign Reporting - Suggestion" or "Campaign Reporting - Problem" (without quotes) as the subject to ensure that it is handled correctly<br /><br />'

			+ 'If you have any queries please inform '+@names+ ' (you can reply directly to this email) or a member of the BI Team<br /><br />'

			+ 'Regards,'			


set @body = ISNULL(@body, 'Hi<br /><br />No campaigns were calculated this week for the Interim period.<br /><br />If you believe this is an error please inform '+@names+' (you can reply directly to this email) or a member of the BI Team<br /><br />Regards,')

-- Create .csv query

DECLARE @Query nvarchar(max)
--SET @Query = 'SELECT ' + '''' +replace(@body, '''', '''''') +  ''''

SET @Query = 	'

SET NOCOUNT ON;

SELECT ''sep=;' + CHAR(13) + CHAR(10) + 'Details'', '''', '''', '''', '''', '''', ''Volumes'', '''', '''', ''Sales'', '''', ''Internal'', '''', ''External'', '''', ''Checks'', '''', '''', ''''

UNION ALL

SELECT ''Client Services Ref'', ''Campaign Name'', ''Start Date'', ''End Date'', ''Internal Control Group'', ''External Control Group''
	, ''Cardholders'', ''Internal Control Group'', ''External Control Group''
	, ''Sales'', ''Commission''
	, ''Sales Uplift'', ''Significance''
	, ''Sales Uplift'', ''Significance''
	, ''Sales'', ''Uplift'', ''AdjFactorCap'', ''IncrementalSales''

UNION ALL

SELECT DISTINCT 
		c.ClientServicesRef
		,CampaignName
		,FORMAT(c.StartDate, ''dd/MM/yyyy'', ''en-GB'')
		,FORMAT(c.MaxEndDate, ''dd/MM/yyyy'', ''en-GB'')
		,InternalControlGroup
		,ExternalControlGroup
		,FORMAT(Cardholders, ''N00'', ''en-GB'')
		,FORMAT([InternalControlGroupSize], ''N00'', ''en-GB'' )
		,FORMAT([ExternalControlGroupSize], ''N00'', ''en-GB'' )
		,FORMAT(sales, ''C00'', ''en-GB'')
		,FORMAT(commission,  ''C00'', ''en-GB'')
		,FORMAT([InternalSalesUplift], ''P00'', ''en-GB'') 
		,InternalSignificantUpliftSPC
		,FORMAT([ExternalSalesUplift], ''P00'', ''en-GB'') 
		,ExternalSignificantUpliftSPC
		,CASE WHEN MAX(SalesCheck) <> ''-'' THEN ''X'' ELSE MAX(SalesCheck) END
		,CASE WHEN MAX(UpliftCheck) <> ''-'' THEN ''X'' ELSE MAX(UpliftCheck) END
		,CASE WHEN MAX(AdjFactorCapCheck) <> ''-'' THEN ''X'' ELSE MAX(AdjFactorCapCheck) END
		,CASE WHEN MAX(IncrementalSalesCheck) <> ''-'' THEN ''X'' ELSE MAX(IncrementalSalesCheck) END
		FROM MI.CampaignReport_CheckFlags c
		INNER JOIN MI.campaignreportlog r ON r.ClientServicesRef = c.ClientServicesRef and r.StartDate = c.StartDate
		WHERE r.ExtendedPeriod = 0 AND CAST(CalcDate AS DATE) >= CAST(DATEADD(d, -2, GETDATE()) as DATE) and r.IsError = 0 and c.Archived = 0
		GROUP BY c.ClientServicesRef, CampaignName, c.StartDate, c.MaxEndDate, InternalControlGroup, ExternalControlGroup,
			Cardholders, InternalControlGroupSize, ExternalControlGroupSize, Sales, Commission, InternalSalesUplift,
			InternalSignificantUpliftSPC, ExternalSalesUplift, ExternalSignificantUpliftSPC'


SET @AttachName = CAST(CAST(GETDATE() as DATE) as nvarchar) + ' ' + @AttachName + '.csv'

EXEC msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients = 'Insight@rewardinsight.com',
	@copy_recipients=@recip,
	@subject = 'Campaign Calculation Checks - Interim',
	@reply_to=@recip,
	@execute_query_database = 'Warehouse',
	@query = @Query,
	@attach_query_result_as_file = 1,
	@query_attachment_filename=@AttachName,
	@query_result_separator=';',
	@query_result_no_padding=1,
	@query_result_header=0,
	@query_result_width=32767,
	@body= @body,
	@body_format = 'HTML', 
	@importance = 'HIGH'

END
