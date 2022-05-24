/*

WarehouseLoad_Cashback_Balances_V1_2

Author:		Stuart Barnley
Date:		22nd November 2013
Purpose:	Storing pending and available balances for assessment to prove database is updating
		
Update:		9th November 2016 SB -	Removal to Table check as this is taking 30 mins on it's own to run	
ChrisM 20161116 use @@ROWCOUNT instead of counting rows in table - see comments
ChrisM 20171121 Rewrite, takes about 15 minutes in DIDEVTEST/Warehouse_Dev for (3,505,688 rows affected)

-- 20180221 removed this index as it wasn't being used
CREATE UNIQUE NONCLUSTERED INDEX [ix_FanID_Date] ON [Staging].[Customer_CashbackBalances]
	([FanID] ASC,[Date] ASC) INCLUDE ([ClubcashPending], [ClubCashAvailable]) WITH (FILLFACTOR = 80)

Final tweak 20180216 update stats instead of index rebuild
*/

CREATE PROCEDURE [WHB].[Customer_Cashback_Balances_V1_2]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	DECLARE @RowCount INT

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	-- DELETE FROM Staging.Customer_CashbackBalances WHERE [Date] = CAST(GETDATE() AS DATE)

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'Customer_CashbackBalances',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'



	----------------------------------------------------------------------------------------------------
	------------Copy balances from slc_report.dbo.FANID for Active customers into table-----------------
	----------------------------------------------------------------------------------------------------
	IF OBJECT_ID('Tempdb..#SLC_Report') IS NOT NULL DROP TABLE #SLC_Report;
	SELECT	f.ID as FanID,
			ClubCashPending,
			ClubCashAvailable,
			[Date] = CAST(GETDATE() AS DATE)
			--TileNo = NTILE(5) OVER (ORDER BY f.ID) 
	INTO #SLC_Report
	FROM SLC_Report.dbo.Fan as f with (nolock)
	WHERE	AgreedTCs = 1 and 
			[Status] = 1 and 
			clubid in (132,138);
	-- (3,505,688 rows affected) / 00:00:18
	SET @RowCount = @@ROWCOUNT; -- ChrisM 20161116 uncomment

	CREATE CLUSTERED INDEX ucx_Stuff ON #SLC_Report ([Date], FanID); -- 00:00:15



	IF NOT EXISTS (SELECT 1 FROM Staging.Customer_CashbackBalances ccb WHERE ccb.[Date] = CAST(GETDATE() AS DATE))
		INSERT INTO Staging.Customer_CashbackBalances WITH (TABLOCKX) 
			(FanID, ClubCashPending, ClubCashAvailable, [Date])
		SELECT FanID, ClubCashPending, ClubCashAvailable, [Date] 
		FROM #SLC_Report f



	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date and row count-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update staging.JobLog_Temp Set		
		EndDate = GETDATE(), 
		TableRowCount = @RowCount
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'Customer_CashbackBalances' and
			EndDate is null

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

END