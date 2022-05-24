﻿-- =============================================
-- Author:		Nirupam / Chris Morris
-- Create date: 2015?
-- Description:	Query timer
-- EXEC dbo.oo_TimerMessageV2 'Start process [WarehouseLoad_ETLBuild_V1_4]', @time OUTPUT, @SSMS OUTPUT
-- =============================================
create PROCEDURE [dbo].[oo_TimerMessageV2](
	@msg varchar(8000),
	@time1 datetime output,
	@SSMS BIT OUTPUT
	)
AS
BEGIN

	-- Decide what to do
	IF @SSMS = 0 RETURN -- not an interactive SSMS query

	IF @SSMS IS NULL BEGIN -- First time in

		-- If not an interactive SSMS query, then don't bother with any output...
		IF (select PROGRAM_NAME from master.dbo.sysprocesses where spid=@@spid) <> 'Microsoft SQL Server Management Studio - Query'
		BEGIN	
			SET @SSMS = 0
		END
		ELSE
			SET @SSMS = 1
	END

	IF @SSMS = 1
	BEGIN
		if @time1 is null
			set @msg = CONVERT(varchar,GETDATE(),127) + ' :  ' + @msg
		else
			set @msg = CONVERT(varchar,GETDATE(),127) + ': ' + CAST(CAST(GETDATE() - @time1 AS TIME(0)) AS VARCHAR(8)) + ' :  ' + @msg 
		
		raiserror(@msg,0,1) with nowait
	
		set @time1 = GETDATE()
	END

	IF @SSMS = 0
	BEGIN
		RETURN
	END
END
RETURN
