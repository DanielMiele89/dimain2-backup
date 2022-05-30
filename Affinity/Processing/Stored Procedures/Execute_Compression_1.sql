
CREATE PROCEDURE [Processing].[Execute_Compression]
(
	@SourceFile VARCHAR(MAX)
	, @DestFile VARCHAR(MAX)
	, @PackageID UNIQUEIDENTIFIER
)
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED --  
	DECLARE @sql varchar(4000)
	SET @sql = 'cd.. && "C:\Program Files\7-Zip\7z.exe" a "' + @DestFile + '" "' + @SourceFile + '"'

	IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output; CREATE TABLE #output (line varchar(MAX))
	INSERT #output EXEC xp_cmdshell @sql

	DECLARE @RunID INT
	SELECT
		@RunID = MAX(LatestRunID)
	FROM Processing.vw_PackageLog_LatestRunID
	WHERE PackageID = @PackageID

	DECLARE @ErrorString VARCHAR(100) = '%Traceback%'
	DECLARE @ErrorString2 VARCHAR(100) = '%Error%'
	DECLARE @ErrorString3 VARCHAR(100) = '%not recognized%'

	INSERT INTO Processing.ExecLog (Msg, isError, CreatedDateTime, RunID, ExecCommand)
	SELECT 
		o.line
		, x.isError
		, GETDATE()
		, @RunID
		, @sql
	FROM #output o
	CROSS APPLY (
		SELECT CAST(COALESCE(MAX(1), 0) AS BIT)
		FROM #output
		WHERE line like @ErrorString
			OR line like @ErrorString2
			OR line like @ErrorString3
	) x(isError)

	IF (SELECT TOP 1 1 FROM Processing.ExecLog WHERE RunID = @RunID AND isError = 1) IS NOT NULL
	BEGIN

		DECLARE @Error VARCHAR(MAX)

		SELECT
			@Error = STUFF((
					SELECT
						' ' + msg
					FROM Processing.ExecLog
					WHERE RunID = @RunID
						AND LogID >= (SELECT MIN(LogID) FROM Processing.ExecLog WHERE RunID = @RunID AND (msg like @ErrorString or msg like @ErrorString2 or msg like @ErrorString3))
					ORDER BY LogID
					FOR XML PATH ('')
				), 1, 1, '')
	
		DECLARE @ErrorEnd VARCHAR(300) = '... SELECT * FROM Processing.ExecLog WHERE RunID =' + CAST(@RunID AS varchar) + ' for more info'
		DECLARE @ErrorOutput VARCHAR(4096) = RIGHT(@Error, 1999 - LEN(@ErrorEnd)) + @ErrorEnd -- max is 2048 NVARCHAR
		RAISERROR(@ErrorOutput,15,-1, -1) 

	END



END
