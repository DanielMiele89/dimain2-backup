
/*
		WarehouseLoad_AdditionalCashbackAwardsV1_11_Append

		Author:		Stuart Barnley
		Date:		07th July 2014

		Purpose:	Additional Cashback Awards - This pull off all the additional
					Cashback Awards. This will start with contactless, then Credit Card.

		Notes:		Point 1 - this loops back to match table, we may have to revisit this for speed later.

					30-09-2014 SB - This update makes ure it is only include customers from the customer table.
					12-06-2015 SB -This is updated to include DirectDebitOriginatorID
					30-09-2015 SB - Optimised on advice of DBA
					09-02-2016 SB - change made to deal with indexes
					30-06-2016 SB - Changed to load only new rows (using added date/processed date)
					20180523 cjm disabled/enabled IX_Stuff, increased chunksize
					31-03-2020 ZT - changed the case statement on the main table load to incclude typeid 29 fnr Reward 30 and changes the is NOT null to IS NULL on directdebitoriginatorid
*/
CREATE PROCEDURE [WHB].[AdditionalCashbackAward_V2_Append_DEV]
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/*******************************************************************************************************************************************
	1.	Write entry to JobLog Table
*******************************************************************************************************************************************/

	INSERT INTO [Staging].[JobLog_temp]
	SELECT	StoredProcedureName = OBJECT_NAME(@@PROCID)
		,	TableSchemaName = 'Relational'
		,	TableName = 'AdditionalCashbackAward'
		,	StartDate = GETDATE()
		,	EndDate = NULL
		,	TableRowCount  = NULL
		,	AppendReload = 'R'


/*******************************************************************************************************************************************
	2.	Measure Index Fragmentation 
*******************************************************************************************************************************************/

	DECLARE @avg_frag DECIMAL(5,2)
	SELECT	@avg_frag = SUM(avg_fragmentation_in_percent) / COUNT(*)
	FROM sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID('Relational.AdditionalCashbackAward'), NULL, NULL, 'LIMITED') ips
	WHERE ips.Index_id > 1


/*******************************************************************************************************************************************
	3.	Fetch Transaction Types
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Types') IS NOT NULL DROP TABLE #Types
	SELECT	aca.AdditionalCashbackAwardTypeID
		,	aca.Title
		,	aca.TransactionTypeID
		,	aca.ItemID
		,	aca.Description
		,	aca.PartnerCommissionRuleID
		,	tt.Multiplier
	INTO #Types
	FROM [Relational].[AdditionalCashbackAwardType] aca
	INNER JOIN [SLC_Report].[dbo].[TransactionType] tt
		ON aca.TransactionTypeID = tt.ID

	CREATE CLUSTERED INDEX CIX_TypeItemID ON #Types (TransactionTypeID, ItemID, Multiplier)


/*******************************************************************************************************************************************
	4.	Find last rows inserted
*******************************************************************************************************************************************/

	DECLARE @AddedDateTime DATETIME
		,	@ACA_ID INT

	SELECT	@AddedDateTime = MAX(AddedDate)
		,	@ACA_ID = MAX(AdditionalCashbackAwardID)
	FROM [Relational].[AdditionalCashbackAward] aca
	
	SET @AddedDateTime = DATEADD(DAY, 1, @AddedDateTime)

/*******************************************************************************************************************************************
	6.	Get Additional Cashback Awards with a PanID
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans;
	WITH
	Trans AS (	SELECT TOP 2500000 *
				FROM [SLC_Report].[dbo].[Trans] tr
				ORDER BY ID DESC)

	SELECT *
	INTO #Trans
	FROM Trans tr
	WHERE tr.VectorMajorID IS NOT NULL
	AND tr.VectorMinorID IS NOT NULL
	AND tr.ProcessDate >= @AddedDateTime

	CREATE NONCLUSTERED INDEX IX_PanID ON #Trans (PanID)

	IF OBJECT_ID('tempdb..#Pan') IS NOT NULL DROP TABLE #Pan;
	SELECT	pa.ID
		,	pa.PaymentCardID
	INTO #Pan
	FROM [SLC_Report].[dbo].[Pan] pa
	WHERE EXISTS (	SELECT 1
					FROM #Trans tr
					WHERE pa.ID = tr.PanID)

	CREATE CLUSTERED INDEX CIX_PaymentCardID ON #Pan (PaymentCardID)

	IF OBJECT_ID('tempdb..#PaymentCard') IS NOT NULL DROP TABLE #PaymentCard;
	SELECT	pa.ID AS PanID
		,	pc.CardTypeID
	INTO #PaymentCard
	FROM #Pan pa
	INNER JOIN [SLC_Report].[dbo].[PaymentCard] pc
		ON pa.PaymentCardID = pc.ID

	CREATE CLUSTERED INDEX CIX_All ON #PaymentCard (PanID, CardTypeID)

	IF OBJECT_ID('tempdb..#AdditionalCashbackAward') IS NOT NULL DROP TABLE #AdditionalCashbackAward
	SELECT	t.Matchid AS MatchID
		,	t.VectorMajorID AS FileID
		,	t.VectorMinorID AS RowNum
		,	t.FanID
		,	t.[Date] AS TranDate
		,	t.ProcessDate AS AddedDate
		,	t.Price AS Amount
		,	t.ClubCash*tt.Multiplier AS CashbackEarned
		,	t.ActivationDays
		,	tt.AdditionalCashbackAwardTypeID
		,	CASE
				WHEN pc.CardTypeID = 1 THEN 1 -- Credit Card
				WHEN pc.CardTypeID = 2 THEN 0 -- Debit Card
				WHEN t.DirectDebitOriginatorID IS NOT NULL THEN 2 -- Direct Debit
				WHEN t.DirectDebitOriginatorID IS NULL AND t.typeid = 29 THEN 2 -- Direct Debit-- ZT 31/032020 changed the clause to IS NULL and included the R30 typeid
				WHEN tt.AdditionalCashbackAwardTypeID = 11 THEN 1 -- ApplyPay and Credit Card
				ELSE 0
			END AS PaymentMethodID
		,	t.DirectDebitOriginatorID
	INTO #AdditionalCashbackAward
	FROM #Types tt
	INNER JOIN #Trans t
		ON tt.ItemID = t.ItemID 
		AND tt.TransactionTypeID = t.TypeID
	LEFT JOIN #PaymentCard pc
		ON t.PanID = pc.PanID


/*******************************************************************************************************************************************
	5.	Disable the indexes for later rebuild if fragmentation >= 1%
*******************************************************************************************************************************************/

	IF @avg_frag >= 1
		BEGIN
			ALTER INDEX [IX_ArchiveRef] ON [Relational].[AdditionalCashbackAward] DISABLE
			ALTER INDEX [IX_MatchID] ON [Relational].[AdditionalCashbackAward] DISABLE
			ALTER INDEX [ix_Stuff] ON [Relational].[AdditionalCashbackAward] DISABLE
		END


	/*--------------------------------------------------------------------------------------------------
	------------------------ Remove those records with a MatchID and no TRANS record ---------------------
	----------------------------------------------------------------------------------------------------*/
	Update aca
		Set MatchID = m.ID
	from Relational.AdditionalCashbackAward as aca
	inner join SLC_Report..match as m with (nolock)
		on	aca.FileID = m.VectorMajorID and
			aca.RowNum = m.VectorMinorID
	inner join Relational.PartnerTrans as pt
		on	m.ID = pt.MatchID
	Where aca.AdditionalCashbackAwardID >= @ACA_ID



	-- Rebuild the indexes if necessary 
	IF @avg_frag >= 10 BEGIN
		ALTER INDEX [ix_Stuff] ON Relational.AdditionalCashbackAward  REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR=80, SORT_IN_TEMPDB = ON) -- CJM 20190212
		ALTER INDEX [IX_ArchiveRef] ON Relational.AdditionalCashbackAward  REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR=80, SORT_IN_TEMPDB = ON) -- CJM 20190212
		ALTER INDEX [IX_MatchID] ON Relational.AdditionalCashbackAward  REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR=80, SORT_IN_TEMPDB = ON) -- CJM 20190212
	END



	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'AdditionalCashbackAward' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	--Update  staging.JobLog_Temp
	--Set		TableRowCount = (Select COUNT(*) - @ACA_RowNo from Relational.AdditionalCashbackAward)
	--where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
	--		TableSchemaName = 'Relational' and
	--		TableName = 'AdditionalCashbackAward' and
	--		TableRowCount is null
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