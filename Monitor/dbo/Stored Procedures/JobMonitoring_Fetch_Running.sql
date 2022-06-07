
CREATE PROCEDURE [dbo].[JobMonitoring_Fetch_Running]
AS
BEGIN
	 SELECT
	   ja.job_id AS JobID
	   , j.name AS JobName	  
	   , cast(right(ja.start_execution_date,8) as varchar(max)) AS StartTime
	   , CONVERT(varchar(3),DATEDIFF(minute,ja.start_execution_date, GetDate())/60) + ':' +
		  RIGHT('0' + CONVERT(varchar(2),DATEDIFF(minute,ja.start_execution_date,getdate())%60),2) AS Duration
	   , ISNULL(ja.last_executed_step_id, 0) + 1 AS CurrentStepID
	   , js.step_name AS StepName
    FROM msdb.dbo.sysjobactivity ja
    LEFT JOIN msdb.dbo.sysjobhistory jh
	   ON jh.instance_id = ja.job_history_id
    JOIN msdb.dbo.sysjobs j
	   ON j.job_id = ja.job_id
    JOIN msdb.dbo.sysjobsteps js
	   ON js.job_id = ja.job_id
	   AND ISNULL(ja.last_executed_step_id, 0) + 1 = js.step_id
    WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC)
	   AND ja.start_execution_date IS NOT NULL
	   AND ja.stop_execution_date IS NULL
END  
	  --Errors