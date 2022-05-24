
-- *********************************************
-- Author: Suraj Chahal
-- Create date: 23/09/2014
-- Description: Store a customers MarketableByEmail status on a daily basis where it has changed from the day previous
-- *********************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_CustomerMarketableByEmailStatusV1_1]
			
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	DECLARE @RowCount INT
	/******************************************************************************
	***********************Write entry to JobLog Table*****************************
	******************************************************************************/
	INSERT INTO Staging.JobLog_Temp
	SELECT	StoredProcedureName = 'WarehouseLoad_CustomerMarketableByEmailStatusV1_1',
		TableSchemaName = 'Relational',
		TableName = 'Customer_MarketableByEmailStatus',
		StartDate = GETDATE(),
		EndDate = NULL,
		TableRowCount  = NULL,
		AppendReload = 'A'

	SET @RowCount = (SELECT COUNT(1) FROM Relational.Customer_MarketableByEmailStatus)


	/******************************************************************************
	*************************Marketable By Email Statuses**************************
	******************************************************************************/
	IF OBJECT_ID('tempdb..#MBE_Status') IS NOT NULL DROP TABLE #MBE_Status
	SELECT c.FanID,
		   c.MarketableByEmail,
		   CAST(GETDATE() AS DATE) as StartDate,
		   CAST(NULL AS DATE) as EndDate
	INTO #MBE_Status
	FROM Relational.Customer as c
	Left Outer JOIN Relational.Customer_MarketableByEmailStatus a
		   ON     c.FanID = a.FanID and
				  c.marketableByEmail = a.MarketableByEmail and 
				  a.EndDate is null
	Where a.FanID is null

	/***************************************************************
	******************Add EndDate to Old entries********************
	****************************************************************/
	--**For records where there are new entries, we must EndDate the
	--**previous ones
	UPDATE Relational.Customer_MarketableByEmailStatus
	SET EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
	FROM Relational.Customer_MarketableByEmailStatus mbes
	INNER JOIN #MBE_Status mbe
		ON mbes.FanID = mbe.FanID
	WHERE mbes.EndDate is null


	/******************************************************************************
	*****************************Insert new entries********************************
	******************************************************************************/
	--**Disable current Indexes on Table
	ALTER INDEX IDX_FanID ON Relational.Customer_MarketableByEmailStatus DISABLE
	ALTER INDEX IDX_StartDate ON Relational.Customer_MarketableByEmailStatus DISABLE
	ALTER INDEX IDX_EndDate ON Relational.Customer_MarketableByEmailStatus DISABLE

	--**Run the insert of the new records
	INSERT INTO Relational.Customer_MarketableByEmailStatus
	SELECT	FanID,
		MarketableByEmail,
		StartDate,
		EndDate
	FROM #MBE_Status

	--**Rebuild Indexes on tables
	ALTER INDEX IDX_FanID ON Relational.Customer_MarketableByEmailStatus REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
	ALTER INDEX IDX_StartDate ON Relational.Customer_MarketableByEmailStatus REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
	ALTER INDEX IDX_EndDate ON Relational.Customer_MarketableByEmailStatus REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212



	/******************************************************************************
	****************Update entry in JobLog Table with End Date*********************
	******************************************************************************/
	UPDATE staging.JobLog_Temp
	SET EndDate = GETDATE()
	WHERE	StoredProcedureName = 'WarehouseLoad_CustomerMarketableByEmailStatusV1_1' 
		AND TableSchemaName = 'Relational'
		AND TableName = 'Customer_MarketableByEmailStatus' 
		AND EndDate IS NULL

	/******************************************************************************
	*****************Update entry in JobLog Table with Row Count*******************
	******************************************************************************/
	--**Count run seperately as when table grows this as a task on its own may 
	--**take several minutes and we do not want it included in table creation times
	UPDATE Staging.JobLog_Temp
	SET TableRowCount = (SELECT COUNT(*) FROM Relational.Customer_MarketableByEmailStatus)-@RowCount
	WHERE	StoredProcedureName = 'WarehouseLoad_CustomerMarketableByEmailStatusV1_1'
		AND TableSchemaName = 'Relational'
		AND TableName = 'Customer_MarketableByEmailStatus' 
		AND TableRowCount IS NULL


	INSERT INTO Staging.JobLog
	SELECT	StoredProcedureName,
		TableSchemaName,
		TableName,
		StartDate,
		EndDate,
		TableRowCount,
		AppendReload
	FROM Staging.JobLog_Temp

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


END