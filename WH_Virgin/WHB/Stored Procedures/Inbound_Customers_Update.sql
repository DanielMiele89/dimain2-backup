
/*
Author:		
Date:		
Purpose:	

Notes:		
*/
CREATE PROCEDURE [WHB].[Inbound_Customers_Update]

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

	WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE [f].[TableName] = 'Customers' AND [f].[FileProcessed] = 0) > 0
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
			WHERE [f].[TableName] = 'Customers'
			AND [f].[FileProcessed] = 0
			ORDER BY [f].[ID]


		/*******************************************************************************************************************************************
			2. Fetch latest customer file to be processed
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
			SELECT	*
			INTO #Customers
			FROM [Inbound].[Customers] cu
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE #FilesToProcess.[cu].FileName = ftp.FileName
							AND #FilesToProcess.[cu].LoadDate = ftp.LoadDate)


		/*******************************************************************************************************************************************
			3. Use the latest customer file to update the WHB version of the table
		*******************************************************************************************************************************************/

			MERGE [WHB].[Inbound_Customers] target							-- Destination table
			USING #Customers source											-- Source table
			ON target.CustomerID = source.CustomerID						-- Match criteria

			WHEN MATCHED THEN
				UPDATE SET	target.RewardCustomerID		= source.RewardCustomerID	-- If matched, update to new value
						,	target.VirginCustomerID		= source.VirginCustomerID
						,	target.Forename				= source.Forename
						,	target.Surname				= source.Surname
						,	target.PostCode				= source.PostCode
						,	target.DateOfBirth			= source.DateOfBirth
						,	target.Gender				= source.Gender
						,	target.EmailAddress			= source.EmailAddress
						,	target.BankID				= source.BankID
						,	target.MarketableByEmail	= source.MarketableByEmail
						,	target.MarketableByPush		= source.MarketableByPaper
						,	target.MarketableByPhone	= source.MarketableByPhone
						,	target.MarketableBySMS		= source.MarketableBySMS
						,	target.RegistrationDate		= source.RegistrationDate
						,	target.ClosedDate			= source.ClosedDate
						,	target.DeactivatedDate		= source.DeactivatedDate
						,	target.LoadDate				= source.LoadDate
						,	target.FileName				= source.FileName

			WHEN NOT MATCHED THEN											-- If not matched, add new rows
				INSERT ([target].[RewardCustomerID]
					,	[target].[VirginCustomerID]
					,	[target].[CustomerID]
					,	[target].[Forename]
					,	[target].[Surname]
					,	[target].[PostCode]
					,	[target].[DateOfBirth]
					,	[target].[Gender]
					,	[target].[EmailAddress]
					,	[target].[BankID]
					,	[target].[MarketableByEmail]
					,	[target].[MarketableByPush]
					,	[target].[MarketableByPhone]
					,	[target].[MarketableBySms]
					,	[target].[RegistrationDate]
					,	[target].[ClosedDate]
					,	[target].[DeactivatedDate]
					,	[target].[LoadDate]
					,	[target].[FileName])
				VALUES (source.RewardCustomerID
					,	source.VirginCustomerID
					,	source.CustomerID
					,	source.Forename
					,	source.Surname
					,	source.PostCode
					,	source.DateOfBirth
					,	source.Gender
					,	source.EmailAddress
					,	source.BankID
					,	source.MarketableByEmail
					,	source.MarketableByPaper
					,	source.MarketableByPhone
					,	source.MarketableBySMS
					,	source.RegistrationDate
					,	source.ClosedDate
					,	source.DeactivatedDate
					,	source.LoadDate
					,	source.FileName);

			SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded rows to [WHB].[Inbound_Customers] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
			EXEC [Monitor].[ProcessLog_Insert] 'Customer_Inbound', @msg


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

		END	--	WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE TableName = 'Customers' AND FileProcessed = 0) > 0
		
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
