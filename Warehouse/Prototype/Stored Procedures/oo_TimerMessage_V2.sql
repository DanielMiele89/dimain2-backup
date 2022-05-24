-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE PROCEDURE [Prototype].[oo_TimerMessage_V2] (@msg nvarchar(4000), @RowsAffected INT, @time1 datetime output)
AS
BEGIN
	-- If not an interactive SSMS query, then don't bother with any output...
	IF (SELECT PROGRAM_NAME FROM master.dbo.sysprocesses WHERE spid = @@spid) != 'Microsoft SQL Server Management Studio - Query'
		RETURN

	IF @time1 is null
		SET @msg = CONVERT(VARCHAR,GETDATE(),127) + ' :  ' + @msg
	ELSE
		SET @msg = CONVERT(VARCHAR,GETDATE(),127) + ' :  ' 
			+ LEFT(@msg + ' ' + REPLICATE('.',65),65) 
			+ '  ' + RIGHT(REPLICATE(' ',12) + CAST(ISNULL(FORMAT(@RowsAffected, '###,###,###,###'),'') AS VARCHAR(12)),12) 
			+ ' / ' + CAST(CAST(GETDATE() - @time1 AS TIME(0)) AS VARCHAR(8))
		
	RAISERROR(@msg,0,1) WITH NOWAIT
	
	SET @time1=GETDATE()
END

RETURN 0

