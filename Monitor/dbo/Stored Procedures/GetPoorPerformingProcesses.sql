/****** Script for SelectTopNRows command from SSMS  ******/


CREATE PROCEDURE [dbo].[GetPoorPerformingProcesses] AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT TOP(500) 
	d.*, Duration = CAST(QueryFinish - d.start_time AS time(0)), sp.sql_command, sp.sql_text, sp.query_plan
FROM (
	SELECT 
		session_id, [host_name], [program_name], login_name, x.start_time, [QueryFinish] = MAX(collection_time)
	FROM [Warehouse].[Relational].[SP_WhoIsActive] s
	CROSS APPLY (SELECT start_time = CASE WHEN start_time IS NULL OR start_time > collection_time THEN DATEADD(SECOND,0-DATEDIFF(SECOND,'00:00:00.000',RIGHT([dd hh:mm:ss.mss],12)),collection_time) ELSE start_time END) x
	WHERE session_id > 25 
		AND login_name NOT IN ('SLCReplication','PRTGBuddy') 
		AND [program_name] NOT LIKE 'DatabaseMail - DatabaseMail%' AND program_name <> 'Report Server' 
	GROUP BY session_id, [host_name], [program_name], login_name, x.start_time
) d
INNER JOIN [Warehouse].[Relational].[SP_WhoIsActive] sp 
	ON sp.session_id = d.session_id
	AND sp.[host_name] = d.[host_name]
	AND sp.[program_name] = d.[program_name]
	AND sp.login_name = d.login_name
	AND sp.collection_time = d.[QueryFinish]
--ORDER BY CAST(QueryFinish - d.start_time AS time(0)) DESC

--WHERE CAST(sp.sql_command AS varchar(MAX)) LIKE '%BACKUP DATABASE %' AND CAST(sp.sql_command AS varchar(MAX)) LIKE '%Warehouse%'
ORDER BY d.start_time DESC

RETURN 0





		
