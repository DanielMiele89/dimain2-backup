/*
PartitionSwitching_LoadCTtable_MyRewards_CJM
Calls
	Staging.PartitionSwitching_CreateShadowTable_MyRewards_CJM

Grab last weeks data into ConsumerTransaction_MyRewards
1. Current rows from ConsumerTransactionHolding, filtered by [Relational].CINList, [Relational].Customer and MI.CINDuplicate
2. Remaining rows from ConsumerTransactionHolding, filtered by InsightArchive.oldcin
3. From ConsumerTransaction, filtered by InsightArchive.newcin and date
4. All rows from [Relational].ConsumerTransaction_CreditCardHolding

Migration CJM 01/09/2021 commented out index disable / rebuild

*/
create PROCEDURE [Staging].[PartitionSwitching_LoadCTtable_MyRewards]
	WITH EXECUTE AS OWNER
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

EXEC [MI].[ProcessLog_Insert] 'PartitionSwitching_LoadCTtable_MyRewards', 'Program Started'

DECLARE	@Time1 DATETIME = GETDATE()
	,	@msg VARCHAR(4000)
	,	@Statement VARCHAR(8000)
	,	@RowsAffected INT 

EXEC [Staging].[oo_TimerMessage] 'Start', @Time1


-----------------------------------------------------------------------------------------------------------------
-- Add a new partition to the end of the table, if necessary.
-- This step replaces [Staging].[PartitionSwitching_CreatePartition_MyRewards]
-----------------------------------------------------------------------------------------------------------------

	DECLARE @MaxPartitionDate DATETIME

	SELECT @MaxPartitionDate = CONVERT(DATETIME,MAX(prv.[Value]),120) 
	FROM [sys].[partition_range_values] prv
	INNER JOIN [sys].[partition_functions] pf 
		ON pf.function_id = prv.function_id
	WHERE pf.[Name] = 'PartitionByMonthFunction_CTR'

	IF @MaxPartitionDate < DATEADD(DAY,1,EOMONTH(GETDATE())) BEGIN

		DECLARE @MonthToMove DATE = DATEADD(MONTH,1,@MaxPartitionDate);
	
		ALTER PARTITION SCHEME PartitionByMonthScheme_CTR NEXT USED fg_ConsumerTransaction_MyRewards; 
		ALTER PARTITION FUNCTION PartitionByMonthFunction_CTR() SPLIT RANGE (@MonthToMove); 

	END


---------------------------------------------------------------------------------------------------------------
 --Capture new MyRewards customers to newcin table
 --oldcin stores the complete list of customers from the last run
 --and is refreshed at the end of this program
---------------------------------------------------------------------------------------------------------------

	TRUNCATE TABLE [InsightArchive].[NewCIN]
	INSERT INTO [InsightArchive].[NewCIN] (CINID)
	SELECT c.CINID
	FROM [Relational].[CINList] c 
	INNER JOIN [Relational].[Customer] cu 
		ON C.CIN = CU.SourceUID
	WHERE NOT EXISTS (	SELECT 1
						FROM [MI].[CINDuplicate] d
						WHERE cu.fanid = d.fanid)
	EXCEPT
	SELECT CINID
	FROM [InsightArchive].[OldCIN]

	SET @RowsAffected = @@ROWCOUNT; 

	UPDATE STATISTICS [InsightArchive].[NewCIN]

	SET @msg = 'Collected [' + CAST(@RowsAffected AS VARCHAR(10)) + '] new CINs'
	EXEC [MI].[ProcessLog_Insert] 'PartitionSwitching_LoadCTtable_MyRewards', @msg
	

-----------------------------------------------------------------------------------------------------------------
-- Load the MR temporary holding table
-----------------------------------------------------------------------------------------------------------------

	-----------------------------------------------------------------------------------------------------------------
	-- Load the MR temporary holding table
	-- [1] Capture "new customer" debit card transactions from [ConsumerTransaction] [5,356,272 / 06:00:00]
	-- Note - The quantities per partition are not so different. 
	-----------------------------------------------------------------------------------------------------------------

		EXEC [Staging].[oo_TimerMessage] 'Loading Transactions', @Time1

		IF OBJECT_ID('tempdb..#MR_holding') IS NOT NULL DROP TABLE #MR_holding;
		SELECT	BatchID = 1
			,	ct.FileID
			,	ct.RowNum
			,	ct.ConsumerCombinationID
			,	ct.CardholderPresentData
			,	ct.TranDate
			,	ct.CINID
			,	ct.Amount
			,	ct.IsOnline
			,	PaymentTypeID = 1 
		INTO #MR_holding
		FROM [Relational].[ConsumerTransaction] ct
		INNER JOIN [InsightArchive].[NewCIN] n 
			ON ct.CINID = n.cinid
		-- (4,905,876 rows affected) / 00:03:20

		SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded DC data from ConsumerTrans, for new MyRewards CINs' + ' [' + CAST(@RowsAffected AS VARCHAR(10)) + ']' 
		EXEC [MI].[ProcessLog_Insert] 'PartitionSwitching_LoadCTtable_MyRewards', @msg


	-----------------------------------------------------------------------------------------------------------------
	-- Load the MR temporary holding table
	-- [2] Capture transactions from CT holding table 
	-- old CIN's only, because we've already collected the new CINs in the previous step
	-----------------------------------------------------------------------------------------------------------------

		INSERT INTO #MR_holding	(	BatchID
								,	FileID
								,	RowNum
								,	ConsumerCombinationID
								,	CardholderPresentData
								,	TranDate
								,	CINID
								,	Amount
								,	IsOnline
								,	PaymentTypeID)
		SELECT	BatchID = 3
			,	FileID
			,	RowNum
			,	ConsumerCombinationID
			,	CardholderPresentData
			,	TranDate
			,	cth.CINID
			,	Amount
			,	IsOnline
			,	PaymentTypeID = 1 
		FROM [Relational].[ConsumerTransactionHolding] cth
		INNER JOIN [InsightArchive].[OldCIN] o
			ON cth.CINID = o.CINID

		SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded DC data from CT holding table, for MyRewards CINs' + ' [' + CAST(@RowsAffected AS VARCHAR(10)) + ']' 
		EXEC [MI].[ProcessLog_Insert] 'PartitionSwitching_LoadCTtable_MyRewards', @msg


	-----------------------------------------------------------------------------------------------------------------
	-- Load the MR temporary holding table
	-- [3] Capture all credit card transactions from CreditCard holding table  [1,769,704 / 00:05:00]
	-----------------------------------------------------------------------------------------------------------------

		INSERT INTO #MR_holding	(	BatchID
								,	FileID
								,	RowNum
								,	ConsumerCombinationID
								,	CardholderPresentData
								,	TranDate
								,	CINID
								,	Amount
								,	IsOnline
								,	PaymentTypeID)
		SELECT	BatchID = 4
			,	FileID
			,	RowNum
			,	ConsumerCombinationID
			,	CardholderPresentData
			,	TranDate
			,	CINID
			,	Amount
			,	IsOnline
			,	PaymentTypeID = 2 
		FROM [Relational].[ConsumerTransaction_CreditCardHolding]
		-- (946,610 rows affected) / 00:00:01

		SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded CC data from CC holding' + ' [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; 
		EXEC [MI].[ProcessLog_Insert] 'PartitionSwitching_LoadCTtable_MyRewards', @msg

		CREATE CLUSTERED INDEX cx_Stuff ON #MR_holding (TranDate, CINID, ConsumerCombinationID)

		EXEC [Staging].[oo_TimerMessage] 'Loading #CTHolding', @Time1


-----------------------------------------------------------------------------------------------------------------
-- Calibrate the CT holding table
-----------------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#CTHolding') IS NOT NULL DROP TABLE #CTHolding;
	SELECT	d.PartitionID
		,	x.[filegroup_name]
		,	x.data_compression_desc
		,	d.[Rows]
		,	TranDate = DATEADD(MONTH,DATEDIFF(MONTH,0,TranDate),0)
		,	rn = ROW_NUMBER() OVER(ORDER BY PartitionID DESC)
	INTO #CTHolding
	FROM (
		SELECT 
			PartitionID = $PARTITION.PartitionByMonthFunction_CTR(Trandate), 
			TranDate = MIN(TranDate),
			[Rows] = COUNT(*)
		FROM #MR_holding 
		GROUP BY $PARTITION.PartitionByMonthFunction_CTR(Trandate)
	) d
	OUTER APPLY (
		SELECT [filegroup_name], data_compression_desc FROM dbo.il_GetFilegroupName('ConsumerTransaction_MyRewards', PartitionID) WHERE index_name = 'cx_CT'
	) x
	ORDER BY PartitionID DESC

	EXEC [MI].[ProcessLog_Insert] 'PartitionSwitching_LoadCTtable_MyRewards', 'Calibrated the CT holding table'



-----------------------------------------------------------------------------------------------------------------
-- Load the partitions one at a time from the holding table #MR_holding
-- 00:11:31 to here
-----------------------------------------------------------------------------------------------------------------

	EXEC [MI].[ProcessLog_Insert] 'PartitionSwitching_LoadCTtable_MyRewards', 'Partitions loading'

	DECLARE 
		@CurrentRow INT = 1 , 
		@strPartitionID VARCHAR(3),
		@CurrentPartitionStart DATE, 
		@strThisPartitionStartDate VARCHAR(8),
		@strNextPartitionStartDate VARCHAR(8),
		@StrFilegroupSuffix VARCHAR(6),
		@filegroup_name VARCHAR(100),
		@data_compression_desc VARCHAR(200),
		@ShadowTable VARCHAR(200),
		@TimeNow DATETIME

	WHILE 1 = 1 BEGIN

		SET @TimeNow = GETDATE() -- reset the timer

		SELECT 
			@strPartitionID = CAST(PartitionID AS VARCHAR(3)),
			@filegroup_name = [filegroup_name],
			@data_compression_desc = CASE WHEN PartitionID > 100 THEN 'PAGE' ELSE data_compression_desc END,
			@CurrentPartitionStart = TranDate, 
			@RowsAffected = [Rows] 
		FROM #CTHolding 
		WHERE rn = @CurrentRow 
		IF @@ROWCOUNT = 0 BREAK

		SELECT 
			@strThisPartitionStartDate = CONVERT(VARCHAR(8),@CurrentPartitionStart,112),
			@strNextPartitionStartDate = CONVERT(VARCHAR(8),DATEADD(MONTH,1,@CurrentPartitionStart),112)


		--------------------------------------------------------------------------------------------------------------------------
		-- Create the shadow table
		--------------------------------------------------------------------------------------------------------------------------

			EXEC [Staging].[PartitionSwitching_CreateShadowTable_MyRewards] @strPartitionID, @strThisPartitionStartDate, @strNextPartitionStartDate, @filegroup_name, @data_compression_desc

			SET @ShadowTable = '[Relational].[ConsumerTransaction_MyRewards_p' + @strPartitionID + '_Stage]'


		--------------------------------------------------------------------------------------------------------------------------
		-- Disable constraints & indexes on the shadow table - csx_stuff is READONLY, everything else is for perf.
		-- If the rowcount exceeds a threshold, disable the indexes
		--------------------------------------------------------------------------------------------------------------------------

			EXEC('ALTER TABLE ' + @ShadowTable + ' NOCHECK CONSTRAINT ALL')
			----EXEC('ALTER INDEX csx_Stuff ON ' + @ShadowTable + ' DISABLE') -- new cjm
			----IF @RowsAffected > 40000 BEGIN 
			----	EXEC('ALTER INDEX ix_Stuff01 ON ' + @ShadowTable + ' DISABLE')
			----	EXEC('ALTER INDEX PK_ConsumerTransaction_MyRewards_Stage_' + @strPartitionID + ' ON ' + @ShadowTable + ' DISABLE')
			----END


		--------------------------------------------------------------------------------------------------------------------------
		-- Switch live data to the shadow table for the partition of interest
		--------------------------------------------------------------------------------------------------------------------------

			EXEC('ALTER TABLE [Relational].[ConsumerTransaction_MyRewards] SWITCH PARTITION ' + @strPartitionID + ' TO ' + @ShadowTable) 


		--------------------------------------------------------------------------------------------------------------------------
		-- Load the switch table with the new data from the different sources
		--------------------------------------------------------------------------------------------------------------------------
		
			EXEC('INSERT INTO ' + @ShadowTable + ' WITH (TABLOCKX) (FileID
																,	RowNum, ConsumerCombinationID
																,	CardholderPresentData
																,	TranDate
																,	CINID
																,	Amount
																,	IsOnline
																,	PaymentTypeID)
				SELECT	DISTINCT  
						FileID
					,	RowNum
					,	ConsumerCombinationID
					,	CardholderPresentData
					,	TranDate
					,	CINID
					,	Amount
					,	IsOnline
					,	PaymentTypeID 
				FROM #MR_holding 
				WHERE [TranDate] >= ''' + @strThisPartitionStartDate + ''' AND [TranDate] < ''' + @strNextPartitionStartDate + '''')


		--------------------------------------------------------------------------------------------------------------------------
		-- Re-enable all constraints and indexes. Note that CheckTranDate has to be "trusted" i.e. entire shadow table must be checked.
		-- If the rowcount exceeds a threshold, rebuild the disabled indexes with their original compression status
		-- Note that the data compression property is not respected for REBUILD from a disabled index, it must be specifically stated.
		--------------------------------------------------------------------------------------------------------------------------

			EXEC('ALTER TABLE ' + @ShadowTable + ' CHECK CONSTRAINT ALL')
			EXEC('ALTER TABLE ' + @ShadowTable + ' WITH CHECK CHECK CONSTRAINT CheckTranDate_R_p' + @strPartitionID) 
			----EXEC('ALTER INDEX csx_Stuff ON ' + @ShadowTable + ' REBUILD')

			----IF @RowsAffected > 40000 BEGIN 
			----	SET @data_compression_desc = CASE WHEN @data_compression_desc = 'PAGE' THEN ' WITH (DATA_COMPRESSION = PAGE, SORT_IN_TEMPDB = ON)' ELSE '' END -- 
			----	EXEC('ALTER INDEX ix_Stuff01 ON ' + @ShadowTable + ' REBUILD' + @data_compression_desc)
			----	EXEC('ALTER INDEX PK_ConsumerTransaction_MyRewards_Stage_' + @strPartitionID + ' ON ' + @ShadowTable + ' REBUILD' + @data_compression_desc)
			----END


		--------------------------------------------------------------------------------------------------------------------------
		-- Switch shadow table contents back to main table then drop the shadow table, we're finished with it 
		--------------------------------------------------------------------------------------------------------------------------

			SET @msg = 'SWITCHING PARTITION [' + @strPartitionID + '] BACK IN'; EXEC Staging.oo_TimerMessage @msg, @Time1
			EXEC('ALTER TABLE ' + @ShadowTable + ' SWITCH TO [Relational].[ConsumerTransaction_MyRewards] PARTITION ' + @strPartitionID)
			EXEC('DROP TABLE ' + @ShadowTable)

			SET @msg = 'Loaded partition ' + @strPartitionID + ' [' + CAST(@RowsAffected AS VARCHAR(10)) + '] in ' + CAST(CAST(GETDATE() - @TimeNow AS TIME(0)) AS VARCHAR(8)) + ' ' + CASE WHEN @RowsAffected > 50000 THEN 'Indexes disabled' ELSE '' END
			EXEC [MI].[ProcessLog_Insert] 'PartitionSwitching_LoadPartitionSwitch_MyRewards', @msg

			SET @CurrentRow = @CurrentRow + 1


	END -- WHILE 1 = 1 BEGIN

	EXEC [MI].[ProcessLog_Insert] 'PartitionSwitching_LoadCTtable_MyRewards', 'All partitions loaded'
	-- 02:00:00


-----------------------------------------------------------------------------------------------------------------
-- Load Holding CC data to ConsumerTransaction_CreditCard
-----------------------------------------------------------------------------------------------------------------

	INSERT INTO [Relational].[ConsumerTransaction_CreditCard] (	FileID
															,	RowNum
															,	ConsumerCombinationID
															,	SecondaryCombinationID
															,	CardholderPresentData
															,	TranDate
															,	CINID
															,	Amount
															,	IsOnline
															,	LocationID
															,	FanID)
	SELECT	FileID
		,	RowNum
		,	ConsumerCombinationID
		,	SecondaryCombinationID
		,	CardholderPresentData
		,	TranDate
		,	CINID
		,	Amount
		,	IsOnline
		,	LocationID
		,	FanID
	FROM [Relational].[ConsumerTransaction_CreditCardHolding] 

	EXEC [MI].[ProcessLog_Insert] 'PartitionSwitching_LoadCTtable_MyRewards', 'Loaded Holding CC data to ConsumerTransaction_CreditCard'


-----------------------------------------------------------------------------------------------------------------
-- Clear down [Relational].ConsumerTransactionHolding (commented out for testing)
-----------------------------------------------------------------------------------------------------------------

	TRUNCATE TABLE [Relational].[ConsumerTransactionHolding]
	TRUNCATE TABLE [Relational].[ConsumerTransaction_CreditCardHolding]


-----------------------------------------------------------------------------------------------------------------
-- Add new MyRewards customers to oldcin table
-----------------------------------------------------------------------------------------------------------------

	INSERT INTO [InsightArchive].[OldCIN] (CINID)
	SELECT CINID
	FROM [InsightArchive].[NewCIN] nc
	WHERE NOT EXISTS (	SELECT 1
						FROM [InsightArchive].[OldCIN] oc
						WHERE nc.cinid = oc.cinid)


-----------------------------------------------------------------------------------------------------------------
-- Make the filegroup holding this partitioned table readonly
-- so it can be excluded from backups
-----------------------------------------------------------------------------------------------------------------
--ALTER DATABASE Warehouse MODIFY FILEGROUP fg_ConsumerTransaction_MyRewards READ_ONLY;

	EXEC [MI].[ProcessLog_Insert] 'PartitionSwitching_LoadCTtable_MyRewards', 'Program Finished'


RETURN 0