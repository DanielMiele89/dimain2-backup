CREATE Procedure [Staging].[WarehouseLoad_Customer_EmailChange1]
AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_Customer_EmailChange1',
			TableSchemaName = 'Staging',
			TableName = 'Customer_EmailAddressChanges_20150101',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'

	Declare @RowCount int
	Set @RowCount = (Select Count(*) From staging.Customer_EmailAddressChanges_20150101)
	---------------------------------------------------------------------------------------------------
	---------------------------------------- Find New Changes -----------------------------------------
	---------------------------------------------------------------------------------------------------
	Insert Into staging.Customer_EmailAddressChanges_20150101
	Select f.ID as FanID
		 , f.Email
		 , Convert(Date, GetDate()) as DateChanged
	From SLC_Report.dbo.Fan as f
	inner join Relational.Customer as c
		on f.id = c.fanid
	Where f.Email != c.Email
	And f.Email Is Not Null
	And Len(f.Email) > 5

	/******************************************************************************
	****************Update entry in JobLog Table with End Date*********************
	******************************************************************************/
	UPDATE staging.JobLog_Temp
	SET EndDate = GETDATE()
	WHERE	StoredProcedureName = 'WarehouseLoad_Customer_EmailChange1' 
		AND TableSchemaName = 'Staging'
		AND TableName = 'Customer_EmailAddressChanges_20150101' 
		AND EndDate IS NULL

	/******************************************************************************
	*****************Update entry in JobLog Table with Row Count*******************
	******************************************************************************/
	--**Count run seperately as when table grows this as a task on its own may 
	--**take several minutes and we do not want it included in table creation times
	UPDATE Staging.JobLog_Temp
	SET TableRowCount = (SELECT COUNT(*) FROM staging.Customer_EmailAddressChanges_20150101)-@RowCount
	WHERE	StoredProcedureName = 'WarehouseLoad_Customer_EmailChange1'
		AND TableSchemaName = 'Staging'
		AND TableName = 'Customer_EmailAddressChanges_20150101' 
		AND TableRowCount IS NULL

	Insert into staging.JobLog
	select [StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
	from staging.JobLog_Temp
	truncate table staging.JobLog_Temp

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