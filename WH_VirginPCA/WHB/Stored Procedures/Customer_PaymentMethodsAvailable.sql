
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Log the type of cards that customers have open, at launch Virgin program only has Credit cards, flags are hardcoded due to this as not enough data was available to code
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Customer_PaymentMethodsAvailable] @RunDate DATE = NULL

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
			1. Fetch the different types of bank card that each customer currently has
		*******************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#PaymentMethodsAvailable') IS NOT NULL DROP TABLE #PaymentMethodsAvailable;
			WITH
			CardTypes AS (	SELECT	FanID
								,	MAX(0) AS IsDebit
								,	MAX(1) AS IsCredit
							FROM [WHB].[Customer] cu
							LEFT JOIN [WHB].[Inbound_Cards] ca
								ON cu.CustomerGUID = ca.PrimaryCustomerGUID
							GROUP BY FanID)
		
			SELECT FanID
				 , CASE
						WHEN IsDebit = 1 AND IsCredit = 0 THEN 0	--	Debit Only
						WHEN IsDebit = 0 AND IsCredit = 1 THEN 1	--	Credit Only
						WHEN IsDebit = 1 AND IsCredit = 1 THEN 2	--	Both Debit & Credit
						WHEN IsDebit = 0 AND IsCredit = 0 THEN 3	--	No Active Cards
				   END AS PaymentMethodsAvailableID
			INTO #PaymentMethodsAvailable
			FROM CardTypes

			CREATE CLUSTERED INDEX CIX_FanID ON #PaymentMethodsAvailable (FanID)

		/*******************************************************************************************************************************************
			2. For customers who have had a change in the bank cards they hold, update [Derived].[Customer_PaymentMethodsAvailable]
		*******************************************************************************************************************************************/

			--DECLARE @RunDate DATE = GETDATE()
			DECLARE @EndDate DATE = DATEADD(DAY, -1, @RunDate)

			UPDATE cpma
			SET cpma.EndDate = @EndDate
			FROM [Derived].[Customer_PaymentMethodsAvailable] cpma
			WHERE cpma.EndDate IS NULL
			AND NOT EXISTS (SELECT 1
							FROM #PaymentMethodsAvailable pma
							WHERE pma.FanID = cpma.FanID
							AND pma.PaymentMethodsAvailableID = cpma.PaymentMethodsAvailableID)
								

		/*******************************************************************************************************************************************
			3. For new customers or customers who have had a change in the bank cards they hold, insert to [Derived].[Customer_PaymentMethodsAvailable]
		*******************************************************************************************************************************************/
		
			--DECLARE @RunDate DATE = GETDATE()

			INSERT INTO [Derived].[Customer_PaymentMethodsAvailable] (	FanID
																	,	PaymentMethodsAvailableID
																	,	StartDate
																	,	EndDate)
			SELECT FanID
				 , PaymentMethodsAvailableID
				 , @RunDate AS StartDate
				 , NULL AS EndDate
			FROM #PaymentMethodsAvailable pma
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_PaymentMethodsAvailable] cpma
								WHERE pma.FanID = cpma.FanID
								AND cpma.EndDate IS NULL)

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
