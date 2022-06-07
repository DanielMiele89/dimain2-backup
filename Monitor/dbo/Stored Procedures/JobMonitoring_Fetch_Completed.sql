CREATE PROCEDURE [dbo].[JobMonitoring_Fetch_Completed]
AS
BEGIN
	   SELECT
		j.job_id AS JobID
	   , j.Name AS JobName
	   , h.step_id AS Step
	   , h.step_name AS StepName
	   , CAST(CAST(h.run_date AS VARCHAR) AS DATE) AS RunDate
	  , CASE
			WHEN LEN(h.run_time) <= 4 THEN CAST(h.run_time as varchar(max))
			ELSE LEFT(h.run_time, LEN(h.run_time)-4) + ':' + RIGHT(LEFT(h.run_time, LEN(h.run_time)-2), 2) + ':' + RIGHT(h.run_time, 2) 
		end as RunTime
	   , h.sql_severity
	   , REPLACE(h.message, 'Executed as user: NT SERVICE\SQLSERVERAGENT. ', '') AS Message
	   , h.server
	   from msdb.dbo.sysjobhistory h
	      JOIN msdb.dbo.sysjobs j
	   ON h.job_id = j.job_id
    WHERE h.run_status = 1 -- Failed 
	   AND h.step_name <> '(Job Outcome)'
	   AND CAST(CAST(h.run_date AS VARCHAR) AS DATE) > DATEADD(WEEK,-3,GETDATE())
  --ORDER BY
	--   CAST(cast(h.run_date as varchar) as date) DESC
	--   ,LEFT(h.run_time, LEN(h.run_time)-4) + ':' + RIGHT(LEFT(h.run_time, LEN(h.run_time)-2), 2) + ':' + RIGHT(h.run_time, 2) DESC

	
END