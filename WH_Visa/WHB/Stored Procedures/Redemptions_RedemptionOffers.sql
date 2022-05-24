
CREATE PROCEDURE [WHB].[Redemptions_RedemptionOffers]
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
			1.		Find latest redemption files
	*******************************************************************************************************************************************/

			MERGE [Derived].[RedemptionOffers] target												-- Destination table
			USING [WHB].[Inbound_RedemptionOffers] source											-- Source table
			ON target.[RedemptionOfferGUID] = source.[RedemptionOfferGUID]							-- Match criteria

			WHEN MATCHED THEN
				UPDATE SET	target.[BankID]							= source.[BankID]				-- If matched, update to new value
						,	target.[RedemptionPartnerGUID]			= source.[RedemptionPartnerGUID]
						,	target.[Currency]						= source.[Currency]
						,	target.[RedemptionOfferID]				= source.[RedemptionOfferID]
						,	target.[Charity_MinimumCashback]		= source.[Charity_MinimumCashback]
						,	target.[TradeUp_CashbackRequired]		= source.[TradeUp_CashbackRequired]
						,	target.[TradeUp_MarketingPercentage]	= source.[TradeUp_MarketingPercentage]
						,	target.[TradeUp_WarningThreshold]		= source.[TradeUp_WarningThreshold]
						,	target.[Status]							= source.[Status]
						,	target.[Priority]						= source.[Priority]

			WHEN NOT MATCHED THEN																	-- If not matched, add new rows
				INSERT ([BankID]
					,	[RedemptionPartnerGUID]
					,	[Currency]
					,	[RedemptionOfferGUID]
					,	[RedemptionOfferID]
					,	[Charity_MinimumCashback]
					,	[TradeUp_CashbackRequired]
					,	[TradeUp_MarketingPercentage]
					,	[TradeUp_WarningThreshold]
					,	[Status]
					,	[Priority])
				VALUES (source.[BankID]
					,	source.[RedemptionPartnerGUID]
					,	source.[Currency]
					,	source.[RedemptionOfferGUID]
					,	source.[RedemptionOfferID]
					,	source.[Charity_MinimumCashback]
					,	source.[TradeUp_CashbackRequired]
					,	source.[TradeUp_MarketingPercentage]
					,	source.[TradeUp_WarningThreshold]
					,	source.[Status]
					,	source.[Priority]);


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
