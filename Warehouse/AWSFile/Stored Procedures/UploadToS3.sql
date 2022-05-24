CREATE PROCEDURE AWSFile.[UploadToS3]
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED --  
	DECLARE
		@rootLocation VARCHAR(max) = '"C:\Users\haydenr\Documents\LoadToS3\stream-to-s3\#ADD#"'
		, @configFolder VARCHAR(max) = 'testLoad\'

	DECLARE @sql varchar(max)
		, @scriptDirectory VARCHAR(500) = REPLACE(@rootLocation, '#ADD#', @configFolder + 'scripts')
		, @scriptConfig VARCHAR(500) = REPLACE(@rootLocation, '#ADD#', @configFolder + 'config.json')
		, @region varchar(500) = '--region "eu-west-2"'
		, @profile varchar(500) = '--profile "trusted-rwrd-data-engineer-etl-user-066"'
		, @seperator varchar(500) = '--sep "|"'
		, @quotecolumns varchar(500) = '--quotecols'
		, @naming varchar(500) = '--naming "REW_{SERVERNAME}_{FILENAME}_{DATE}"'
		, @extension varchar(500) = '--ext "txt"'
		, @addcolumnnames varchar(500) = '--addcolumnnames'
		, @cloudtypeformat varchar(500) = '--cloudtypeformat'
		, @local varchar(500) = '--local'
		, @awslogs varchar(500) = '--awslogs'
		, @donefile varchar(500) = '--donefile'
		, @noincremental varchar(500) = '--noincremental'
		, @creds varchar(500) = '--creds ' + REPLACE(@rootLocation, '#ADD#', @configFolder + 'creds.creds')
	
	SELECT @SQL = stuff(cmd, 1, 1, '') 
	FROM 
	(
		SELECT 
			' ' + cmdpart
		FROM (
			VALUES
				(1, REPLACE(@rootLocation, '#ADD#', 'stream-to-s3.exe'))
				, (2, @scriptDirectory)
				, (3, @scriptConfig)
				, (4, @region)
				, (4, @profile)
				, (4, @seperator)
				, (4, @naming)
				, (4, @extension)
				, (4, @awslogs)
				, (4, @creds)
			) x (id, cmdpart)
			ORDER BY ID
		FOR XML PATH('')
	) z(cmd)

	IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output; CREATE TABLE #output (line varchar(max))
	INSERT #output EXEC xp_cmdshell @sql

	DECLARE @RunID INT
	SELECT @RunID = NEXT VALUE FOR AWSFile.UploadToS3_RunID

	DECLARE @isError BIT
	SELECT @isError = CAST(COALESCE(MAX(1), 0) AS BIT)
	FROM #output
	WHERE line like '%Traceback%'
		OR line like '%Error%'

	INSERT INTO AWSFile.UploadToS3_Log (Msg, isError, CreatedDateTime, RunID)
	SELECT 
		o.line
		, @isError
		, GETDATE()
		, @RunID
	FROM #output o

END