CREATE PROCEDURE [WHB].[LoginInfo_Load]
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED --  
	DECLARE @sql varchar(400)
	SET @sql = '"E:\DataOpsFunctions\useragent-parser\useragent-parser.exe"'

	IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output; CREATE TABLE #output (line varchar(255))
	INSERT #output EXEC xp_cmdshell @sql

	DECLARE @RunID INT
	SELECT @RunID = NEXT VALUE FOR WHB.LoginInfo_Log_RunID

	INSERT INTO WHB.LoginInfo_Log ([WHB].[LoginInfo_Log].[Msg], [WHB].[LoginInfo_Log].[isError], [WHB].[LoginInfo_Log].[CreatedDateTime], [WHB].[LoginInfo_Log].[RunID])
	SELECT 
		o.line
		, #output.[x].isError
		, GETDATE()
		, @RunID
	FROM #output o
	CROSS APPLY (
		SELECT CAST(COALESCE(MAX(1), 0) AS BIT)
		FROM #output
		WHERE #output.[line] like '%Traceback%'
	) x(isError)
END


