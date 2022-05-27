/******************************************************************************
Author	  Hayden Reid
Created	  18/07/2017
Purpose	  Maps out the flow of jobs being called on the server

Copyright © 2017, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

DD/MM/YYYY - Author Name

******************************************************************************/
CREATE PROCEDURE [Prototype].[OnCall_ProcessHierarchy] 
AS
BEGIN
    
     SET NOCOUNT ON

    ---------------------------------------------------------------------------
    -- Get all the jobs that call other jobs i.e. jobs that are parents
	   -- If processes from other sources are required, insert into this table
    ---------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#JobParent') IS NOT NULL DROP TABLE #JobParent
    SELECT DISTINCT
	   Job_ID
	   , Name
	   , JobParent
	   , SupportLevel
	   , SupportDescription
	   , SUBSTRING(command, index1, index2-index1) childJob -- The name of the child job
	   , x.step_id
    INTO #JobParent
    FROM (
	   SELECT 
		  j.Job_ID
		  , j.name
		  , s.step_id
		  , CAST(NULL AS UNIQUEIDENTIFIER) JobParent
		  , ISNULL(p.SupportLevel, 99) SupportLevel
		  , ISNULL(sl.SupportDescription, 'Unsupported') SupportDescription
		  , command
		  , CHARINDEX('''', command, CHARINDEX('sp_start_job', command))+1 Index1
		  , CHARINDEX('''', command, CHARINDEX('''', command, CHARINDEX('sp_start_job', command))+1) Index2
	   FROM msdb..sysjobsteps s
	   JOIN msdb..sysjobs j    
		  ON j.job_id = s.job_id 
	   LEFT join warehouse.prototype.OnCall_Processes p 
		  ON p.Job_ID = j.job_id
	   LEFT join warehouse.prototype.OnCall_SupportLevel sl 
		  ON sl.SupportLevel = p.SupportLevel
	   WHERE command like '%exec %start_job%'
    ) x

    --SELECT * FROM #JobParent

    ---------------------------------------------------------------------------
    -- Get the Job_ID for all the children jobs
    ---------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#JobCalls') IS NOT NULL DROP TABLE #JobCalls
    SELECT
	   c.Name 
	   , c.job_id
	   , c.childJob
	   , j.job_id childJob_ID
	   , c.step_id
	   , c.SupportLevel
	   , SupportDescription
    INTO #JobCalls
    FROM #JobParent c
    JOIN msdb..sysjobs j
	   ON j.name = c.childJob

    ---------------------------------------------------------------------------
    -- Remove Parents that also have a parent
    ---------------------------------------------------------------------------
    DELETE j 
    FROM #JobParent j
    JOIN #JobCalls c 
	   ON c.childJob_Id = j.Job_ID

    --SELECT * FROM #JobParent

    ---------------------------------------------------------------------------
    -- Build Hierarchy
    ---------------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
    ;WITH JobHierarchy
    AS
    (
	   SELECT DISTINCT
		  Job_ID
		  , CAST(Name AS VARCHAR(100)) Name
		  , JobParent
		  , CAST(NULL AS VARCHAR(100)) JobParentName
		  , CAST(NULL AS INT) Step
		  , 1 AS Lvl
		  , SupportLevel
		  , SupportDescription
		  , Job_ID TopParent
	   FROM #JobParent

	   UNION ALL

	   SELECT 
		  childJob_ID
		  , CAST(childJob AS VARCHAR(100))
		  , jc.job_id
		  , CAST(jc.Name AS VARCHAR(100))
		  , step_id
		  , Lvl + 1
		  , jc.SupportLevel
		  , jc.SupportDescription
		  , TopParent
	   FROM #JobCalls jc
	   JOIN JobHierarchy jh
		  ON jc.job_id = jh.Job_id	
    )
    SELECT 
	   CAST(Job_ID AS VARCHAR(50)) Job_ID
	   , Name
	   , CAST(JobParent AS VARCHAR(50)) JobParent
	   , JobParentName
	   , Step
	   , ISNULL(SupportLevel, 99) SupportLevel
	   , ISNULL(SupportDescription, 'Unsupported') SupportDescription
	   , Lvl AS Level
	   , TopParent
    INTO #Results
    FROM JobHierarchy
    ORDER BY level, step

    ---------------------------------------------------------------------------
    -- Build Report Table
    ---------------------------------------------------------------------------
    SELECT 
	   x.*
	   , LAG(JobRank, 1) OVER (ORDER BY JobRank) PrevJobRank -- get previous job rank to determine when a new parent group has started
    FROM 
    (
	   SELECT
		  CONCAT(Job_ID, ROW_NUMBER() OVER (PARTITION BY Job_ID ORDER BY Level)) Job_ID -- Add row number to end of GUID to differentiate mutliple rows
		  , Name
		  , NULLIF(CONCAT(JobParent, ROW_NUMBER() OVER (PARTITION BY ISNULL(JobParent, Name), Job_ID, Level ORDER BY Level)),'1') JobParent -- Similarly, Add row number to JobParent so that the Parent has something to linkt o
		  , JobParentName
		  , Step
		  , SupportLevel
		  , SupportDescription
		  , Level
		  , CAST(TopParent AS VARCHAR(100)) TopParent -- defines the parent for an entire hierarchy, for querying and report colour management to identify when a new hiearchy has started
		  , CASE WHEN JobParent IS NULL THEN ROW_NUMBER() OVER (PARTITION BY JobParent ORDER BY Name) END JobRank -- Rank each parent
	   FROM #Results r
    ) x
    ORDER BY Level

END