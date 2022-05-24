/*

		Author:				Stuart Barnley
		
		Date:				12/06/2015
		
		Purpose:			This table creates the list of Suns from LIVE
*/
CREATE PROCEDURE [Staging].[WarehouseLoad_DirectDebitOriginator]
AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_DirectDebitOriginator',
			TableSchemaName = 'Relational',
			TableName = 'DirectDebitOriginator',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'
	/*--------------------------------------------------------------------------------------------------
	-----------------------------------Truncate OINs table----------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Truncate Table Relational.[DirectDebitOriginator]
	/*--------------------------------------------------------------------------------------------------
	-----------------------------------Populate OINs table----------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into Relational.[DirectDebitOriginator]

	select	do.ID,
			do.Oin,
			do.Name as SupplierName,
			c1.Name as Category1,
			Case
				When a.Oin is not null then 'Water'
				Else c2.Name
			End as Category2,
			do.StartDate,
			do.EndDate
	from SLC_Report.dbo.DirectDebitOriginator as do
	Left Outer join SLC_Report.dbo.DirectDebitCategory1 as c1
		on do.Category1ID = c1.ID
	Left Outer join SLC_Report.dbo.DirectDebitCategory2 as c2
		on do.Category2ID = c2.ID
	left outer join 
	(	Select Distinct OIN
		from	Relational.DirectDebit_OINs
		Where	InternalCategory2 = 'Utilities' and 
				RBSCategory2 = 'Local Authority and Water'
	) as a
		on do.OIN = a.oin

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_DirectDebitOriginator' and
			TableSchemaName = 'Relational' and
			TableName = 'DirectDebitOriginator' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) From Relational.[DirectDebitOriginator])
	where	StoredProcedureName = 'WarehouseLoad_DirectDebitOriginator' and
			TableSchemaName = 'Relational' and
			TableName = 'DirectDebitOriginator' and
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