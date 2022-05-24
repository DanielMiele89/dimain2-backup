
CREATE PROCEDURE AWS.S3Upload
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED --  
	DECLARE @sql varchar(max)
	SET @sql = '^
		"C:\Python Functions\streamer\stream-to-s3\stream-to-s3.exe" ^
		"C:\Python Functions\streamer\virgin\scripts" ^
		"C:\Python Functions\streamer\virgin\config.json" ^
		--creds "C:\Python Functions\streamer\virgin\creds.creds" ^
		--region eu-west-2 ^
		--profile trusted-rwd-engineer-etl-role-048 ^
		--sep "|" ^
		--cloudtypeformat ^
		--naming "REW_{SERVERNAME}_{FILENAME}_{DATE}" ^
		--ext "txt"'

	IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output; CREATE TABLE #output (line varchar(max))
	INSERT #output EXEC xp_cmdshell @sql

	DECLARE @RunID INT
	SELECT @RunID = NEXT VALUE FOR AWS.S3Upload_RunID

	INSERT INTO AWS.S3Upload_Log ([AWS].[S3Upload_Log].[Msg], [AWS].[S3Upload_Log].[isError], [AWS].[S3Upload_Log].[RunID])
	SELECT 
		o.line
		, #output.[x].isError
		, @RunID
	FROM #output o
	CROSS APPLY (
		SELECT CAST(COALESCE(MAX(1), 0) AS BIT)
		FROM #output
		WHERE #output.[line] like '%Traceback%'
			or #output.[line] like '%ERROR:%'
	) x(isError)
END




