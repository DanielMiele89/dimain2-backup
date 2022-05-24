
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Take the staging table of the customer table that has been derived from the latest files & insert to permanent tables for use
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Customer_Customer]

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
			1.	Find the latest deactivation date for customers who are not currently active
		*******************************************************************************************************************************************/

			--IF OBJECT_ID('tempdb..#ActivationHistory') IS NOT NULL DROP TABLE #ActivationHistory;
			--WITH
			--CustomersCurrentlyActive AS (	SELECT FanID
			--								FROM [Derived].[Customer_ActivationHistory] ah
			--								WHERE ah.DeactivatedDate IS NULL)

			--SELECT FanID
			--	 , MAX(DeactivatedDate) AS DeactivatedDate
			--INTO #ActivationHistory
			--FROM [Derived].[Customer_ActivationHistory] ah
			--WHERE NOT EXISTS (	SELECT 1
			--					FROM CustomersCurrentlyActive cca
			--					WHERE ah.FanID = cca.FanID)
			--GROUP BY FanID
	
			--CREATE CLUSTERED INDEX CIX_FanID ON #ActivationHistory (FanID)


		/*******************************************************************************************************************************************
			2.	Replaced the [Derived].[Customer] with the new [WHB].[Customer]
		*******************************************************************************************************************************************/
		
			TRUNCATE TABLE [Derived].[Customer]
			INSERT INTO [Derived].[Customer] (	[Derived].[Customer].[FanID]
											,	[Derived].[Customer].[ClubID]
											,	[Derived].[Customer].[CompositeID]
											,	[Derived].[Customer].[SourceUID]
											,	[Derived].[Customer].[AccountType]
											,	[Derived].[Customer].[EmailStructureValid]
											,	[Derived].[Customer].[Title]
											,	[Derived].[Customer].[City]
											,	[Derived].[Customer].[County]
											,	[Derived].[Customer].[Region]
											,	[Derived].[Customer].[PostCodeDistrict]
											,	[Derived].[Customer].[PostArea]
											,	[Derived].[Customer].[PostalSector]
											,	[Derived].[Customer].[CAMEOCode]
											,	[Derived].[Customer].[AgeCurrent]
											,	[Derived].[Customer].[AgeCurrentBandText]
											,	[Derived].[Customer].[Gender]
											,	[Derived].[Customer].[CashbackAvailable]
											,	[Derived].[Customer].[CashbackPending]
											,	[Derived].[Customer].[CashbackLTV]
											,	[Derived].[Customer].[MarketableByEmail]
											,	[Derived].[Customer].[MarketableByPush]
											,	[Derived].[Customer].[CurrentlyActive]
											,	[Derived].[Customer].[Hardbounced]
											,	[Derived].[Customer].[Unsubscribed]
											,	[Derived].[Customer].[RegistrationDate]
											,	[Derived].[Customer].[DeactivatedDate])
			SELECT	[cu].[FanID]
				,	[cu].[ClubID]
				,	[cu].[CompositeID]
				,	[cu].[SourceUID]
				,	[cu].[AccountType]
				,	[cu].[EmailStructureValid]
				,	[cu].[Title]
				,	[cu].[City]
				,	[cu].[County]
				,	[cu].[Region]
				,	[cu].[PostCodeDistrict]
				,	[cu].[PostArea]
				,	[cu].[PostalSector]
				,	[cu].[CAMEOCode]
				,	[cu].[AgeCurrent]
				,	[cu].[AgeCurrentBandText]
				,	[cu].[Gender]
				,	[cu].[CashbackAvailable]
				,	[cu].[CashbackPending]
				,	[cu].[CashbackLTV]
				,	[cu].[MarketableByEmail]
				,	[cu].[MarketableByPush]
				,	[cu].[CurrentlyActive]
				,	[cu].[Hardbounced]
				,	[cu].[Unsubscribed]
				,	[cu].[RegistrationDate]
				,	COALESCE([cu].[DeactivatedDate], [cu].[ClosedDate]) AS DeactivatedDate
			FROM [WHB].[Customer] cu
		
			TRUNCATE TABLE [Derived].[Customer_PII]
			INSERT INTO [Derived].[Customer_PII] (	[Derived].[Customer_PII].[FanID]
												,	[Derived].[Customer_PII].[ClubID]
												,	[Derived].[Customer_PII].[CompositeID]
												,	[Derived].[Customer_PII].[SourceUID]
												,	[Derived].[Customer_PII].[Email]
												,	[Derived].[Customer_PII].[MobileTelephone]
												,	[Derived].[Customer_PII].[FirstName]
												,	[Derived].[Customer_PII].[LastName]
												,	[Derived].[Customer_PII].[Address1]
												,	[Derived].[Customer_PII].[Address2]
												,	[Derived].[Customer_PII].[Postcode]
												,	[Derived].[Customer_PII].[DOB])
			SELECT	[cu].[FanID]
				,	[cu].[ClubID]
				,	[cu].[CompositeID]
				,	[cu].[SourceUID]
				,	[cu].[Email]
				,	[cu].[MobileTelephone]
				,	[cu].[FirstName]
				,	[cu].[LastName]
				,	[cu].[Address1]
				,	[cu].[Address2]
				,	[cu].[PostCode]
				,	[cu].[DOB]
			FROM [WHB].[Customer] cu

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