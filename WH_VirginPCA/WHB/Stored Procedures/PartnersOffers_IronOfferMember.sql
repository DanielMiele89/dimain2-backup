/*

*/
CREATE PROCEDURE [WHB].[PartnersOffers_IronOfferMember]
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
			1.	Find the latest Welcome Offer Memberships that have been assigned
		*******************************************************************************************************************************************/

			DECLARE @TwoDaysAgo DATE = DATEADD(DAY, -2, GETDATE())

			IF OBJECT_ID('tempdb..#WelcomeIronOfferMembers') IS NOT NULL DROP TABLE #WelcomeIronOfferMembers
			SELECT	cu.CompositeID
				,	iof.IronOfferID
				,	wiom.StartDate
				,	CASE
						WHEN CONVERT(DATETIME, wiom.EndDate) > wiom.EndDate THEN DATEADD(SECOND, -1, wiom.EndDate)
						ELSE wiom.EndDate
					END AS EndDate
				,	MIN(wiom.LoadDate) AS ImportDate
			INTO #WelcomeIronOfferMembers
			FROM [Inbound].[WelcomeIronOfferMembers] wiom
			INNER JOIN [Derived].[IronOffer] iof
				ON wiom.OfferGUID = iof.HydraOfferID
			INNER JOIN [Derived].[Customer] cu
				ON wiom.CustomerGUID = cu.CustomerGUID
			WHERE @TwoDaysAgo < wiom.LoadDate
			AND iof.IsSignedOff = 1
			GROUP BY	cu.CompositeID
					,	iof.IronOfferID
					,	wiom.StartDate
					,	wiom.EndDate

			CREATE CLUSTERED INDEX [CSX_All] ON #WelcomeIronOfferMembers ([IronOfferID], [CompositeID],	[StartDate], [EndDate],	[ImportDate])

		/*******************************************************************************************************************************************
			2.	Find the latest Segmented Offer Memberships that have been assigned
		*******************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#SegmentedIronOfferMember') IS NOT NULL DROP TABLE #SegmentedIronOfferMember
			SELECT	oma.IronOfferID
				,	oma.CompositeID
				,	oma.StartDate
				,	oma.EndDate
				,	MAX(opl.ProcessedDate) AS ImportDate
			INTO #SegmentedIronOfferMember
			FROM [Segmentation].[OfferMemberAddition] oma
			INNER JOIN [Segmentation].[OfferProcessLog] opl
				ON oma.IronOfferID = opl.IronOfferID
				AND opl.IsUpdate = 0
				AND opl.Processed = 1
			WHERE @TwoDaysAgo < ProcessedDate
			GROUP BY	oma.IronOfferID
					,	oma.CompositeID
					,	oma.StartDate
					,	oma.EndDate

			CREATE CLUSTERED INDEX [CSX_All] ON #SegmentedIronOfferMember ([IronOfferID], [CompositeID], [StartDate], [EndDate], [ImportDate])

		/*******************************************************************************************************************************************
			3.	Split out the rows that need to be added [Derived].[IronOfferMember]
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember
			SELECT	wiom.IronOfferID
				,	wiom.CompositeID
				,	wiom.StartDate
				,	wiom.EndDate
				,	wiom.ImportDate
			INTO #IronOfferMember
			FROM #WelcomeIronOfferMembers wiom
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[IronOfferMember] iom
								WHERE wiom.IronOfferID = iom.IronOfferID
								AND CONVERT(DATE, wiom.StartDate) = CONVERT(DATE, iom.StartDate)
								AND CONVERT(DATE, wiom.EndDate) = CONVERT(DATE, iom.EndDate)
								AND wiom.CompositeID = iom.CompositeID)

			INSERT INTO #IronOfferMember
			SELECT	siom.IronOfferID
				,	siom.CompositeID
				,	siom.StartDate
				,	siom.EndDate
				,	siom.ImportDate
			FROM #SegmentedIronOfferMember siom
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[IronOfferMember] iom
								WHERE siom.IronOfferID = iom.IronOfferID
								AND siom.StartDate = iom.StartDate
								AND siom.EndDate = iom.EndDate
								AND siom.CompositeID = iom.CompositeID)


		/*******************************************************************************************************************************************
			3.	Insert the latest Welcome Offer Memberships to [Derived].[IronOfferMember]
		*******************************************************************************************************************************************/
	
			--ALTER INDEX [CSX_All] ON [Derived].[IronOfferMember] DISABLE

			--DECLARE @InsertQuery VARCHAR(MAX)

			--SET @InsertQuery = '
			INSERT INTO [Derived].[IronOfferMember] (	IronOfferID
													,	CompositeID
													,	StartDate
													,	EndDate
													,	ImportDate)
			SELECT iom.IronOfferID
				 , iom.CompositeID
				 , iom.StartDate
				 , iom.EndDate
				 , iom.ImportDate
			FROM #IronOfferMember iom
			--'

			--EXEC(@InsertQuery)

			--ALTER INDEX [CSX_All] ON [Derived].[IronOfferMember] REBUILD
	
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

