
CREATE PROCEDURE Staging.OnCall_Processes_Completed
WITH Execute as Owner
As 
Begin

DECLARE @SearchDate DATE 

-- Initialize Variables 
SET @SearchDate = DATEADD(dd, -2, GETDATE()) -- Last 1 day




/**************************************************************************

    Get Completed

***************************************************************************/

    SELECT 
	   p.job_id AS JobID
	   , j.name AS JobName
	   , sl.SupportDescription SupportLevel
	   , ja.start_execution_date AS RunStart
	   , ja.stop_execution_date AS RunEnd
	   , CONVERT(varchar(3),DATEDIFF(minute,ja.start_execution_date, ja.stop_execution_date)/60) + ':' +
		  RIGHT('0' + CONVERT(varchar(2),DATEDIFF(minute,ja.start_execution_date, ja.stop_execution_date)%60),2) AS Duration
	   , ISNULL(ja.last_executed_step_id, 0) + 1 AS LastStep
	   , js.step_name AS StepName
    FROM Warehouse.Prototype.OnCall_Processes p
    JOIN Warehouse.Prototype.OnCall_SupportLevel sl
	   ON sl.SupportLevel = p.SupportLevel
    JOIN msdb.dbo.sysjobactivity ja
	   ON ja.job_id = p.job_id
    LEFT JOIN msdb.dbo.sysjobhistory jh
	   ON jh.instance_id = ja.job_history_id
    JOIN msdb.dbo.sysjobs j
	   ON j.job_id = ja.job_id
    JOIN msdb.dbo.sysjobsteps js
	   ON js.job_id = ja.job_id
	   AND ja.last_executed_step_id = js.step_id
    WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC)
	   AND ja.start_execution_date is not NULL
	   and ja.stop_execution_date is not null
	   AND p.isArchived = 0
    ORDER BY ja.stop_execution_date DESC



End