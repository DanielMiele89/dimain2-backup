
CREATE PROCEDURE [AWS].[S3Upload]
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	/**********************************************************************
	EXE PARAMETERS
	***********************************************************************/
	DECLARE 
		@scriptDirectory VARCHAR(200) = 'E:\DataOpsFunctions\streamer\visa\scripts'
		, @serverConfig VARCHAR(200) = 'E:\DataOpsFunctions\streamer\visa\config.json'
		, @credsLocation VARCHAR(200) = 'E:\DataOpsFunctions\streamer\visa\creds.creds' 
		, @region VARCHAR(100) = 'eu-west-2'
		, @profile VARCHAR(100) = 'trusted-rwd-engineer-etl-role-048'
		, @seperator VARCHAR(1) = '|'
		, @naming VARCHAR(100) = 'REW_{SERVERNAME}_{FILENAME}_{DATE}'
		, @extension VARCHAR(10) = 'txt'



	/**********************************************************************
	Run EXE and log results to table
	***********************************************************************/
	DECLARE @sql varchar(500)
	SET @sql = 'powershell.exe -Command "E:\DataOpsFunctions\streamer\stream-to-s3\stream-to-s3.exe"' + ' '
		+ CONCAT('\"', replace(@scriptDirectory, '"', ''), '\"') + ' '
		+ CONCAT('\"', replace(@serverConfig, '"', ''), '\"') + ' '
		+ CONCAT('--creds ','\"', replace(@credsLocation, '"', ''), '\"') + ' '
		+ CONCAT('--region ','\"', replace(@region, '"', ''), '\"') + ' '
		+ CONCAT('--profile ','\"', replace(@profile, '"', ''), '\"') + ' '
		+ CONCAT('--sep ','\"', replace(@seperator, '"', ''), '\"') + ' '
		+ CONCAT('--naming ','\"', replace(@naming, '"', ''), '\"') + ' '
		+ CONCAT('--ext ','\"', replace(@extension, '"', ''), '\"') + ' '
		+ '--addcolnames'

	IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output; CREATE TABLE #output (line varchar(max))
	INSERT #output EXEC xp_cmdshell @sql

	DECLARE @RunID INT
	SELECT @RunID = NEXT VALUE FOR AWS.S3Upload_RunID

	INSERT INTO AWS.S3Upload_Log (Msg, isError, RunID)
	SELECT 
		o.line
		, x.isError
		, @RunID
	FROM #output o
	CROSS APPLY (
		SELECT CAST(COALESCE(MAX(1), 0) AS BIT)
		FROM #output
		WHERE line like '%Traceback%'
			or line like '%ERROR:%'
	) x(isError)
END








   
