/*
	Author:		Stuart Barnley
	
	Date:		21st December 2016

	Purpose:	Make sure deceased customers are no longer marked as Currently Actvie
		
	Update:		N/A


*/

CREATE PROCEDURE [Staging].[WarehouseLoad_Deactivate_Deceased_Customers]
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
	Select	StoredProcedureName = 'WarehouseLoad_Deactivate_Deceased_Customers',
			TableSchemaName = 'Relational',
			TableName = 'Customer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'

	/*--------------------------------------------------------------------------------------------------
	-------------------------Pull a list of deceased customers with status = 1--------------------------
	----------------------------------------------------------------------------------------------------*/

	if object_id('tempdb..#Deceased') is not null drop table #Deceased
	Select	f.ID as FanID,
			f.DeceasedDate
	Into #Deceased
	From slc_report.dbo.fan as f with (nolock)
	Where DeceasedDate is not null and
			ClubID in (132,138) and
			Status = 1

	Create Clustered index i_Deceased_FanID on #Deceased (FanID)

	/*--------------------------------------------------------------------------------------------------
	-------------------------Pull a list of deceased customers with status = 1--------------------------
	----------------------------------------------------------------------------------------------------*/
	Declare @RowCount int

	Update c
	Set	CurrentlyActive = 0,
		DeactivatedDate = (Case	
								When DeceasedDate <= ActivatedDate then Dateadd(day,1,ActivatedDate)
								Else DeceasedDate
							End)
	From Relational.Customer as c with (nolock)
	inner join #Deceased as d
		on c.FanID = d.FanID
	Where CurrentlyActive = 1
	SET @RowCount = @@ROWCOUNT
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_Deactivate_Deceased_Customers' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = @RowCount
	where	StoredProcedureName = 'WarehouseLoad_Deactivate_Deceased_Customers' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			TableRowCount is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/

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

End