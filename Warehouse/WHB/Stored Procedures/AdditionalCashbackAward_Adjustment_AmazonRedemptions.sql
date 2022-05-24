/*

	Author:		Stuart Barnley

	Date:		19th January 2017

	Purpose:	To seperate the Additional Cashback Adjustments for Amazon into 6 types
				(3 x earn, 3 x refund)

*/
CREATE PROCEDURE [WHB].[AdditionalCashbackAward_Adjustment_AmazonRedemptions]
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
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
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
	 t.ID TranID,
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

	-- ItemID is ID from SLC_REPORT.dbo.Redeem
	-- TypeID is 26 (EAYB earnings) or 27 (EAYB earnings reversal) from the SLC_Report.dbo.TransactionType table
	-- AdditionalCashbackAdjustmentTypeID ("THEN" clauses) links to the AdditionalCashbackAdjustmentTypeID in the Warehouse.Relational.AdditionalCashbackAdjustmentType table- this table is populated manually

	/******************************************************************************
	-- Example manual inset into Warehouse.Relational.AdditionalCashbackAdjustmentType
	
	INSERT INTO Warehouse.Relational.AdditionalCashbackAdjustmentType (TypeID, ItemID, [Description], AdditionalCashbackAdjustmentCategoryID) 
	SELECT 
	26 AS TypeID
	, 0 AS ItemID
	, CONCAT('John Lewis Partnership ',SUBSTRING(r.[Description], CHARINDEX('£',  r.[Description]), 3), ' eGift card Earn Back') AS [Description]
	, 4 AS AdditionalCashbackAdjustmentCategoryID
	FROM SLC_Report.dbo.Redeem r
	WHERE 
	r.[Description] LIKE '%Lewis%'
	AND r.[Status] = 1
	
	UNION ALL
	
	SELECT 
	27 AS TypeID
	, 0 AS ItemID
	, CONCAT('John Lewis Partnership ',SUBSTRING(r.[Description], CHARINDEX('£',  r.[Description]), 3), ' eGift card Earn Cancelled') AS 'Description'
	, 4 AS AdditionalCashbackAdjustmentCategoryID
	FROM SLC_Report.dbo.Redeem r
	WHERE
	r.[Description] LIKE '%Lewis%'
	AND r.[Status] = 1
	ORDER BY 
	TypeID
	, [Description];
	******************************************************************************/

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

				When b.ItemID =  7274 and a.TypeID = 26 THEN 152
				When b.ItemID =  7274 and a.TypeID = 27 THEN 155
				When b.ItemID =  7275 and a.TypeID = 26 THEN 151
				When b.ItemID =  7275 and a.TypeID = 27 THEN 154
				When b.ItemID =  7276 and a.TypeID = 26 THEN 150
				When b.ItemID =  7276 and a.TypeID = 27 THEN 153

				-- B&Q
				When b.ItemID = 7248 and a.TypeID = 26 then 95
				When b.ItemID = 7249 and a.TypeID = 26 then 96
				When b.ItemID = 7250 and a.TypeID = 26 then 97
				When b.ItemID = 7248 and a.TypeID = 27 then 98
				When b.ItemID = 7249 and a.TypeID = 27 then 99
				When b.ItemID = 7250 and a.TypeID = 27 then 100

				When b.ItemID =  7279 and a.TypeID = 26 THEN 144
				When b.ItemID =  7279 and a.TypeID = 27 THEN 147
				When b.ItemID =  7277 and a.TypeID = 26 THEN 146
				When b.ItemID =  7277 and a.TypeID = 27 THEN 149
				When b.ItemID =  7278 and a.TypeID = 26 THEN 145
				When b.ItemID =  7278 and a.TypeID = 27 THEN 148

				-- Argos
				When b.ItemID = 7256 and a.TypeID = 26 then 101
				When b.ItemID = 7257 and a.TypeID = 26 then 102
				When b.ItemID = 7258 and a.TypeID = 26 then 103
				When b.ItemID = 7256 and a.TypeID = 27 then 104
				When b.ItemID = 7257 and a.TypeID = 27 then 105
				When b.ItemID = 7258 and a.TypeID = 27 then 106
				-- John Lewis
				When b.ItemID = 7260 and a.TypeID = 26 then 107
				When b.ItemID = 7261 and a.TypeID = 26 then 108
				When b.ItemID = 7262 and a.TypeID = 26 then 109
				When b.ItemID = 7260 and a.TypeID = 27 then 110
				When b.ItemID = 7261 and a.TypeID = 27 then 111
				When b.ItemID = 7262 and a.TypeID = 27 then 112
				-- Greggs
				When b.ItemID = 7264 and a.TypeID = 26 then 114
				When b.ItemID = 7265 and a.TypeID = 26 then 115
				When b.ItemID = 7266 and a.TypeID = 26 then 116
				When b.ItemID = 7264 and a.TypeID = 27 then 117
				When b.ItemID = 7265 and a.TypeID = 27 then 118
				When b.ItemID = 7266 and a.TypeID = 27 then 119
				-- Morrisons
				When b.ItemID = 7268 and a.TypeID = 26 then 126
				When b.ItemID = 7269 and a.TypeID = 26 then 127
				When b.ItemID = 7270 and a.TypeID = 26 then 128
				When b.ItemID = 7268 and a.TypeID = 27 then 129
				When b.ItemID = 7269 and a.TypeID = 27 then 130
				When b.ItemID = 7270 and a.TypeID = 27 then 131
				--	Nero
				When b.ItemID =  7283 and a.TypeID = 26 THEN 140
				When b.ItemID =  7283 and a.TypeID = 27 THEN 143
				When b.ItemID =  7284 and a.TypeID = 26 THEN 139
				When b.ItemID =  7284 and a.TypeID = 27 THEN 142
				When b.ItemID =  7285 and a.TypeID = 26 THEN 138
				When b.ItemID =  7285 and a.TypeID = 27 THEN 141
				--	Curry's
				When b.ItemID =  7271 and a.TypeID = 26 THEN 158
				When b.ItemID =  7271 and a.TypeID = 27 THEN 161
				When b.ItemID =  7273 and a.TypeID = 26 THEN 156
				When b.ItemID =  7273 and a.TypeID = 27 THEN 159
				When b.ItemID =  7272 and a.TypeID = 26 THEN 157
				When b.ItemID =  7272 and a.TypeID = 27 THEN 160
				--	TK Maxx
				When b.ItemID =  7280 and a.TypeID = 26 THEN 134
				When b.ItemID =  7280 and a.TypeID = 27 THEN 137
				When b.ItemID =  7282 and a.TypeID = 26 THEN 132
				When b.ItemID =  7282 and a.TypeID = 27 THEN 135
				When b.ItemID =  7281 and a.TypeID = 26 THEN 133
				When b.ItemID =  7281 and a.TypeID = 27 THEN 136

				Else 0
			End as [AdditionalCashbackAdjustmentTypeID]
	From #Trans as a
	inner join SLC_report.dbo.Trans as b with (Nolock)
		on a.ItemID = b.ID
	SET @RowCount = @@ROWCOUNT


	--------------------------------------------------------------------
	-- new FIFO table
	--------------------------------------------------------------------
	Insert into [Relational].[AdditionalCashbackAdjustment_incTranID]
	Select	a.FanID,
			a.tranID, 
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

				When b.ItemID =  7274 and a.TypeID = 26 THEN 152
				When b.ItemID =  7274 and a.TypeID = 27 THEN 155
				When b.ItemID =  7275 and a.TypeID = 26 THEN 151
				When b.ItemID =  7275 and a.TypeID = 27 THEN 154
				When b.ItemID =  7276 and a.TypeID = 26 THEN 150
				When b.ItemID =  7276 and a.TypeID = 27 THEN 153

				-- B&Q
				When b.ItemID = 7248 and a.TypeID = 26 then 95
				When b.ItemID = 7249 and a.TypeID = 26 then 96
				When b.ItemID = 7250 and a.TypeID = 26 then 97
				When b.ItemID = 7248 and a.TypeID = 27 then 98
				When b.ItemID = 7249 and a.TypeID = 27 then 99
				When b.ItemID = 7250 and a.TypeID = 27 then 100

				When b.ItemID =  7279 and a.TypeID = 26 THEN 144
				When b.ItemID =  7279 and a.TypeID = 27 THEN 147
				When b.ItemID =  7277 and a.TypeID = 26 THEN 146
				When b.ItemID =  7277 and a.TypeID = 27 THEN 149
				When b.ItemID =  7278 and a.TypeID = 26 THEN 145
				When b.ItemID =  7278 and a.TypeID = 27 THEN 148

				-- Argos
				When b.ItemID = 7256 and a.TypeID = 26 then 101
				When b.ItemID = 7257 and a.TypeID = 26 then 102
				When b.ItemID = 7258 and a.TypeID = 26 then 103
				When b.ItemID = 7256 and a.TypeID = 27 then 104
				When b.ItemID = 7257 and a.TypeID = 27 then 105
				When b.ItemID = 7258 and a.TypeID = 27 then 106
				-- John Lewis
				When b.ItemID = 7260 and a.TypeID = 26 then 107
				When b.ItemID = 7261 and a.TypeID = 26 then 108
				When b.ItemID = 7262 and a.TypeID = 26 then 109
				When b.ItemID = 7260 and a.TypeID = 27 then 110
				When b.ItemID = 7261 and a.TypeID = 27 then 111
				When b.ItemID = 7262 and a.TypeID = 27 then 112
				-- Greggs
				When b.ItemID = 7264 and a.TypeID = 26 then 114
				When b.ItemID = 7265 and a.TypeID = 26 then 115
				When b.ItemID = 7266 and a.TypeID = 26 then 116
				When b.ItemID = 7264 and a.TypeID = 27 then 117
				When b.ItemID = 7265 and a.TypeID = 27 then 118
				When b.ItemID = 7266 and a.TypeID = 27 then 119
				-- Morrisons
				When b.ItemID = 7268 and a.TypeID = 26 then 126
				When b.ItemID = 7269 and a.TypeID = 26 then 127
				When b.ItemID = 7270 and a.TypeID = 26 then 128
				When b.ItemID = 7268 and a.TypeID = 27 then 129
				When b.ItemID = 7269 and a.TypeID = 27 then 130
				When b.ItemID = 7270 and a.TypeID = 27 then 131
				--	Nero
				When b.ItemID =  7283 and a.TypeID = 26 THEN 140
				When b.ItemID =  7283 and a.TypeID = 27 THEN 143
				When b.ItemID =  7284 and a.TypeID = 26 THEN 139
				When b.ItemID =  7284 and a.TypeID = 27 THEN 142
				When b.ItemID =  7285 and a.TypeID = 26 THEN 138
				When b.ItemID =  7285 and a.TypeID = 27 THEN 141
				--	Curry's
				When b.ItemID =  7271 and a.TypeID = 26 THEN 158
				When b.ItemID =  7271 and a.TypeID = 27 THEN 161
				When b.ItemID =  7273 and a.TypeID = 26 THEN 156
				When b.ItemID =  7273 and a.TypeID = 27 THEN 159
				When b.ItemID =  7272 and a.TypeID = 26 THEN 157
				When b.ItemID =  7272 and a.TypeID = 27 THEN 160
				--	TK Maxx
				When b.ItemID =  7280 and a.TypeID = 26 THEN 134
				When b.ItemID =  7280 and a.TypeID = 27 THEN 137
				When b.ItemID =  7282 and a.TypeID = 26 THEN 132
				When b.ItemID =  7282 and a.TypeID = 27 THEN 135
				When b.ItemID =  7281 and a.TypeID = 26 THEN 133
				When b.ItemID =  7281 and a.TypeID = 27 THEN 136

				Else 0
			End as [AdditionalCashbackAdjustmentTypeID]
	From #Trans as a
	inner join SLC_report.dbo.Trans as b with (Nolock)
		on a.ItemID = b.ID


	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
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
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
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