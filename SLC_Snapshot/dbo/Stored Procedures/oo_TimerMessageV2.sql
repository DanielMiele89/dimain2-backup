﻿-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE PROCEDURE [dbo].[oo_TimerMessageV2](
	@msg varchar(8000),
	@time1 datetime output,
	@SSMS BIT OUTPUT
	)
AS
BEGIN

	-- Decide what to do
	IF @SSMS = 0 RETURN -- not an interactive SSMS query

	IF @SSMS IS NULL -- First time in
	BEGIN

		-- If not an interactive SSMS query, then don't bother with any output...
		IF (select PROGRAM_NAME from master.dbo.sysprocesses where spid=@@spid) <> 'Microsoft SQL Server Management Studio - Query'
		BEGIN	
			SET @SSMS = 0
			RETURN
		END
		ELSE
			SET @SSMS = 1
	END

	IF @SSMS = 1
	BEGIN
		if @time1 is null
			set @msg=CONVERT(varchar,GETDATE(),127) + ' :  ' + @msg
		else
			set @msg=CONVERT(varchar,GETDATE(),127) + ' :  ' + @msg + '  >>>>>  Time Taken: ' + cast(DATEDIFF(s,@time1,getdate()) as varchar) + ' secs'
		
		raiserror(@msg,0,1) with nowait
	
		set @time1 = GETDATE()
	END
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[oo_TimerMessageV2] TO [Analyst]
    AS [dbo];
