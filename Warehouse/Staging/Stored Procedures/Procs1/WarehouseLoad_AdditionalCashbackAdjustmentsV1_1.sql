CREATE Procedure [Staging].[WarehouseLoad_AdditionalCashbackAdjustmentsV1_1]
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_AddtionalCashbackAdjustmentsV1_1',
			TableSchemaName = 'Relational',
			TableName = 'Relational.AdditionalCashbackAdjustment',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'


	Truncate Table Relational.AdditionalCashbackAdjustment
	/*--------------------------------------------------------------------------------------------------
	------------------------------------Create Typesd Table Table---------------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Types') is not null drop table #Types
	Select aca.*,tt.Multiplier
	Into #Types
	From Relational.AdditionalCashbackAdjustmentType as aca
	inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
		on aca.TypeID = tt.ID

	/*--------------------------------------------------------------------------------------------------
	------------------------------------populate customer Table-----------------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Customer') is not null drop table #Customer
	Select FanID,ROW_NUMBER() OVER(ORDER BY FanID ASC) AS RowNo
	Into #Customer
	From Relational.Customer

	Create Clustered Index ix_Customer_FanID on #Customer (FanID)
	/*--------------------------------------------------------------------------------------------------
	------------------------------------populate customer Table-----------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Declare @RowNo int, @RowNoMax int, @ChunkSize int

	Set @RowNo = 1
	Set @RowNoMax = (Select max(RowNo) from #Customer as c)
	Set @Chunksize = 250000


	While @RowNo <= @RowNoMax
	Begin

		/*--------------------------------------------------------------------------------------------------
		------------------------------------Re-populate Table-----------------------------------------------
		----------------------------------------------------------------------------------------------------*/
		Insert into Relational.AdditionalCashbackAdjustment
		Select	t.FanID						as FanID,
				t.ProcessDate				as AddedDate,
				t.ClubCash* aca.Multiplier	as CashbackEarned,
				t.ActivationDays,
				aca.AdditionalCashbackAdjustmentTypeID
		from SLC_Report.dbo.Trans as t with (Nolock)
		INNER JOIN #Types AS aca
			on t.ItemID = aca.ItemID and t.TypeID = aca.TypeID
			--and t.fanid = 1960606
		inner join #Customer as c
			on t.FanID = c.FanID
		Where c.RowNo between @RowNo and @RowNo + (@Chunksize-1)

		Set @RowNo = @RowNo+@Chunksize
	End	
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_AddtionalCashbackAdjustmentsV1_1' and
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
	where	StoredProcedureName = 'WarehouseLoad_AddtionalCashbackAdjustmentsV1_1' and
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