--Use Warehouse
CREATE PROCEDURE [WHB].[Customer_DuplicateSourceUID_V1_2]
As
Begin

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
			TableName = 'Customer_DuplicateSourceUID',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'

	/*--------------------------------------------------------------------------------------------------
	----------------------------------Find duplicate SourceUIDs-----------------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#DuplicateSourceUID') is not null drop table #DuplicateSourceUID
	select Distinct SourceUID 
	Into #DuplicateSourceUID
	from Relational.Customer as c
	Group by SourceUID
	Having Count(*) > 1
	/*--------------------------------------------------------------------------------------------------
	------------------Re-Populate Staging.Customer_DuplicateSourceUID Table with latest list------------
	----------------------------------------------------------------------------------------------------*/
	Insert Staging.Customer_DuplicateSourceUID
	Select	d.SourceUID,
			Cast(getdate() as date) as StartDate,
			Cast(Null as Date) as EndDate
	from #DuplicateSourceUID as d
	left Outer join Staging.Customer_DuplicateSourceUID as c
		on d.SourceUID = c.SourceUID
	Where	c.SourceUID is Null and 
			c.enddate is null
	/*--------------------------------------------------------------------------------------------------
	------------------------------Add EndDates when a soruceUID is resolved-----------------------------
	----------------------------------------------------------------------------------------------------*/
	Update Staging.Customer_DuplicateSourceUID
	Set EndDate = dateadd(day,-1,Cast(getdate() as date))
	from Staging.Customer_DuplicateSourceUID as c
	Left Outer Join #DuplicateSourceUID as d
		on c.SourceUID = d.SourceUID
	Where	d.SourceUID is null and
			c.EndDate is null

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'Customer_DuplicateSourceUID' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select Count(Distinct SourceUID) from Staging.Customer_DuplicateSourceUID)
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'Customer_DuplicateSourceUID' and
			TableRowCount is null

	/*--------------------------------------------------------------------------------------------------
	------------------------------------------Add entry in JobLog Table --------------------------------
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
	/*--------------------------------------------------------------------------------------------------
	------------------------------------------Truncate JobLog temporary Table --------------------------
	----------------------------------------------------------------------------------------------------*/
	Truncate Table staging.JobLog_Temp

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