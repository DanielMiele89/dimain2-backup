
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Fetch the latest App Login data, at launch, this info was not available for Virgin customers
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[__Customer_AppLogins_Archived]

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
			SELECT	ID AS FileID
				,	LoadDate
				,	FileName
			INTO #FilesToProcess
			FROM [WHB].[Inbound_Files] f
			WHERE TableName = 'Login'
			AND FileProcessed = 0
			ORDER BY ID

		/*******************************************************************************************************************************************
			2. Fetch all events that have occured since the last run
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Customer_LookupFanID') IS NOT NULL DROP TABLE #Customer_LookupFanID
			SELECT	DISTINCT
					CustomerID AS CustomerGUID
				,	FanID
			INTO #Customer_LookupFanID
			FROM [WH_AllPublishers].[Derived].[CustomerIDs] ci
			WHERE ci.CustomerIDTypeID = 2
			AND ci.PublisherID = 180

			IF OBJECT_ID('tempdb..#TrackingData') IS NOT NULL DROP TABLE #TrackingData
			SELECT	clu.FanID
				,	LoginDateTime AS TrackDate
				,	0 AS TrackTypeID
				,	REPLACE(LoginInformation, '"', '') AS FanData
			INTO #TrackingData
			FROM [Inbound].[Login] td
			INNER JOIN #Customer_LookupFanID clu
				ON td.CustomerGUID = clu.CustomerGUID
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE td.FileName = ftp.FileName
							AND td.LoadDate = ftp.LoadDate)
			AND EXISTS (SELECT 1
						FROM [WHB].[Customer] cu
						WHERE clu.FanID = cu.FanID)

			CREATE CLUSTERED INDEX CIX_FanTypeDate ON #TrackingData (FanID, TrackTypeID, TrackDate, FanData)

		/*******************************************************************************************************************************************
			3. Insert all events that do not currently exist in [Derived].[AppLogins]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[AppLogins] (	FanID
											,	TrackTypeID
											,	TrackDate
											,	FanData)
			SELECT	FanID
				,	TrackTypeID
				,	TrackDate
				,	FanData
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
			SET FileProcessed = 1
			FROM [WHB].[Inbound_Files] f
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE f.ID = ftp.FileID
							AND f.LoadDate = ftp.LoadDate)
	
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
