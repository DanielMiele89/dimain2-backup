/*
Stored procedure header stub

*/
CREATE PROCEDURE [Staging].[PartitionSwitching_LoadCTtable_MyRewards_20200708]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE 
		@Time1 DATETIME = GETDATE(), 
		@msg VARCHAR(4000), 
		@Statement VARCHAR(8000),
		@RowsAffected INT 

	EXEC Staging.oo_TimerMessage 'Start', @Time1


	-- Measure the CT holding table
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


	DECLARE 
		@CurrentPartitionID INT, @LastPartitionID INT,
		@LastPartitionRowcount INT,
		@CurrentPartitionStart DATE, @LastPartitionStart DATE

	SELECT @CurrentPartitionID = PartitionID, @CurrentPartitionStart = TranDate FROM #CTHolding WHERE rn = 1
	SELECT @LastPartitionID = PartitionID, @LastPartitionRowcount = [Rows], @LastPartitionStart = TranDate FROM #CTHolding WHERE rn = 2


	EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad_MyRewards', 'Partition - Holding Temp Table Loaded'


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
	-- Load the remaining rows as conventional inserts directly into CT table
	-----------------------------------------------------------------------------------------------------------------
	DECLARE 
		@strLastPartitionStart VARCHAR(8),
		@strLastPartitionID VARCHAR(3) = CAST(@LastPartitionID AS VARCHAR(3)),
		@strCurrentPartitionID VARCHAR(3) = CAST(@CurrentPartitionID AS VARCHAR(3))


	IF @LastPartitionRowcount > 50000 
		SET @strLastPartitionStart = CONVERT(VARCHAR(8),@LastPartitionStart,112)
	ELSE
		SET @strLastPartitionStart = CONVERT(VARCHAR(8),@CurrentPartitionStart,112)


	-- Load remaining debit card transactions from holding table
	INSERT INTO Relational.ConsumerTransaction_MyRewards WITH (TABLOCKX) (
		[FileID],[RowNum],[ConsumerCombinationID],[CardholderPresentData],[TranDate],[CINID],[Amount],[IsOnline],[PaymentTypeID]			)
	SELECT 
		--[FileID],[RowNum],[ConsumerCombinationID],[CardholderPresentData],[TranDate],cth.[CINID],[Amount],[IsOnline],PaymentTypeID = 0 --0 for debit transactions
		[FileID],[RowNum],[ConsumerCombinationID],[CardholderPresentData],[TranDate],cth.[CINID],[Amount],[IsOnline],PaymentTypeID = 1 -- CJM 20180608 --0 for debit transactions
	FROM [Relational].[ConsumerTransactionHolding] cth
	INNER JOIN InsightArchive.oldcin o ON cth.CINID = o.cinid
	--INNER JOIN Relational.CINList c 
	--	ON c.CINID = cth.CINID
	--INNER JOIN Relational.Customer cu 
	--	ON C.CIN = CU.SourceUID
	--WHERE NOT EXISTS (SELECT 1 FROM MI.CINDuplicate d WHERE cu.FanID = d.FanID)
	--	AND 
	WHERE [TranDate] < @strLastPartitionStart

	SET @RowsAffected = @@ROWCOUNT

	EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad_MyRewards', 'Partition - Loaded Non-switched DC data '

	-----------------------------------------------------------------------------------------------------------------
	-- Switch partitions back in (this empties the shadow tables)
	-----------------------------------------------------------------------------------------------------------------
	-- Last partition
	IF @LastPartitionRowcount > 50000 
	EXEC('ALTER TABLE Relational.ConsumerTransaction_MyRewards_p' + @strLastPartitionID + '_Stage SWITCH TO Relational.ConsumerTransaction_MyRewards PARTITION ' + @strLastPartitionID)

	-- Current partition
	EXEC('ALTER TABLE Relational.ConsumerTransaction_MyRewards_p' + @strCurrentPartitionID + '_Stage SWITCH TO Relational.ConsumerTransaction_MyRewards PARTITION ' + @strCurrentPartitionID)



	-----------------------------------------------------------------------------------------------------------------
	--JEA 08/05/2018 catchup of transactions for customers activated since the last run of this procedure
	--oldcin stores the complete list of customers from the last run
	-----------------------------------------------------------------------------------------------------------------

	TRUNCATE TABLE InsightArchive.newcin

	INSERT INTO InsightArchive.newcin(cinid)
	SELECT c.CINID
	FROM Relational.CINList c 
	INNER JOIN Relational.Customer cu 
		ON C.CIN = CU.SourceUID
	WHERE NOT EXISTS (SELECT 1 FROM mi.cinduplicate d WHERE cu.fanid = d.fanid)
	EXCEPT
	SELECT cinid
	FROM InsightArchive.oldcin

	-- Load debit card transactions from holding table in one go
	INSERT INTO Relational.ConsumerTransaction_MyRewards 
		   (FileID, RowNum, ConsumerCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, PaymentTypeID)
	SELECT ct.FileID, ct.RowNum, ct.ConsumerCombinationID, ct.CardholderPresentData, ct.TranDate, ct.CINID, ct.Amount, ct.IsOnline, PaymentTypeID = 1 -- CJM 20180608
	FROM Relational.ConsumerTransaction ct
	INNER JOIN InsightArchive.newcin n ON ct.CINID = n.cinid
	WHERE [TranDate] < @strLastPartitionStart

	SET @RowsAffected = @@ROWCOUNT
	SET @msg = 'Partition - Loaded ' + CAST(@RowsAffected AS VARCHAR(10)) + ' rows of Non-switched DC data' -- 5,356,272

	EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad_MyRewards', @msg


	--TRUNCATE TABLE InsightArchive.oldcin

	--INSERT INTO InsightArchive.oldcin(cinid)
	--SELECT c.CINID
	--FROM Relational.CINList c 
	--INNER JOIN Relational.Customer cu 
	--	ON C.CIN = CU.SourceUID
	--WHERE NOT EXISTS (SELECT 1 FROM mi.cinduplicate d WHERE cu.fanid = d.fanid)

	INSERT INTO InsightArchive.oldcin
	SELECT CINID FROM InsightArchive.newcin

	-- Load credit card transactions from holding table in one go
	INSERT INTO Relational.ConsumerTransaction_MyRewards 
		   (FileID, RowNum, ConsumerCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, PaymentTypeID)
	SELECT FileID, RowNum, ConsumerCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, PaymentTypeID = 2 -- CJM 20180608
	FROM Relational.ConsumerTransaction_CreditCardHolding 

	SET @RowsAffected = @@ROWCOUNT
	SET @msg = 'Partition - Loaded ' + CAST(@RowsAffected AS VARCHAR(10)) + ' rows of Non-switched CC data' -- 1,769,704

	EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad_MyRewards', @msg



	INSERT INTO Relational.ConsumerTransaction_CreditCard
		(FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, LocationID, FanID)
	SELECT FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, CardholderPresentData, TranDate, CINID, Amount, IsOnline, LocationID, FanID
	FROM Relational.ConsumerTransaction_CreditCardHolding 

	EXEC MI.ProcessLog_Insert 'ConsumerTransactionHoldingLoad_MyRewards', 'Partition - Loaded Holding CC data'



	-----------------------------------------------------------------------------------------------------------------
	-- Clear down Relational.ConsumerTransactionHolding
	-----------------------------------------------------------------------------------------------------------------
	TRUNCATE TABLE Relational.ConsumerTransactionHolding
	TRUNCATE TABLE Relational.ConsumerTransaction_CreditCardHolding

END
