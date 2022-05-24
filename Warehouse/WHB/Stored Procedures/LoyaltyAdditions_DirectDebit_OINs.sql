/*
		Author:		Stuart Barnley

		Date:		15-05-2015

		Purpose:	This stored procedure has two purposes:

						1. To reload an updated relational table of the OINS we have assessed

						2. To reload an updated list of the OINs we want the live system to start receiving transactions for


*/
CREATE PROCEDURE [WHB].[LoyaltyAdditions_DirectDebit_OINs]
--with Execute as owner
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog_Temp Table---------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Truncate Table staging.JobLog_Temp

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'DirectDebit_OINs',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'


	/*--------------------------------------------------------------------------------------------------
	--------------------------------Prepare table for Reload--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	DROP INDEX Relational.DirectDebit_OINs.ix_DirectDebit_OINs_OIN

	Truncate Table Relational.DirectDebit_OINs
	/*--------------------------------------------------------------------------------------------------
	-------------------------------Insert UN-NORMALISED version of data---------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into Relational.DirectDebit_OINs
	Select	d.ID,
			d.OIN,
			d.Narrative,
			s.Status_Description,
			a.Reason_Description,
			AddedDate,
			i.Category1 as InternalCategory1,
			i.category2 as InternalCategory2,
			r.Category1 as RBSCategory1,
			r.Category2 as RBSCategory2,
			d.StartDate as StartDate,
			d.EndDate as EndDate,
			sup.SupplierID,
			sup.SupplierName
	--into Relational.DirectDebit_OINs
	From Staging.DirectDebit_OINs as d
	Inner join Staging.DirectDebit_Status as s
		on d.DirectDebit_StatusID = s.ID
	inner join Staging.DirectDebit_AssessmentReason as a
		on d.DirectDebit_AssessmentReasonID = a.ID
	Left Outer join Staging.DirectDebit_Categories_Internal as i
		on d.InternalCategoryID = i.id
	Left Outer join Staging.DirectDebit_Categories_RBS as r
		on d.RBSCategoryID = r.id
	Left Outer join Relational.DD_DataDictionary_Suppliers as sup
		on d.DirectDebit_SupplierID = sup.SupplierID

	/*--------------------------------------------------------------------------------------------------
	----------------------------------Reapply the index to tyhe table-----------------------------------
	----------------------------------------------------------------------------------------------------*/
	Create nonclustered index ix_DirectDebit_OINs_OIN on  Relational.DirectDebit_OINs (OIN)
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'DirectDebit_OINs' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog_Temp Table with Row Count-------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Relational.DirectDebit_OINs)
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'DirectDebit_OINs' and
			TableRowCount is null

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog_Temp Table---------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'DirectDebit_EligibleOINs',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'

	/*--------------------------------------------------------------------------------------------------
	--------------------------------Prepare table for Reload--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Truncate Table [Staging].[DirectDebit_EligibleOINs]
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into [Staging].[DirectDebit_EligibleOINs]
	Select	OIN,
			Case
				When RBSCategory1 = 'Household Bills' then 'Household'
				Else RBSCategory1
			end as RBSCategory1,
			RBSCategory2,
			SupplierName,
			StartDate
	from Relational.DirectDebit_OINs as r 
	Where [Status_Description] = 'Accepted by RBSG' and EndDate is NULL

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLogTemp Table with End Date---------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'DirectDebit_EligibleOINs' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog_Temp Table with Row Count--------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Staging.DirectDebit_EligibleOINs)
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'DirectDebit_EligibleOINs' and
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