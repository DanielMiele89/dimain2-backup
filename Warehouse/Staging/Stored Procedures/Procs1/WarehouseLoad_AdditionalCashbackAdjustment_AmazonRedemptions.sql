/*

	Author:		Stuart Barnley

	Date:		19th January 2017

	Purpose:	To seperate the Additional Cashback Adjustments for Amazon into 6 types
				(3 x earn, 3 x refund)

*/
CREATE Procedure [Staging].[WarehouseLoad_AdditionalCashbackAdjustment_AmazonRedemptions]
--with Execute as Owner
as
Begin

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	Declare @RowCount int
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAdjustment_AmazonRedemptions',
		TableSchemaName = 'Relational',
		TableName = 'AdditionalCashbackAdjustment',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

	/*--------------------------------------------------------------------------------------------------
	------------------------Find Transactions for Earn while you burn bonus-----------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Trans') is not null drop table #Trans
	Select	t.TypeiD,
			t.FanID,
			t.ProcessDate,
			t.ClubCash* tt.Multiplier	as CashbackEarned,
			t.ActivationDays,
			t.ItemID
	Into #Trans
	From SLC_Report.dbo.Trans as t with (Nolock)
	inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
		on t.TypeID = tt.ID		
	inner join Relational.Customer as c with (Nolock)
			on t.FanID = c.FanID
	Where TypeID in (26,27)

	Create Clustered Index i_Trans_ItemID on #Trans (ItemID)
	/*--------------------------------------------------------------------------------------------------
	-------------------------------------Find out which Redemption--------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into [Relational].[AdditionalCashbackAdjustment]
	Select	a.FanID,
			a.ProcessDate,
			a.CashbackEarned,
			a.ActivationDays,
			Case
				-- Amazon
				When b.ItemID = 7236 and a.TypeID = 26 then 77
				When b.ItemID = 7238 and a.TypeID = 26 then 78
				When b.ItemID = 7240 and a.TypeID = 26 then 79
				When b.ItemID = 7236 and a.TypeID = 27 then 80
				When b.ItemID = 7238 and a.TypeID = 27 then 81
				When b.ItemID = 7240 and a.TypeID = 27 then 82
				-- M&S
				When b.ItemID = 7242 and a.TypeID = 26 then 83
				When b.ItemID = 7243 and a.TypeID = 26 then 84
				When b.ItemID = 7244 and a.TypeID = 26 then 85
				When b.ItemID = 7242 and a.TypeID = 27 then 86
				When b.ItemID = 7243 and a.TypeID = 27 then 87
				When b.ItemID = 7244 and a.TypeID = 27 then 88
				-- B&Q
				When b.ItemID = 7248 and a.TypeID = 26 then 95
				When b.ItemID = 7249 and a.TypeID = 26 then 96
				When b.ItemID = 7250 and a.TypeID = 26 then 97
				When b.ItemID = 7248 and a.TypeID = 27 then 98
				When b.ItemID = 7249 and a.TypeID = 27 then 99
				When b.ItemID = 7250 and a.TypeID = 27 then 100
				--Argos
				When b.ItemID = 7256 and a.TypeID = 26 then 101
				When b.ItemID = 7257 and a.TypeID = 26 then 102
				When b.ItemID = 7258 and a.TypeID = 26 then 103
				When b.ItemID = 7256 and a.TypeID = 27 then 104
				When b.ItemID = 7257 and a.TypeID = 27 then 105
				When b.ItemID = 7258 and a.TypeID = 27 then 106

				Else 0
			End as [AdditionalCashbackAdjustmentTypeID]
	From #Trans as a
	inner join SLC_report.dbo.Trans as b with (Nolock)
		on a.ItemID = b.ID
	SET @RowCount = @@ROWCOUNT
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAdjustment_AmazonRedemptions' and
			TableSchemaName = 'Relational' and
			TableName = 'AdditionalCashbackAdjustment' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = @RowCount
	where	StoredProcedureName = 'WarehouseLoad_AdditionalCashbackAdjustment_AmazonRedemptions' and
			TableSchemaName = 'Relational' and
			TableName = 'AdditionalCashbackAdjustment' and
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

End