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
			SELECT	DISTINCT
					PCR_ID = iofd.OfferDetailGUID
				,	PartnerID = oi.PartnerID
				,	TypeID = 1	--	Marketing
				,	RewardType =	CASE
										WHEN iofd.IsBounty = 0 THEN 'Percentage'
										ELSE 'Bounty'
									END
				,	CommissionRate = iofd.MarketingRate
				,	Override = iofd.Override
				,	Status = iof.OfferStatusID
				,	Priority = iof.PrioritisationScore
				,	DeletionDate = NULL
				,	MaximumUsesPerFan = NULL
				,	RequiredNumberOfPriorTransactions = NULL
				,	MinimumBasketSize = CASE
											WHEN iofd.MinimumSpendAmount = 0.00 AND iofd.MaximumSpendAmount = 0.00 THEN NULL
											ELSE iofd.MinimumSpendAmount
										END
				,	MaximumBasketSize = CASE
											WHEN iofd.MinimumSpendAmount = 0.00 AND iofd.MaximumSpendAmount = 0.00 THEN NULL
											ELSE iofd.MaximumSpendAmount
										END
				,	Channel = iof.OfferChannelID
				,	ClubID = oi.PublisherID
				,	IronOfferID = oi.IronOfferID
				,	OutletID = NULL
				,	CardHolderPresence = NULL
				,	OfferCap = iofd.OfferCap
			FROM [WHB].[Inbound_Offer] iof
			INNER JOIN [WHB].[Inbound_OfferDetail] iofd
				ON iof.OfferGUID = iofd.OfferGUID
				AND iof.OfferDetailGUID = iofd.OfferDetailGUID
			INNER JOIN [WH_AllPublishers].[Derived].[OfferIDs] oi
				ON CONVERT(VARCHAR(64), iof.OfferGUID) = oi.OfferCode

				
			INSERT INTO [Derived].[IronOffer_PartnerCommissionRule]
			SELECT	DISTINCT
					PCR_ID = iofd.OfferDetailGUID
				,	PartnerID = oi.PartnerID
				,	TypeID = 2	--	Billing
				,	RewardType =	CASE
										WHEN iofd.IsBounty = 0 THEN 'Percentage'
										ELSE 'Bounty'
									END
				,	CommissionRate = iofd.BillingRate
				,	Override = iofd.Override
				,	Status = iof.OfferStatusID
				,	Priority = iof.PrioritisationScore
				,	DeletionDate = NULL
				,	MaximumUsesPerFan = NULL
				,	RequiredNumberOfPriorTransactions = NULL
				,	MinimumBasketSize = CASE
											WHEN iofd.MinimumSpendAmount = 0.00 AND iofd.MaximumSpendAmount = 0.00 THEN NULL
											ELSE iofd.MinimumSpendAmount
										END
				,	MaximumBasketSize = CASE
											WHEN iofd.MinimumSpendAmount = 0.00 AND iofd.MaximumSpendAmount = 0.00 THEN NULL
											ELSE iofd.MaximumSpendAmount
										END
				,	Channel = iof.OfferChannelID
				,	ClubID = oi.PublisherID
				,	IronOfferID = oi.IronOfferID
				,	OutletID = NULL
				,	CardHolderPresence = NULL
				,	OfferCap = iofd.OfferCap
			FROM [WHB].[Inbound_Offer] iof
			INNER JOIN [WHB].[Inbound_OfferDetail] iofd
				ON iof.OfferGUID = iofd.OfferGUID
				AND iof.OfferDetailGUID = iofd.OfferDetailGUID
			INNER JOIN [WH_AllPublishers].[Derived].[OfferIDs] oi
				ON CONVERT(VARCHAR(64), iof.OfferGUID) = oi.OfferCode
			
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
