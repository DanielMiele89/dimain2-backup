/*
If @SSMS is NULL, see if we're running from within SSMS and assign 1 if we are, or 0 if not.
If @SSMS = 0, we're running programmatically so log to table
If @SSMS = 1, we're running from SSMS, so log to screen
If @SSMS = 2 then log to table & screen 
*/
CREATE PROCEDURE [Monitor].[ProcessLogger] 
	(
		@ProcessName VARCHAR(50),
		@Activity VARCHAR(200),
		@iTime DATETIME OUTPUT,
		@SSMS BIT OUTPUT
	)
AS

--BEGIN
	DECLARE @msg VARCHAR(8000)

	IF @SSMS IS NULL -- First time in, is this program called from SSMS?
	BEGIN
		IF 'Microsoft SQL Server Management Studio - Query' = (SELECT PROGRAM_NAME FROM master.dbo.sysprocesses WHERE spid = @@spid) 
		BEGIN	
			SET @SSMS = 1
		END
		ELSE
			SET @SSMS = 0
	END

	IF @SSMS IN (0,2) BEGIN
		INSERT INTO monitor.ProcessLog (ProcessName, ActionName)
		VALUES (@ProcessName, @Activity)
	END
	
	IF @SSMS IN (1,2) BEGIN
		IF @iTime is null
			SET @msg = CONVERT(varchar,GETDATE(),127) + ' :  ' + @ProcessName + ' - ' + @Activity
		ELSE
			SET @msg = CONVERT(varchar,GETDATE(),127) + ' :  ' + @ProcessName + ' - ' + @Activity + '  >>>>>  Time Taken: ' + cast(DATEDIFF(s,@iTime,getdate()) as varchar) + ' secs'
		
		RAISERROR(@msg,0,1) WITH NOWAIT
	
	END

	SET @iTime = GETDATE()

--END

RETURN 0

