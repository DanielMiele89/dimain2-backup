
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Record the Cashback balances a customer has each day
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Customer_CashbackBalances] @RunDate DATE = NULL

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
			1.	Fetch all cashback balances for all Virgin customers
		*******************************************************************************************************************************************/

			--DECLARE @RunDate DATE = GETDATE()

			IF OBJECT_ID('tempdb..#CashbackBalances') IS NOT NULL DROP TABLE #CashbackBalances
			SELECT	[WHB].[Customer].[FanID]
				,	[WHB].[Customer].[CashbackPending]
				,	[WHB].[Customer].[CashbackAvailable]
				,	[WHB].[Customer].[CashbackLTV]
				,	@RunDate AS Date
			INTO #CashbackBalances
			FROM [WHB].[Customer]

			CREATE CLUSTERED INDEX CIX_DateFanID ON #CashbackBalances (Date, FanID)


		/*******************************************************************************************************************************************
			2.	Insert the cashback data aas of run date to [Derived].[Customer_CashbackBalances]
		*******************************************************************************************************************************************/
		
			DELETE ccb
			FROM [Derived].[Customer_CashbackBalances] ccb
			WHERE EXISTS (	SELECT 1
							FROM #CashbackBalances cb
							WHERE cb.FanID = #CashbackBalances.[ccb].FanID
							AND cb.Date = #CashbackBalances.[ccb].Date)
		
			INSERT INTO [Derived].[Customer_CashbackBalances] (	[Derived].[Customer_CashbackBalances].[FanID]
															,	[Derived].[Customer_CashbackBalances].[CashbackPending]
															,	[Derived].[Customer_CashbackBalances].[CashbackAvailable]
															,	[Derived].[Customer_CashbackBalances].[CashbackLTV]
															,	[Derived].[Customer_CashbackBalances].[Date])
			SELECT	[cb].[FanID]
				,	[cb].[CashbackPending]
				,	[cb].[CashbackAvailable]
				,	[cb].[CashbackLTV]
				,	[cb].[Date]
			FROM #CashbackBalances cb
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_CashbackBalances] ccb
								WHERE cb.FanID = ccb.FanID
								AND cb.Date = ccb.Date)
			ORDER BY [cb].[CashbackAvailable] DESC

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