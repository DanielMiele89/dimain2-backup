/*
Author:		Suraj Chahal
Date:		11 March 2013
Purpose:	To keep a record of deactivated customers at a specific point in time
Reason:		Emails have been sent to deactivated customers in the past and we have no cureent field that records 
		any kind of deactivation date 
Update:		This version is being amended for use as a stored procedure and to be ultimately automated.
*/
CREATE PROCEDURE [WHB].[Customer_Deactivations_V1_2]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'DeactivatedCustomers',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'
	-------------------------------------------------------------------------------------------------------------------
	/*	This finds all records that were launched to that have since been deactivated (Fan.Status=0) and are 
		not in the Control group (ReportBaseMay2012.IsControl=0). The resulting records have several key 
		fields written to a Staging table in the datamart.
	*/
	Insert Into Staging.DeactivatedCustomers
	select	f.ID					as FanID,
		f.[Status]				as [Status],
		f.AgreedTCs				as AgreedTCs,
		f.AgreedTCsDate				as AgreedTCsDate,
		Dateadd(day,-1,Convert(Date,GetDate())) as DataDate,	--This is the date the data was last loaded
		Convert(Date,GetDate())			as LoadedDate	--This is the date the data was copied to this new table
	--Into datamart.Staging.DeactivatedCustomers			--Used to originally create table
	from  slc_report.dbo.Fan f
		  inner join Relational.ReportBaseMay2012 rb on f.ID = rb.FanID
	where	f.status = 0				---This indicates record deactivated
		  and rb.IsControl = 0			---Not part of the control group
      
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'DeactivatedCustomers' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Staging.DeactivatedCustomers WHERE LoadedDate = CAST(GETDATE() AS DATE))
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'DeactivatedCustomers' and
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