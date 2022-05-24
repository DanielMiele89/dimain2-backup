-- =============================================
--	Author:		
--	Create date: 
--	Description:	

--	Updates:
-- =============================================

CREATE PROCEDURE [WHB].[Inbound_FilesToProcess]

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
			1.	Fetch all the files & load datetimes for each of the tables in the Inbound Schema
		*******************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#InboundTables') IS NOT NULL DROP TABLE #InboundTables;
			SELECT	ROW_NUMBER() OVER (ORDER BY t.name) AS RowID
				,	t.name AS TableName
				,	'WH_Virgin.' + s.name + '.' + t.name AS SourceTable
			INTO #InboundTables
			FROM [sys].[tables] t
			INNER JOIN [sys].[schemas] s
				ON t.schema_id = s.schema_id
			WHERE s.name = 'Inbound'
			AND t.name IN ('Accounts', 'Balances', 'Cards', 'Customers', 'Redemptions', 'Goodwill', 'Login')

			DECLARE @RowID INT = 1
				,	@TableName VARCHAR(MAX)
				,	@SourceTable VARCHAR(MAX)

			WHILE 1 = 1
				BEGIN
					
					IF NOT EXISTS (SELECT 1 FROM #InboundTables WHERE @RowID = RowID)
						BREAK

					SELECT	@TableName = TableName
						,	@SourceTable = SourceTable
					FROM #InboundTables
					WHERE RowID = @RowID

					SET @Query = '	
									INSERT INTO [WHB].[Inbound_Files]
									SELECT	DISTINCT	
											''' + @TableName + '''
										,	LoadDate
										,	FileName
										,	0
									FROM ' + @SourceTable + ' st
									WHERE NOT EXISTS (	SELECT 1
														FROM [WHB].[Inbound_Files] f
														WHERE st.FileName = f.FileName
														AND st.LoadDate = f.LoadDate
														AND f.TableName = ''' + @TableName + ''')
									ORDER BY	FileName
											,	LoadDate'
					EXEC(@Query)

					SET @RowID = @RowID + 1

				END

			INSERT INTO [WHB].[Inbound_Files]
			SELECT	DISTINCT	
					TableName = 'Transactions'
				,	LoadDate = CONVERT(DATE, st.LoadDate)
				,	FileName
				,	FileProcessed = 0
			FROM [Inbound].[Transactions] st
			WHERE NOT EXISTS (	SELECT 1
								FROM [WHB].[Inbound_Files] f
								WHERE st.FileName = f.FileName
								AND CONVERT(DATE, st.LoadDate) = CONVERT(DATE, f.LoadDate)
								AND f.TableName = 'Transactions')
			ORDER BY	FileName
					,	LoadDate

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