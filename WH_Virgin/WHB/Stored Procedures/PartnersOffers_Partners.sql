-- =============================================
--	Author:		
--	Create date: 
--	Description:	

--	Updates:
-- =============================================

CREATE PROCEDURE [WHB].[PartnersOffers_Partners]
	
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
			1.	Add new Partners
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[Partner]
			SELECT	pa.ID AS PartnerID
				,	pa.Name as PartnerName
				,	paw.BrandID
				,	paw.BrandName
				,	0 AS CurrentlyActive
				,	'' AS AccountManager
				,	1 AS TransactionTypeID
			FROM [DIMAIN_TR].[SLC_REPL].[dbo].[Partner] pa
			LEFT JOIN [Warehouse].[Relational].[Partner] paw
				ON pa.ID = paw.PartnerID
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Partner] p
								WHERE pa.ID = p.PartnerID)
			AND EXISTS (	SELECT 1
							FROM [Derived].[IronOffer] iof
							WHERE pa.ID = iof.PartnerID)

			UPDATE pa
			SET pa.BrandID = paw.BrandID
			,	pa.BrandName = paw.BrandName
			FROM [Derived].[Partner] pa
			INNER JOIN [Warehouse].[Relational].[Partner] paw
				ON pa.PartnerID = paw.PartnerID
			WHERE pa.BrandID IS NULL
			AND paw.BrandID IS NOT NULL

		/*******************************************************************************************************************************************
			2.	Reset Currently Active flag
		*******************************************************************************************************************************************/

			UPDATE [Derived].[Partner]
			SET CurrentlyActive = 0


		/*******************************************************************************************************************************************
			3.	Find active offers
		*******************************************************************************************************************************************/

			DECLARE @Date DATETIME = GETDATE()

			IF OBJECT_ID('tempdb..#IronOffer') IS NOT NULL DROP TABLE #IronOffer
			SELECT	iof.IronOfferID
				,	iof.PartnerID
				,	CASE
						WHEN IronOfferName like '%MFDD%' THEN 2
						ELSE 1
					END AS OfferType
				,	iof.IsSignedOff
				,	iof.StartDate
			INTO #IronOffer
			FROM [Derived].[IronOffer] iof
			WHERE (iof.EndDate IS NULL OR iof.EndDate >= @Date)
			AND iof.IsTriggerOffer = 0

			CREATE CLUSTERED INDEX CIX_IronOfferID on #IronOffer (IronOfferID)


		/*******************************************************************************************************************************************
			4.	Check offers have members
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#CurrentOffers') IS NOT NULL DROP TABLE #CurrentOffers
			SELECT	DISTINCT
					PartnerID
			INTO #CurrentOffers
			FROM #IronOffer iof
			WHERE EXISTS (	SELECT 1
							FROM [Derived].[IronOfferMember] iom
							WHERE iof.IronOfferID = iom.IronOfferID)
			AND IsSignedOff = 1
			AND StartDate <= @Date

			CREATE CLUSTERED INDEX CIX_PartnerID on #CurrentOffers (PartnerID)


		/*******************************************************************************************************************************************
			5.	Update partner records
		*******************************************************************************************************************************************/

			UPDATE [Derived].[Partner]
			SET CurrentlyActive = 1
			WHERE PartnerID IN (SELECT PartnerID FROM #CurrentOffers)


		/*******************************************************************************************************************************************
			6.	Update TransactionTypeID flag
		*******************************************************************************************************************************************/

			UPDATE pa
			SET TransactionTypeID = OfferType
			FROM [Derived].[Partner] pa
			INNER JOIN #IronOffer iof 
				ON pa.PartnerID = iof.PartnerID
			WHERE pa.TransactionTypeID IS NULL


		/*******************************************************************************************************************************************
			7.	Update the Relational.Partner table, setting AccountManager to Unassigned where no entry is found
		*******************************************************************************************************************************************/
		
			UPDATE pa
			SET AccountManager = ISNULL(am.AccountManager, 'Unassigned')
			FROM [Derived].[Partner] pa
			LEFT JOIN [Warehouse].[Selections].[PartnerAccountManager] am
				on pa.PartnerID = am.PartnerID
				AND am.EndDate IS NULL
		
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