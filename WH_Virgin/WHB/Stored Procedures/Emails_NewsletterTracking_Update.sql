CREATE PROCEDURE [WHB].[Emails_NewsletterTracking_Update]
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
			1.		Prepare variables
	*******************************************************************************************************************************************/

		DECLARE @EmailsOpened BIGINT = 0
			  , @RowCount BIGINT = 0
		  

	/*******************************************************************************************************************************************
			2.		Find how many customers have opened an email since last updated
	*******************************************************************************************************************************************/

		SELECT @EmailsOpened = COUNT(FanID)
		FROM [Email].[Newsletter_Customers] ls
		WHERE ls.EmailOpened = 0
		AND EXISTS (SELECT 1
					FROM [Derived].[EmailEvent] ee
					WHERE ls.FanID = ee.FanID
					AND ls.CampaignKey = ee.CampaignKey
					AND ee.EmailEventCodeID = 1301)

	/*******************************************************************************************************************************************
			3.		If there are not enough entries to make update worthwhile, skip to after the update
	*******************************************************************************************************************************************/
	
		IF @EmailsOpened < 10000
			GOTO NotEnoughEmailsToUpdate;

	/*******************************************************************************************************************************************
			4.		Run update for email opens
	*******************************************************************************************************************************************/
		
		/***************************************************************************************************************************************
			4.1.	Drop index on [Lion].[LionSend_Customers]
		***************************************************************************************************************************************/

				IF INDEXPROPERTY(OBJECT_ID('[Email].[Newsletter_Customers]'), 'CSX_LionSendCustomers_All', 'IndexId') IS NOT NULL
					BEGIN
						DROP INDEX [CSX_LionSendCustomers_All] ON [Email].[Newsletter_Customers]
					END

		/***********************************************************************************************************************
			4.2.	Update the CampaignKey where it was previous not found
		***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#EmailCampaign') IS NOT NULL DROP TABLE #EmailCampaign
				SELECT	ec.CampaignKey
					,	CampaignName
					,	SendDate
					,	166 AS ClubID
					 ,	NULL AS IsLoyalty
					 ,	CASE
							WHEN PATINDEX('%LSID%', CampaignName) > 0 THEN SUBSTRING(CampaignName, PATINDEX('%LSID%', CampaignName) + 4, 3)
							ELSE NULL
						END AS LionSendID
				INTO #EmailCampaign
				FROM [Derived].[EmailCampaign] ec
				WHERE CampaignName LIKE '%Newsletter_LSID[0-9][0-9][0-9]_[0-9]%'
				AND CampaignName NOT LIKE 'TEST%'

				UPDATE ls
				SET ls.CampaignKey = ec.CampaignKey
				FROM [Email].[Newsletter_Customers] ls
				INNER JOIN #EmailCampaign ec
					ON ls.LionSendID = ec.LionSendID
					--AND ls.IsLoyalty = ec.IsLoyalty
					AND ls.ClubID = ec.ClubID
				WHERE ls.CampaignKey IS NULL
		

		/***********************************************************************************************************************
			4.3.	Update EmailSent flag
		***********************************************************************************************************************/
	
				IF OBJECT_ID('tempdb..#EmailNotSent') IS NOT NULL DROP TABLE #EmailNotSent
				SELECT	lsc.CampaignKey
					,	lsc.FanID
				INTO #EmailNotSent
				FROM [Email].[Newsletter_Customers] lsc
				WHERE lsc.EmailSent = 0

				CREATE CLUSTERED INDEX CIX_EmailNotSent_FanID ON #EmailNotSent (CampaignKey, FanID)
	

				IF OBJECT_ID('tempdb..#EmailSent') IS NOT NULL DROP TABLE #EmailSent
				SELECT	DISTINCT
						ee.CampaignKey
					,	ee.FanID
				INTO #EmailSent
				FROM #EmailNotSent ens
				INNER JOIN [Derived].[EmailEvent] ee
					ON ens.FanID = ee.FanID
					AND ens.CampaignKey = ee.CampaignKey

				UPDATE lsc
				SET	EmailSent = 1
				FROM [Email].[Newsletter_Customers] lsc
				INNER JOIN #EmailSent es
					ON lsc.CampaignKey = es.CampaignKey
					AND lsc.FanID = es.FanID
				WHERE EmailSent = 0

				SET @RowCount = @RowCount + @@ROWCOUNT
		

		/***********************************************************************************************************************
			4.4.	Update EmailOpened flag
		***********************************************************************************************************************/
	
				IF OBJECT_ID('tempdb..#EmailNotOpened') IS NOT NULL DROP TABLE #EmailNotOpened
				SELECT	lsc.CampaignKey
					,	lsc.FanID
				INTO #EmailNotOpened
				FROM [Email].[Newsletter_Customers] lsc
				WHERE lsc.EmailOpened = 0

				CREATE CLUSTERED INDEX CIX_EmailNotOpened_CampaignKeyFanID ON #EmailNotOpened (CampaignKey, FanID)


				IF OBJECT_ID('tempdb..#EmailOpens') IS NOT NULL DROP TABLE #EmailOpens
				SELECT	ee.CampaignKey
					,	ee.FanID
					,	MIN(EventDate) AS EventDate
				INTO #EmailOpens
				FROM #EmailNotOpened eno
				INNER JOIN Derived.EmailEvent ee
					ON eno.CampaignKey = ee.CampaignKey
					AND eno.FanID = ee.FanID
				WHERE ee.EmailEventCodeID = 1301
				GROUP BY ee.CampaignKey
					  , ee.FanID

				UPDATE lsc
				SET	EmailOpened = 1
				,	EmailOpenedDate = EventDate
				FROM [Email].[Newsletter_Customers] lsc
				INNER JOIN #EmailOpens eo
					ON lsc.CampaignKey = eo.CampaignKey
					AND lsc.FanID = eo.FanID
				WHERE EmailOpened = 0

				SET @RowCount = @RowCount + @@ROWCOUNT
			
				SET @RowsAffected = @RowCount;SET @Msg = 'Updated rows to [Derived].[Newsletter_Customers] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
				EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, @Msg
		

		/***********************************************************************************************************************
			4.4.	Recreate index
		***********************************************************************************************************************/
	
				ALTER INDEX [IX_LionCampaignClubFan] ON [Email].[Newsletter_Customers] REBUILD WITH (SORT_IN_TEMPDB = ON)
				CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_LionSendCustomers_All] ON [Email].[Newsletter_Customers] ([LionSendID], [EmailSendDate], [CampaignKey], [CompositeID], [FanID], [ClubID], [IsLoyalty], [EmailSent], [EmailOpened], [EmailOpenedDate])
			
				EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Indexes recreated on [Email].[Newsletter_Customers]'


	/*******************************************************************************************************************************************
			5.		If there are not enough entries to make update worthwhile, scripts skips to here	
	*******************************************************************************************************************************************/

		NotEnoughEmailsToUpdate:
	
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