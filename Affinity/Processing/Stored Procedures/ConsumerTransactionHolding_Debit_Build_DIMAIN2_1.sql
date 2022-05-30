/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Empties, inserts and recreates index on the Staging Transaction table 
				from ConsumerTransaction, including the equivalent holding table
				for unseen transactions

				Raw Transactions for: YYYY_MM_DD-Daily.csv

------------------------------------------------------------------------------
Modification History

[24/09/2021] [CJM]
	- [Multiple changes for migration from DIMAIN to DIMAIN2]

******************************************************************************/
CREATE PROCEDURE [Processing].[ConsumerTransactionHolding_Debit_Build_DIMAIN2]
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.ConsumerTransactionHolding_Debit;
	--IF EXISTS
	--	(
	--		SELECT
	--			1
	--		FROM sys.indexes
	--		WHERE name = 'PK_ConsumerTransaction_DebitCardHolding'
	--			AND object_id = OBJECT_ID('Processing.ConsumerTransactionHolding_Debit')
	--	)
	--	DROP INDEX PK_ConsumerTransaction_DebitCardHolding ON [Processing].[ConsumerTransactionHolding_Debit]
		--ALTER INDEX [PK_ConsumerTransaction_DebitCardHolding] ON [Processing].[ConsumerTransactionHolding_Debit] DISABLE


	----------------------------------------------------------------------
	-- Get minimum file id to pull transactions from
	----------------------------------------------------------------------
	DECLARE @MinFileID INT
		  , @RowCount INT = 0

	SELECT
		@MinFileID = FileID
	FROM Processing.vw_MinFileID
	WHERE FileType = 'FI'
	--select @MinFileID -- 22488

	----------------------------------------------------------------------
	-- Get Transactions from Holding
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#ConsumerTransactionHolding_Debit') IS NOT NULL DROP TABLE #ConsumerTransactionHolding_Debit;
	 SELECT ct.FileID, ct.RowNum, ConsumerCombinationID, SecondaryCombinationID, BankID, LocationID, CardholderPresentData, TranDate, ct.CINID, Amount, IsRefund, IsOnline, InputModeID, PostStatusID, PaymentTypeID
	 INTO #ConsumerTransactionHolding_Debit
	 FROM Warehouse.Relational.ConsumerTransactionHolding ct
	 JOIN Processing.Customers c
		 ON c.CINID = ct.CINID
			 AND rw = 1
	 LEFT JOIN Processing.RowNum_Log rnl
		 ON ct.FileID = rnl.FileID
			 AND ct.RowNum = rnl.RowNum
	 WHERE rnl.FileID IS NULL -- where the fileid/rownum combo has not been seen before
		 AND ct.FileID >= @MinFileID;

	--SET @RowCount += @@rowcount

	----------------------------------------------------------------------
	-- Get transactions from main table
	-- slow 01:20:00
	----------------------------------------------------------------------
	DECLARE @PartitionNo INT = Warehouse.$PARTITION.PartitionByMonthFunction(GETDATE()) - 12 -- 100 - 113
	
	INSERT INTO #ConsumerTransactionHolding_Debit WITH (TABLOCK)
		(FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, BankID, LocationID, CardholderPresentData, TranDate, CINID, Amount, IsRefund, IsOnline, InputModeID, PostStatusID, PaymentTypeID)
	SELECT ct.FileID, ct.RowNum, ConsumerCombinationID, SecondaryCombinationID, BankID, LocationID, CardholderPresentData, TranDate, ct.CINID, Amount, IsRefund, IsOnline, InputModeID, PostStatusID, PaymentTypeID
	FROM Warehouse.Relational.ConsumerTransaction ct
	INNER JOIN Processing.Customers c
		ON c.CINID = ct.CINID
		AND rw = 1
	WHERE ct.FileID >= @MinFileID
		AND Warehouse.$PARTITION.PartitionByMonthFunction(TranDate) > @PartitionNo
		AND NOT EXISTS ( -- where the fileid/rownum combo has not been seen before
			SELECT 1 
			FROM Processing.RowNum_Log rnl
			WHERE rnl.FileID = ct.FileID 
				AND rnl.RowNum = ct.RowNum
		);

	INSERT INTO Processing.ConsumerTransactionHolding_Debit WITH (TABLOCK)
		(FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, BankID, LocationID, CardholderPresentData, TranDate, CINID, Amount, IsRefund, IsOnline, InputModeID, PostStatusID, PaymentTypeID)
	SELECT FileID, RowNum, ConsumerCombinationID, SecondaryCombinationID, BankID, LocationID, CardholderPresentData, TranDate, ct.CINID, Amount, IsRefund, IsOnline, InputModeID, PostStatusID, PaymentTypeID
	FROM #ConsumerTransactionHolding_Debit ct
	ORDER BY FileID, RowNum
		 
	SET @RowCount += @@rowcount

	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------
	--ALTER INDEX [PK_ConsumerTransaction_DebitCardHolding] ON [Processing].[ConsumerTransactionHolding_Debit] REBUILD WITH (DATA_COMPRESSION = PAGE)
	--CREATE UNIQUE CLUSTERED INDEX [PK_ConsumerTransaction_DebitCardHolding] ON [Processing].[ConsumerTransactionHolding_Debit] (FileID, RowNum)
	UPDATE STATISTICS [Processing].[ConsumerTransactionHolding_Debit]

	RETURN @RowCount

END
