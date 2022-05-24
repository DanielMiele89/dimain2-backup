
CREATE PROCEDURE Staging.OnCall_Processes_Errors
WITH Execute as Owner
As 
Begin

DECLARE @SearchDate DATE 

-- Initialize Variables 
SET @SearchDate = DATEADD(dd, -2, GETDATE()) -- Last 1 day


/**************************************************************************

    Get Errors

***************************************************************************/

    SELECT
	   p.job_id AS JobID
	   , j.Name AS JobName
	   , sl.SupportDescription SupportLevel
	   , h.step_id AS Step
	   , h.step_name AS StepName
	   , CAST(CAST(h.run_date AS VARCHAR) AS DATE) AS RunDate
	   , LEFT(h.run_time, LEN(h.run_time)-4) + ':' + RIGHT(LEFT(h.run_time, LEN(h.run_time)-2), 2) + ':' + RIGHT(h.run_time, 2) as RunTime
	   , h.sql_severity
	   , REPLACE(h.message, 'Executed as user: NT SERVICE\SQLSERVERAGENT. ', '') AS Message
	   , h.server
    FROM Warehouse.Prototype.OnCall_Processes p
    JOIN Warehouse.Prototype.OnCall_SupportLevel sl
	   ON sl.SupportLevel = p.SupportLevel
    JOIN msdb.dbo.sysjobhistory h
	   ON h.job_id = p.job_id
    JOIN msdb.dbo.sysjobs j
	   ON h.job_id = j.job_id
    WHERE h.run_status = 0 -- Failed 
	   AND CAST(CAST(h.run_date AS VARCHAR) AS DATE) > @SearchDate
	   AND h.step_name <> '(Job Outcome)'
	   AND p.isArchived = 0
    ORDER BY
	   CAST(cast(h.run_date as varchar) as date) DESC
	   ,LEFT(h.run_time, LEN(h.run_time)-4) + ':' + RIGHT(LEFT(h.run_time, LEN(h.run_time)-2), 2) + ':' + RIGHT(h.run_time, 2) DESC



End