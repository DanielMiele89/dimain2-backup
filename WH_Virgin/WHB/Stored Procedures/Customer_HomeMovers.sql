
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Keep a record of when a customer has changed the postcode they have linked to their account
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Customer_HomeMovers] @RunDate DATE = NULL

AS
BEGIN

	SET @RunDate = COALESCE(@RunDate, GETDATE())

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);
	
	DECLARE @StoredProcedureName VARCHAR(100) = OBJECT_NAME(@@PROCID)
		,	@msg VARCHAR(200)
		,	@RowsAffected INT
		,	@Query VARCHAR(MAX)

	EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Started'

	BEGIN TRY

		/*******************************************************************************************************************************************
			1. This pulls through the address data for anyone that has had their postcode changed since last run
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#HomeMovers') IS NOT NULL DROP TABLE #HomeMovers
			SELECT cus.FanID
				 , cus.Postcode AS NewPostCode
				 , cup.Postcode AS OldPostCode
			INTO #HomeMovers
			FROM [WHB].[Customer] cus
			INNER JOIN [Derived].[Customer] cud
				ON cus.FanID = cud.FanID
			INNER JOIN [Derived].[Customer_PII] cup
				ON cus.FanID = cup.FanID
			WHERE cus.CurrentlyActive = 1
			AND cud.CurrentlyActive = 1
			AND RIGHT(cus.Postcode, 3) != RIGHT(cup.Postcode, 3)
			AND LEN(cus.Postcode) > 4
			AND LEN(cup.Postcode) > 4

			CREATE CLUSTERED INDEX CIX_FanID ON #HomeMovers (FanID)

		/*******************************************************************************************************************************************
			2. Insert this data to permanent table
		*******************************************************************************************************************************************/
	
			INSERT INTO [Derived].[Customer_HomemoverDetails] (FanID
															 , OldPostCode
															 , NewPostCode
															 , LoadDate)

			SELECT	FanID
				,	OldPostCode = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', OldPostCode), 2)
				,	NewPostCode = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', NewPostCode), 2)
				,	@RunDate
			FROM #HomeMovers hm
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_HomemoverDetails] hd
								WHERE hm.FanID = hd.FanID
								AND hd.LoadDate = @RunDate)
	
			EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Finished'

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