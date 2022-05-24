
/*
Author:		
Date:		
Purpose:	

Notes:		
*/

CREATE PROCEDURE [WHB].[Inbound_BankAccountCustomerLinks_Update]

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
			1.	If there is an unprocessed file then set all following files as unprocessed
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Inbound_Files') IS NOT NULL DROP TABLE #Inbound_Files
			SELECT	ID
				,	FileNameDate = CONVERT(DATE, RIGHT(REPLACE(FileName, '.csv', ''), 8))
				,	FileName
				,	LoadDate
				,	FileProcessed
			INTO #Inbound_Files
			FROM [WHB].[Inbound_Files] f
			WHERE TableName = 'BankAccountCustomerLinks'

			DECLARE @MinFileNameDate DATE

			SELECT	@MinFileNameDate = MIN(FileNameDate)
			FROM #Inbound_Files
			WHERE FileProcessed = 0

			UPDATE f
			SET f.FileProcessed = 0
			FROM #Inbound_Files ift
			INNER JOIN [WHB].[Inbound_Files] f
				ON ift.ID = f.ID
			WHERE FileNameDate >= @MinFileNameDate

	WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE TableName = 'BankAccountCustomerLinks' AND FileProcessed = 0) > 0
		BEGIN

		/*******************************************************************************************************************************************
			2. Fetch files that haven't been processed
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#FilesToProcess') IS NOT NULL DROP TABLE #FilesToProcess
			SELECT	TOP 1
					ID AS FileID
				,	LoadDate
				,	FileName
			INTO #FilesToProcess
			FROM [WHB].[Inbound_Files] f
			WHERE TableName = 'BankAccountCustomerLinks'
			AND FileProcessed = 0
			ORDER BY ID


		/*******************************************************************************************************************************************
			3. Fetch latest Account file to be processed
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#BankAccountCustomerLinks') IS NOT NULL DROP TABLE #BankAccountCustomerLinks
			SELECT	*
			INTO #BankAccountCustomerLinks
			FROM [Inbound].[BankAccountCustomerLinks] cu
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE cu.FileName = ftp.FileName
							AND cu.LoadDate = ftp.LoadDate)


		/*******************************************************************************************************************************************
			4. Use the latest Account file to update the WHB version of the table
		*******************************************************************************************************************************************/

			MERGE [WHB].[Inbound_BankAccountCustomerLinks] target									-- Destination table
			USING #BankAccountCustomerLinks source													-- Source table
			ON target.[BankAccountCustomerLinkID] = source.[BankAccountCustomerLinkID]				-- Match criteria

			WHEN MATCHED THEN
				UPDATE SET	target.[BankAccountGUID]		= source.[BankAccountGUID]				-- If matched, update to new value
						,	target.[CustomerGUID]			= source.[CustomerGUID]
						,	target.[AccountRelationship]	= source.[AccountRelationship]
						,	target.[StartDate]				= source.[StartDate]
						,	target.[EndDate]				= source.[EndDate]
						,	target.[LoadDate]				= source.[LoadDate]
						,	target.[FileName]				= source.[FileName]

			WHEN NOT MATCHED THEN																	-- If not matched, add new rows
				INSERT ([BankAccountCustomerLinkID]
					,	[BankAccountGUID]
					,	[CustomerGUID]
					,	[AccountRelationship]
					,	[StartDate]
					,	[EndDate]
					,	[LoadDate]
					,	[FileName])
				VALUES (source.[BankAccountCustomerLinkID]
					,	source.[BankAccountGUID]
					,	source.[CustomerGUID]
					,	source.[AccountRelationship]
					,	source.[StartDate]
					,	source.[EndDate]
					,	source.[LoadDate]
					,	source.[FileName]);

		SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded rows to [WHB].[Inbound_BankAccountCustomerLinks] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
		EXEC [Monitor].[ProcessLog_Insert] 'BankAccountCustomerLinks_Inbound', @msg


		/*******************************************************************************************************************************************
			5. Mark the file as Processed
		*******************************************************************************************************************************************/

			UPDATE f
			SET FileProcessed = 1
			FROM [WHB].[Inbound_Files] f
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE f.ID = ftp.FileID
							AND f.LoadDate = ftp.LoadDate)

		END	--	WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE TableName = 'Accounts' AND FileProcessed = 0) > 0

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