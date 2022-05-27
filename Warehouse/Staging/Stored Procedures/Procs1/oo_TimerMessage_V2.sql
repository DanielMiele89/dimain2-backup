-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE PROCEDURE [Staging].[oo_TimerMessage_V2](@msg nvarchar(max),@time1 datetime output)
AS
BEGIN
	-- If not an interactive SSMS query, then don't bother with any output...
	if (select PROGRAM_NAME from master.dbo.sysprocesses where spid=@@spid)!='Microsoft SQL Server Management Studio - Query'
		return

	if @time1 is null
		set @msg=CONVERT(varchar,GETDATE(),127) + ' :  ' + @msg
	else

		SET @msg = CONVERT(varchar,GETDATE(),127) + ' :  ' + 'Time Taken (Seconds): ' + LEFT(cast(DATEDIFF(s,@time1,getdate()) as varchar) + '     ', 5) + ' >>>>>  ' + @msg

	raiserror(@msg,0,1) with nowait
	
	set @time1=GETDATE()
END
