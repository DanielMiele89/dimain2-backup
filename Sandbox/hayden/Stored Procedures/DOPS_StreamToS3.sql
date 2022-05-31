CREATE PROCEDURE Hayden.DOPS_StreamToS3
(
	@Directory VARCHAR(MAX)
	, @additionalParams VARCHAR(MAX) = ''
)
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED --  
	DECLARE @sql varchar(4000)

	IF CHARINDEX(':', @Directory) = 0
		SET @Directory = 'E:\DataOpsFunctions\s3-streaming\streams\' + @Directory

	SET @sql = '"E:\DataOpsFunctions\s3-streaming\stream-to-s3\stream-to-s3.exe"" ""' + @Directory + '"" "' + @additionalParams

	--set @sql = 'whoami'

	IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output; CREATE TABLE #output (line varchar(255))
	INSERT #output EXEC xp_cmdshell @sql

	--DECLARE @RunID INT
	--SELECT @RunID = NEXT VALUE FOR WHB.LoginInfo_Log_RunID

	IF OBJECT_ID('Hayden.Test') IS NOT NULL
		DROP TABLE Hayden.Test
	SELECT 
		o.line
		, x.isError
		, GETDATE() AS InsertedDate
		--, @RunID
	INTO Hayden.Test
	FROM #output o
	CROSS APPLY (
		SELECT CAST(COALESCE(MAX(1), 0) AS BIT)
		FROM #output
		WHERE line like '%Traceback%'
	) x(isError)
END



