/*
Author:		Suraj Chahal
Date:		21 May 2013
Purpose:	To load all the new weblogins into the Weblogins table in the warehouse.
Reason:		This is not currently being pulled into the warehouse as the data still sits within SLC_Report.
		This job will be automated as part of the warehouse Build which will run on a daily basis.

Change Log:	Added clubId 138 to build
			
			20-02-2014 SB - Remove reference to warehouse

*/
CREATE PROCEDURE [WHB].[Customer_WebLogins_V1_1]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	DECLARE	@RowCount INT
	SET @RowCount = (SELECT COUNT(1) FROM Relational.WebLogins)

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'WebLogins',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'


	DELETE FROM Relational.WebLogins  
	WHERE trackdate > DATEADD(DAY,-2,CAST(GETDATE() AS DATE))
	--(166 row(s) affected)



	INSERT INTO Relational.WebLogins
	SELECT	fanid,
		trackdate,
		fandata
	FROM SLC_Report.dbo.Fan f 
	INNER JOIN SLC_Report.dbo.TrackingData td 
		ON td.fanid = f.ID
	WHERE	f.ClubID IN (132,138)
		AND fandata LIKE 'login ip=%'
		AND td.tracktypeid = 1
		AND trackdate > DATEADD(DAY,-2,CAST(GETDATE() AS DATE))
	--(166 row(s) affected)

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'WebLogins' and
			EndDate is null
		
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set	TableRowCount = (Select (COUNT(*)-@RowCount) from Relational.WebLogins)
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'WebLogins' and
			TableRowCount is null


	Insert into staging.JobLog
	select [StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
	from staging.JobLog_Temp

	TRUNCATE TABLE staging.JobLog_Temp

	RETURN 0; -- normal exit here

END TRY
BEGIN CATCH		
		
	-- Grab the error details
	SELECT  
		@ERROR_NUMBER = ERROR_NUMBER(), 
		@ERROR_SEVERITY = ERROR_SEVERITY(), 
		@ERROR_STATE = ERROR_STATE(), 
		@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
		@ERROR_LINE = ERROR_LINE(),   
		@ERROR_MESSAGE = ERROR_MESSAGE();
	SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
	-- Insert the error into the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END

