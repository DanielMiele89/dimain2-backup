
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	Fetch all new Email Events from SLC and stored them in local Virgin Table
--					Fetch all new existing Email Campaigns and Email Event Codes used by Virgin
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Emails_EmailEvents]

AS

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
		1.	Populate all Email Events
*******************************************************************************************************************************************/

	/***************************************************************************************************************************************
		1.1.	Fetch all new Email Events
	***************************************************************************************************************************************/
	
		DECLARE @StartRow BIGINT = (SELECT COALESCE(MAX(EventID), 754373679) FROM [Derived].[EmailEvent])	--	754373679 Max ID day before Virgin go live

		IF OBJECT_ID('tempdb..#EmailEvent') IS NOT NULL DROP TABLE #EmailEvent
		SELECT	ee.ID AS EventID
			,	ee.Date AS EventDateTime	--The date field is actually a datetime field
			,	ee.FanID
			,	ee.CampaignKey
			,	ee.EmailEventCodeID
		INTO #EmailEvent
		FROM [SLC_Report].[dbo].[EmailEvent] ee
		WHERE ee.ID > @StartRow
		AND EXISTS (SELECT 1
					FROM [Derived].[Customer] cu
					WHERE ee.FanID = cu.FanID)
					

	/***************************************************************************************************************************************
		1.2.	Add email events for Virgin customers to table
	***************************************************************************************************************************************/
	
		ALTER INDEX [CSX_All] ON [Derived].[EmailEvent] DISABLE

		INSERT INTO [Derived].[EmailEvent] (EventID, EventDateTime, EventDate, FanID, CompositeID, CampaignKey, EmailEventCodeID)
		SELECT ee.EventID
			 , ee.EventDateTime
			 , ee.EventDateTime AS EventDate
			 , ee.FanID
			 , cu.CompositeID
			 , ee.CampaignKey
			 , ee.EmailEventCodeID
		FROM #EmailEvent ee
		INNER JOIN [Derived].[Customer] cu
			ON ee.FanID = cu.FanID
			AND cu.ClubID IN (180)	--	Virgin Loyalty ClubID

		-- log it
		SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Derived].[EmailEvent] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
		EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, @msg

		ALTER INDEX [CSX_All] ON [Derived].[EmailEvent] REBUILD

		-- log it
		EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Columnstore index created on [Derived].[EmailEvent]'

/*******************************************************************************************************************************************
		2.	Populate all Email Campaigns
*******************************************************************************************************************************************/

	TRUNCATE TABLE [Derived].[EmailCampaign]

	SET IDENTITY_INSERT [Derived].[EmailCampaign] ON

	INSERT INTO	[Derived].[EmailCampaign] (	ID
										,	CampaignKey
										,	EmailKey
										,	CampaignName
										,	[Subject]
										,	SendDateTime
										,	SendDate)
	SELECT	ec.ID
		,	ec.CampaignKey
		,	ec.EmailKey
		,	ec.CampaignName
		,	ec.[Subject]
		,	ec.SendDate AS SendDateTime
		,	CONVERT(DATE, ec.SendDate) AS SendDate
	FROM [SLC_Report].[dbo].[EmailCampaign] ec
	WHERE EXISTS (	SELECT 1
					FROM [Derived].[EmailEvent] ee
					WHERE ee.CampaignKey = ec.CampaignKey)

	SET IDENTITY_INSERT [Derived].[EmailCampaign] OFF

	-- log it
	SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Derived].[EmailCampaign] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
	EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, @msg

/*******************************************************************************************************************************************
		3.	Populate all Email Event Codes
*******************************************************************************************************************************************/
	
	TRUNCATE TABLE [Derived].[EmailEventCode]

	INSERT INTO	[Derived].[EmailEventCode] (EmailEventCodeID
										,	EmailEventDesc)	
	SELECT	[ID]
		,	[Name]
	FROM [SLC_Report].[dbo].[EmailEventCode] eec
	WHERE EXISTS (	SELECT 1
					FROM [Derived].[EmailEvent] ee
					WHERE ee.EmailEventCodeID = eec.ID)

	-- log it
	SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Derived].[EmailEventCode] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
	EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, @msg

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
			
	-- Insert the error INTO the ErrorLog
	INSERT INTO [Monitor].[ErrorLog] (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run
