CREATE proc dbo.[testproc_OLD] 
as
begin
	  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @svrName varchar(255) = @@SERVERNAME, @sql varchar(400)
	--by default it will take the current server name, we can set the server name as well
	SET @sql = 'powershell.exe -c "echo $env:userprofile"'
	select @sql
	--inserting disk name, total space and free space value into temporary table
	TRUNCATE TABLE dbo.o
	INSERT dbo.o EXEC xp_cmdshell 'whoami.exe' 
end
----script to retrieve the values in GB from PS Script output
--SELECT *, [FreeSpace%] = 100*([freespace(GB)] / ([capacity(GB)]*1.0))
--FROM (
--    SELECT 
--        DriveName = LEFT(line,3),
--        [Capacity(GB)] = CAST(CAST(SUBSTRING(line,4,p-4) AS NUMERIC(10,2))/1024 AS INT),
--        [FreeSpace(GB)] = CAST(CAST(SUBSTRING(line,p+1,8000) AS NUMERIC(10,2))/1024 AS INT) 
--    FROM #output
--    CROSS APPLY (SELECT p = CHARINDEX('%',line)) x
--    WHERE line LIKE '[A-Z][:]%'
--) d
--ORDER BY drivename

--SELECT * FROM #Output