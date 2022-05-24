
/*
Author:		
Date:		
Purpose:	

Notes:		
*/

CREATE PROCEDURE [WHB].[Inbound_Cards_Update]

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

	WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE [f].[TableName] = 'Cards' AND [f].[FileProcessed] = 0) > 0
		BEGIN

		/*******************************************************************************************************************************************
			1. Fetch files that haven't been processed
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#FilesToProcess') IS NOT NULL DROP TABLE #FilesToProcess
			SELECT	TOP 1
					[f].[ID] AS FileID
				,	[f].[LoadDate]
				,	[f].[FileName]
			INTO #FilesToProcess
			FROM [WHB].[Inbound_Files] f
			WHERE [f].[TableName] = 'Cards'
			AND [f].[FileProcessed] = 0
			ORDER BY [f].[ID]


		/*******************************************************************************************************************************************
			2. Fetch latest Card file to be processed
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Cards') IS NOT NULL DROP TABLE #Cards
			SELECT	*
			INTO #Cards
			FROM [Inbound].[Cards] cu
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE #FilesToProcess.[cu].FileName = ftp.FileName
							AND #FilesToProcess.[cu].LoadDate = ftp.LoadDate)


		/*******************************************************************************************************************************************
			3. Use the latest Card file to update the WHB version of the table
		*******************************************************************************************************************************************/

			MERGE [WHB].[Inbound_Cards] target										-- Destination table
			USING #Cards source														-- Source table
			ON target.CardID = source.CardID										-- Match criteria

			WHEN MATCHED THEN
				UPDATE SET	target.AccountID			= source.AccountID			-- If matched, update to new value
						,	target.PrimaryCustomerID	= source.PrimaryCustomerID
						,	target.BankID				= source.BankID
						,	target.LoadDate				= source.LoadDate
						,	target.FileName				= source.FileName

			WHEN NOT MATCHED THEN													-- If not matched, add new rows
				INSERT ([target].[CardID]
					,	[target].[AccountID]
					,	[target].[PrimaryCustomerID]
					,	[target].[BankID]
					,	[target].[LoadDate]
					,	[target].[FileName])
				VALUES (source.CardID
					,	source.AccountID
					,	source.PrimaryCustomerID
					,	source.BankID
					,	source.LoadDate
					,	source.FileName);

		SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded rows to [WHB].[Inbound_Cards] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
		EXEC [Monitor].[ProcessLog_Insert] 'Card_Inbound', @msg


		/*******************************************************************************************************************************************
			4. Mark the file as Processed
		*******************************************************************************************************************************************/

			UPDATE f
			SET [f].[FileProcessed] = 1
			FROM [WHB].[Inbound_Files] f
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE #FilesToProcess.[f].ID = ftp.FileID
							AND #FilesToProcess.[f].LoadDate = ftp.LoadDate)

		END	--	WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE TableName = 'Cards' AND FileProcessed = 0) > 0

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
		INSERT INTO [Monitor].[ErrorLog] ([Monitor].[ErrorLog].[ErrorDate], [Monitor].[ErrorLog].[ProcedureName], [Monitor].[ErrorLog].[ErrorLine], [Monitor].[ErrorLog].[ErrorMessage], [Monitor].[ErrorLog].[ErrorNumber], [Monitor].[ErrorLog].[ErrorSeverity], [Monitor].[ErrorLog].[ErrorState])
		VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
		SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
		RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
		RETURN -1;

	END CATCH

	RETURN 0; -- should never run

END
