/*

	Author:		Stuart Barnley


	Date:		27th December 2017


	Purpose:	To pull through the latest Monthly Credit Card incentivised Transactions

	
*/
CREATE PROCEDURE [WHB].[AdditionalCashbackAward_CC_MonthlyAwards]
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
			TableSchemaName = 'Relational',
			TableName = 'AdditionalCashbackAward',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Pull off a list of Transactions for Amazon Offer-----------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Trans') is not null drop table #Trans
	Select	ID as TranID,
			t.ItemID,
			a.ACATypeID
	Into #Trans
	From SLC_Report.dbo.Trans as t
	inner join Staging.AdditionalCashbackAwards_MonthlyCCOffers as a
		on t.ItemID = a.ItemID
	Where	TypeID = 1

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Find out number of last entry------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Declare @MaxRow int

	Set @MaxRow = (	Select Max(RowNum) 
					From Staging.RBSGFundedCreditCardMonthlyOffers
				  )

	Set @MaxRow = coalesce(@MaxRow,0)

	/*--------------------------------------------------------------------------------------------------
	-------------------------------Insert missing Transactions into listing table-----------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into Staging.RBSGFundedCreditCardMonthlyOffers 
	Select	t.TranID,
			-1 as FileID,
			ROW_NUMBER() OVER(ORDER BY t.TranID ASC)+@MaxRow AS RowNum,
			t.ACATypeID	as AdditionalCashbackAwardTypeID
	From #Trans as t
	Left Outer Join Staging.RBSGFundedCreditCardMonthlyOffers as b
		on t.TranID = b.TranID
	Where b.TranID is null

	/*--------------------------------------------------------------------------------------------------
	------------------------------------Create Typesd Table Table---------------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Types') is not null drop table #Types
	Select aca.*,tt.Multiplier
	Into #Types
	From Relational.[AdditionalCashbackAwardType] as aca
	inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
		on	aca.TransactionTypeID = tt.ID

	------------------------------------------------------------------------------
	--------------Get Additional Cashback Awards with a PanID---------------------
	------------------------------------------------------------------------------
	Declare @RowCount int

	Insert Into Relational.AdditionalCashbackAward
	
		select t.Matchid as MatchID,
			   a.FileID as FileID,
			   a.RowNum as RowNum,
			   t.FanID,
			   t.[Date] as TranDate,
			   t.ProcessDate as AddedDate,
			   t.Price as Amount,
			   t.ClubCash*tt.Multiplier as CashbackEarned,
			   t.ActivationDays,
			   tt.AdditionalCashbackAwardTypeID,
			   1 as PaymentMethodID,
			   t.DirectDebitOriginatorID
		from relational.Customer as c with (nolock)
		inner join SLC_Report.DBO.Trans as t with (nolock)
			on t.FanID = c.fanid
		inner join #Types as tt
			on tt.ItemID = t.ItemID and
			   tt.TransactionTypeID = t.TypeID          
		inner join Staging.RBSGFundedCreditCardMonthlyOffers as a
			on t.ID = a.TranID
		Where RowNum > @MaxRow
		Set @Rowcount = @@RowCount

	--ALTER INDEX [IX_ArchiveRef] ON Relational.AdditionalCashbackAward  REBUILD
	--ALTER INDEX [IX_MatchID] ON Relational.AdditionalCashbackAward  REBUILD

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE(),
			TableRowCount = @RowCount
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'AdditionalCashbackAward' and
			EndDate is null
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
