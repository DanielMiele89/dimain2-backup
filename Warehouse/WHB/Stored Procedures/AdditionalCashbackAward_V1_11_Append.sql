
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
					28-04-2021 RF - Date filter for which transactions to process pushed back to allow previous days transactions through, where not exists added to insert query to prevent dupes
					06/08/2021 CJM Pull Trans rows to temp table for perf lift
*/
CREATE PROCEDURE [WHB].[AdditionalCashbackAward_V1_11_Append]
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	DECLARE 
		@time DATETIME,
		@msg VARCHAR(2048),
		@SSMS BIT

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	EXEC dbo.oo_TimerMessageV2 'Start process [WarehouseLoad_AdditionalCashbackAwardsV1_11_Append]', @time OUTPUT, @SSMS OUTPUT



	/* Measure index fragmentation of the AdditionalCashbackAwards table */
	--DECLARE @avg_frag DECIMAL(5,2)
	--SELECT 
	--	@avg_frag = SUM(avg_fragmentation_in_percent) / COUNT(*)
	--FROM sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID('Relational.AdditionalCashbackAward'),NULL,NULL,'LIMITED') ips
	--WHERE ips.Index_id > 1

	--SELECT @avg_frag

	EXEC dbo.oo_TimerMessageV2 'Measured fragmentation in Relational.AdditionalCashbackAward', @time OUTPUT, @SSMS OUTPUT


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
			AppendReload = 'R'

	/*--------------------------------------------------------------------------------------------------
	------------------------------------populate customer Table-----------------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Customer') is not null drop table #Customer
	Select FanID,ROW_NUMBER() OVER(ORDER BY FanID ASC) AS RowNo
	Into #Customer
	From Relational.Customer

	Create Clustered Index ix_Customer_FanID on #Customer (FanID)

	EXEC dbo.oo_TimerMessageV2 'Customer table created', @time OUTPUT, @SSMS OUTPUT

	/*--------------------------------------------------------------------------------------------------
	------------------------------------Create Types Table Table---------------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Types') is not null drop table #Types
	Select aca.*,tt.Multiplier
	Into #Types
	From Relational.[AdditionalCashbackAwardType] as aca
	inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
		on	aca.TransactionTypeID = tt.ID

	EXEC dbo.oo_TimerMessageV2 'Types table created', @time OUTPUT, @SSMS OUTPUT

	----------------------------------------------------------------------------------------
	-----------------------------------Set Parameters---------------------------------------
	----------------------------------------------------------------------------------------
	Declare @MaxDay date,
			@RowNo int = 1,
			@MaxRowNo int = (Select Max(RowNo) from #Customer),
			@ChunkSize int = 1000000, --250000,
			@AddedDate date, --********Date of last transaction********--
			@AddedDateTime datetime, --********Datetime of last transaction********--
			@ACA_ID int

		 , @RowCount BIGINT = 0
		

	--------------------------------------------------------------------------------------
	------------------------------Find Last record Imported-------------------------------
	--***Find the last processed date so that we only import rows after this day***---
	--------------------------------------------------------------------------------------
	SELECT 
		@AddedDate = Max(AddedDate), 
		@ACA_ID = Max(AdditionalCashbackAwardID)
	FROM Relational.AdditionalCashbackAward as aca				

	Set @AddedDate = Dateadd(day, -2, @AddedDate)
	Set @AddedDateTime = @AddedDate

	SET @msg = 'Max ID and Date recorded [' + CAST(@ACA_ID AS VARCHAR(12)) + '], [' + CONVERT(VARCHAR(30),@AddedDate,121) + ']'
	EXEC dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT


	--------------------------------------------------------------------------------------
	--------------------Collect qualifying Trans rows to temp table-----------------------
	--------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT	ItemID
		,	TypeID
		,	Matchid
		,	VectorMajorID
		,	VectorMinorID
		,	FanID
		,	[Date]
		,	ProcessDate
		,	Price
		,	ClubCash
		,	ActivationDays
		,	DirectDebitOriginatorID
		,	PanID
		,	CardTypeID = CONVERT(INT, NULL)
	INTO #Trans
	FROM [SLC_Report].[dbo].[Trans] t 
	WHERE t.VectorMajorID IS NOT NULL
	AND t.VectorMinorID IS NOT NULL
	AND t.ProcessDate >= @AddedDateTime
	AND NOT EXISTS (	SELECT 1
						FROM [Relational].[AdditionalCashbackAward] aca
						WHERE t.VectorMajorID = aca.FileID
						AND t.VectorMinorID = aca.RowNum)

	EXEC dbo.oo_TimerMessageV2 'Trans extract created', @time OUTPUT, @SSMS OUTPUT

	CREATE CLUSTERED INDEX CIX_FanID ON #Trans (FanID)
	CREATE NONCLUSTERED INDEX IX_ItemType ON #Trans (ItemID, TypeID)
	CREATE NONCLUSTERED INDEX IX_FanID ON #Trans (PanID)

	EXEC dbo.oo_TimerMessageV2 'Trans extract indexed', @time OUTPUT, @SSMS OUTPUT
						
	IF OBJECT_ID('tempdb..#PanPaymentCard') IS NOT NULL DROP TABLE #PanPaymentCard
	SELECT	PanID = pa.ID
		,	CardTypeID = pc.CardTypeID
	INTO #PanPaymentCard
	FROM [SLC_Report].[dbo].[Pan] pa
	LEFT JOIN [SLC_Report].[dbo].[PaymentCard] pc
		ON pa.PaymentCardID = pc.ID
	WHERE EXISTS (	SELECT 1
					FROM #Trans tr
					WHERE tr.PanID = pa.ID)

	EXEC dbo.oo_TimerMessageV2 'Pan Payment Card extract created', @time OUTPUT, @SSMS OUTPUT

	UPDATE tr
	SET tr.CardTypeID = ppc.CardTypeID
	FROM #Trans tr
	INNER JOIN #PanPaymentCard ppc
		ON tr.PanID = ppc.PanID

	EXEC dbo.oo_TimerMessageV2 'CardTypeID in Trans extract updated', @time OUTPUT, @SSMS OUTPUT


	--------------------------------------------------------------------------------------
	--------------------Pull data and add MatchIDs where appropriate----------------------
	--------------------------------------------------------------------------------------
	if object_id('tempdb..#Customer_Temp') is not null drop table #Customer_Temp
		Create Table #Customer_Temp (FanID int, Primary Key (FanID))
	--This process uses the #AddedDays table to pull the data in chunks

	--IF @avg_frag >= 1 BEGIN -- disable the indexes for later rebuild if fragmentation >= 1%
	--	ALTER INDEX [IX_ArchiveRef] ON Relational.AdditionalCashbackAward DISABLE
	--	ALTER INDEX [IX_MatchID] ON Relational.AdditionalCashbackAward DISABLE
	--	ALTER INDEX [ix_Stuff] ON Relational.AdditionalCashbackAward DISABLE
	--END

	While @RowNo <= @MaxRowNo
	Begin
		------------------------------------------------------------------------------
		------------------------------ Find specific customers -----------------------
		------------------------------------------------------------------------------
	
		Insert into #Customer_Temp	
		Select	FanID
		From	#Customer as c
		Where	c.RowNo Between @RowNo and @RowNo + (@ChunkSize-1)
	
		------------------------------------------------------------------------------
		--------------Get Additional Cashback Awards with a PanID---------------------
		------------------------------------------------------------------------------
		Insert Into Relational.AdditionalCashbackAward	
		select t.Matchid as MatchID,
			   t.VectorMajorID as FileID,
			   t.VectorMinorID as RowNum,
			   t.FanID,
			   t.[Date] as TranDate,
			   t.ProcessDate as AddedDate,
			   t.Price as Amount,
			   t.ClubCash*tt.Multiplier as CashbackEarned,
			   t.ActivationDays,
			   tt.AdditionalCashbackAwardTypeID,
			   Case
					When t.CardTypeID = 1 then 1 -- Credit Card
					When t.CardTypeID = 2 then 0 -- Debit Card
					When t.DirectDebitOriginatorID IS not null then 2 -- Direct Debit
					When t.DirectDebitOriginatorID IS null and t.typeid = 29 then 2 -- Direct Debit-- ZT 31/032020 changed the clause to IS NULL and included the R30 typeid
					When tt.AdditionalCashbackAwardTypeID = 11 then 1 -- ApplyPay and Credit Card
					Else 0
			   End as PaymentMethodID,
			   t.DirectDebitOriginatorID
			    
		from #Types as tt
	
		inner join #Trans as t with (nolock)
			on tt.ItemID = t.ItemID 
			and tt.TransactionTypeID = t.TypeID
		inner join #Customer_Temp as c
			on t.FanID = c.fanid
	
		SET @RowCount = @RowCount + @@ROWCOUNT

		Truncate Table #Customer_Temp
	
		Set @RowNo = @RowNo+@ChunkSize

		EXEC dbo.oo_TimerMessageV2 'Finished INSERT loop', @time OUTPUT, @SSMS OUTPUT

	End






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

	EXEC dbo.oo_TimerMessageV2 'Finished update', @time OUTPUT, @SSMS OUTPUT

	-- Rebuild the indexes if necessary 
	--IF @avg_frag >= 10 BEGIN
	--	ALTER INDEX [ix_Stuff] ON Relational.AdditionalCashbackAward  REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR=80, SORT_IN_TEMPDB = ON) -- CJM 20190212
	--	ALTER INDEX [IX_ArchiveRef] ON Relational.AdditionalCashbackAward  REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR=80, SORT_IN_TEMPDB = ON) -- CJM 20190212
	--	ALTER INDEX [IX_MatchID] ON Relational.AdditionalCashbackAward  REBUILD WITH (DATA_COMPRESSION = PAGE, FILLFACTOR=80, SORT_IN_TEMPDB = ON) -- CJM 20190212
	--END

	IF @@SERVERNAME = 'DIMAIN2'
		BEGIN
			UPDATE STATISTICS Relational.AdditionalCashbackAward 
		END

	EXEC dbo.oo_TimerMessageV2 'Finished index rebuild', @time OUTPUT, @SSMS OUTPUT -- about 30 minutes 

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
	Update  staging.JobLog_Temp
	Set		TableRowCount = @RowCount
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
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