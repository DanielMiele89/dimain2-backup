-- *******************************************************************************
-- Author: Rory Francis
-- Create date: 19/11/2018
-- Description: Updates the Account Manager field on the Partner Table. 
-- Update:		
-- *******************************************************************************
CREATE Procedure [Staging].[WarehouseLoad_Partner_UpdateAccountManager]
		
As
Begin

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/***********************************************************************************************************************
		1.	Write entry to JobLog Temp Table
	***********************************************************************************************************************/

		Insert into Staging.JobLog_Temp
		Select StoredProcedureName = 'WarehouseLoad_Partner_UpdateAccountManager'
			 , TableSchemaName = 'Relational'
			 , TableName = 'Partner'
			 , StartDate = GETDATE()
			 , EndDate = Null
			 , TableRowCount  = Null
			 , AppendReload = 'U'
	

	/***********************************************************************************************************************
		2.	Fetch current list of account managers
	***********************************************************************************************************************/

		If Object_ID('tempdb..#PartnerAccountManager') Is Not Null Drop Table #PartnerAccountManager
		Select PartnerID
			 , AccountManager
		Into #PartnerAccountManager
		From Selections.PartnerAccountManager
		Where EndDate Is Null


	/***********************************************************************************************************************
		3.	Update the Relational.Partner table, setting AccountManager to Unassigned where no entry is found
	***********************************************************************************************************************/

		Update pa
		Set pa.AccountManager = Case
									When am.AccountManager Is Null Then 'Unassigned'
									Else am.AccountManager
								End
		From Relational.Partner pa
		Left join #PartnerAccountManager am
			on pa.PartnerID = am.PartnerID


	/***********************************************************************************************************************
		4.	Update entry to JobLog Temp Table
	***********************************************************************************************************************/

		/*******************************************************************************************************************
			4.1.	Update entry to JobLog Temp Table - Execution time
		*******************************************************************************************************************/

			Update Staging.JobLog_Temp
			Set EndDate = GetDate()
			Where StoredProcedureName = 'WarehouseLoad_Partner_UpdateAccountManager' 
			And TableSchemaName = 'Relational'
			And TableName = 'Partner' 
			And EndDate Is Null


		/*******************************************************************************************************************
			4.2.	Update entry to JobLog Temp Table - Row count
		*******************************************************************************************************************/

			Update Staging.JobLog_Temp
			Set TableRowCount = (Select Count(1) From Relational.Partner)
			Where StoredProcedureName = 'WarehouseLoad_Partner_UpdateAccountManager' 
			And TableSchemaName = 'Relational'
			And TableName = 'Partner' 
			And TableRowCount Is Null


	/***********************************************************************************************************************
		5.	Insert entry to JobLog Table
	***********************************************************************************************************************/

		Insert into Staging.JobLog
		Select StoredProcedureName
			 , TableSchemaName
			 , TableName
			 , StartDate
			 , EndDate
			 , TableRowCount
			 , AppendReload
		From Staging.JobLog_Temp

		Truncate Table Staging.JobLog_Temp

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