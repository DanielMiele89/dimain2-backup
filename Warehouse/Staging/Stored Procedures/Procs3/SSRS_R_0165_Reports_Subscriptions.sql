
/********************************************************************************************
** Name: SSRS Report Subscriptions
** Desc: To display the subscription information for reports on DIMAIN
** Auth: Zoe Taylor
** Date: 25/07/2017
*********************************************************************************************
** Change History
** ---------------------
** No                Date            Author              Description 
** --                --------        -------             ------------------------------------
** 1    
*********************************************************************************************/


CREATE Procedure [Staging].[SSRS_R_0165_Reports_Subscriptions] (@Day varchar(20), @Active bit)
With Execute as Owner

AS
Begin

	 Select 
		Subs.ReportName
		, replace(Subs.ReportPath, '/' + subs.ReportName, '') ReportPath 
		,	CASE	
				when Subs.ReportName like '%R_[0-9]%' then 'Data Operations'
				Else 'BI'
			End as ResponsibleTeam 
		, Subs.Active
		, subs.LastRunTime
		, Subs.RunInLast4Weeks
		, ISNULL(subs.WeekOfMonth, Subs.WeeksInterval) WeeksInterval
		, Subs.StartEndDate
		, Subs.ReportingDays
		, Subs.SendTo
		, Subs.SendCC
		, Subs.SendBCC
		, Subs.ReplyTo
		, CASE WHEN CHARINDEX('@', REPLACE(REPLACE(Subs.SendTo, '@reward', ''), '@contactable', '')) > 0 THEN 1 ELSE 0 END isExternal
		, Subs.EmailSubject
		, Subs.EmailMessage
		, Subs.Parameter1Name
		, Subs.Parameter1Value
		, Subs.Parameter2Name
		, Subs.Parameter2Value
		, Subs.Parameter3Name
		, Subs.Parameter3Value	
	 From 
		(
			SELECT 
				right(c.path, charindex('/', reverse(c.path))-1) [ReportName]
				, c.[Path] AS [ReportPath]
				, SUB.LastRunTime 
					, case 
					when datediff(day, cast(sch.LastRunTime as date), cast(getdate() as date)) >= 29 then 'N'
					Else 'Y'
				End as RunInLast4Weeks
				, Case when sch.EndDate is null then '1'
					Else '0'
				End as [Active]
				, case 
					when sch.WeeksInterval = 1 then 'Every week'
					when sch.WeeksInterval = 2 then 'Fortnightly'
					Else 'Every ' + cast(sch.WeeksInterval as varchar(2)) + ' weeks'
				End as WeeksInterval
				, Case 
					when sch.MonthlyWeek = 1 then 'First Week Of Month'
					when sch.MonthlyWeek = 2 then 'Second Week Of Month'
					when sch.MonthlyWeek = 3 then 'Third Week Of Month'
					when sch.MonthlyWeek = 4 then 'Fourth Week Of Month'
				End as WeekOfMonth
				, cast(replace(Warehouse.Staging.ReportingDays(coalesce(cast(sch.DaysOfWeek as int),0)), ',', CHAR(13)+CHAR(10)) as varchar(100)) as [ReportingDays] 
			--	, SUB.[Description] 
			--	, SCH.Name AS ScheduleName
				, cast(replace(CAST(ExtensionSettings AS XML).value('(//ParameterValue[Name="TO"]/Value)[1]','VARCHAR(MAX)') , ';', CHAR(13)+CHAR(10)) as varchar(500)) AS [SendTo]
				, cast(replace(CAST(ExtensionSettings AS XML).value('(//ParameterValue[Name="CC"]/Value)[1]','VARCHAR(MAX)') , ';', CHAR(13)+CHAR(10)) as varchar(500))  AS [SendCC]  
				, cast(replace(CAST(ExtensionSettings AS XML).value('(//ParameterValue[Name="BCC"]/Value)[1]','VARCHAR(MAX)') , ';', CHAR(13)+CHAR(10)) as varchar(500))  AS [SendBCC]  
				, cast(replace(CAST(ExtensionSettings AS XML).value('(//ParameterValue[Name="ReplyTo"]/Value)[1]','VARCHAR(MAX)') , ';', CHAR(13)+CHAR(10)) as varchar(500))  AS [ReplyTo]     
				, CAST(ExtensionSettings AS XML).value('(//ParameterValue[Name="Subject"]/Value)[1]','VARCHAR(MAX)') AS [EmailSubject]  
				, CAST(ExtensionSettings AS XML).value('(//ParameterValue[Name="Comment"]/Value)[1]','VARCHAR(MAX)') AS [EmailMessage]  
				, CAST(sub.Parameters AS XML).value('(//ParameterValue/Name)[1]','varchar(max)') as Parameter1Name
				, CAST(sub.Parameters AS XML).value('(//ParameterValue/Value)[1]','varchar(max)') as Parameter1Value
				, CAST(sub.Parameters AS XML).value('(//ParameterValue/Name)[2]','varchar(max)') as Parameter2Name
				, CAST(sub.Parameters AS XML).value('(//ParameterValue/Value)[2]','varchar(max)') as Parameter2Value
				, CAST(sub.Parameters AS XML).value('(//ParameterValue/Name)[3]','varchar(max)') as Parameter3Name
				, CAST(sub.Parameters AS XML).value('(//ParameterValue/Value)[3]','varchar(max)') as Parameter3Value
				, convert(varchar(15), sch.StartDate, 103) + ' - ' + ISNULL(convert(varchar(15), sch.EndDate, 103), 'Current') [StartEndDate]
			FROM ReportServer.dbo.Subscriptions AS Sub
			INNER JOIN ReportServer.dbo.Catalog AS c
				ON SUB.Report_OID = C.ItemID 
			INNER JOIN ReportServer.dbo.ReportSchedule AS rs
				ON SUB.Report_OID = RS.ReportID 
				AND SUB.SubscriptionID = RS.SubscriptionID 
			INNER JOIN ReportServer.dbo.Schedule AS sch
				ON RS.ScheduleID = SCH.ScheduleID 

	) Subs
	Where 1=1 
		and Subs.ReportingDays like '%' + @Day +'%' COLLATE Latin1_General_CI_AS_KS_WS -- Collate is used because the maintenance collation differs between Warehouse (where the function is stored) and ReportServer 
		and (Active = @Active or (@Active is null and Active in (1, 0)))


End