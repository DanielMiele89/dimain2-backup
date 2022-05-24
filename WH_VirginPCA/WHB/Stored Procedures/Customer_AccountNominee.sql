
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Review the contents of the latest Customer data to keep a log of whether a customer is a nominee on any of their accounts

--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Customer_AccountNominee] @RunDate DATE = NULL

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
			1.	Fetch customer Nominee status
		*******************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#Nominee') IS NOT NULL DROP TABLE #Nominee;
			SELECT	cu.FanID
				,	MAX(CASE
							WHEN ban.CustomerGUID IS NULL THEN 0
							ELSE 1
						END) AS IsNominee
			INTO #Nominee
			FROM [WHB].[Customer] cu
			LEFT JOIN [WHB].[Inbound_BankAccountNominees] ban
				ON cu.CustomerGUID = ban.CustomerGUID
				AND ban.EndDate IS NULL
			GROUP BY cu.FanID

		/*******************************************************************************************************************************************
			2.	EndDate entries that are no longer correct
		*******************************************************************************************************************************************/
		
			--DECLARE @RunDate DATE = GETDATE()
			DECLARE @EndDate DATE = DATEADD(DAY, -1, @RunDate)

			UPDATE an
			SET EndDate = @EndDate
			FROM [Derived].[Customer_AccountNominee] an
			WHERE an.EndDate IS NULL 
			AND NOT EXISTS (SELECT 1
							FROM #Nominee n
							WHERE an.FanID = n.FanID
							AND an.IsNominee = n.IsNominee)


		/*******************************************************************************************************************************************
			3.	Insert new entries for change in nominee status
		*******************************************************************************************************************************************/
			
			--DECLARE @RunDate DATE = GETDATE()

			INSERT INTO [Derived].[Customer_AccountNominee] (	FanID
															,	IsNominee
															,	StartDate
															,	EndDate)
			SELECT FanID
				 , IsNominee
				 , @RunDate AS StartDate
				 , NULL AS EndDate
			FROM #Nominee n
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_AccountNominee] an
								WHERE n.FanID = an.FanID
								AND an.EndDate IS NULL)

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
