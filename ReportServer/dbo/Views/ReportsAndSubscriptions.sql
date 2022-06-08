

CREATE VIEW [dbo].[ReportsAndSubscriptions]
AS
SELECT	ca.ItemID AS ReportID
	,	ca.Path AS ReportPath
	,	ca.Name AS ReportName
	,	uca.UserName AS ReportCreatedBy
	,	sch.ScheduleID
	,	sch.Name AS ScheduleName
	,	sch.StartDate AS ScheduleStartDate
	,	sch.EndDate AS ScheduleEndDate
	,	sch.NextRunTime AS ScheduleNextRunTime
	,	sch.LastRunTime AS ScheduleLastRunTime

	,	rs.SubscriptionID
	,	sub.Parameters
	,	usub.UserName AS SubscriptionCreatedBy
	,	sub.Description AS SubscriptionDescription
	,	sub.LastStatus AS SubscriptionLastStatus
FROM [ReportServer].[dbo].[Catalog] ca
INNER JOIN [ReportServer].[dbo].[Users] uca
	ON ca.CreatedByID = uca.UserID
LEFT JOIN [ReportServer].[dbo].[ReportSchedule] rs
	ON ca.ItemID = rs.ReportID
LEFT JOIN [ReportServer].[dbo].[Subscriptions] sub
	ON rs.SubscriptionID = sub.SubscriptionID
LEFT JOIN [ReportServer].[dbo].[Users] usub
	ON sub.OwnerID = usub.UserID
LEFT JOIN [ReportServer].[dbo].[Schedule] sch
	ON rs.ScheduleID = sch.ScheduleID
