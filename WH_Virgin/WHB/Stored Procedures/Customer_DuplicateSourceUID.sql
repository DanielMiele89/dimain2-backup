
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Keep a log of any duplicated customer IDs we receive from a publisher
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Customer_DuplicateSourceUID] @RunDate DATE = NULL

AS
BEGIN

	SET @RunDate = COALESCE(@RunDate, GETDATE())

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
			1.	Fetch all customer entries where the same Source UID is used agross different customers within Virgin
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Duplicates') IS NOT NULL DROP TABLE #Duplicates
			SELECT	[WHB].[Customer].[SourceUID]
			INTO #Duplicates
			FROM [WHB].[Customer]
			GROUP BY	[WHB].[Customer].[SourceUID]
			HAVING COUNT(*) > 1

			CREATE CLUSTERED INDEX CIX_SourceUID ON #Duplicates (SourceUID)


		/*******************************************************************************************************************************************
			2.	Insert any new duplicated Source UIDs to [Derived].[Customer_DuplicateSourceUID]
		*******************************************************************************************************************************************/
		
			--DECLARE @RunDate DATE = GETDATE()

			INSERT INTO [Derived].[Customer_DuplicateSourceUID] ([Derived].[Customer_DuplicateSourceUID].[SourceUID]
															   , [Derived].[Customer_DuplicateSourceUID].[StartDate]
															   , [Derived].[Customer_DuplicateSourceUID].[EndDate])
			SELECT	dup.SourceUID
				,	@RunDate AS StartDate
				,	NULL AS EndDate
			FROM #Duplicates dup
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_DuplicateSourceUID] dsu
								WHERE dup.SourceUID = dsu.SourceUID
								AND dsu.EndDate IS NULL)


		/*******************************************************************************************************************************************
			3.	Find all open entries from [Derived].[Customer_DuplicateSourceUID] where SourceUID is no longer duplicated
		*******************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#NoLongerDuplicated') IS NOT NULL DROP TABLE #NoLongerDuplicated
			SELECT	dsu.ID
				,	dsu.SourceUID
			INTO #NoLongerDuplicated
			FROM [Derived].[Customer_DuplicateSourceUID] dsu
			WHERE dsu.EndDate IS NULL
			AND NOT EXISTS (	SELECT 1
								FROM #Duplicates dup
								WHERE #Duplicates.[dsu].SourceUID = dup.SourceUID)

			CREATE CLUSTERED INDEX CIX_ID ON #NoLongerDuplicated (ID)


		/*******************************************************************************************************************************************
			4.	EndDate all entries from [Derived].[Customer_DuplicateSourceUID] where SourceUID is no longer duplicated
		*******************************************************************************************************************************************/
		
			DECLARE @EndDate DATE = DATEADD(DAY, -1, @RunDate)

			UPDATE dsu
			SET [dsu].[EndDate] = @EndDate
			FROM [Derived].[Customer_DuplicateSourceUID] dsu
			WHERE EXISTS (	SELECT 1
							FROM #NoLongerDuplicated nld
							WHERE #NoLongerDuplicated.[dsu].ID = nld.ID)

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