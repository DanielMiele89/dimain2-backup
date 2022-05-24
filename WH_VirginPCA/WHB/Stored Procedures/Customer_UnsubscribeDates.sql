
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Record the dates at which point a customer either unsubsribes from marketing from either the client App or through an email event
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Customer_UnsubscribeDates] @RunDate DATE = NULL

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
			1.	Fetch all customers who have Unsubscribed via links in their email
		*******************************************************************************************************************************************/
		
			DECLARE @MaxUnsubscribeDate_Email DATE = (SELECT MAX(UnsubscribeDate) FROM [Derived].[Customer_UnsubscribeDates] WHERE UnsubscribeType = 'Email')

			IF OBJECT_ID('tempdb..#EmailUnsubscribed') IS NOT NULL DROP TABLE #EmailUnsubscribed
			SELECT	FanID
				,	EventDate AS UnsubscribeDate
				,	'Email' AS UnsubscribeType
				,	CampaignKey
			INTO #EmailUnsubscribed
			FROM [Derived].[EmailEvent] ee
			WHERE ee.EmailEventCodeID = 301
			AND ee.EventDate > @MaxUnsubscribeDate_Email
			AND EXISTS (	SELECT 1
							FROM [WHB].[Customer] c
							WHERE ee.FanID = c.FanID)

			CREATE CLUSTERED INDEX CIX_FanIDDateCampaignKey ON #EmailUnsubscribed (FanID, UnsubscribeDate, UnsubscribeType, CampaignKey)


		/*******************************************************************************************************************************************
			2.	Insert all customers who have Unsubscribed via links in their email to [Derived].[Customer_UnsubscribeDates]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[Customer_UnsubscribeDates] (FanID
															 , UnsubscribeDate
															 , UnsubscribeType
															 , CampaignKey)
			SELECT	FanID
				,	UnsubscribeDate
				,	UnsubscribeType
				,	CampaignKey
			FROM #EmailUnsubscribed eu
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_UnsubscribeDates] ud
								WHERE eu.FanID = ud.FanID
								AND eu.UnsubscribeDate = ud.UnsubscribeDate
								AND eu.UnsubscribeType = ud.UnsubscribeType
								AND eu.CampaignKey = ud.CampaignKey)


		/*******************************************************************************************************************************************
			3.	Fetch all customers who have unsubscribed through their account marketing preferences
		*******************************************************************************************************************************************/
		
			--DECLARE @RunDate DATE = GETDATE()

			IF OBJECT_ID('tempdb..#AccountUnsubscribed') IS NOT NULL DROP TABLE #AccountUnsubscribed
			SELECT	FanID
				,	@RunDate AS UnsubscribeDate
				,	'Account' AS UnsubscribeType
			INTO #AccountUnsubscribed
			FROM [WHB].[Customer] cu
			WHERE cu.Unsubscribed = 1
			AND NOT EXISTS (SELECT 1
							FROM [Derived].[Customer] c
							WHERE cu.FanID = c.FanID
							AND cu.Unsubscribed = c.Unsubscribed)
			AND NOT EXISTS (SELECT 1
							FROM #EmailUnsubscribed eu
							WHERE cu.FanID = eu.FanID)

			CREATE CLUSTERED INDEX CIX_FanIDDateCampaignKey ON #AccountUnsubscribed (FanID, UnsubscribeDate, UnsubscribeType)


		/*******************************************************************************************************************************************
			4.	Insert all customers who have Unsubscribed via marketing preferences to [Derived].[Customer_UnsubscribeDates]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[Customer_UnsubscribeDates] (	FanID
															,	UnsubscribeDate
															,	UnsubscribeType)
			SELECT	FanID
				,	UnsubscribeDate
				,	UnsubscribeType
			FROM #AccountUnsubscribed au
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_UnsubscribeDates] ud
								WHERE au.FanID = ud.FanID
								AND au.UnsubscribeDate = ud.UnsubscribeDate
								AND au.UnsubscribeType = ud.UnsubscribeType)
								
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
