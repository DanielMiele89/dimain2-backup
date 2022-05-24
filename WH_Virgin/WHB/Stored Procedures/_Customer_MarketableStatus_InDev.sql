
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Record any changes in the contributing flags that determine whether or not we can market to a customer through emails
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[_Customer_MarketableStatus_InDev] @RunDate DATE = NULL

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
			1. Fetch all customer information where there has been a change in status from the previous day
		*******************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
			SELECT	[cus].[FanID]
				,	[cus].[CurrentlyActive]
				,	[cus].[Hardbounced]
				,	[cus].[Unsubscribed]
				,	[cus].[MarketableByEmail]
				,	[cus].[MarketableByPush]
			INTO #Customer
			FROM [WHB].[Customer] cus
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer] cud
								WHERE cus.FanID = cud.FanID
								AND cus.CurrentlyActive = cud.CurrentlyActive
								AND cus.Hardbounced = cud.Hardbounced
								AND cus.Unsubscribed = cud.Unsubscribed
								AND cus.MarketableByEmail = cud.MarketableByEmail
								AND cus.MarketableByPush = cud.MarketableByPush)

			CREATE CLUSTERED INDEX CIX_FanID ON #Customer (FanID)


		/*******************************************************************************************************************************************
			2. For customers who have had a change in status, update [Derived].[Customer_MarketableByEmailStatus]
		*******************************************************************************************************************************************/
		
			--DECLARE @RunDate DATE = GETDATE()
			DECLARE @EndDate DATE = DATEADD(DAY, -1, @RunDate)

			UPDATE mesd
			SET mesd.EndDate = @EndDate
			FROM [Derived].[Customer_MarketableStatus] mesd
			WHERE mesd.EndDate IS NULL
			AND EXISTS (SELECT 1
						FROM #Customer cu
						WHERE #Customer.[mesd].FanID = cu.FanID)
			AND NOT EXISTS (SELECT 1
							FROM #Customer cu
							WHERE #Customer.[mesd].FanID = cu.FanID
							AND cu.Unsubscribed = #Customer.[mesd].Unsubscribed
							AND cu.CurrentlyActive = #Customer.[mesd].CurrentlyActive
							AND cu.Hardbounced = #Customer.[mesd].Hardbounced
							AND cu.MarketableByEmail = #Customer.[mesd].MarketableByEmail
							AND cu.MarketableByPush = #Customer.[mesd].MarketableByPush)


		/*******************************************************************************************************************************************
			3. For new customers or customers who have had a change in status, insert to [Derived].[Customer_MarketableByEmailStatus]
		*******************************************************************************************************************************************/

			--DECLARE @RunDate DATE = GETDATE()

			INSERT INTO [Derived].[Customer_MarketableStatus] (	[Derived].[Customer_MarketableStatus].[FanID]
															,	[Derived].[Customer_MarketableStatus].[CurrentlyActive]
															,	[Derived].[Customer_MarketableStatus].[Hardbounced]
															,	[Derived].[Customer_MarketableStatus].[Unsubscribed]
															,	[Derived].[Customer_MarketableStatus].[MarketableByEmail]
															,	[Derived].[Customer_MarketableStatus].[MarketableByPush]
															,	[Derived].[Customer_MarketableStatus].[StartDate]
															,	[Derived].[Customer_MarketableStatus].[EndDate])
			SELECT	[cu].[FanID]
				,	[cu].[CurrentlyActive]
				,	[cu].[Hardbounced]
				,	[cu].[Unsubscribed]
				,	[cu].[MarketableByEmail]
				,	[cu].[MarketableByPush]
				,	@RunDate AS StartDate
				,	NULL AS EndDate
			FROM #Customer cu
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_MarketableStatus] mesd
								WHERE cu.FanID = #Customer.[mesd].FanID
								AND #Customer.[mesd].EndDate IS NULL)

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