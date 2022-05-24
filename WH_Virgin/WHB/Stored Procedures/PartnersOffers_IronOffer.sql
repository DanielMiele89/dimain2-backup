/*
-- REPLACEs this bunch of stored procedures:
EXEC WHB.PartnersOffers_IronOffer

*/
CREATE PROCEDURE [WHB].[PartnersOffers_IronOffer]

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
			1.	Copy [SLC_Report].[dbo].[IronOffer] into table
		*******************************************************************************************************************************************/

			DECLARE @ClubID INT = 166

			TRUNCATE TABLE [Derived].[IronOffer]
			INSERT INTO [Derived].[IronOffer] (	IronOfferID
											,	IronOfferName
											,	HydraOfferID
											,	StartDate
											,	EndDate
											,	PartnerID
											,	IsAboveTheLine
											,	AutoAddToNewRegistrants
											,	IsDefaultCollateral
											,	IsSignedOff
											,	AreEligibleMembersCommitted
											,	AreControlMembersCommitted
											,	IsTriggerOffer
											,	TopCashBackRate
											,	SegmentName
											,	ClubID)
			SELECT	CONVERT(INT, iof.[ID]) AS IronOfferID
				,	CONVERT(NVARCHAR(200), iof.[Name]) AS IronOfferName
				,	oca.HydraOfferID
				,	CONVERT(DATETIME, iof.[StartDate]) AS StartDate
				,	CONVERT(DATETIME, iof.[EndDate]) AS EndDate
				,	CONVERT(INT, iof.[PartnerID]) AS PartnerID
				,	CONVERT(BIT, iof.[IsAboveTheLine]) AS IsAboveTheLine
				,	CONVERT(BIT, iof2.[AutoAddToNewRegistrants]) AS AutoAddToNewRegistrants
				,	CONVERT(BIT, iof.[IsDefaultCollateral]) AS IsDefaultCollateral
				,	CONVERT(BIT, iof.[IsSignedOff]) AS IsSignedOff
				,	CONVERT(BIT, iof2.[AreEligibleMembersCommitted]) AS AreEligibleMembersCommitted
				,	CONVERT(BIT, iof2.[AreControlMembersCommitted]) AS AreControlMembersCommitted
				,	CONVERT(BIT, iof.[IsTriggerOffer]) AS IsTriggerOffer
				,	CASE
						WHEN iof.Name IN ('Above the line', 'Above the line Collateral', 'Default', 'Default Collateral') THEN 0
						ELSE NULL
					END AS TopCashBackRate
				,	CASE
						WHEN iof.Name LIKE '%Lapsed%' THEN 'Lapsed'
						WHEN iof.Name LIKE '%Lasped%' THEN 'Lapsed'
						WHEN iof.Name LIKE '%Acquire%' THEN 'Acquire'
						WHEN iof.Name LIKE '%Welcome%' THEN 'Welcome'
						WHEN iof.Name LIKE '%Shopper%' THEN 'Shopper'
						WHEN iof.Name LIKE '%Nursery%' THEN 'Shopper'
						WHEN iof.Name LIKE '%Lapsing%' THEN 'Shopper'
					END AS SegmentName
				,	@ClubID
			FROM [DIMAIN_TR].[SLC_REPL].[dbo].[IronOffer] iof
			LEFT JOIN [SLC_Report].[dbo].[IronOffer] iof2
				ON iof.ID = iof2.ID
			LEFT JOIN [DIMAIN_TR].[SLC_REPL].[hydra].[OfferConverterAudit] oca
				ON iof.ID = oca.IronOfferId
			WHERE EXISTS (	SELECT 1
							FROM [DIMAIN_TR].[SLC_REPL].[dbo].[IronOfferClub] ioc
							WHERE iof.ID = ioc.IronOfferID
							AND ioc.ClubID = @ClubID)
			ORDER BY	iof.ID DESC

			UPDATE [Derived].[IronOffer]
			SET IronOfferName = REPLACE(IronOfferName, 'Shopper', 'Welcome')
			WHERE IronOfferID IN (22400)

			UPDATE [Derived].[IronOffer]
			SET IronOfferName = REPLACE(IronOfferName, 'HUS003', 'HUS003')
			WHERE IronOfferID IN (23832, 23833, 23830, 23831)


		/*******************************************************************************************************************************************
			2.	Fetch Cashback Rate
		*******************************************************************************************************************************************/

			UPDATE iof
			SET TopCashbackRate = TCBR
			FROM [Derived].[IronOffer] iof
			CROSS APPLY (	SELECT MAX(CommissionRate) AS TCBR
							FROM [DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule] pcr
							WHERE pcr.RequiredIronOfferID = iof.IronOfferID 
							AND pcr.[Status] = 1
							AND pcr.TypeID = 1) x
			WHERE iof.TopCashbackRate IS NULL


		/*******************************************************************************************************************************************
			3.	Work Out Campaign Type
		*******************************************************************************************************************************************/

			UPDATE i
			SET CampaignType = 'Tactical Campaign'
			FROM [Derived].[IronOffer] as i
			--INNER JOIN [Derived].[IronOffer_Campaign_HTM] htm
			--	on i.IronOfferID = htm.IronOfferID
			--INNER JOIN [Staging].[IronOffer_Campaign_Type] ct
			--	on htm.ClientServicesRef = ct.ClientServicesRef
			--INNER JOIN [Staging].[IronOffer_Campaign_Type_Lookup] ctl
			--	on ct.CampaignTypeID = ctl.CampaignTypeID


		/*******************************************************************************************************************************************
			4.	Remove expired unsigned off offers
		*******************************************************************************************************************************************/

			DELETE iof
			FROM [Derived].[IronOffer] iof
			WHERE iof.IsAboveTheLine = 0 
			AND iof.IsDefaultCollateral = 0 
			AND iof.IsSignedOff = 0 
			AND iof.EndDate < GETDATE()
			AND iof.IsTriggerOffer = 0
	
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