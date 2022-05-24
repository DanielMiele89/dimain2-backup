
CREATE PROCEDURE [WHB].[Redemptions_Redemptions]
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
			1.		Find latest redemption files
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#FilesToProcess') IS NOT NULL DROP TABLE #FilesToProcess
		SELECT *
		INTO #FilesToProcess
		FROM [WHB].[Inbound_Files]
		WHERE TableName = 'Redemptions'
		AND FileProcessed = 0

	/*******************************************************************************************************************************************
			2.		Fetch latest redemptions
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL DROP TABLE #Redemptions
		SELECT *
		INTO #Redemptions
		FROM [Inbound].[Redemptions] re
		WHERE EXISTS (	SELECT 1
						FROM #FilesToProcess ftp
						WHERE re.FileName = ftp.FileName
						AND re.LoadDate = ftp.LoadDate)


	/*******************************************************************************************************************************************
			3.		Transfom latest redemptions
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#ToInsert') IS NOT NULL DROP TABLE #ToInsert
		SELECT	cu.FanID
			,	re.RedemptionType
			,	re.Amount AS RedemptionAmount
			,	re.RedemptionDate
			,	0 AS Cancelled
			,	ftp.ID AS FileID
			,	ftp.FileName
			,	ftp.LoadDate
		INTO #ToInsert
		FROM #Redemptions re
		INNER JOIN [Derived].[Customer] cu
			ON re.CustomerID = cu.FanID
		INNER JOIN #FilesToProcess ftp
			ON re.FileName = ftp.FileName
			AND re.LoadDate = ftp.LoadDate

		CREATE CLUSTERED INDEX CIX_FileFanDate ON #ToInsert (FileID, FanID, RedemptionDate)

	/*******************************************************************************************************************************************
			4.		Insert to [Derived].[Redemptions]
	*******************************************************************************************************************************************/
	
		INSERT INTO [Derived].[Redemptions]
		SELECT	FanID
			,	CASE
					WHEN RedemptionType = 'B'
						THEN 'Bank'
					WHEN RedemptionType = 'C'
						THEN 'Credit'
				END AS RedemptionType
			,	RedemptionAmount
			,	RedemptionDate
			,	Cancelled
			,	FileID
			,	FileName
			,	LoadDate
		FROM #ToInsert ti
		WHERE NOT EXISTS (	SELECT 1
							FROM [Derived].[Redemptions] r
							WHERE ti.FileID = r.FileID
							AND ti.FanID = r.FanID
							AND ti.RedemptionDate = r.RedemptionDate)

		-- log it
		SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Derived].[Redemptions] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
		EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, @msg

	/*******************************************************************************************************************************************
			5.		Set Files to Processed
	*******************************************************************************************************************************************/

		UPDATE inf
		SET FileProcessed = 1
		FROM [WHB].[Inbound_Files] inf
		WHERE EXISTS (	SELECT 1
						FROM #FilesToProcess ftp
						WHERE inf.ID = ftp.ID
						AND inf.LoadDate = ftp.LoadDate)


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