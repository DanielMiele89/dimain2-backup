/*
-- REPLACEs this bunch of stored procedures:
EXEC WHB.PartnersOffers_PartnerCommissionRule

*/
CREATE PROCEDURE [WHB].[PartnersOffers_PartnerCommissionRule]

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
			1.	Reload PartnerCommissionRule Data
		*******************************************************************************************************************************************/

			TRUNCATE TABLE [Derived].[IronOffer_PartnerCommissionRule]
			INSERT INTO [Derived].[IronOffer_PartnerCommissionRule]
			SELECT	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[ID] as PCR_ID
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[PartnerID]
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[TypeID]
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[CommissionRate]
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[Status]
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[Priority]
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[DeletionDate]
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[MaximumUsesPerFan] as MaximumUsesPerFan
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[RequiredNumberOfPriorTransactions] as NumberofPriorTransactions
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[RequiredMinimumBasketSize] as MinimumBasketSize
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[RequiredMaximumBasketSize] as MaximumBasketSize
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[RequiredChannel] as Channel
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[RequiredClubID] as ClubID
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[RequiredIronOfferID] as IronOfferID
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[RequiredRetailOutletID] as OutletID
				,	[DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule].[RequiredCardholderPresence] as CardHolderPresence
			FROM [DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule] pcr
			WHERE EXISTS (	SELECT 1
							FROM [Derived].[IronOffer] iof
							WHERE pcr.RequiredIronOfferID = iof.IronOfferID)

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