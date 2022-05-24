
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Fetch the latest Goodwill data
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Customer_GoodwillAdjustments]

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
			WHERE [f].[TableName] = 'Goodwill'
			AND [f].[FileProcessed] = 0
			ORDER BY [f].[ID]

		/*******************************************************************************************************************************************
			2. Fetch all events that have occured since the last run
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#GoodwillData') IS NOT NULL DROP TABLE #GoodwillData
			SELECT	[td].[CustomerID] AS FanID
				,	[td].[GoodwillAmount]
				,	[td].[GoodwillDateTime]
				,	[td].[GoodwillType]
				,	[td].[LoadDate] AS AddedDate
			INTO #GoodwillData
			FROM [Inbound].[Goodwill] td
			WHERE EXISTS (	SELECT 1
							FROM #FilesToProcess ftp
							WHERE #FilesToProcess.[td].FileName = ftp.FileName
							AND #FilesToProcess.[td].LoadDate = ftp.LoadDate)

			CREATE CLUSTERED INDEX CIX_GoodwillDateTime ON #GoodwillData (GoodwillDateTime)

		/*******************************************************************************************************************************************
			3. Insert all GoodwillTypes that do not currently exist in [Derived].[GoodwillTypes]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[GoodwillTypes]
			SELECT	DISTINCT
					[gwd].[GoodwillType]
			FROM #GoodwillData gwd
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[GoodwillTypes] gwt
								WHERE gwd.GoodwillType = gwt.GoodwillType)

		/*******************************************************************************************************************************************
			3. Insert all events that do not currently exist in [Derived].[AppLogins]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[BalanceAdjustments_Goodwill] (	[Derived].[BalanceAdjustments_Goodwill].[FanID]
																,	[Derived].[BalanceAdjustments_Goodwill].[GoodwillAmount]
																,	[Derived].[BalanceAdjustments_Goodwill].[GoodwillDateTime]
																,	[Derived].[BalanceAdjustments_Goodwill].[GoodwillTypeID]
																,	[Derived].[BalanceAdjustments_Goodwill].[AddedDate])
			SELECT	gwd.FanID
				,	gwd.GoodwillAmount
				,	gwd.GoodwillDateTime
				,	gwt.GoodwillTypeID
				,	gwd.AddedDate
			FROM #GoodwillData gwd
			INNER JOIN [Derived].[GoodwillTypes] gwt
				ON gwd.GoodwillType = gwt.GoodwillType
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[BalanceAdjustments_Goodwill] bag
								WHERE gwd.FanID = bag.FanID
								AND gwd.GoodwillAmount = bag.GoodwillAmount
								AND gwd.GoodwillDateTime = bag.GoodwillDateTime)


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