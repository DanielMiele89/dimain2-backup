
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

CREATE PROCEDURE [MI].[CampaignReport_Email_SuspectsLTE]
AS
BEGIN
	SET NOCOUNT ON;

/* VARIABLES */

DECLARE @body VARCHAR(MAX)
DECLARE @Deadline nvarchar(50) = DATEADD(WK, DATEDIFF(WK, 0, GETDATE()), 4) -- Set to end of week (Friday)
DECLARE @AttachName nvarchar(100)

declare @recip nvarchar(500)
select @recip = [MI].[CampaignReport_Recipients]()

declare @names nvarchar(500)
exec MI.CampaignReport_Email_GetNames @names = @names OUTPUT

/*************/

SET @AttachName = 'Campaign Calculation Checks - Extended'

-- Create string for table rows for data
-- FORMAT used to format values into strings
SET @body = CAST
( 
	(
		SELECT DISTINCT '<td>'
			+ c.clientservicesref + '</td><td>' 
			+ CampaignName + '</td><td>'
			+ FORMAT(c.startDate, 'dd/MM/yyyy', 'en-GB') + '</td><td>' 
			+ FORMAT(MaxEndDate, 'dd/MM/yyyy', 'en-GB')+ '</td><td>' 
			+ InternalControlGroup + '</td><td>' 
			+ ExternalControlGroup + '</td><td align="right">' 
			+ FORMAT(Cardholders, 'N00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(Sales, 'C00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(Commission, 'C00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(IncrementalSales_Internal, 'C00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(IncrementalSales_External, 'C00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(Cardholders_Awareness, 'N', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(Sales_Awareness, 'C00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(UpliftCardholders_Perc_Internal_Awareness, 'P00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(IncrementalSales_Internal_Awareness, 'C00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(UpliftCardholders_Perc_External_Awareness, 'P00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(IncrementalSales_External_Awareness, 'C00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(Cardholders_Loyalty, 'N00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(Sales_Loyalty, 'C00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(UpliftCardholders_Perc_Internal_Loyalty, 'P00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(IncrementalSales_Internal_Loyalty, 'C00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(UpliftCardholders_Perc_External_Loyalty, 'P00', 'en-GB') + '</td><td align="right">' 
			+ FORMAT(IncrementalSales_External_Loyalty, 'C00', 'en-GB') + '</td><td align="center">' 
			+ CASE WHEN MAX(AwarenessCheck) <> '-' THEN '&#x2717;' ELSE MAX(AwarenessCheck) END + '</td><td align="center">' 
			+ CASE WHEN MAX(LoyaltyCheck) <> '-' THEN '&#x2717;' ELSE MAX(LoyaltyCheck) END + '</td>'
		FROM MI.CampaignReport_CheckFlagsLTE c 
		INNER JOIN MI.campaignreportlog r ON r.ClientServicesRef = c.ClientServicesRef AND r.StartDate = c.StartDate
		WHERE r.IsError = 0 AND r.ExtendedPeriod = 1 AND CAST(CalcDate AS DATE) >= CAST(DATEADD(d, -2, GETDATE()) as DATE) and c.Archived = 0
		GROUP BY c.ClientServicesRef, CampaignName, c.StartDate, MaxEndDate, InternalControlGroup, ExternalControlGroup, Cardholders,
			Sales, Commission, IncrementalSales_Internal, IncrementalSales_External, Cardholders_Awareness, Sales_Awareness,
			IncrementalSales_Internal_Awareness, IncrementalSales_External_Awareness, Cardholders_Loyalty, Sales_Loyalty, IncrementalSales_Internal_Loyalty,
			IncrementalSales_External_Loyalty,UpliftCardholders_Perc_Internal_Awareness,UpliftCardholders_Perc_External_Awareness,
			UpliftCardholders_Perc_Internal_Loyalty,UpliftCardholders_Perc_External_Loyalty
		FOR XML PATh ('tr'), TYPE 
	) AS VARCHAR(MAX)
)

-- Creates table settings and headings
SET @body = '<table cellpadding="1" cellspacing="2" border="1">'
				+ '<tr><th colspan=6>Details</th><th colspan=5>During Campaign</th><th colspan=6>Awareness</th><th colspan=6>Loyalty</th><th colspan=2>Checks</th></tr>'
				+ '<tr><th colspan=6></th><th colspan=5></th><th colspan=2></th><th colspan=2>Internal</th><th colspan=2>External</th><th colspan=2></th><th colspan=2>Internal</th><th colspan=2>External</th><th colspan=2></th></tr>'
				+ '<tr><th>Client Services Ref</th><th>Campaign Name</th><th>Start Date</th><th>End Date</th><th>Internal Control Group</th><th>External Control Group</th><th>Cardholders</th><th>Sales</th><th>Commission</th><th>Incremental Sales - Internal</th><th>Incremental Sales - External</th><th>Cardholders</th><th>Sales</th><th>% Cardholders Used for Uplift Calc</th><th>Incremental Sales</th><th>% Cardholders Used for Uplift Calc</th><th>Incremental Sales</th><th>Cardholders</th><th>Sales</th><th>% Cardholders Used for Uplift Calc</th><th>Incremental Sales</th><th>% Cardholders Used for Uplift Calc</th><th>Incremental Sales</th><th>Awareness</th><th>Loyalty</th></tr>'
				+ REPLACE(REPLACE( REPLACE( @body, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&')
				+ '</table>'


-- Creates email with introduction and instructions 
SET @Deadline = DATENAME(dw, @deadline) + ' ' + DATENAME(dd, @Deadline) + 'th ' + DATENAME(mm, @Deadline)
--SET @Deadline = 'Wednesday 9th September'
SET @body = 'Hi<br /><br />'

			--+ '<b>Apologies for the emails, an error in the process caused them to be sent blank.  Campaign OE002 2015-08-20 currently has an error that is being looked at.  If you require this urgently, please let me know. </b><br /><br />'

			+ 'These are the campaigns that were measured and any automated checks that flagged an error. <br /><br />'

			+ 'Please note that the deadline for this QA is on <b>'+@Deadline+'.</b> <br /><br />'

			+ 'A check that has a " - " indicates that the campaign passed that test successfully otherwise a &#x2717; is diplayed <br /><br />' 

			+ @body + '<br /><br />' -- @body holds the table of data

			+ '<b><u>Check Explanations:</u></b><br /><br />'

			+ '<b>Awareness:</b> If awareness results have a 0 value in incremental sales -- Decide if you want to override default limits (min 10 or 10% customers not assigned to another WOW offer) <br /><br />'

			+ '<b>Loyalty:</b> If loyalty results have a 0 value in incremental sales -- Decide if you want to override default limits (min 10 or 10% customers not assigned to another WOW offer) <br /><br />'

			+ 'If you would like further information on the errors produced, use MI.CampaignReport_CheckFlagsLTE using the ClientServicesRef, StartDate and Archived = 0. <br />'
			
			+ 'If you have any suggestions or problems, please email '+@names+' with "Campaign Reporting - Suggestion" or "Campaign Reporting - Problem" (without quotes) as the subject to ensure that it is handled correctly<br /><br />'

			+ 'If you have any queries please inform '+@names+' (you can reply directly to this email) or a member of the BI Team<br /><br />'

			+ 'Regards,'			


set @body = isnull(@body, 'Hi<br /><br />No campaigns were calculated this week for the Extended period.<br /><br />If you believe this is an error please inform '+@names+' (you can reply directly to this email) or a member of the BI Team<br /><br />Regards,')

DECLARE @Query nvarchar(max)
--SET @Query = 'SELECT ' + '''' +replace(@body, '''', '''''') +  ''''

SET @Query = 	'

SELECT ''sep=;' + CHAR(13) + CHAR(10) + 'Details'', '''', '''', '''', '''', '''', ''During Campaign'', '''', '''', '''', '''', ''Awareness'', '''', '''', '''', '''', '''', ''Loyalty'', '''', '''', '''', '''', '''', ''Checks'', ''''

UNION ALL

SELECT ''Client Services Ref'', ''Campaign Name'', ''Start Date'', ''End Date'', ''Internal Control Group'', ''External Control Group''
	, ''Cardholders'', ''Sales'', ''Commission'', ''Incremental Sales: Internal'', ''Incremental Sales: External''
	, ''Cardholders'', ''Sales'', ''% Cardholders Used for Uplift Calc'', ''Incremental Sales'', ''% Cardholders Used for Uplift Calc'', ''Incremental Sales''
	, ''Cardholders'', ''Sales'', ''% Cardholders Used for Uplift Calc'', ''Incremental Sales'', ''% Cardholders Used for Uplift Calc'', ''Incremental Sales''
	, ''Awareness'', ''Loyalty''

UNION ALL

		SELECT DISTINCT
			c.ClientServicesRef
			,CampaignName
			,FORMAT(c.StartDate, ''dd/MM/yyyy'', ''en-GB'')
			,FORMAT(c.MaxEndDate, ''dd/MM/yyyy'', ''en-GB'')
			,InternalControlGroup
			,ExternalControlGroup
			,FORMAT(Cardholders, ''N00'', ''en-GB'')
			,FORMAT(Sales, ''C00'', ''en-GB'')
			,FORMAT(Commission, ''C00'', ''en-GB'')
			,FORMAT(IncrementalSales_Internal, ''C00'', ''en-GB'')
			,FORMAT(IncrementalSales_External, ''C00'', ''en-GB'')
			,FORMAT(Cardholders_Awareness, ''N00'', ''en-GB'')
			,FORMAT(Sales_Awareness, ''C00'', ''en-GB'')
			,FORMAT(UpliftCardholders_Perc_Internal_Awareness, ''P00'', ''en-GB'')
			,FORMAT(IncrementalSales_Internal_Awareness, ''C00'', ''en-GB'')
			,FORMAT(UpliftCardholders_Perc_External_Awareness, ''P00'', ''en-GB'')
			,FORMAT(IncrementalSales_External_Awareness, ''C00'', ''en-GB'')
			,FORMAT(Cardholders_Loyalty, ''N00'', ''en-GB'')
			,FORMAT(Sales_Loyalty, ''C00'', ''en-GB'')
			,FORMAT(UpliftCardholders_Perc_Internal_Loyalty, ''P00'', ''en-GB'')
			,FORMAT(IncrementalSales_Internal_Loyalty, ''C00'', ''en-GB'')
			,FORMAT(UpliftCardholders_Perc_External_Loyalty, ''P00'', ''en-GB'')
			,FORMAT(IncrementalSales_External_Loyalty, ''C00'', ''en-GB'')
			,CASE WHEN MAX(AwarenessCheck) <> ''-'' THEN ''X'' ELSE MAX(AwarenessCheck) END
			,CASE WHEN MAX(LoyaltyCheck) <> ''-'' THEN ''X'' ELSE MAX(LoyaltyCheck) END
		FROM MI.CampaignReport_CheckFlagsLTE c 
		INNER JOIN MI.campaignreportlog r ON r.ClientServicesRef = c.ClientServicesRef AND r.StartDate = c.StartDate
		WHERE r.IsError = 0 AND r.ExtendedPeriod = 1 AND CAST(CalcDate AS DATE) >= CAST(DATEADD(d, -2, GETDATE()) as DATE) and c.Archived = 0
		GROUP BY c.ClientServicesRef, CampaignName, c.StartDate, MaxEndDate, InternalControlGroup, ExternalControlGroup, Cardholders,
			Sales, Commission, IncrementalSales_Internal, IncrementalSales_External, Cardholders_Awareness, Sales_Awareness,
			IncrementalSales_Internal_Awareness, IncrementalSales_External_Awareness, Cardholders_Loyalty, Sales_Loyalty, IncrementalSales_Internal_Loyalty,
			IncrementalSales_External_Loyalty,UpliftCardholders_Perc_Internal_Awareness,UpliftCardholders_Perc_External_Awareness,
			UpliftCardholders_Perc_Internal_Loyalty,UpliftCardholders_Perc_External_Loyalty'


SET @AttachName = CAST(CAST(GETDATE() as DATE) as nvarchar) + ' ' + @AttachName + '.csv'

EXEC msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients = 'Insight@rewardinsight.com',
	@copy_recipients=@recip,
	@subject = 'Campaign Calculation Checks - Extended',
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


