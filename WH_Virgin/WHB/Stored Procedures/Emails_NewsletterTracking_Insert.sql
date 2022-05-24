/*

*/
CREATE PROCEDURE [WHB].[Emails_NewsletterTracking_Insert]
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
			1.		Find most recent Email Send Date & associated LionSendIDs
	*******************************************************************************************************************************************/

		DECLARE	@EmailSendDate DATE = (SELECT MAX([Report].[V_0003_NewsletterVolumes].[EmailSendDate]) FROM [Report].[V_0003_NewsletterVolumes])
			,	@Today DATE = GETDATE()

		IF OBJECT_ID('tempdb..#LionSendID') IS NOT NULL DROP TABLE #LionSendID
		SELECT	DISTINCT
				[ls].[LionSendID]
		INTO #LionSendID
		FROM [Report].[V_0003_NewsletterVolumes] ls
		WHERE [ls].[EmailSendDate] = @EmailSendDate


	/*******************************************************************************************************************************************
			2.		Load data if required
	*******************************************************************************************************************************************/

		IF NOT EXISTS (	SELECT 1
						FROM [Email].[Newsletter_Customers] lsc
						WHERE @EmailSendDate = lsc.EmailSendDate
						AND EXISTS (SELECT 1
									FROM #LionSendID ls
									WHERE #LionSendID.[lsc].LionSendID = ls.LionSendID))

			BEGIN

		/***************************************************************************************************************************************
			2.1.	Fetch offer details
		***************************************************************************************************************************************/

				IF OBJECT_ID('tempdb..#LionSend') IS NOT NULL DROP TABLE #LionSend
				SELECT	ls.LionSendID
					,	@EmailSendDate AS EmailSendDate
					,	ls.CompositeID
					,	ls.TypeID
					,	ls.ItemID
					,	ls.ItemRank
				INTO #LionSend
				FROM [Email].[NominatedLionSendComponent] ls
				WHERE EXISTS (	SELECT 1
								FROM #LionSendID lsi
								WHERE #LionSendID.[ls].LionSendID = lsi.LionSendID)
				UNION ALL
				SELECT	ls.LionSendID
					,	@EmailSendDate AS EmailSendDate
					,	ls.CompositeID
					,	ls.TypeID
					,	ls.ItemID
					,	ls.ItemRank
				FROM [Email].[NominatedLionSendComponent_RedemptionOffers] ls
				WHERE EXISTS (	SELECT 1
								FROM #LionSendID lsi
								WHERE #LionSendID.[ls].LionSendID = lsi.LionSendID)


				IF OBJECT_ID('tempdb..#LionSend_Offers') IS NOT NULL DROP TABLE #LionSend_Offers
				SELECT	ls.LionSendID
					,	ls.EmailSendDate
					,	ls.CompositeID
					,	cu.FanID
					,	ls.TypeID
					,	ls.ItemID
					,	ls.ItemRank
				INTO #LionSend_Offers
				FROM #LionSend ls
				INNER JOIN [Derived].[Customer] cu
					ON ls.CompositeID = cu.CompositeID
				WHERE NOT EXISTS (	SELECT 1
									FROM [Email].[Newsletter_Offers] lso
									WHERE ls.LionSendID = lso.LionSendID
									AND ls.CompositeID = lso.CompositeID)


				IF INDEXPROPERTY(OBJECT_ID('[Email].[Newsletter_Offers]'), 'CSX_LionSendOffers_All', 'IndexId') IS NOT NULL
					BEGIN
						DROP INDEX [CSX_LionSendOffers_All] ON [Email].[Newsletter_Offers]
					END

			

				INSERT INTO [Email].[Newsletter_Offers] (	[Email].[Newsletter_Offers].[LionSendID]
														,	[Email].[Newsletter_Offers].[EmailSendDate]
														,	[Email].[Newsletter_Offers].[CompositeID]
														,	[Email].[Newsletter_Offers].[FanID]
														,	[Email].[Newsletter_Offers].[TypeID]
														,	[Email].[Newsletter_Offers].[ItemID]
														,	[Email].[Newsletter_Offers].[OfferSlot])
				SELECT	#LionSend_Offers.[LionSendID]
					,	#LionSend_Offers.[EmailSendDate]
					,	#LionSend_Offers.[CompositeID]
					,	#LionSend_Offers.[FanID]
					,	#LionSend_Offers.[TypeID]
					,	#LionSend_Offers.[ItemID]
					,	#LionSend_Offers.[ItemRank]
				FROM #LionSend_Offers
			
				EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Loaded new rows to [Email].[Newsletter_Offers]'
		
				CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_LionSendOffers_All] ON [Email].[Newsletter_Offers] ([LionSendID], [EmailSendDate], [CompositeID], [FanID], [TypeID], [ItemID], [OfferSlot])
						
				EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Indexes recreated [Email].[Newsletter_Offers]'


		/***************************************************************************************************************************************
			2.2.	Fetch customer details
		***************************************************************************************************************************************/
	
				IF OBJECT_ID('tempdb..#LionSend_Customers') IS NOT NULL DROP TABLE #LionSend_Customers
				SELECT	DISTINCT
						ls.LionSendID
					,	ls.EmailSendDate
					,	ls.CompositeID
					,	cu.FanID
					,	cu.ClubID
					,	NULL AS CustomerSegment
				INTO #LionSend_Customers
				FROM #LionSend ls
				INNER JOIN [Derived].[Customer] cu
					ON ls.CompositeID = cu.CompositeID
				WHERE NOT EXISTS (	SELECT 1
									FROM [Email].[Newsletter_Customers] lsc
									WHERE ls.LionSendID = lsc.LionSendID
									AND ls.CompositeID = lsc.CompositeID)
			
				EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Fetch customer details'
				  
				IF INDEXPROPERTY(OBJECT_ID('[Email].[Newsletter_Customers]'), 'CSX_LionSendCustomers_All', 'IndexId') IS NOT NULL
					BEGIN
						DROP INDEX [CSX_LionSendCustomers_All] ON [Email].[Newsletter_Customers]
					END

				ALTER INDEX [IX_LionCampaignClubFan] ON [Email].[Newsletter_Customers] DISABLE

				-- Initial populatiON of tables

				INSERT INTO [Email].[Newsletter_Customers] ([Email].[Newsletter_Customers].[LionSendID]
														, [Email].[Newsletter_Customers].[EmailSendDate]
														, [Email].[Newsletter_Customers].[CompositeID]
														, [Email].[Newsletter_Customers].[FanID]
														, [Email].[Newsletter_Customers].[ClubID]
														, [Email].[Newsletter_Customers].[CustomerSegment])
				SELECT	#LionSend_Customers.[LionSendID]
					,	#LionSend_Customers.[EmailSendDate]
					,	#LionSend_Customers.[CompositeID]
					,	#LionSend_Customers.[FanID]
					,	#LionSend_Customers.[ClubID]
					,	#LionSend_Customers.[CustomerSegment]
				FROM #LionSend_Customers

				ALTER INDEX [IX_LionCampaignClubFan] ON [Email].[Newsletter_Customers] REBUILD WITH (SORT_IN_TEMPDB = ON)
			
				EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Loaded new rows to [Email].[Newsletter_Customers]'

				-- update campaign key info

				IF OBJECT_ID('tempdb..#EmailCampaign') IS NOT NULL DROP TABLE #EmailCampaign
				SELECT	ec.CampaignKey
					,	[ec].[CampaignName]
					,	[ec].[SendDate]
					,	166 AS ClubID
					 ,	NULL AS IsLoyalty
					 ,	CASE
							WHEN PATINDEX('%LSID%', [ec].[CampaignName]) > 0 THEN SUBSTRING([ec].[CampaignName], PATINDEX('%LSID%', [ec].[CampaignName]) + 4, 3)
							ELSE NULL
						END AS LionSendID
				INTO #EmailCampaign
				FROM [Derived].[EmailCampaign] ec
				WHERE [ec].[CampaignName] LIKE '%Newsletter_LSID[0-9][0-9][0-9]_[0-9]%'
				AND [ec].[CampaignName] NOT LIKE 'TEST%'

				UPDATE ls
				SET ls.CampaignKey = ec.CampaignKey
				FROM [Email].[Newsletter_Customers] ls
				INNER JOIN #EmailCampaign ec
					ON ls.LionSendID = ec.LionSendID
					--AND ls.IsLoyalty = ec.IsLoyalty
					AND ls.ClubID = ec.ClubID
				WHERE ls.CampaignKey IS NULL
	

				-- update sent & opened
	
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
				SET	[lsc].[EmailSent] = 1
				FROM [Email].[Newsletter_Customers] lsc
				INNER JOIN #EmailSent es
					ON lsc.CampaignKey = es.CampaignKey
					AND lsc.FanID = es.FanID
				WHERE EmailSent = 0
	
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
				SET	[lsc].[EmailOpened] = 1
				,	[lsc].[EmailOpenedDate] = [eo].[EventDate]
				FROM [Email].[Newsletter_Customers] lsc
				INNER JOIN #EmailOpens eo
					ON lsc.CampaignKey = eo.CampaignKey
					AND lsc.FanID = eo.FanID
				WHERE EmailOpened = 0
			
				EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Missing details updated [Email].[Newsletter_Customers]'
		
				CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_LionSendCustomers_All] ON [Email].[Newsletter_Customers] ([LionSendID], [EmailSendDate], [CampaignKey], [CompositeID], [FanID], [ClubID], [CustomerSegment], [EmailSent], [EmailOpened], [EmailOpenedDate])
			
				EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Indexes recreated on [Email].[Newsletter_Customers]'

			END	--	If NOT EXISTS (SELECT 1 FROM Lion.LionSend_Customers WHERE LionSendID = @LionSendID) AND @EmailSendDate Is NOT Null AND DateDiff(day, @EmailSendDate, Convert(Date, GetDate())) = 1
		
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