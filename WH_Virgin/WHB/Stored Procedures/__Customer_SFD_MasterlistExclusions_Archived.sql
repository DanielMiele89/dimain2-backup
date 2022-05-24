
/*

*/
CREATE PROCEDURE [WHB].[__Customer_SFD_MasterlistExclusions_Archived] 

AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);
DECLARE @msg VARCHAR(200), @RowsAffected INT;


EXEC [Monitor].[ProcessLog_Insert] 'Customer_SFD_MasterlistExclusions', 'Started'

BEGIN TRY

/*******************************************************************************************************************************************
	1. To provide to the DBAs a list of customers that are not deemed marketable by email
*******************************************************************************************************************************************/

	TRUNCATE TABLE [Email].[SFD_NonMasterListCustomers]
	INSERT INTO [Email].[SFD_NonMasterListCustomers]
	SELECT	[Staging].[Customer].[FanID]
	FROM [Staging].[Customer] c
	WHERE c.MarketableByEmail = 0
	AND c.CurrentlyActive = 1
	AND c.EmailStructureValid = 1

	-- log it
	SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to SLC_report_DailyLoad_NonMasterListCustomers [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
	EXEC Monitor.ProcessLog_Insert 'Customer_SFD_MasterlistExclusions', @msg

	EXEC [Monitor].[ProcessLog_Insert] 'Customer_SFD_MasterlistExclusions', 'Finished'

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
	INSERT INTO Staging.ErrorLog ([Staging].[ErrorLog].[ErrorDate], [Staging].[ErrorLog].[ProcedureName], [Staging].[ErrorLog].[ErrorLine], [Staging].[ErrorLog].[ErrorMessage], [Staging].[ErrorLog].[ErrorNumber], [Staging].[ErrorLog].[ErrorSeverity], [Staging].[ErrorLog].[ErrorState])
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run