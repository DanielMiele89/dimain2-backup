CREATE procedure [dbo].[ActivityMonitor]
as

DECLARE @BeforeTime DATETIME, @AfterTime DATETIME

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT @BeforeTime = MAX([collection_time]) FROM [Monitor].[dbo].[WhoIsActive]

EXEC master.[dbo].[sp_WhoIsActive] @get_plans = 1, @destination_table = 'Monitor.dbo.WhoIsActive';

SELECT @AfterTime = MAX([collection_time]) FROM [Monitor].[dbo].[WhoIsActive]

IF DATEDIFF(MINUTE, @BeforeTime, @AfterTime) > 20 BEGIN

	SELECT 
		[collection_time],
		[dd hh:mm:ss.mss],
		[session_id],
		[sql_text] = CAST(LEFT(CAST([sql_text] AS VARCHAR(MAX)),200) AS VARCHAR(200)), -- XML
		[login_name],
		[host_name],
		[database_name],
		[wait_info],
		[CPU],
		[tempdb_allocations],
		[tempdb_current],
		[blocking_session_id],
		[reads],
		[writes],
		[physical_reads]
	INTO #WhoIsActive
	FROM [Monitor].[dbo].[WhoIsActive] WHERE [collection_time] = @AfterTime

	DECLARE 
		@EmailSubject NVARCHAR(255) = '[' + @@SERVERNAME + '] Congestion warning',
		@body_xml_text VARCHAR(MAX) = '<h3>DIMAIN2 appears to be i/o congested. Please check this list to confirm, then notify revelant people immediately.</h3>'

	SET @body_xml_text = @body_xml_text + '<p></p><p></p>'
	SET @body_xml_text = @body_xml_text + 'Typical indicators of i/o congestion are expensive processes in this list.'
	SET @body_xml_text = @body_xml_text + '<p></p><p></p>'

	SET @body_xml_text = @body_xml_text + 
		'<table border="1">
			<tr>
				<th>[collection_time]</th>
				<th>[dd hh:mm:ss.mss]</th>
				<th>[session_id]</th>
				<th>[sql_text]</th>
				<th>[login_name]</th>
				<th>[host_name]</th>
				<th>[database_name]</th>
				<th>[wait_info]</th>
				<th>[CPU]</th>
				<th>[tempdb_allocations]</th>
				<th>[tempdb_current]</th>
				<th>[blocking_session_id]</th>
				<th>[reads]</th>
				<th>[writes]</th>
				<th>[physical_reads]</th>
			</tr>
		'
		+
		convert(varchar(max),
			(
				SELECT 
					[collection_time] AS 'td','',
					[dd hh:mm:ss.mss] AS 'td','',
					[session_id] AS 'td','',
					[sql_text] AS 'td','',
					[login_name] AS 'td','',
					[host_name] AS 'td','',
					[database_name] AS 'td','',
					[wait_info] AS 'td','',
					[CPU] AS 'td','',
					[tempdb_allocations] AS 'td','',
					[tempdb_current] AS 'td','',
					[blocking_session_id] AS 'td','',
					[reads] AS 'td','',
					[writes] AS 'td','',
					[physical_reads] AS 'td',''
				FROM #WhoIsActive 
				ORDER BY [dd hh:mm:ss.mss] desc
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