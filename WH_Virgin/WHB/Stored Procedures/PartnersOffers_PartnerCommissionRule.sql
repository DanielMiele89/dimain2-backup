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
			SELECT	ID as PCR_ID
				,	PartnerID
				,	TypeID
				,	CommissionRate
				,	Status
				,	Priority
				,	DeletionDate
				,	MaximumUsesPerFan as MaximumUsesPerFan
				,	RequiredNumberOfPriorTransactions as NumberofPriorTransactions
				,	RequiredMinimumBasketSize as MinimumBasketSize
				,	RequiredMaximumBasketSize as MaximumBasketSize
				,	RequiredChannel as Channel
				,	RequiredClubID as ClubID
				,	RequiredIronOfferID as IronOfferID
				,	RequiredRetailOutletID as OutletID
				,	RequiredCardholderPresence as CardHolderPresence
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