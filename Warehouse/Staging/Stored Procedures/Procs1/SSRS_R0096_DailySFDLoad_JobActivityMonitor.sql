

-- ***************************************************************************
-- Author: Stuart Barnley
-- Create date: 18/08/2015
-- Description: Shows Job Activity Monitor tasks and reports and how long they take on a daily basis
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0096_DailySFDLoad_JobActivityMonitor](
			@ReportDate DATE)
									
AS
BEGIN
	SET NOCOUNT ON;


IF OBJECT_ID ('tempdb..#FullSysJobs') IS NOT NULL DROP TABLE #FullSysJobs
SELECT	*
INTO #FullSysJobs
FROM	(
	SELECT	j.name as JobName,
		s.step_id as Step,
		s.step_name as StepName,
		msdb.dbo.agent_datetime(run_date, run_time) as RunDateTime,
		CONVERT(DATETIME, RTRIM(run_date)) + ((run_time/10000 * 3600) + ((run_time%10000)/100*60) + (run_time%10000)%100) / (86399.9964 /* Start Date Time */)
		+ ((run_duration/10000 * 3600) + ((run_duration%10000)/100*60) + (run_duration%10000)%100 /*run_duration_elapsed_seconds*/) / (86399.9964 /* seconds in a day*/) AS EndTime,

		((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) as RunDurationMinutes
	FROM msdb.dbo.sysjobs j 
	INNER JOIN msdb.dbo.sysjobsteps s 
		ON j.job_id = s.job_id
	INNER JOIN msdb.dbo.sysjobhistory h 
		ON s.job_id = h.job_id 
		AND s.step_id = h.step_id 
		AND h.step_id <> 0
	WHERE j.enabled = 1 and j.name in ('Restore SLC_Report Database','SLC_Report Data Processing')
	) as a
WHERE	CAST(RunDateTime AS DATE) = @ReportDate
	AND Step in (6,7,8,9,10)--StepName IN ('Update Customer Journey Status','Update Customer DD Stats')
ORDER BY RunDateTime ASC
--(41 row(s) affected)


SELECT	RunDateTime,
		EndTime,
	Step,
	CASE	
		WHEN JobName COLLATE DATABASE_DEFAULT IS NULL THEN  ReportName COLLATE DATABASE_DEFAULT
		ELSE JobName COLLATE DATABASE_DEFAULT
	END as JobName,
	StepName,	
	CASE	
		WHEN JobName COLLATE DATABASE_DEFAULT IS NULL THEN  'Report'
		ELSE 'Task'
	END as JobType,
	CAST(RunDurationMinutes/60 AS VARCHAR) + ' hours ' + CAST(RunDurationMinutes%60 AS VARCHAR) + ' minutes' as TimeTaken
FROM
	(
	SELECT	RunDateTime,
			EndTime,
		Step,
		StepName,
		CASE
			WHEN CAST(StepName AS VARCHAR(100)) LIKE '%step_1%' THEN NULL ELSE JobName
		END as JobName,
		ReportName,
		RunDurationMinutes
	FROM #FullSysJobs fsj
	LEFT OUTER JOIN (
			SELECT  e.Name as ReportName,
				CAST(ScheduleID AS VARCHAR(50)) as ScheduleID
			FROM ReportServer.dbo.ReportSchedule a
			INNER JOIN ReportServer.dbo.Subscriptions d
				ON a.SubscriptionID = d.SubscriptionID
			INNER JOIN ReportServer.dbo.Catalog e
				ON d.report_oid = e.itemid
			)rs
		ON fsj.JobName COLLATE DATABASE_DEFAULT = ScheduleID COLLATE DATABASE_DEFAULT
	)a
ORDER BY RunDateTime



END