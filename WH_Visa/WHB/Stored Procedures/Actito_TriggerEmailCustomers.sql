

CREATE PROCEDURE [WHB].[Actito_TriggerEmailCustomers]
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

	DECLARE @Today DATE = GETDATE()

	--	Create Table Of All currently live Redemption Reminder - Value trigger emails
		
		-- CashbackValue is calculated from the Trigger Enail name found in [Email].[TriggerEmailType]
		IF OBJECT_ID('tempdb..#RedemptionReminder_Value') IS NOT NULL DROP TABLE #RedemptionReminder_Value
		SELECT tet.ID AS TriggerEmailTypeID
			 , CONVERT(INT, te2.TriggerEmail_FromFirstNumericUpToNonNumeric) AS CashbackValue
		INTO #RedemptionReminder_Value
		FROM [Email].[TriggerEmailType] tet
		CROSS APPLY (	SELECT te.ID
							 , te.TriggerEmail
							 , SUBSTRING(te.TriggerEmail, PATINDEX('%[0-9]%', te.TriggerEmail), 100) AS TriggerEmail_FromFirstNumeric
						FROM [Email].[TriggerEmailType] te
						WHERE tet.ID = te.ID) te1
		CROSS APPLY (	SELECT te.ID
							 , LEFT(te1.TriggerEmail_FromFirstNumeric, PATINDEX('%[^0-9]%', te1.TriggerEmail_FromFirstNumeric) - 1) AS TriggerEmail_FromFirstNumericUpToNonNumeric
						FROM [Email].[TriggerEmailType] te
						WHERE te1.ID = te.ID) te2
		WHERE tet.TriggerEmail LIKE '%Redemption%Cashback%'
		AND tet.CurrentlyLive = 1


	--	Create Table Of All currently live Redemption Reminder - Value trigger emails
	
		-- DaysSinceEmail is calculated from the Trigger Enail name found in [Email].[TriggerEmailType]
		IF OBJECT_ID('tempdb..#RedemptionReminder_Days') IS NOT NULL DROP TABLE #RedemptionReminder_Days
		SELECT tet.ID AS TriggerEmailTypeID
			 , CONVERT(INT, te2.TriggerEmail_FromFirstNumericUpToNonNumeric) AS DaysSinceEmail
		INTO #RedemptionReminder_Days
		FROM [Email].[TriggerEmailType] tet
		CROSS APPLY (	SELECT te.ID
							 , te.TriggerEmail
							 , SUBSTRING(te.TriggerEmail, PATINDEX('%[0-9]%', te.TriggerEmail), 100) AS TriggerEmail_FromFirstNumeric
						FROM [Email].[TriggerEmailType] te
						WHERE tet.ID = te.ID) te1
		CROSS APPLY (	SELECT te.ID
							 , LEFT(te1.TriggerEmail_FromFirstNumeric, PATINDEX('%[^0-9]%', te1.TriggerEmail_FromFirstNumeric) - 1) AS TriggerEmail_FromFirstNumericUpToNonNumeric
						FROM [Email].[TriggerEmailType] te
						WHERE te1.ID = te.ID) te2
		WHERE tet.TriggerEmail LIKE '%Redemption%Days%'
		AND tet.CurrentlyLive = 1

		CREATE CLUSTERED INDEX CIX_CashbackValue ON #RedemptionReminder_Days (DaysSinceEmail)


		IF OBJECT_ID('tempdb..#DailyData') IS NOT NULL DROP TABLE #DailyData
		SELECT *
			 , @Today AS EmailSendDate
		INTO #DailyData
		FROM [Email].[Actito_Deltas]
		WHERE RedeemReminder_Day IS NOT NULL
		OR EarnConfirmation_Date IS NOT NULL
		

		IF OBJECT_ID('tempdb..#TriggerEmailTracking') IS NOT NULL DROP TABLE #TriggerEmailTracking
		SELECT FanID
			 , (SELECT ID FROM [Email].[TriggerEmailType] WHERE TriggerEmail = 'Birthday') AS TriggerEmailTypeID
			 , @Today AS EmailSendDate
			 , Birthday_Code
			 , Birthday_CodeExpiryDate
			 , NULL AS FirstEarn_RetailerName
			 , NULL AS FirstEarn_Date
			 , NULL AS FirstEarn_Amount
			 , NULL AS FirstEarn_Type
			 , NULL AS Reached5GBP_Date
			 , NULL AS EarnConfirmation_Date
			 , NULL AS RedeemReminder_Amount
			 , NULL AS RedeemReminder_Day
		INTO #TriggerEmailTracking
		FROM [Email].[Actito_Deltas]
		WHERE Birthday_Flag != 0
		UNION
		SELECT FanID
			 , (SELECT ID FROM [Email].[TriggerEmailType] WHERE TriggerEmail = 'First Earn POS') AS TriggerEmailTypeID
			 , @Today AS EmailSendDate
			 , NULL AS Birthday_Code
			 , NULL AS Birthday_CodeExpiryDate
			 , dd.FirstEarn_RetailerName
			 , dd.FirstEarn_Date
			 , dd.FirstEarn_Amount
			 , dd.FirstEarn_Type
			 , NULL AS Reached5GBP_Date
			 , NULL AS EarnConfirmation_Date
			 , NULL AS RedeemReminder_Amount
			 , NULL AS RedeemReminder_Day
		FROM [Email].[Actito_Deltas] dd
		WHERE '1900-01-01' < FirstEarn_Date
		UNION
		SELECT FanID
			 , (SELECT ID FROM [Email].[TriggerEmailType] WHERE TriggerEmail = '£5 Balance') AS TriggerEmailTypeID
			 , @Today AS EmailSendDate
			 , NULL AS Birthday_Code
			 , NULL AS Birthday_CodeExpiryDate
			 , NULL AS FirstEarn_RetailerName
			 , NULL AS FirstEarn_Date
			 , NULL AS FirstEarn_Amount
			 , NULL AS FirstEarn_Type
			 , dd.Reached5GBP_Date
			 , NULL AS EarnConfirmation_Date
			 , NULL AS RedeemReminder_Amount
			 , NULL AS RedeemReminder_Day
		FROM [Email].[Actito_Deltas] dd
		WHERE '1900-01-01' < Reached5GBP_Date
		UNION
		SELECT FanID
			 , (SELECT ID FROM [Email].[TriggerEmailType] WHERE TriggerEmail = 'Earn confirmation') AS TriggerEmailTypeID
			 , @Today AS EmailSendDate
			 , NULL AS Birthday_Code
			 , NULL AS Birthday_CodeExpiryDate
			 , NULL AS FirstEarn_RetailerName
			 , NULL AS FirstEarn_Date
			 , NULL AS FirstEarn_Amount
			 , NULL AS FirstEarn_Type
			 , NULL AS Reached5GBP_Date
			 , EarnConfirmation_Date
			 , NULL AS RedeemReminder_Amount
			 , NULL AS RedeemReminder_Day
		FROM [Email].[Actito_Deltas]
		WHERE '1900-01-01' < EarnConfirmation_Date
		UNION
		SELECT FanID
			 , tet.ID AS TriggerEmailTypeID
			 , @Today AS EmailSendDate
			 , NULL AS Birthday_Code
			 , NULL AS Birthday_CodeExpiryDate
			 , NULL AS FirstEarn_RetailerName
			 , NULL AS FirstEarn_Date
			 , NULL AS FirstEarn_Amount
			 , NULL AS FirstEarn_Type
			 , NULL AS Reached5GBP_Date
			 , NULL AS EarnConfirmation_Date
			 , dd.RedeemReminder_Amount
			 , NULL AS RedeemReminder_Day
		FROM [Email].[Actito_Deltas] dd
		INNER JOIN #RedemptionReminder_Value v
			ON dd.RedeemReminder_Amount = v.CashbackValue
		INNER JOIN [Email].[TriggerEmailType] tet
			ON v.TriggerEmailTypeID = tet.ID
		WHERE 0 < RedeemReminder_Amount
		UNION
		SELECT FanID
			 , tet.ID AS TriggerEmailTypeID
			 , @Today AS EmailSendDate
			 , NULL AS Birthday_Code
			 , NULL AS Birthday_CodeExpiryDate
			 , NULL AS FirstEarn_RetailerName
			 , NULL AS FirstEarn_Date
			 , NULL AS FirstEarn_Amount
			 , NULL AS FirstEarn_Type
			 , NULL AS Reached5GBP_Date
			 , NULL AS EarnConfirmation_Date
			 , NULL AS RedeemReminder_Amount
			 , dd.RedeemReminder_Day
		FROM [Email].[Actito_Deltas] dd
		INNER JOIN #RedemptionReminder_Days d
			ON dd.RedeemReminder_Day = d.DaysSinceEmail
		INNER JOIN [Email].[TriggerEmailType] tet
			ON d.TriggerEmailTypeID = tet.ID

		INSERT INTO [Email].[TriggerEmailCustomers]
		SELECT *
		FROM #TriggerEmailTracking

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
