CREATE PROCEDURE [dbo].[GetDatabaseSizes]

AS


;WITH DBSize AS (
    SELECT 
        [LogDate],
        [DatabaseName],
        [SizeGB] = CAST(CAST(REPLACE([Size], ' KB', '') AS bigINT)/(1024*1024.) AS DECIMAL(8,2)),
        [Usage]
    FROM [Monitor].[dbo].[DatabaseFileSizeHistory] 
    WHERE logdate >= '2019-01-01'
    AND [DatabaseName] NOT IN ('master', 'model', 'msdb', 'ReportServer', 'ReportServerTempDB', 'SSISDB')
)
SELECT 
    [LogDate],
    [Warehouse] = SUM(CASE WHEN DatabaseName = 'Warehouse' THEN SizeGB ELSE 0 END),
    [Archive_Light] = SUM(CASE WHEN DatabaseName = 'Archive_Light' THEN SizeGB ELSE 0 END),
    [Affinity] = SUM(CASE WHEN DatabaseName = 'Affinity' THEN SizeGB ELSE 0 END),
    [tempdb] = SUM(CASE WHEN DatabaseName = 'tempdb' THEN SizeGB ELSE 0 END),
    [SLC_REPL] = SUM(CASE WHEN DatabaseName = 'SLC_REPL' THEN SizeGB ELSE 0 END),
    [SLC_Snapshot] = SUM(CASE WHEN DatabaseName = 'SLC_Snapshot' THEN SizeGB ELSE 0 END),
    [Finance] = SUM(CASE WHEN DatabaseName = 'Finance' THEN SizeGB ELSE 0 END),
    [Sandbox] = SUM(CASE WHEN DatabaseName = 'Sandbox' THEN SizeGB ELSE 0 END),
    [nFI] = SUM(CASE WHEN DatabaseName = 'nFI' THEN SizeGB ELSE 0 END),
    [WH_Virgin] = SUM(CASE WHEN DatabaseName = 'WH_Virgin' THEN SizeGB ELSE 0 END), 
    [SLC_Report] = SUM(CASE WHEN DatabaseName = 'SLC_Report' THEN SizeGB ELSE 0 END),
    [APWDirectLoadHelper] = SUM(CASE WHEN DatabaseName = 'APWDirectLoadHelper' THEN SizeGB ELSE 0 END),
    [Outbound] = SUM(CASE WHEN DatabaseName = 'Outbound' THEN SizeGB ELSE 0 END),
    [SchemeWarehouse] = SUM(CASE WHEN DatabaseName = 'SchemeWarehouse' THEN SizeGB ELSE 0 END),
    [PapiMemberOffer] = SUM(CASE WHEN DatabaseName = 'PapiMemberOffer' THEN SizeGB ELSE 0 END),
    [WH_AllPublishers] = SUM(CASE WHEN DatabaseName = 'WH_AllPublishers' THEN SizeGB ELSE 0 END), 
    [Monitor] = SUM(CASE WHEN DatabaseName = 'Monitor' THEN SizeGB ELSE 0 END)
FROM DBSize
WHERE 1 = 1
    AND Usage = 'data only'
GROUP BY [LogDate], [Usage]
ORDER BY [LogDate] DESC

RETURN 0