
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Keep a record of when a customer has changed the email address they have linked to their account
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Customer_EmailChange] @RunDate DATE = NULL

AS
BEGIN

	SET @RunDate = COALESCE(@RunDate, GETDATE())

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);
	DECLARE @msg VARCHAR(200), @RowsAffected INT;


	EXEC [Monitor].[ProcessLog_Insert] 'Customer_EmailChange', 'Started'

	BEGIN TRY

		/*******************************************************************************************************************************************
			1. This pulls through the address data for anyone that has had their email changed since last run
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#EmailAddressChanges') IS NOT NULL DROP TABLE #EmailAddressChanges
			SELECT	cus.FanID
				,	cup.Email
			INTO #EmailAddressChanges
			FROM [WHB].[Customer] cus
			INNER JOIN [Derived].[Customer] cud
				ON cus.FanID = cud.FanID
			INNER JOIN [Derived].[Customer_PII] cup
				ON cus.FanID = cup.FanID
			WHERE COALESCE(cus.Email, '') != COALESCE(cup.Email, '')

		/*******************************************************************************************************************************************
			2. Insert this data to permanent table
		*******************************************************************************************************************************************/

			--DECLARE @RunDate DATE = GETDATE()

			INSERT INTO [Derived].[Customer_EmailAddressChanges] (	FanID
																,	Email
																,	DateChanged)

			SELECT FanID
				 , CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', Email), 2)
				 , @RunDate
			FROM #EmailAddressChanges eac
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_EmailAddressChanges] ceac
								WHERE eac.FanID = ceac.FanID
								AND ceac.DateChanged = @RunDate)
	
			EXEC [Monitor].[ProcessLog_Insert] 'Customer_EmailChange', 'Finished'

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
			INSERT INTO [Monitor].[ErrorLog] (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
			VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
			SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
			RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
			RETURN -1;

	END CATCH

	RETURN 0; -- should never run

END