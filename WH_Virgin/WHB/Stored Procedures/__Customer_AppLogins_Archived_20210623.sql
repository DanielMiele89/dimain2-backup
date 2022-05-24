
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Fetch the latest App Login data, at launch, this info was not available for Virgin customers
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[__Customer_AppLogins_Archived_20210623]

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
			1. Fetch the latest date that events have been loaded
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#FilesToProcess') IS NOT NULL DROP TABLE #FilesToProcess
			SELECT	[f].[ID] AS FileID
				,	[f].[LoadDate]
				,	[f].[FileName]
			INTO #FilesToProcess
			FROM [WHB].[Inbound_Files] f
			WHERE [f].[TableName] = 'Login'
			AND [f].[FileProcessed] = 0
			ORDER BY [f].[ID]

		/*******************************************************************************************************************************************
			2. Fetch all events that have occured since the last run
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#TrackingData') IS NOT NULL DROP TABLE #TrackingData
			SELECT	[td].[CustomerID] AS FanID
				,	[td].[LoginDateTime] AS TrackDate
				,	0 AS TrackTypeID
				,	[td].[LoginInformation] AS FanData
			INTO #TrackingData
			FROM [Inbound].[Login] td
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE #FilesToProcess.[td].FileName = ftp.FileName
							AND #FilesToProcess.[td].LoadDate = ftp.LoadDate)
			AND EXISTS (SELECT 1
						FROM [WHB].[Customer] cu
						WHERE td.CustomerID = cu.FanID)

			CREATE CLUSTERED INDEX CIX_FanTypeDate ON #TrackingData (FanID, TrackTypeID, TrackDate, FanData)

		/*******************************************************************************************************************************************
			3. Insert all events that do not currently exist in [Derived].[AppLogins]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[AppLogins] (	[Derived].[AppLogins].[FanID]
											,	[Derived].[AppLogins].[TrackTypeID]
											,	[Derived].[AppLogins].[TrackDate]
											,	[Derived].[AppLogins].[FanData])
			SELECT	[td].[FanID]
				,	[td].[TrackTypeID]
				,	[td].[TrackDate]
				,	[td].[FanData]
			FROM #TrackingData td
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[AppLogins] al
								WHERE td.FanID = al.FanID
								AND td.TrackTypeID = al.TrackTypeID
								AND td.TrackDate = al.TrackDate
								AND td.FanData = al.FanData)


		/*******************************************************************************************************************************************
			4. Mark the file as Processed
		*******************************************************************************************************************************************/

			UPDATE f
			SET [f].[FileProcessed] = 1
			FROM [WHB].[Inbound_Files] f
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE #FilesToProcess.[f].ID = ftp.FileID
							AND #FilesToProcess.[f].LoadDate = ftp.LoadDate)
	
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