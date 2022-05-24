
/*
Author:		
Date:		
Purpose:	

Notes:		
*/

CREATE PROCEDURE [WHB].[Inbound_RedemptionOffers_Update]

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
			WHERE TableName = 'RedemptionOffers'

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

	WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE TableName = 'RedemptionOffers' AND FileProcessed = 0) > 0
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
			WHERE TableName = 'RedemptionOffers'
			AND FileProcessed = 0
			ORDER BY ID


		/*******************************************************************************************************************************************
			2.2.	Fetch latest Redemption Offers file to be processed
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#RedemptionOffers') IS NOT NULL DROP TABLE #RedemptionOffers
			SELECT	*
				,	'Trade Up' AS OfferType
			INTO #RedemptionOffers
			FROM [Inbound].[RedemptionOffers] cu
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess_TradeUp ftp
							WHERE cu.FileName = ftp.FileName
							AND cu.LoadDate = ftp.LoadDate)

		/*******************************************************************************************************************************************
			2.3.	Use the latest Card file to update the WHB version of the table
		*******************************************************************************************************************************************/

			MERGE [WHB].[Inbound_RedemptionOffers] target										-- Destination table
			USING #RedemptionOffers source														-- Source table
			ON target.[RedemptionOfferGUID] = source.[RedemptionOfferGUID]						-- Match criteria

			WHEN MATCHED THEN
				UPDATE SET	target.[OfferType]						= source.[OfferType]		-- If matched, update to new value
						,	target.[RedemptionPartnerGUID]			= source.[RedemptionPartnerGUID]
						,	target.[RedemptionPartnerName]			= source.[RetailerName]
						,	target.[Currency]						= source.[Currency]
						
					--	,	target.[RedemptionOfferID]				= source.[RedemptionOfferID]
					--	,	target.[Charity_MinimumCashback]		= source.[Charity_MinimumCashback]

						,	target.[TradeUp_CashbackRequired]		= source.[Amount]
						,	target.[TradeUp_MarketingPercentage]	= source.[MarketingPercentage]
						,	target.[TradeUp_WarningThreshold]		= source.[WarningThreshold]
						,	target.[Status]							= source.[Status]
						,	target.[Priority]						= source.[Priority]
						,	target.[CreatedAt]						= source.[CreatedAt]
						,	target.[UpdatedAt]						= source.[UpdatedAt]
						,	target.[LoadDate]						= source.[LoadDate]
						,	target.[FileName]						= source.[FileName]

			WHEN NOT MATCHED THEN																-- If not matched, add new rows
				INSERT ([OfferType]
					,	[RedemptionPartnerGUID]
					,	[RedemptionPartnerName]
					,	[Currency]
					,	[RedemptionOfferGUID]
				--	,	[RedemptionOfferID]
				--	,	[Charity_MinimumCashback]
					,	[TradeUp_CashbackRequired]
					,	[TradeUp_MarketingPercentage]
					,	[TradeUp_WarningThreshold]
					,	[Status]
					,	[Priority]
					,	[CreatedAt]
					,	[UpdatedAt]
					,	[LoadDate]
					,	[FileName])
				VALUES (source.[OfferType]
					,	source.[RedemptionPartnerGUID]
					,	source.[RetailerName]
					,	source.[Currency]
					,	source.[RedemptionOfferGUID]
				--	,	source.[RedemptionOfferID]
				--	,	source.[Charity_MinimumCashback]

					,	source.[Amount]
					,	source.[MarketingPercentage]
					,	source.[WarningThreshold]

					,	source.[Status]
					,	source.[Priority]
					,	source.[CreatedAt]
					,	source.[UpdatedAt]
					,	source.[LoadDate]
					,	source.[FileName]);

		SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded rows to [WHB].[Inbound_RedemptionOffers] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
		EXEC [Monitor].[ProcessLog_Insert] 'RedemptionOffers_Inbound', @msg


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

		END	--	WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE TableName = 'Cards' AND FileProcessed = 0) > 0

	/***********************************************************************************************************************************************
		3.	Fetch Charity Offer files that haven't been processed
	***********************************************************************************************************************************************/

	WHILE (SELECT COUNT(*) FROM [WHB].[Inbound_Files] f WHERE TableName = 'CharityOffers' AND FileProcessed = 0) > 0
		BEGIN

		/*******************************************************************************************************************************************
			3.1.	Fetch files that haven't been processed
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#FilesToProcess_Charity') IS NOT NULL DROP TABLE #FilesToProcess_Charity
			SELECT	TOP 1
					ID AS FileID
				,	LoadDate
				,	FileName
			INTO #FilesToProcess_Charity
			FROM [WHB].[Inbound_Files] f
			WHERE TableName = 'CharityOffers'
			AND FileProcessed = 0
			ORDER BY ID

		/*******************************************************************************************************************************************
			3.2.	Fetch latest Redemption Offers file to be processed
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CharityOffers') IS NOT NULL DROP TABLE #CharityOffers
			SELECT	*
				,	'Charity' AS OfferType
			INTO #CharityOffers
			FROM [Inbound].[CharityOffers] cu
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess_Charity ftp
							WHERE cu.FileName = ftp.FileName
							AND cu.LoadDate = ftp.LoadDate)


		/*******************************************************************************************************************************************
			3.3.	Use the latest Card file to update the WHB version of the table
		*******************************************************************************************************************************************/
		

			MERGE [WHB].[Inbound_RedemptionOffers] target										-- Destination table
			USING #CharityOffers source															-- Source table
			ON target.[RedemptionOfferGUID] = source.[CharityOfferGUID]							-- Match criteria

			WHEN MATCHED THEN
				UPDATE SET	target.[OfferType]						= source.[OfferType]		-- If matched, update to new value
						,	target.[RedemptionPartnerGUID]			= source.[RedemptionPartnerGUID]
						,	target.[RedemptionPartnerName]			= source.[CharityName]
						,	target.[Currency]						= source.[Currency]
						
						,	target.[RedemptionOfferID]				= source.[CharityItemID]
						,	target.[Charity_MinimumCashback]		= source.[MinimumAmount]

					--	,	target.[TradeUp_CashbackRequired]		= source.[Amount]
					--	,	target.[TradeUp_MarketingPercentage]	= source.[MarketingPercentage]
					--	,	target.[TradeUp_WarningThreshold]		= source.[WarningThreshold]
						,	target.[Status]							= source.[Status]
						,	target.[Priority]						= source.[Priority]
						,	target.[CreatedAt]						= source.[CreatedAt]
						,	target.[UpdatedAt]						= source.[UpdatedAt]
						,	target.[LoadDate]						= source.[LoadDate]
						,	target.[FileName]						= source.[FileName]

			WHEN NOT MATCHED THEN																-- If not matched, add new rows
				INSERT ([OfferType]
					,	[RedemptionPartnerGUID]
					,	[RedemptionPartnerName]
					,	[Currency]
					,	[RedemptionOfferGUID]
					,	[RedemptionOfferID]
					,	[Charity_MinimumCashback]
				--	,	[TradeUp_CashbackRequired]
				--	,	[TradeUp_MarketingPercentage]
				--	,	[TradeUp_WarningThreshold]
					,	[Status]
					,	[Priority]
					,	[CreatedAt]
					,	[UpdatedAt]
					,	[LoadDate]
					,	[FileName])
				VALUES (source.[OfferType]
					,	source.[RedemptionPartnerGUID]
					,	source.[CharityName]
					,	source.[Currency]
					,	source.[CharityOfferGUID]
					,	source.[CharityItemID]
					,	source.[MinimumAmount]

				--	,	source.[Amount]
				--	,	source.[MarketingPercentage]
				--	,	source.[WarningThreshold]

					,	source.[Status]
					,	source.[Priority]
					,	source.[CreatedAt]
					,	source.[UpdatedAt]
					,	source.[LoadDate]
					,	source.[FileName]);

		SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded rows to [WHB].[Inbound_RedemptionOffers] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
		EXEC [Monitor].[ProcessLog_Insert] 'RedemptionOffers_Inbound', @msg


		/*******************************************************************************************************************************************
			3.4.	Mark the file as Processed
		*******************************************************************************************************************************************/

			UPDATE f
			SET FileProcessed = 1
			FROM [WHB].[Inbound_Files] f
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess_Charity ftp
							WHERE f.ID = ftp.FileID
							AND f.LoadDate = ftp.LoadDate)

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