-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE PROCEDURE [Prototype].[oo_TimerMessage](@msg nvarchar(4000),@time1 datetime output)
AS
BEGIN
	-- If not an interactive SSMS query, then don't bother with any output...
	if (select PROGRAM_NAME from master.dbo.sysprocesses where spid=@@spid)!='Microsoft SQL Server Management Studio - Query'
		return

	if @time1 is null
		set @msg=CONVERT(varchar,GETDATE(),127) + ' :  ' + @msg
	else
		set @msg=CONVERT(varchar,GETDATE(),127) + ' :  ' + LEFT(@msg+' '+REPLICATE('.',65),65) + ' Time Taken: ' + CAST(CAST(GETDATE() - @time1 AS TIME(0)) AS varchar(8))
		
	raiserror(@msg,0,1) with nowait
	
	set @time1=GETDATE()
END

RETURN 0