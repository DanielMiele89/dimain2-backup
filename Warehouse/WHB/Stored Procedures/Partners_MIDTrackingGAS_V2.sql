
/*
Author:		Rory Francis
Date:		9 June 2018
Purpose:	Maintain table used to keep track of MIDs being incentivised on MyRewards

Notes:		
*/

CREATE PROCEDURE [WHB].[Partners_MIDTrackingGAS_V2]
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

		BEGIN TRY

		/*******************************************************************************************************************************************
				1.	Write entry to JobLog Temp table
		*******************************************************************************************************************************************/

			INSERT INTO [Staging].[JobLog_temp]
			SELECT	StoredProcedureName = OBJECT_NAME(@@PROCID)
				,	TableSchemaName = 'Relational'
				,	TableName = 'MIDTrackingGAS_V2'
				,	StartDate = GETDATE()
				,	EndDate = NULL
				,	TableRowCount  = NULL
				,	AppendReload = 'U'

		/*******************************************************************************************************************************************
				2.	Fetch all entries from RetailOutlet
		*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet;
			SELECT	ro.ID AS RetailOutletID
				,	ro.MerchantID AS MerchantID
				,	ro.PartnerID
			INTO #RetailOutlet
			FROM [SLC_REPL].[dbo].[RetailOutlet] ro

		/*******************************************************************************************************************************************
				3.	Update EndDate for existing entries where the MerchantID has been updated
		*******************************************************************************************************************************************/
	
			DECLARE @EndDate DATE = DATEADD(DAY, -1, GETDATE())

			UPDATE mtg
			SET mtg.EndDate = @EndDate
			FROM [Relational].[MIDTrackingGAS_V2] mtg
			INNER JOIN #RetailOutlet ro
				ON mtg.RetailOutletID = ro.RetailOutletID
				AND mtg.MerchantID != ro.MerchantID
			WHERE mtg.EndDate IS NULL

		/*******************************************************************************************************************************************
				4.	Insert new entries for new or updated MIDs
		*******************************************************************************************************************************************/
	
			DECLARE @StartDate DATE = GETDATE()

			INSERT INTO [Relational].[MIDTrackingGAS_V2]
			SELECT	PartnerID
				,	RetailOutletID
				,	MerchantID
				,	@StartDate AS StartDate
				,	NULL AS EndDate
			FROM #RetailOutlet ro
			WHERE NOT EXISTS (	SELECT 1
								FROM [Relational].[MIDTrackingGAS_V2] mtg
								WHERE ro.RetailOutletID = mtg.RetailOutletID
								AND mtg.EndDate IS NULL)

		/*******************************************************************************************************************************************
				5.	Update entry in JobLog Temp table with EndDate & RowCount
		*******************************************************************************************************************************************/

			UPDATE [Staging].[JobLog_temp]
			SET EndDate = GETDATE()
			WHERE StoredProcedureName = OBJECT_NAME(@@PROCID)
			AND TableSchemaName = 'Relational'
			AND TableName = 'MIDTrackingGAS_V2'
			AND EndDate IS NULL

			UPDATE [Staging].[JobLog_temp]
			SET TableRowCount = (Select COUNT(*) from Relational.MIDTrackingGAS)
			WHERE StoredProcedureName = OBJECT_NAME(@@PROCID)
			AND TableSchemaName = 'Relational'
			AND TableName = 'MIDTrackingGAS_V2'
			AND TableRowCount IS NULL

		/*******************************************************************************************************************************************
				6.	Insert entry to JobLog table
		*******************************************************************************************************************************************/
	
			INSERT INTO [Staging].[JobLog]
			SELECT	StoredProcedureName
				,	TableSchemaName
				,	TableName
				,	StartDate
				,	EndDate
				,	TableRowCount
				,	AppendReload
			FROM [Staging].[JobLog_temp]

			TRUNCATE TABLE [Staging].[JobLog_temp]

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
		INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
		VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
		SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
		RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
		RETURN -1;
	END CATCH

	RETURN 0; -- should never run

END