
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Fetch the latest Goodwill data
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Inbound_Customers_GenerateFanID]

AS
BEGIN

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
			1. Fetch the latest date that events have been loaded
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
			SELECT	DISTINCT
					CustomerGUID
				,	GETDATE() AS ImportDate
			INTO #Customers
			FROM [Inbound].[Customers] cu

			INSERT INTO [WH_AllPublishers].[Derived].[CustomerIDs]
			SELECT	180 AS PublisherID
				,	180 AS PublisherID_RewardBI
				,	CustomerGUID AS CustomerID
				,	2 AS CustomerIDTypeID
				,	MIN(ImportDate) AS ImportDate
			FROM #Customers cu
			WHERE NOT EXISTS (	SELECT 1
								FROM [WH_AllPublishers].[Derived].[CustomerIDs] ci
								WHERE cu.CustomerGUID = ci.CustomerID
								AND ci.CustomerIDTypeID = 2
								AND ci.PublisherID = 180)
			GROUP BY cu.CustomerGUID
			ORDER BY cu.CustomerGUID
	
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
