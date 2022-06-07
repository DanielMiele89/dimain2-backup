
CREATE PROCEDURE [dbo].[CongestionChecker]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output;
SELECT *
INTO #Output
FROM (
	SELECT
		sp.spid AS session_id,
		sp.ecid,
		CASE sp.status
			WHEN 'sleeping' THEN sp.last_batch
			ELSE COALESCE(req.start_time, sp.last_batch)
		END AS start_time,
		sp.dbid,
		[DatabaseName] = db_name(sp.dbid), 
		[LoginName] = sp.loginame, 
		[HostName] = sp.hostname, 
		[ProgramName] = sp.program_name
	FROM sys.sysprocesses AS sp
	OUTER APPLY (
		SELECT TOP(1)
			CASE
				WHEN 
				(
					sp.hostprocess > ''
					OR r.total_elapsed_time < 0
				) THEN
					r.start_time
				ELSE
					DATEADD
					(
						ms, 
						1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())), 
						DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
					)
			END AS start_time
		FROM sys.dm_exec_requests AS r
		WHERE r.session_id = sp.spid
			AND r.request_id = sp.request_id
	) AS req
	WHERE sp.spid > 50
) d


DECLARE @REPLSpidCount INT, @PRTGSpidCount INT, @TotalSpidCount INT

SELECT 
	@REPLSpidCount = SUM(CASE WHEN LoginName = 'SLCReplication' THEN 1 ELSE 0 END),
	@PRTGSpidCount = SUM(CASE WHEN LoginName = 'PRTGBuddy' THEN 1 ELSE 0 END),
	@TotalSpidCount = COUNT(DISTINCT session_id)
FROM #Output


--IF (@REPLSpidCount > 28 or @PRTGSpidCount > 20) BEGIN
IF (@REPLSpidCount > 28 OR @PRTGSpidCount > 10 OR @TotalSpidCount > 180) BEGIN
	DECLARE 
		@EmailSubject NVARCHAR(255) = '[' + @@SERVERNAME + '] Congestion warning',
		@body_xml_text VARCHAR(MAX) = '<h3>DIMAIN appears to be i/o congested. Please check this list to confirm, then notify revelant people immediately.</h3>'

	SET @body_xml_text = @body_xml_text + '<p></p><p></p>'
	SET @body_xml_text = @body_xml_text + 'Typical indicators of i/o congestion are multiple entries in this list for both PRTG and Replication processes.'
	SET @body_xml_text = @body_xml_text + '<p></p><p></p>'

	SET @body_xml_text = @body_xml_text + 
		'<table border="1">
			<tr>
				<th>session_id</th>
				<th>ecid</th>
				<th>start_time</th>
				<th>dbid</th>
				<th>DatabaseName</th>
				<th>LoginName</th>
				<th>HostName</th>
				<th>ProgramName</th>
			</tr>
		'
		+
		convert(varchar(max),
			(
				SELECT 
					session_id AS 'td','',
					ecid AS 'td','',
					start_time AS 'td','',
					dbid AS 'td','',
					DatabaseName AS 'td','',
					LoginName AS 'td','',
					HostName AS 'td','',
					ProgramName AS 'td',''
				FROM #Output 
				ORDER BY session_id, ecid
				FOR XML PATH('tr')
			)
		)
		+
		'</table>'

	--add a paragraph break
	SET @body_xml_text = @body_xml_text + '<p></p><p></p>'

	if len(@body_xml_text) > 0
		exec msdb..sp_send_dbmail 
			@profile_name = 'Administrator', 
			@recipients = 'SysAdmin@rewardinsight.com; devdb@rewardinsight.com; tony.phipps@rewardinsight.com; Zoe.Taylor@rewardinsight.com; Rory.Francis@rewardinsight.com; lobbymuncher@hotmail.com',
			--@recipients = 'christopher.morris@rewardinsight.com',
			@subject = @EmailSubject,
			@body = @body_xml_text,
			@body_format = 'HTML', 
			@importance = 'HIGH', 
			@exclude_query_output = 1

END



RETURN 0




				