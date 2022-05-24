/*
		
		Author:		Stuart Barnley

		Date:		07th June 2016

		Purpose:	To stop new registrants from being deemed emailable when
					they are not


*/
CREATE Procedure [Staging].[WarehouseLoad_Customer_SmartFocusUnsubscribes_Part2]
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	------------------Find customers Marked as ContactByPost using modern website-----------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#CustomersUnsubs') is not null drop table #CustomersUnsubs
	Select FanID
	Into #CustomersUnsubs
	From Relational.Customer as c
	inner join SLC_Report..Fan as f
		on c.FanID = f.ID
	Where	ActivatedDate >= '2016-06-01' and
			MarketableByEmail = 1 and
			f.ContactByPost = 1
	/*--------------------------------------------------------------------------------------------------
	-------------------------------Mark customers as not MarketableByEmail------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update Relational.Customer
	Set MarketableByEmail = 0
	Where FanID in (Select fanID from #CustomersUnsubs)


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