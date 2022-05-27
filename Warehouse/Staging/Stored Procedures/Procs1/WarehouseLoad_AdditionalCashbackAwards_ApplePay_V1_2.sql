
/*
		Author:		Stuart Barnley
		Date:		20th May 2015

		Purpose:	Additional Cashback Awards - This stored procedure is coded to pull through ApplePay 
					Transactions being subsequently incentivised

		Update:		2017-12-13 SB - Amended to remove weekend full load, this is because full load of
									the rest of ACA was done a while ago.
		Notes:		*/

CREATE Procedure [Staging].[WarehouseLoad_AdditionalCashbackAwards_ApplePay_V1_2]
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAwards_ApplePay_V1_2',
			TableSchemaName = 'Relational',
			TableName = 'AdditionalCashbackAward',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'

	Declare @MaxApplePayTran int
	Set @MaxApplePayTran = (Select coalesce(Max(TranID),0) from Staging.AdditonalCashbackAward_ApplePay)
	/*--------------------------------------------------------------------------------------------------
	------------------------------------populate customer Table-----------------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Customer') is not null drop table #Customer
	Select FanID,ROW_NUMBER() OVER(ORDER BY FanID ASC) AS RowNo
	Into #Customer
	From Relational.Customer

	Create Clustered Index ix_Customer_FanID on #Customer (FanID)

	/*--------------------------------------------------------------------------------------------------
	------------------------------------Create Typesd Table Table---------------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Types') is not null drop table #Types
	Select aca.*,tt.Multiplier
	Into #Types
	From Relational.[AdditionalCashbackAwardType] as aca
	inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
		on	aca.TransactionTypeID = tt.ID
	Where Title Like '%Apple Pay%'

	--------------------------------------------------------------------------------------
	--------------------Pull data and add MatchIDs where appropriate----------------------
	--------------------------------------------------------------------------------------
	if object_id('tempdb..#Trans') is not null drop table #Trans
	select	   t.ID as TranID,
			   0 as FileID,
			   --t.VectorMinorID as RowNum,
			   t.FanID,
			   t.[Date] as TranDate,
			   t.ProcessDate as AddedDate,
			   t.Price as Amount,
			   t.ClubCash*tt.Multiplier as CashbackEarned,
			   t.ActivationDays,
			   tt.AdditionalCashbackAwardTypeID,
			   1 as PaymentMethodID,
			   0 as DirectDebitOriginatorID
		into #Trans
		from #Types as tt
		inner join SLC_Report.DBO.Trans as t with (nolock)
			   on tt.ItemID = t.ItemID and
			   tt.TransactionTypeID = t.TypeID
		Left Outer join Staging.AdditonalCashbackAward_ApplePay as a
			on t.ID = a.TranID
		Where a.TranID is null
	--------------------------------------------------------------------------------------
	--------------------------------Create RowNumbers and FileIDs-------------------------
	--------------------------------------------------------------------------------------
	Declare @HighestRowNo int
	Set @HighestRowNo = (Select Max(RowNum) From Staging.AdditonalCashbackAward_ApplePay)

	Set @HighestRowNo = Coalesce(@HighestRowNo,0)

	Insert into Staging.AdditonalCashbackAward_ApplePay
	Select	TranID,
			FileID,
			   --t.VectorMinorID as RowNum,
			ROW_NUMBER() OVER (ORDER BY TranID) + @HighestRowNo AS RowNum
	From	#Trans as t
	inner join #Customer as c
		on t.FanID = c.FanID
 
	--------------------------------------------------------------------------------------
	-----------------------------------Find final customers-------------------------------
	--------------------------------------------------------------------------------------

	--ALTER INDEX [IX_ArchiveRef] ON Relational.AdditionalCashbackAward  DISABLE
	--ALTER INDEX [IX_MatchID] ON Relational.AdditionalCashbackAward  DISABLE

	Insert into Relational.AdditionalCashbackAward
	select	   NULL as MatchID,
			   a.FileID as FileID,
			   a.RowNum as RowNum,
			   t.FanID,
			   Cast(t.[Date] as date) as TranDate,
			   Cast(t.ProcessDate as date) as AddedDate,
			   t.Price as Amount,
			   t.ClubCash*tt.Multiplier as CashbackEarned,
			   t.ActivationDays,
			   tt.AdditionalCashbackAwardTypeID,
			   1 as PaymentMethodID,
			   NULL as DirectDebitOriginatorID
		from Staging.AdditonalCashbackAward_ApplePay as a
		inner loop join SLC_Report.DBO.Trans as t with (nolock)
			on a.TranID = t.ID
		inner join #Types as tt
			on tt.ItemID = t.ItemID and
			   tt.TransactionTypeID = t.TypeID
	Where TranID > @MaxApplePayTran ---******INCREMENTAL LOAD ONLY

	--ALTER INDEX [IX_ArchiveRef] ON Relational.AdditionalCashbackAward  Enable
	--ALTER INDEX [IX_MatchID] ON Relational.AdditionalCashbackAward  Enable

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAwards_ApplePay_V1_2' and
			TableSchemaName = 'Relational' and
			TableName = 'AdditionalCashbackAward' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Staging.AdditonalCashbackAward_ApplePay)
	where	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAwards_ApplePay_V1_2' and
			TableSchemaName = 'Relational' and
			TableName = 'AdditionalCashbackAward' and
			TableRowCount is null
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
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