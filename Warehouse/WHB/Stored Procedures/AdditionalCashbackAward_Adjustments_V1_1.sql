CREATE PROCEDURE [WHB].[AdditionalCashbackAward_Adjustments_V1_1]
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'Relational.AdditionalCashbackAdjustment',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'


	Truncate Table Relational.AdditionalCashbackAdjustment
	Truncate Table Relational.AdditionalCashbackAdjustment_incTranID -- ZT added for FIFO process
	/*--------------------------------------------------------------------------------------------------
	------------------------------------Create Typesd Table Table---------------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#AdditionalCashbackAdjustmentType') is not null drop table #AdditionalCashbackAdjustmentType
	Select	aca.*
		,	tt.Multiplier
	Into #AdditionalCashbackAdjustmentType
	From Relational.AdditionalCashbackAdjustmentType as aca
	inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
		on aca.TypeID = tt.ID

	/*--------------------------------------------------------------------------------------------------
	------------------------------------populate customer Table-----------------------------------------
	----------------------------------------------------------------------------------------------------*/

	if object_id('tempdb..#Customer') is not null drop table #Customer
	Select FanID
	Into #Customer
	From Relational.Customer

	Create Clustered Index ix_Customer_FanID on #Customer (FanID)

	/*--------------------------------------------------------------------------------------------------
	------------------------------------Re-populate Table-----------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	if object_id('tempdb..#AdditionalCashbackAdjustment') is not null drop table #AdditionalCashbackAdjustment
	Select	tr.FanID
		, tr.ID TranID
		,	tr.ProcessDate AS AddedDate
		,	tr.ClubCash * aca.Multiplier AS CashbackEarned
		,	tr.ActivationDays
		,	aca.AdditionalCashbackAdjustmentTypeID
	INTO #AdditionalCashbackAdjustment
	FROM [SLC_Report].[dbo].[Trans] tr
	INNER JOIN #AdditionalCashbackAdjustmentType aca -- Insert excludes Burn As You Earn, as these have an ItemID of 0 in the Warehouse.Relational.AdditionalCashbackAdjustmentType table
		on tr.ItemID = aca.ItemID
		and tr.TypeID = aca.TypeID
	WHERE EXISTS (	SELECT 1
					FROM #Customer as c
					WHERE tr.FanID = c.FanID)

--------------------------------------------------------------------
-- Original table
--------------------------------------------------------------------
	INSERT INTO [Relational].[AdditionalCashbackAdjustment]
	SELECT	aja.FanID
		,	aja.AddedDate
		,	aja.CashbackEarned
		,	aja.ActivationDays
		,	aja.AdditionalCashbackAdjustmentTypeID
	FROM #AdditionalCashbackAdjustment aja

--------------------------------------------------------------------
-- New table insert - used in FIFO
--------------------------------------------------------------------
	INSERT INTO [Relational].[AdditionalCashbackAdjustment_incTranID]
	SELECT	aja.FanID
		,   aja.TranID
		,	aja.AddedDate
		,	aja.CashbackEarned
		,	aja.ActivationDays
		,	aja.AdditionalCashbackAdjustmentTypeID
	FROM #AdditionalCashbackAdjustment aja


	-- Burn As You Earn redemptions inserted by Warehouse.WHB.AdditionalCashbackAward_Adjustment_AmazonRedemptions stored procedure


	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Relational.AdditionalCashbackAdjustment' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Relational.AdditionalCashbackAdjustment)
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'Relational.AdditionalCashbackAdjustment' and
			TableRowCount is null

	Insert into staging.JobLog
	select [StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
	from staging.JobLog_Temp
	truncate table staging.JobLog_Temp

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