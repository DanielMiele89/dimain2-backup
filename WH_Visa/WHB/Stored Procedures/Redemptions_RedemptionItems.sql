
CREATE PROCEDURE [WHB].[Redemptions_RedemptionItems]
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
			1.		Fetch the WHB Redemption Item List
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#RedemptionItems') IS NOT NULL DROP TABLE #RedemptionItems
		SELECT	ri.*
			,	ro.RedemptionPartnerGUID
		INTO #RedemptionItems
		FROM [WHB].[Inbound_RedemptionItems] ri
		INNER JOIN [Derived].[RedemptionOffers] ro
			ON ri.RedemptionOfferGUID = ro.RedemptionOfferGUID


	/*******************************************************************************************************************************************
			2.		Update the RedmeptionItem List
	*******************************************************************************************************************************************/

			MERGE [Derived].[RedemptionItems] target											-- Destination table
			USING #RedemptionItems source														-- Source table
			ON target.[RedemptionItemID] = source.[RedemptionItemID]							-- Match criteria
			AND target.[RedemptionOfferGUID] = source.[RedemptionOfferGUID]						-- Match criteria

			WHEN MATCHED THEN
				UPDATE SET	target.[BankID]					= source.[BankID]					-- If matched, update to new value
						,	target.[RedemptionPartnerGUID]	= source.[RedemptionPartnerGUID]
						,	target.[Amount]					= source.[Amount]
						,	target.[Currency]				= source.[Currency]
						,	target.[Expiry]					= source.[Expiry]
						,	target.[Redeemed]				= source.[Redeemed]
						,	target.[RedeemedDate]			= source.[RedeemedDate]

			WHEN NOT MATCHED THEN																-- If not matched, add new rows
				INSERT ([BankID]
					,	[RedemptionPartnerGUID]
					,	[RedemptionOfferGUID]
					,	[RedemptionItemID]
					,	[Amount]
					,	[Currency]
					,	[Expiry]
					,	[Redeemed]
					,	[RedeemedDate])
				VALUES (source.[BankID]
					,	source.[RedemptionPartnerGUID]
					,	source.[RedemptionOfferGUID]
					,	source.[RedemptionItemID]
					,	source.[Amount]
					,	source.[Currency]
					,	source.[Expiry]
					,	source.[Redeemed]
					,	source.[RedeemedDate]);

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
