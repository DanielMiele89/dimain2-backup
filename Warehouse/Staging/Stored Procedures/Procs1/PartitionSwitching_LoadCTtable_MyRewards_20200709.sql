/*
Grab last weeks data into ConsumerTransaction_MyRewards
1. Current rows from ConsumerTransactionHolding, filtered by Relational.CINList, Relational.Customer and MI.CINDuplicate
2. Remaining rows from ConsumerTransactionHolding, filtered by InsightArchive.oldcin
3. From ConsumerTransaction, filtered by InsightArchive.newcin and date
4. All rows from Relational.ConsumerTransaction_CreditCardHolding
MODIFIED ChrisM 20200626 to call PLT_Prepare on DIDEVTEST
*/
CREATE PROCEDURE [Staging].[PartitionSwitching_LoadCTtable_MyRewards_20200709]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Program Started'

	EXECUTE('EXEC Warehouse_Dev.dbo.PLT_Prepare') AT DIDEVTEST

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Warehouse_Dev.dbo.PLT_Prepare has been executed'

	DECLARE 
		@Time1 DATETIME = GETDATE(), 
		@msg VARCHAR(4000), 
		@Statement VARCHAR(8000),
		@RowsAffected INT 

	DECLARE 
		@CurrentPartitionID INT, @LastPartitionID INT,
		@LastPartitionRowcount INT,
		@CurrentPartitionStart DATE, @LastPartitionStart DATE

	EXEC Staging.oo_TimerMessage 'Start', @Time1

	IF EXISTS(SELECT 1 FROM sys.indexes WHERE name = 'csx_Stuff' AND OBJECT_NAME([object_id]) = 'ConsumerTransaction_MyRewards') 
		DROP INDEX [csx_Stuff] ON [Relational].[ConsumerTransaction_MyRewards]

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Columnstore index dropped'


	-----------------------------------------------------------------------------------------------------------------
	-- Measure the CT holding table
	-----------------------------------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#CTHolding') IS NOT NULL DROP TABLE #CTHolding;
	SELECT PartitionID, [Rows], TranDate = DATEADD(MONTH,DATEDIFF(MONTH,0,TranDate),0),
		rn = ROW_NUMBER() OVER(ORDER BY PartitionID DESC)
	INTO #CTHolding
	FROM (
		SELECT 
			PartitionID = $PARTITION.PartitionByMonthFunction_CTR(Trandate), 
			TranDate = MIN(TranDate),
			[Rows] = COUNT(*)
		FROM [Relational].[ConsumerTransactionHolding] cth
		INNER JOIN Relational.CINList c 
			ON c.CINID = cth.CINID
		INNER JOIN Relational.Customer cu 
			ON C.CIN = CU.SourceUID
		WHERE NOT EXISTS (SELECT 1 FROM MI.CINDuplicate d WHERE cu.FanID = d.FanID)
		GROUP BY $PARTITION.PartitionByMonthFunction_CTR(Trandate)
	) d
	ORDER BY PartitionID DESC

	SELECT @CurrentPartitionID = PartitionID, @CurrentPartitionStart = TranDate FROM #CTHolding WHERE rn = 1
	SELECT @LastPartitionID = PartitionID, @LastPartitionRowcount = [Rows], @LastPartitionStart = TranDate FROM #CTHolding WHERE rn = 2

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Partition - Holding Temp Table Loaded'


	-----------------------------------------------------------------------------------------------------------------
	-- If the "last" partition has enough rows, then load them by switching (leave switched out afterwards)
	-----------------------------------------------------------------------------------------------------------------
	IF @LastPartitionRowcount > 50000 
	EXEC [Staging].[PartitionSwitching_LoadPartitionSwitch_MyRewards] @LastPartitionID, @LastPartitionStart


	-----------------------------------------------------------------------------------------------------------------
	-- Load the current partition (leave switched out afterwards)
	-----------------------------------------------------------------------------------------------------------------
	EXEC [Staging].[PartitionSwitching_LoadPartitionSwitch_MyRewards] @CurrentPartitionID, @CurrentPartitionStart


	-----------------------------------------------------------------------------------------------------------------
	-- Load the remaining rows in CT Holding as conventional inserts directly into CT table
	-- Restrict CINID using oldcin
	-----------------------------------------------------------------------------------------------------------------
	DECLARE 
		@strLastPartitionStart VARCHAR(8),
		@strLastPartitionID VARCHAR(3) = CAST(@LastPartitionID AS VARCHAR(3)),
		@strCurrentPartitionID VARCHAR(3) = CAST(@CurrentPartitionID AS VARCHAR(3))

	IF @LastPartitionRowcount > 50000 
		SET @strLastPartitionStart = CONVERT(VARCHAR(8),@LastPartitionStart,112)
	ELSE
		SET @strLastPartitionStart = CONVERT(VARCHAR(8),@CurrentPartitionStart,112)

	EXEC('
		INSERT INTO Relational.ConsumerTransaction_MyRewards WITH (TABLOCKX) (
			[FileID],[RowNum],[ConsumerCombinationID],[CardholderPresentData],[TranDate],[CINID],[Amount],[IsOnline],[PaymentTypeID]			)
		SELECT 
			[FileID],[RowNum],[ConsumerCombinationID],[CardholderPresentData],[TranDate],cth.[CINID],[Amount],[IsOnline],PaymentTypeID = 1 -- CJM 20180608 --0 for debit transactions
		FROM [Relational].[ConsumerTransactionHolding] cth
		INNER JOIN InsightArchive.oldcin o ON cth.CINID = o.cinid
		WHERE [TranDate] < ''' + @strLastPartitionStart + ''' ')

	SET @RowsAffected = @@ROWCOUNT
	SET @msg = 'Loaded ' + CAST(@RowsAffected AS VARCHAR(10)) + ' Non-switched DC data from ConsumerTransactionHolding' 
	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', @msg

	-----------------------------------------------------------------------------------------------------------------
	-- Switch partitions back in (this empties the shadow tables)
	-----------------------------------------------------------------------------------------------------------------
	-- Last partition
	IF @LastPartitionRowcount > 50000 
	EXEC('ALTER TABLE Relational.ConsumerTransaction_MyRewards_p' + @strLastPartitionID + '_Stage SWITCH TO Relational.ConsumerTransaction_MyRewards PARTITION ' + @strLastPartitionID)

	-- Current partition
	EXEC('ALTER TABLE Relational.ConsumerTransaction_MyRewards_p' + @strCurrentPartitionID + '_Stage SWITCH TO Relational.ConsumerTransaction_MyRewards PARTITION ' + @strCurrentPartitionID)

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Switch-loaded DC data '



	-----------------------------------------------------------------------------------------------------------------
	--JEA 08/05/2018 catchup of transactions for customers activated since the last run of this procedure
	--oldcin stores the complete list of customers from the last run
	-----------------------------------------------------------------------------------------------------------------
	TRUNCATE TABLE InsightArchive.newcin

	INSERT INTO InsightArchive.newcin (CINID)
	SELECT c.CINID
	FROM Relational.CINList c 
	INNER JOIN Relational.Customer cu 
		ON C.CIN = CU.SourceUID
	WHERE NOT EXISTS (SELECT 1 FROM mi.cinduplicate d WHERE cu.fanid = d.fanid)
	EXCEPT
	SELECT cinid
	FROM InsightArchive.oldcin

	INSERT INTO InsightArchive.oldcin (CINID)
	SELECT CINID FROM InsightArchive.newcin


	-----------------------------------------------------------------------------------------------------------------
	-- Disable indexes for table load
	-----------------------------------------------------------------------------------------------------------------
	ALTER INDEX [ix_Stuff01] ON Relational.ConsumerTransaction_MyRewards DISABLE


	-----------------------------------------------------------------------------------------------------------------
	-- Extract and load new customer debit card transactions from [ConsumerTransaction] in one go  [5,356,272 / 06:00:00]
	-- There's no point in partition-switching this because the quantities per partition are not so different. 
	-----------------------------------------------------------------------------------------------------------------
	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Loading extra rows of Non-switched DC data from ConsumerTrans'

	EXEC('
		INSERT INTO Relational.ConsumerTransaction_MyRewards 
			   (FileID, RowNum, ConsumerCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, PaymentTypeID)
		SELECT ct.FileID, ct.RowNum, ct.ConsumerCombinationID, ct.CardholderPresentData, ct.TranDate, ct.CINID, ct.Amount, ct.IsOnline, PaymentTypeID = 1 -- CJM 20180608
		FROM Relational.ConsumerTransaction ct
		INNER JOIN InsightArchive.newcin n 
			ON ct.CINID = n.cinid
		WHERE ct.TranDate < ''' + @strLastPartitionStart + ''' ')

	SET @RowsAffected = @@ROWCOUNT
	SET @msg = 'Loaded ' + CAST(@RowsAffected AS VARCHAR(10)) + ' extra rows of Non-switched DC data from ConsumerTransaction' 
	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', @msg



	-----------------------------------------------------------------------------------------------------------------
	-- Load all credit card transactions from CreditCard holding table in one go  [1,769,704 / 00:05:00]
	-----------------------------------------------------------------------------------------------------------------
	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Loading Non-switched CC data from CC holding'

	EXEC('
		INSERT INTO Relational.ConsumerTransaction_MyRewards 
		   (FileID, RowNum, ConsumerCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, PaymentTypeID)
		SELECT FileID, RowNum, ConsumerCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, PaymentTypeID = 2 -- CJM 20180608
		FROM Relational.ConsumerTransaction_CreditCardHolding') 

	SET @RowsAffected = @@ROWCOUNT
	SET @msg = 'Loaded ' + CAST(@RowsAffected AS VARCHAR(10)) + ' rows of Non-switched CC data from ConsumerTransaction_CreditCardHolding' 
	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', @msg

	
	-----------------------------------------------------------------------------------------------------------------
	-- Enable indexes which were disabled for table load
	-----------------------------------------------------------------------------------------------------------------
	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Rebuilding ordinary index'
	
	ALTER INDEX [ix_Stuff01] ON Relational.ConsumerTransaction_MyRewards REBUILD

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Rebuilt ordinary index'


	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Loading Holding CC data to ConsumerTransaction_CreditCard'

	INSERT INTO Relational.ConsumerTransaction_CreditCard
		(FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, LocationID, FanID)
	SELECT FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, LocationID, FanID
	FROM Relational.ConsumerTransaction_CreditCardHolding 

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Loaded Holding CC data to ConsumerTransaction_CreditCard'



	-----------------------------------------------------------------------------------------------------------------
	-- Clear down Relational.ConsumerTransactionHolding
	-----------------------------------------------------------------------------------------------------------------
	TRUNCATE TABLE Relational.ConsumerTransactionHolding
	TRUNCATE TABLE Relational.ConsumerTransaction_CreditCardHolding

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Creating columnstore index'

	-- Recreate the columnstore index
	CREATE NONCLUSTERED COLUMNSTORE INDEX [csx_Stuff] ON [Relational].[ConsumerTransaction_MyRewards]
	(
       [TranDate],
       [CINID],
       [ConsumerCombinationID],
       [Amount],
       [IsOnline],
       paymenttypeid
	)WITH (DROP_EXISTING = OFF)

	EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Rebuilt columnstore index'

END

EXEC MI.ProcessLog_Insert 'PartitionSwitching_LoadCTtable_MyRewards', 'Program Finished'

RETURN 0
