
/*
Author:		
Date:		
Purpose:	

Notes:		
*/
CREATE PROCEDURE [WHB].[Inbound_Offer_Update]

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

	WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE TableName = 'Offer' AND FileProcessed = 0) > 0
		BEGIN

		/*******************************************************************************************************************************************
			1. Fetch files that haven't been processed
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#FilesToProcess') IS NOT NULL DROP TABLE #FilesToProcess
			SELECT	TOP 1
					ID AS FileID
				,	LoadDate
				,	FileName
			INTO #FilesToProcess
			FROM [WHB].[Inbound_Files] f
			WHERE TableName = 'Offer'
			AND FileProcessed = 0
			ORDER BY ID


		/*******************************************************************************************************************************************
			2. Fetch latest customer file to be processed
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Offer') IS NOT NULL DROP TABLE #Offer
			SELECT	*
			INTO #Offer
			FROM [Inbound].[Offer] cu
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE cu.FileName = ftp.FileName
							AND cu.LoadDate = ftp.LoadDate)

		/*******************************************************************************************************************************************
			3. Use the latest customer file to update the WHB version of the table
		*******************************************************************************************************************************************/

			MERGE [WHB].[Inbound_Offer] target						-- Destination table
			USING #Offer source									-- Source table
			ON target.[OfferGUID] = source.[OfferGUID]				-- Match criteria
			AND target.[OfferDetailGUID] = source.[OfferDetailGUID]	-- Match criteria
			WHEN MATCHED THEN
				UPDATE SET	target.OfferGUID			= source.OfferGUID	-- If matched, update to new value
						,	target.OfferName			= source.OfferName
						,	target.StartDate			= source.StartDate
						,	target.EndDate				= source.EndDate
						,	target.RetailerGUID			= source.RetailerGUID
						,	target.PublisherGUID		= source.PublisherGUID
						,	target.OfferChannelID		= source.OfferChannelID
						,	target.CurrencyID			= source.CurrencyID
						,	target.OfferDetailGUID		= source.OfferDetailGUID
						,	target.PrioritisationScore	= source.PrioritisationScore
						,	target.OfferStatusID		= source.OfferStatusID
						,	target.CreatedDate			= source.CreatedDate
						,	target.UpdatedDate			= source.UpdatedDate
						,	target.PublishedDate		= source.PublishedDate
						,	target.LoadDate				= source.LoadDate
						,	target.FileName				= source.FileName

			WHEN NOT MATCHED THEN											-- If not matched, add new rows
				INSERT (OfferGUID
					,	OfferName
					,	StartDate
					,	EndDate
					,	RetailerGUID
					,	PublisherGUID
					,	OfferChannelID
					,	CurrencyID
					,	OfferDetailGUID
					,	PrioritisationScore
					,	OfferStatusID
					,	CreatedDate
					,	UpdatedDate
					,	PublishedDate
					,	LoadDate
					,	FileName)
				VALUES (source.OfferGUID
					,	source.OfferName
					,	source.StartDate
					,	source.EndDate
					,	source.RetailerGUID
					,	source.PublisherGUID
					,	source.OfferChannelID
					,	source.CurrencyID
					,	source.OfferDetailGUID
					,	source.PrioritisationScore
					,	source.OfferStatusID
					,	source.CreatedDate
					,	source.UpdatedDate
					,	source.PublishedDate
					,	source.LoadDate
					,	source.FileName);

			SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded rows to [WHB].[Inbound_Offer] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
			EXEC [Monitor].[ProcessLog_Insert] 'Inbound_Offer', @msg


		/*******************************************************************************************************************************************
			4. Mark the file as Processed
		*******************************************************************************************************************************************/

			UPDATE f
			SET FileProcessed = 1
			FROM [WHB].[Inbound_Files] f
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE f.ID = ftp.FileID
							AND f.LoadDate = ftp.LoadDate)

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
