
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Email Client Services an overview of reports created 
	in a HTML formatted table

	======================= Change Log =======================

	30/11/2015 (HR) 
	   - Added list of reports that are due the following week at the end of the email
	14/1/2016 (HR)
	   - Changed report summary table structure to better accommodate Client Service requirements.
	   Specifically to allow them to easily copy and paste data into retailer summary decks.

	   - Added option variables to better handle simple bespoke changes

	   - Code cleanup and formatting

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Email_ClientServices_V2Beta]
AS
BEGIN
	SET NOCOUNT ON;

/*********** VARIABLE SETUP - CHANGE WITH CARE ***********/

DECLARE @CalcDay datetime
DECLARE @body varchar(max), @intTable varchar(max), @tbl varchar(max), @extTable varchar(max)
DECLARE @recip nvarchar(500)
DECLARE @update nvarchar(500)
DECLARE @names nvarchar(500)
SELECT @recip = [MI].[CampaignReport_Recipients]()
DECLARE @ReportDate date
DECLARE @insight nvarchar(1000) 
SELECT @CalcDay = dateadd(day, 1, dateadd(week, (datediff(day,0, getdate())/7), 0))
EXEC MI.CampaignReport_Email_GetNames @names = @names OUTPUT

/*******************************************************/

/* OPTION VARIABLES - CHANGE TO CONTROL PROCESS OUTPUTS */
set @ReportDate = cast(getdate() as date)
set @insight = 'Insight@rewardinsight.com'
set @update = 'The format of the results table located below has been changed to allow for easy pasting of data into retailer summary reports
Campaign Reports should show incremental sales by default'

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


--Create Overview table rows
set @body = cast( (

SELECT '<td><a href="S:\Data Insight\Team\Work Templates\Campaign\Campaign Measurement\Campaign Reports\'+ x.ClientServicesRef + '_' + LEFT(CONVERT(VARCHAR, x.StartDate, 120), 10) + ' - Final Campaign Report.pptx">'
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
	   CASE WHEN (x.IncrementalSales + IncrementalSalesAw + IncrementalSalesLo)/ ((x.Sales + SalesAw + SalesLo) - (x.IncrementalSales + IncrementalSalesAw + IncrementalSalesLo)) < 0.01 THEN 0.01
	   ELSE (x.IncrementalSales + IncrementalSalesAw + IncrementalSalesLo)/ ((x.Sales + SalesAw + SalesLo) - (x.IncrementalSales + IncrementalSalesAw + IncrementalSalesLo)) END
	   , 'P00', 'en-GB') + '</td><td align="right">' 
	+ FORMAT((x.Sales + SalesAw + SalesLo)/(x.Investment + InvestmentAw + InvestmentLo), 'C02', 'en-GB') + '</td><td align="right">' 
	+ FORMAT((x.IncrementalSales + IncrementalSalesAw + IncrementalSalesLo)/(x.Investment + InvestmentAw + InvestmentLo), 'C02', 'en-GB') + '</td><td>'
	+ x.SignificantUpliftSPC + '</td>' 
FROM (
    	SELECT l.ClientServicesRef, l.StartDate, cw.MaxEndDate, w.Cardholders, w.Sales, w.CampaignCost 'Investment', w.IncrementalSales, w.SalesUplift, w.SignificantUpliftSPC, cw.CampaignName,
		we.Effect, ISNULL(SUM(we.IncrementalSales), 0) 'IncrementalSalesAw', ISNULL(SUM(we.Sales), 0) 'SalesAw', ISNULL(SUM(we.CampaignCost), 0) 'InvestmentAw', SUM(w.Spenders + we.Spenders) 'Spenders'
	FROM MI.CampaignReportLog l
	JOIN MI.CampaignExternalResultsFinalWave w on w.ClientServicesRef = l.ClientServicesRef and w.StartDate = l.StartDate
	JOIN MI.CampaignExternalResultsLTEFinalWave we on we.ClientServicesRef = l.ClientServicesRef and we.StartDate = l.StartDate
	JOIN MI.CampaignDetailsWave cw on cw.ClientServicesRef = l.ClientServicesRef and cw.StartDate = l.StartDate
	WHERE CAST(ReportDate AS DATE) = @ReportDate and ExtendedPeriod = 1 and Effect = 'Awareness'
	group by l.ClientServicesRef, l.StartDate, cw.MaxEndDate, w.Cardholders, w.Sales, w.CampaignCost, w.IncrementalSales, w.SalesUplift, w.SignificantUpliftSPC, cw.CampaignName,
		we.Effect
) x
JOIN (
	SELECT l.ClientServicesRef, l.StartDate, cw.MaxEndDate, w.Cardholders, w.Sales, w.CampaignCost 'Investment', w.IncrementalSales, w.SalesUplift, w.SignificantUpliftSPC, cw.CampaignName,
		we.Effect, ISNULL(SUM(we.IncrementalSales),0) 'IncrementalSalesLo', ISNULL(SUM(we.Sales), 0) 'SalesLo', ISNULL(SUM(we.CampaignCost), 0) 'InvestmentLo'
	FROM MI.CampaignReportLog l
	JOIN MI.CampaignExternalResultsFinalWave w on w.ClientServicesRef = l.ClientServicesRef and w.StartDate = l.StartDate
	JOIN MI.CampaignExternalResultsLTEFinalWave we on we.ClientServicesRef = l.ClientServicesRef and we.StartDate = l.StartDate
	JOIN MI.CampaignDetailsWave cw on cw.ClientServicesRef = l.ClientServicesRef and cw.StartDate = l.StartDate
	WHERE CAST(ReportDate AS DATE) = @ReportDate and ExtendedPeriod = 1 and Effect = 'Loyalty'
	group by l.ClientServicesRef, l.StartDate, cw.MaxEndDate, w.Cardholders, w.Sales, w.CampaignCost, w.IncrementalSales, w.SalesUplift, w.SignificantUpliftSPC, cw.CampaignName,
		we.Effect
	
) y on y.ClientServicesRef = x.ClientServicesRef and y.StartDate = x.StartDate
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

-- Create Reports Due Campaign Table rows

set @extTable = cast( (

    select Csref + Sdate + Edate FROM (
	   
	   SELECT 
			'<td>' + ClientServicesRef + '</td><td>' as CSRef
			,format(StartDate, 'dd/MM/yyyy', 'en-GB') + '</td><td>' as SDate
			,format(MaxEndDate, 'dd/MM/yyyy', 'en-GB') + '</td>' as EDate
			,1 as Ext
		FROM Warehouse.MI.CampaignDetailsWave w
		WHERE MaxEnddate<=@CalcDay-13-6*7
			AND NOT EXISTS 
			(
				SELECT 1 FROM Warehouse.MI.CampaignReportLog wk
				WHERE wk.ClientServicesRef=w.ClientServicesRef
				AND wk.StartDate=w.StartDate and wk.ExtendedPeriod = 1
			)
			AND EXISTS 
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
set @intTable = replace(@intTable, 'REPLACE TITLE', 'Interim Reports')

set @extTable = replace(@tbl, 'REPLACE TABLE', replace(replace(replace( replace( @extTable, '&lt;', '<' ), '&gt;', '>' ), '&amp;', '&'), '<td>', '<td style="height:28px">'))
set @extTable = replace(@extTable, 'REPLACE TITLE', 'Campaign Reports')


set @tbl = '<table cellspacing="0" style="padding: 0 15px 0 0;" border="0"><tr valign="top"><td>' + @intTable + '</td><td>' + @extTable + '</td></tr></table>'

-- Create Email body

set @body = 'Hi all,<br /><br />'

			+ @update + 

			+ 'This is the overview of the campaigns that were reported this week.<br /><br />'

			+ @body + '<br /><br />'

			+ 'You can click the Client Services Ref to be taken to the PowerPoint report otherwise you can find the reports here:<br /><br />'

				+ '&emsp; <a href="S:\Data Insight\Team\Work Templates\Campaign\Campaign Measurement\Campaign Reports" >S:\Data Insight\Team\Work Templates\Campaign\Campaign Measurement\Campaign Reports</a><br /><br />'

			+ 'If you require the Interim reports, they are located here:<br /><br />'

				+ '&emsp; <a href="S:\Data Insight\Team\Work Templates\Campaign\Campaign Measurement\Interim Reports" >S:\Data Insight\Team\Work Templates\Campaign\Campaign Measurement\Interim Reports</a><br /><br />'

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