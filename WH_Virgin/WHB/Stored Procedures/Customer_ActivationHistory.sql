
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Record customer deactivations and actications / reactivations
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Customer_ActivationHistory] @RunDate DATE = NULL

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
			1.	Fetch all customers current status
		*******************************************************************************************************************************************/
			   
			IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
			SELECT	[cu].[FanID]
				,	[cu].[RegistrationDate]
				,	[cu].[DeactivatedDate]
				,	[cu].[ClosedDate]
			INTO #Customer
			FROM [WHB].[Customer] cu

			CREATE CLUSTERED INDEX CIX_FanID ON #Customer (FanID)


		/*******************************************************************************************************************************************
			2.	Update Registration Dates of all accounts in [Derived].[Customer_ActivationHistory]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[Customer_ActivationHistory] ([Derived].[Customer_ActivationHistory].[FanID]
															  ,	[Derived].[Customer_ActivationHistory].[ActionDate]
															  , [Derived].[Customer_ActivationHistory].[ActionType])
			SELECT	[cu].[FanID]
				,	[cu].[RegistrationDate]
				,	'Registration' AS ActionType
			FROM #Customer cu
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_ActivationHistory] ah
								WHERE cu.FanID = ah.FanID
								AND cu.RegistrationDate = ah.ActionDate)


		/*******************************************************************************************************************************************
			3.	Update Deactivated Dates of all accounts in [Derived].[Customer_ActivationHistory]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[Customer_ActivationHistory] ([Derived].[Customer_ActivationHistory].[FanID]
															  ,	[Derived].[Customer_ActivationHistory].[ActionDate]
															  , [Derived].[Customer_ActivationHistory].[ActionType])
			SELECT	[cu].[FanID]
				,	[cu].[DeactivatedDate]
				,	'Deactivated' AS ActionType
			FROM #Customer cu
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_ActivationHistory] ah
								WHERE cu.FanID = ah.FanID
								AND cu.DeactivatedDate = ah.ActionDate)
			AND [cu].[DeactivatedDate] IS NOT NULL


		/*******************************************************************************************************************************************
			4.	Update Closed Dates of all accounts in [Derived].[Customer_ActivationHistory]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[Customer_ActivationHistory] ([Derived].[Customer_ActivationHistory].[FanID]
															  ,	[Derived].[Customer_ActivationHistory].[ActionDate]
															  , [Derived].[Customer_ActivationHistory].[ActionType])
			SELECT	[cu].[FanID]
				,	[cu].[ClosedDate]
				,	'Closed' AS ActionType
			FROM #Customer cu
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_ActivationHistory] ah
								WHERE cu.FanID = ah.FanID
								AND cu.ClosedDate = ah.ActionDate)
			AND [cu].[ClosedDate] IS NOT NULL


		/*******************************************************************************************************************************************
			5.	Update Reactivation Dates of all accounts in [Derived].[Customer_ActivationHistory]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[Customer_ActivationHistory] ([Derived].[Customer_ActivationHistory].[FanID]
															  ,	[Derived].[Customer_ActivationHistory].[ActionDate]
															  , [Derived].[Customer_ActivationHistory].[ActionType])
			SELECT	[cu].[FanID]
				,	[cu].[RegistrationDate]
				,	'Reactivation' AS ActionType
			FROM #Customer cu
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_ActivationHistory] ah
								WHERE cu.FanID = ah.FanID
								AND cu.RegistrationDate = ah.ActionDate)
			AND EXISTS (SELECT 1
						FROM [Derived].[Customer_ActivationHistory] ah
						WHERE cu.FanID = ah.FanID
						AND (	cu.ClosedDate IS NOT NULL
							OR	cu.DeactivatedDate IS NOT NULL))

			
			IF OBJECT_ID('tempdb..#Customer_ActivationHistory') IS NOT NULL DROP TABLE #Customer_ActivationHistory
			SELECT	[Derived].[Customer_ActivationHistory].[FanID]
				,	[Derived].[Customer_ActivationHistory].[ActionType]
				,	[Derived].[Customer_ActivationHistory].[ActionDate]
				,	ROW_NUMBER() OVER (PARTITION BY [Derived].[Customer_ActivationHistory].[FanID] ORDER BY [Derived].[Customer_ActivationHistory].[ActionDate] DESC) AS ActionRank
			INTO #Customer_ActivationHistory
			FROM [Derived].[Customer_ActivationHistory]
			
			--DECLARE @RunDate DATE = GETDATE()

			INSERT INTO [Derived].[Customer_ActivationHistory] ([Derived].[Customer_ActivationHistory].[FanID]
															  ,	[Derived].[Customer_ActivationHistory].[ActionDate]
															  , [Derived].[Customer_ActivationHistory].[ActionType])
			SELECT	[cu].[FanID]
				,	@RunDate
				,	'Reactivation' AS ActionType
			FROM #Customer cu
			WHERE EXISTS (	SELECT 1
							FROM #Customer_ActivationHistory ah
							WHERE #Customer_ActivationHistory.[cu].FanID = ah.FanID
							AND ah.ActionRank = 1
							AND ah.ActionType IN ('Deactivated'))
			AND [cu].[DeactivatedDate] IS NULL

			INSERT INTO [Derived].[Customer_ActivationHistory] ([Derived].[Customer_ActivationHistory].[FanID]
															  ,	[Derived].[Customer_ActivationHistory].[ActionDate]
															  , [Derived].[Customer_ActivationHistory].[ActionType])
			SELECT	[cu].[FanID]
				,	@RunDate
				,	'Reactivation' AS ActionType
			FROM #Customer cu
			WHERE EXISTS (	SELECT 1
							FROM #Customer_ActivationHistory ah
							WHERE #Customer_ActivationHistory.[cu].FanID = ah.FanID
							AND ah.ActionRank = 1
							AND ah.ActionType IN ('Closed'))
			AND [cu].[ClosedDate] IS NULL
	
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