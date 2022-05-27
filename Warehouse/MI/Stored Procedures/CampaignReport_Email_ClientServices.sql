


/**********************************************************************

    Author:		 Hayden Reid
    Create date: 13/08/2015
    Description: Email Client Services an overview of reports created 
    in a HTML formatted table

    ======================= Change Log =======================

    30/11/2015 (HR) 
	   - Added list of reports that are due the following week at the end of the email

    14/01/2016 (HR)
	   - Changed report summary table structure to better accommodate Client Service requirements.
	   Specifically to allow them to easily copy and paste data into retailer summary decks.

	   - Added option variables to better handle simple bespoke changes

	   - Code cleanup and formatting

    27/05/2016 (PL)
	   - amended total sales to include post-campaign period.
	   - aligned other stats with spreadsheet and powerpoint outputs

    19/07/2016
	   - Added @note variable option to allow for comments to be inserted easier

    26/09/2016 
	   - Extended version has become legacy and removed from the code

    01/11/2016
	   - Updated code to set incrementality metrics to 0 when they are < 0

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Email_ClientServices]
AS
BEGIN
	SET NOCOUNT ON;

/*********** VARIABLE SETUP - CHANGE WITH CARE ***********/

DECLARE @CalcDay datetime
DECLARE @body varchar(max), @intTable varchar(max), @tbl varchar(max), @extTable varchar(max)
DECLARE @recip nvarchar(500)
DECLARE @update nvarchar(500), @note nvarchar(500)
DECLARE @names nvarchar(500)
SELECT @recip = [MI].[CampaignReport_Recipients]()
DECLARE @ReportDate date
DECLARE @insight nvarchar(1000) 
SELECT @CalcDay = dateadd(day, 1, dateadd(week, (datediff(day,0, getdate())/7), 0))
EXEC MI.CampaignReport_Email_GetNames @names = @names OUTPUT

/*******************************************************/

/* OPTION VARIABLES - Change to control outputs */
set @ReportDate = cast(getdate() as date)
set @insight = 'Insight@rewardinsight.com'
set @update = ''
set @note = 'The previous set of folders have now been ''Archived'' and are where all previously delivered reports have been moved.  This folder is located <a href="S:\Data Insight\Team\Work Templates\Campaign\Campaign Measurement\Archived (29-09-2016)">here</a>.
<br />If you require Extended reports, please inform ' + @names + ' as and when they are required.'

/*****************************************************/

set @insight = @recip + ';' + @insight -- setup email recipients

set @update = SUBSTRING(@update, 0, ISNULL(NULLIF(CHARINDEX(CHAR(13) + CHAR(10), @update, LEN(@update) - 2), 0), LEN(@update) + 1))

set @update = REPLACE(@update, CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10), CHAR(13) + CHAR(10)) -- replace double newlines

set @update = SUBSTRING(@update, 0, ISNULL(NULLIF(CHARINDEX(CHAR(13) + CHAR(10), @update, LEN(@update) - 2), 0), LEN(@update)+1)) -- replace last newline, if applicable

set @update = CASE 
			 WHEN LEN(@update) > 0 THEN '<b>The campaign report process has been updated:</b> <br /><ul><li>' + REPLACE(@update, CHAR(13) + CHAR(10), '</li><li>') + '</li></ul>'  
			 ELSE '' 
		  END -- setup html

set @update = CASE 
			WHEN LEN(@update) > 0 THEN @update + '</ul><b>If you have any further improvements, please inform ' + @names + '.</b> <br /> <br />'
			ELSE ''
		END -- finish html setup

set @note = CASE WHEN LEN(@Note) > 0 THEN '<b> NOTE: </b>' + @note + '<br /><br />' ELSE '' END

--Create Overview table rows
set @body = cast( (

SELECT '<td><a href="S:\Data Insight\Team\Work Templates\Campaign\Campaign Measurement\Campaign Reports\'+ x.ClientServicesRef + '_' + LEFT(CONVERT(VARCHAR, x.StartDate, 120), 10) + ' - Campaign Report.pptx">'
	+ x.ClientServicesRef + '</a></td><td>'
	+ FORMAT(x.StartDate, 'dd/MM/yyyy', 'en-GB') + '</td><td>'  
	+ FORMAT(x.MaxEndDate, 'dd/MM/yyyy', 'en-GB') + '</td><td>'  
     + x.CampaignName + '</td><td align="right">'
	+ FORMAT(x.Cardholders, 'N00', 'en-GB') + '</td><td align="right">'
	+ FORMAT(x.Spenders, 'N00', 'en-GB') + '</td><td align="right">'
	+ FORMAT(cast(x.Spenders as float)/cast(x.Cardholders as float), 'P01', 'en-GB') + '</td><td align="right">'  
	+ FORMAT(x.Sales, 'C00', 'en-GB') + '</td><td align="right">' 
     + FORMAT(x.IncrementalSales, 'C00', 'en-GB') + '</td><td align="right">' 
	+ FORMAT(x.Investment, 'C00', 'en-GB') + '</td><td align="right">' 
     + FORMAT(
	  (x.IncrementalSales)/ ISNULL(NULLIF(((x.Sales) - (x.IncrementalSales)), 0), 0.001)
	   , 'P00', 'en-GB') + '</td><td align="right">' 
	+ FORMAT((x.Sales)/(x.Investment), 'C02', 'en-GB') + '</td><td align="right">' 
	+ FORMAT((x.IncrementalSales)/(x.Investment), 'C02', 'en-GB') + '</td><td>'
	+ x.SignificantUpliftSPC + '</td>' 
FROM (
    	SELECT l.ClientServicesRef, l.StartDate, cw.MaxEndDate, w.Cardholders, w.Sales, w.CampaignCost 'Investment', CASE WHEN w.IncrementalSales < 0 THEN 0 ELSE w.IncrementalSales END IncrementalSales, CASE WHEN w.SalesUplift < 0 THEN 0 ELSE w.SalesUplift END SalesUplift, w.SignificantUpliftSPC, cw.CampaignName
	   , SUM(w.Spenders) 'Spenders'
	FROM MI.CampaignReportLog l
	JOIN MI.CampaignExternalResultsFinalWave w on w.ClientServicesRef = l.ClientServicesRef and w.StartDate = l.StartDate
	JOIN MI.CampaignDetailsWave cw on cw.ClientServicesRef = l.ClientServicesRef and cw.StartDate = l.StartDate
	WHERE CAST(ReportDate AS DATE) = @ReportDate and ExtendedPeriod = 0
	group by l.ClientServicesRef, l.StartDate, cw.MaxEndDate, w.Cardholders, w.Sales, w.CampaignCost, w.IncrementalSales, w.SalesUplift, w.SignificantUpliftSPC, cw.CampaignName
) x
ORDER BY x.ClientServicesRef, x.StartDate
for xml path ('tr'), type) as varchar(max))


-- Create Report Due Interim Table rows
set @intTable = cast( (
		
	select Csref + Sdate + Edate FROM (	
		SELECT 
			'<td>' + ClientServicesRef + '</td><td>' as CSRef
			,format(StartDate, 'dd/MM/yyyy', 'en-GB') + '</td><td>' as SDate
			,format(MaxEndDate, 'dd/MM/yyyy', 'en-GB') + '</td>' as EDate
			,0 as Ext
		FROM Warehouse.MI.CampaignDetailsWave w
		WHERE MaxEnddate<=@CalcDay-13
			AND NOT EXISTS 
			(
				SELECT 1 FROM Warehouse.MI.CampaignReportLog wk
				WHERE wk.ClientServicesRef=w.ClientServicesRef
				AND wk.StartDate=w.StartDate and wk.ExtendedPeriod = 0
			)
			AND CampaignType NOT LIKE '%Base%'
	   
		) x
		ORDER BY Ext, CSRef, SDate
		for xml path ('tr'), type
) as varchar(max))

set @intTable = ISNULL(@intTable, '<td colspan="100">There are no campaign reports to be delviered next week <br /> If you believe this is an error, please inform us</td>')

-- Create rest of Overview table (headings, table tags)
set @body = '<table cellpadding="4" cellspacing="0" border="1" style="width:100%;">'
				+ '<tr>'
				+'<th>Client Services Ref</th><th>Start Date</th><th>End Date</th><th>Campaign Name</th><th>Mailed Customers</th><th>Spenders</th><th>Response Rate</th><th>Total Sales</th>'
				+'<th>Incremental Sales</th><th>Investment</th><th>Sales Uplift</th><th>Total Sales ROI</th><th>Incremental Sales ROI</th><th>Significance</th>'
				+'</tr>'
				+ replace(replace(replace( replace( @body, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">')
				+ '</table>'

-- Create generic table to be used by both Interim/Extended tables
set @tbl = '<table cellpadding="4" cellspacing="0" border="1" style="display:inline-block;">'
				+ '<tr>'
				+ '<th colspan=3>REPLACE TITLE</th>'
				+ '</tr><tr>'
				+ '<th>Client Services Ref</th><th>Start Date</th><th>End Date</th>'
				+ '</tr>'
				+ 'REPLACE TABLE'
				+ '</table>'

set @intTable = replace(@tbl, 'REPLACE TABLE', replace(replace(replace( replace( @intTable, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">'))
set @intTable = replace(@intTable, 'REPLACE TITLE', 'Campaign Reports')


set @tbl = '<table cellspacing="0" style="padding: 0 15px 0 0;" border="0"><tr valign="top"><td>' + @intTable + '</td></tr></table>'

-- Create Email body

set @body = 'Hi all,<br /><br />'

			+ @update + 

			+ @note +

			+ 'This is the overview of the campaigns that were reported this week.<br /><br />'

			+ @body + '<br /><br />'

			+ 'You can click the Client Services Ref to be taken to the PowerPoint report otherwise you can find the reports here:<br /><br />'

				+ '&emsp; <a href="S:\Data Insight\Team\Work Templates\Campaign\Campaign Measurement\Campaign Reports" >S:\Data Insight\Team\Work Templates\Campaign\Campaign Measurement\Campaign Reports</a><br /><br />'

			+ 'If you have requested and require the Extended reports, they are located here:<br /><br />'

				+ '&emsp; <a href="S:\Data Insight\Team\Work Templates\Campaign\Campaign Measurement\Extended Reports" >S:\Data Insight\Team\Work Templates\Campaign\Campaign Measurement\Extended Reports</a><br /><br />'

			+ 'Reports due for next week ('+FORMAT(dateadd(day, 6, @CalcDay), 'dd/MM/yyyy', 'en-GB') + '): <br /><br />'

			+ @tbl + '<br />'

			+ 'If you have any suggestions or problems, please email '+ @names+ ' with "Campaign Reporting - Suggestion" or "Campaign Reporting - Problem" (without quotes) as the subject to ensure that it is handled correctly<br /><br />'

			+ 'If you have any queries please inform '+@names+ ' (you can reply directly to this email if preferred) or a member of the BI Team<br /><br />'

			+ 'Regards,'	

set @body = ISNULL(@body, 
				'Hi<br /><br />'
				+ 'There were no campaigns to report on this week.<br /><br />'
				
				+ 'Reports due for next week ('+FORMAT(dateadd(day, 6, @CalcDay), 'dd/MM/yyyy', 'en-GB') + '): <br /><br />'

				+ @tbl + '</ br>'
				
				+ 'If you believe this is an error please inform ' + @names + '  (you can reply directly to this email) or a member of the BI Team<br /><br />'
				
				+ 'Regards,'
		  )	

exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator',
	@recipients= 'ClientServices@rewardinsight.com',
	--@recipients='hayden.reid@rewardinsight.com',
	@copy_recipients=@insight,
	@reply_to=@recip,
	@subject = 'Campaign Reporting - Client Services',
	@body= @body,
	@body_format = 'HTML', 
	@importance = 'HIGH'

END

