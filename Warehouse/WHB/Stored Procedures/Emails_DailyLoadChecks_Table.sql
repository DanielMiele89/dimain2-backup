
CREATE PROCEDURE [WHB].[Emails_DailyLoadChecks_Table]
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

	BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'FanSFDDailyUploadData_PreviousDay',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Populate Previous Days Table-------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Truncate Table [Staging].[FanSFDDailyUploadData_PreviousDay]

	Insert into [Staging].[FanSFDDailyUploadData_PreviousDay]
	SELECT [FanID]
		  ,[ClubCashAvailable]
		  ,[CustomerJourneyStatus]
		  ,[ClubCashPending]
		  ,[WelcomeEmailCode]
		  ,[DateOfLastCard]
		  ,[CJS]
		  ,[WeekNumber]
		  ,[IsDebit]
		  ,[IsCredit]
		  ,[RowNumber]
		  ,[ActivatedDate]
		  ,[CompositeID]
	  FROM [Staging].[FanSFDDailyUploadData]

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'FanSFDDailyUploadData_PreviousDay' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Staging.FanSFDDailyUploadData_PreviousDay)
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'FanSFDDailyUploadData_PreviousDay' and
			TableRowCount is null

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'FanSFDDailyUploadData',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'

	----------------------------------------------------------------------
	----------------------------------------------------------------------
	----------------------------------------------------------------------
	Truncate Table [Staging].[FanSFDDailyUploadData]

	Insert into [Staging].[FanSFDDailyUploadData]
	SELECT [FanID]
		  ,[ClubCashAvailable]
		  ,[CustomerJourneyStatus]
		  ,[ClubCashPending]
		  ,[WelcomeEmailCode]
		  ,[DateOfLastCard]
		  ,[CJS]
		  ,[WeekNumber]
		  ,[IsDebit]
		  ,[IsCredit]
		  ,[RowNumber]
		  ,[ActivatedDate]
		  ,[CompositeID]
	  FROM SLC_Report.dbo.[FanSFDDailyUploadData]

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'FanSFDDailyUploadData' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Staging.FanSFDDailyUploadData)
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'FanSFDDailyUploadData' and
			TableRowCount is null

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'FanSFDDailyUploadData_DirectDebit_PreviousDay',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'
	/*--------------------------------------------------------------------------------------------------
	----------------------------------------popluate Table----------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Truncate Table [Staging].[FanSFDDailyUploadData_DirectDebit_PreviousDay]

	Insert into [Staging].[FanSFDDailyUploadData_DirectDebit_PreviousDay]
	Select *
	From [Staging].[FanSFDDailyUploadData_DirectDebit]

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'FanSFDDailyUploadData_DirectDebit_PreviousDay' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Staging.[FanSFDDailyUploadData_DirectDebit_PreviousDay])
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'FanSFDDailyUploadData_DirectDebit_PreviousDay' and
			TableRowCount is null

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'FanSFDDailyUploadData_DirectDebit',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'
	/*--------------------------------------------------------------------------------------------------
	----------------------------------------Populate Table----------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Truncate Table [Staging].[FanSFDDailyUploadData_DirectDebit]

	Insert into [Staging].[FanSFDDailyUploadData_DirectDebit]
	Select * 
	From SLC_Report.dbo.[FanSFDDailyUploadData_DirectDebit]

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'FanSFDDailyUploadData_DirectDebit' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Staging.FanSFDDailyUploadData_DirectDebit)
	where	StoredProcedureName = 'FanSFDDailyUploadData_DirectDebit' and
			TableSchemaName = 'Staging' and
			TableName = 'FanSFDDailyUploadData_DirectDebit' and
			TableRowCount is null

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog
	select [StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
	from staging.JobLog_Temp

	TRUNCATE TABLE staging.JobLog_Temp

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
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run