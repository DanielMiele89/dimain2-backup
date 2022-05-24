/*
	Author:			Stuart Barnley
	Date:			01/04/2014

	Description:	This procedure looks to see who has registered their online account

	Note:			This is something that has come up due to One-click and we are putting
					in place ready for reporting requests
*/
CREATE PROCEDURE [WHB].[Customer_Registrations]
as 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'Customer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'U'



	------------------------------------------------------------------------
	------------------Pull off list of Registrations------------------------
	------------------------------------------------------------------------
	/*This relates to confirming details on website rather than activation*/
	select	fc.FanID
	Into #Reg
	from SLC_Report..FanCredentials as fc with (nolock)
	inner join Relational.Customer as c with (nolock)
		on fc.FanID = c.FanID
	Where	HashedPassword is not null and 
			HashedPassword <> ''
	------------------------------------------------------------------------
	------------------Create Index for temporary table----------------------
	------------------------------------------------------------------------
	create clustered index ixc_FanID on #Reg(FanID)

	------------------------------------------------------------------------
	----------------Update Registered field in Customer Table---------------
	------------------------------------------------------------------------
	--Field set to 0 initially this overwrites with correct value

	Update relational.customer
	Set Registered = 1
	From relational.customer as c
	Inner join  #Reg as r
		on c.fanid = r.FanID



	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = ((Select COUNT(1) from Warehouse.Relational.Customer))
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
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