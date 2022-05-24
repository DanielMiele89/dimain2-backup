CREATE PROCEDURE [WHB].[Emails_LionSendTracking_UpdateEmailEvents_V2]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

/*******************************************************************************************************************************************
	1. Write entry to JobLog Table
*******************************************************************************************************************************************/

	INSERT INTO [Staging].[JobLog_temp]
	SELECT StoredProcedureName = OBJECT_NAME(@@PROCID)
		 , TableSchemaName = 'Lion'
		 , TableName = 'LionSend_Customers'
		 , StartDate = GETDATE()
		 , EndDate = NULL
		 , TableRowCount  = NULL
		 , AppendReload = 'U'
		 	

/*******************************************************************************************************************************************
	2. Prepare variables
*******************************************************************************************************************************************/

	DECLARE @EmailsOpened BIGINT = 0
		  , @RowCount BIGINT = 0

		  
/*******************************************************************************************************************************************
	3. Find how many customers have opened an email since last updated
*******************************************************************************************************************************************/

	SELECT @EmailsOpened = COUNT(DISTINCT FanID)
	FROM [Lion].[LionSend_Customers] ls
	WHERE ls.EmailOpened = 0
	AND EXISTS (SELECT 1
				FROM [Relational].[EmailEvent] ee
				WHERE ls.FanID = ee.FanID
				AND ls.CampaignKey = ee.CampaignKey
				AND ee.EmailEventCodeID = 1301)


				SELECT @EmailsOpened
	

/*******************************************************************************************************************************************
	4. If there are not enough entries to make update worthwhile, skip to after the update
*******************************************************************************************************************************************/
	
	IF @EmailsOpened < 10000
		GOTO NotEnoughEmailsToUpdate;

/*******************************************************************************************************************************************
	5. Run update for email opens
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		5.1. Drop index on [Lion].[LionSend_Customers]
	***********************************************************************************************************************/

		DROP INDEX [CSX_LionSendCustomers_All] ON [Lion].[LionSend_Customers]
		

	/***********************************************************************************************************************
		5.2. Update the CampaignKey where it was previous not found
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#EmailCampaign') IS NOT NULL DROP TABLE #EmailCampaign
		SELECT ec.CampaignKey
			 , CampaignName
			 , SendDate
			 , CASE
					WHEN CampaignName LIKE '%NWC%' OR CampaignName LIKE '%NatWest%' THEN 132
					WHEN CampaignName LIKE '%NWP%' OR CampaignName LIKE '%NatWest%' THEN 132
					WHEN CampaignName LIKE '%RBSC%' OR CampaignName LIKE '%RBS%' THEN 138
					WHEN CampaignName LIKE '%RBSP%' OR CampaignName LIKE '%RBS%' THEN 138
			   END AS ClubID
			 , CASE
					WHEN CampaignName LIKE '%NWC%' OR CampaignName LIKE '%Core%' THEN 0
					WHEN CampaignName LIKE '%NWP%' OR CampaignName LIKE '%Private%' THEN 1
					WHEN CampaignName LIKE '%RBSC%' OR CampaignName LIKE '%Core%' THEN 0
					WHEN CampaignName LIKE '%RBSP%' OR CampaignName LIKE '%Private%' THEN 1
			   END AS IsLoyalty
			 , CASE
					WHEN PATINDEX('%LSID%', CampaignName) > 0 THEN SUBSTRING(CampaignName, PATINDEX('%LSID%', CampaignName) + 4, 3)
					ELSE NULL
			   END AS LionSendID
		INTO #EmailCampaign
		FROM [Relational].[EmailCampaign] ec
		WHERE CampaignName LIKE '%newsletter%'

		UPDATE #EmailCampaign
		SET LionSendID =	CASE
								WHEN CampaignName IN ('NWC_GenericHybridNewsletter_LSID727_14Jan202', 'NWP_GenericHybridNewsletter_LSID727_14Jan202', 'RBSC_GenericHybridNewsletter_LSID727_14Jan202', 'RBSP_GenericHybridNewsletter__LSID727_14Jan2021', 'NWC_GenericHybridNewsletter_LSID727_14Jan202') THEN 728
								WHEN CampaignName IN ('NWC_SLHybridNewsletter_LSID729_14Jan2021') THEN 730
								WHEN CampaignName IN ('NWC_SLHybridNewsletter_LSID729_14Jan2021_LIVE2') THEN 732
								WHEN CampaignName IN ('RBSP_GenericHybridNewsletter_LSID731_28Jan2021', 'RBSC_GenericHybridNewsletter_LSID731_28Jan2021', 'NWP_GenericHybridNewsletter_LSID731_28Jan2021', 'NWC_GenericHybridNewsletter_LSID731_28Jan2021') THEN 734
								WHEN CampaignName IN ('NWC_SLHybridNewsletter_LSID752_08Apr2021') THEN 762
								ELSE LionSendID
							END


		EXEC('	UPDATE ls
				SET ls.CampaignKey = ec.CampaignKey
				FROM [Lion].[LionSend_Customers] ls
				INNER JOIN #EmailCampaign ec
					ON ls.LionSendID = ec.LionSendID
					AND ls.IsLoyalty = ec.IsLoyalty
					AND ls.ClubID = ec.ClubID
				WHERE ls.CampaignKey IS NULL')
		
	/***********************************************************************************************************************
		5.3. Update EmailSent flag
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#EmailNotSent') IS NOT NULL DROP TABLE #EmailNotSent
		SELECT lsc.CampaignKey
			 , lsc.FanID
		INTO #EmailNotSent
		FROM [Lion].[LionSend_Customers] lsc
		WHERE lsc.EmailSent = 0

		CREATE CLUSTERED INDEX CIX_EmailNotSent_FanID ON #EmailNotSent (CampaignKey, FanID)
	

		IF OBJECT_ID('tempdb..#EmailSent') IS NOT NULL DROP TABLE #EmailSent
		SELECT Distinct
			   ee.CampaignKey
			 , ee.FanID
		INTO #EmailSent
		FROM #EmailNotSent ens
		INNER JOIN [Relational].[EmailEvent] ee
			ON ens.FanID = ee.FanID
			AND ens.CampaignKey = ee.CampaignKey

		EXEC('	UPDATE lsc
				SET EmailSent = 1
				FROM [Lion].[LionSend_Customers] lsc
				INNER JOIN #EmailSent es
					ON lsc.CampaignKey = es.CampaignKey
					AND lsc.FanID = es.FanID
				WHERE EmailSent = 0')

		SET @RowCount = @@ROWCOUNT
		

	/***********************************************************************************************************************
		5.4. Update EmailOpened flag
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#EmailNotOpened') IS NOT NULL DROP TABLE #EmailNotOpened
		SELECT lsc.CampaignKey
			 , lsc.FanID
		INTO #EmailNotOpened
		FROM [Lion].[LionSend_Customers] lsc
		WHERE lsc.EmailOpened = 0

		Create Clustered Index CIX_EmailNotOpened_CampaignKeyFanID ON #EmailNotOpened (CampaignKey, FanID)


		IF OBJECT_ID('tempdb..#EmailOpens') IS NOT NULL DROP TABLE #EmailOpens
		SELECT ee.CampaignKey
			 , ee.FanID
			 , MIN(EventDate) AS EventDate
		INTO #EmailOpens
		FROM #EmailNotOpened eno
		INNER JOIN [Relational].[EmailEvent] ee
			ON eno.CampaignKey = ee.CampaignKey
			AND eno.FanID = ee.FanID
		WHERE ee.EmailEventCodeID = 1301
		GROUP BY ee.CampaignKey
			   , ee.FanID

		EXEC('	UPDATE lsc
				SET EmailOpened = 1
				  , EmailOpenedDate = EventDate
				FROM [Lion].[LionSend_Customers] lsc
				INNER JOIN #EmailOpens eo
					ON lsc.CampaignKey = eo.CampaignKey
					AND lsc.FanID = eo.FanID
				WHERE EmailOpened = 0')

		SET @RowCount = @RowCount + @@ROWCOUNT
		

	/***********************************************************************************************************************
		5.5. Recreate index on [Lion].[LionSend_Customers]
	***********************************************************************************************************************/
		

		CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_LionSendCustomers_All] ON [Lion].[LionSend_Customers] ([LionSendID]
																										, [EmailSendDate]
																										, [CampaignKey]
																										, [CompositeID]
																										, [FanID]
																										, [ClubID]
																										, [IsLoyalty]
																										, [EmailSent]
																										, [EmailOpened]
																										, [EmailOpenedDate]) ON Warehouse_Columnstores

/*******************************************************************************************************************************************
	6. Update JobLog
*******************************************************************************************************************************************/
 
	NotEnoughEmailsToUpdate:
		

	/***********************************************************************************************************************
		6.1. Update JobLogTemp
	***********************************************************************************************************************/

		UPDATE [Staging].[JobLog_temp]
		SET EndDate = GETDATE()
		  , TableRowCount = @RowCount
		WHERE StoredProcedureName = OBJECT_NAME(@@PROCID) 
		AND TableSchemaName = 'Lion' 
		AND TableName = 'LionSend_Customers' 
		AND EndDate IS NULL
		

	/***********************************************************************************************************************
		6.2. Insert to JobLog
	***********************************************************************************************************************/
	
		INSERT INTO [Staging].[JobLog]
		SELECT StoredProcedureName
			 , TableSchemaName
			 , TableName
			 , StartDate
			 , EndDate
			 , TableRowCount
			 , AppendReload
		FROM [Staging].[JobLog_temp]
		

	/***********************************************************************************************************************
		6.3. Truncate JobLog_temp
	***********************************************************************************************************************/

		TRUNCATE TABLE [Staging].[JobLog_temp]


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
			
	-- Insert the error INTO the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

End