
/*
Author:		
Date:		
Purpose:	

Notes:		
*/

CREATE PROCEDURE [WHB].[Inbound_RedemptionPartners_Update]

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
			WHERE TableName = 'RedemptionPartners'

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

		/***********************************************************************************************************************************************
			2.	Fetch Redemption Offer files that haven't been processed
		***********************************************************************************************************************************************/

		WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE TableName = 'RedemptionPartners' AND FileProcessed = 0) > 0
			BEGIN

			/*******************************************************************************************************************************************
				2.1.	Fetch files that haven't been processed
			*******************************************************************************************************************************************/

				IF OBJECT_ID('tempdb..#FilesToProcess_TradeUp') IS NOT NULL DROP TABLE #FilesToProcess_TradeUp
				SELECT	TOP 1
						ID AS FileID
					,	LoadDate
					,	FileName
				INTO #FilesToProcess_TradeUp
				FROM [WHB].[Inbound_Files] f
				WHERE TableName = 'RedemptionPartners'
				AND FileProcessed = 0
				ORDER BY ID


			/*******************************************************************************************************************************************
				2.2.	Fetch latest Redemption Offers file to be processed
			*******************************************************************************************************************************************/

				IF OBJECT_ID('tempdb..#RedemptionPartners') IS NOT NULL DROP TABLE #RedemptionPartners
				SELECT	*
				INTO #RedemptionPartners
				FROM [Inbound].[RedemptionPartners] cu
				WHERE EXISTS (	SELECT 1
								FROM #FilesToProcess_TradeUp ftp
								WHERE cu.FileName = ftp.FileName
								AND cu.LoadDate = ftp.LoadDate)


			/*******************************************************************************************************************************************
				2.3.	Use the latest Card file to update the WHB version of the table
			*******************************************************************************************************************************************/

				MERGE [WHB].[Inbound_RedemptionPartners] target										-- Destination table
				USING #RedemptionPartners source														-- Source table
				ON target.[RedemptionPartnerGUID] = source.[RedemptionPartnerGUID]						-- Match criteria

				WHEN MATCHED THEN
					UPDATE SET	target.[PartnerName]			= source.[PartnerName]				-- If matched, update to new value
							,	target.[PartnerType]			= source.[PartnerType]
							,	target.[CreatedAt]				= source.[CreatedAt]
							,	target.[UpdatedAt]				= source.[UpdatedAt]
							,	target.[LoadDate]				= source.[LoadDate]
							,	target.[FileName]				= source.[FileName]

				WHEN NOT MATCHED THEN																-- If not matched, add new rows
					INSERT ([RedemptionPartnerGUID]
						,	[PartnerName]
						,	[PartnerType]
						,	[CreatedAt]
						,	[UpdatedAt]
						,	[LoadDate]
						,	[FileName])
					VALUES (source.[RedemptionPartnerGUID]
						,	source.[PartnerName]
						,	source.[PartnerType]
						,	source.[CreatedAt]
						,	source.[UpdatedAt]
						,	source.[LoadDate]
						,	source.[FileName]);

			SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded rows to [WHB].[Inbound_RedemptionPartners] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
			EXEC [Monitor].[ProcessLog_Insert] 'RedemptionPartners_Inbound', @msg


			/*******************************************************************************************************************************************
				2.4.	Mark the file as Processed
			*******************************************************************************************************************************************/

				UPDATE f
				SET FileProcessed = 1
				FROM [WHB].[Inbound_Files] f
				WHERE EXISTS (	SELECT 1
								FROM #FilesToProcess_TradeUp ftp
								WHERE f.ID = ftp.FileID
								AND f.LoadDate = ftp.LoadDate)

			END	--	WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE TableName = 'RedemptionPartners' AND FileProcessed = 0) > 0

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
