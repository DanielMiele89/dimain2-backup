/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Empties, inserts and recreates index on the Staging Transaction table 
				from ConsumerTransaction, including the equivalent holding table
				for unseen transactions

				Raw Transactions for: YYYY_MM_DD-Daily.csv

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[ConsumerTransactionHolding_Debit_Build]
AS
BEGIN

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.ConsumerTransactionHolding_Debit;
	IF EXISTS
		(
			SELECT
				1
			FROM sys.indexes
			WHERE name = 'PK_ConsumerTransaction_DebitCardHolding'
				AND object_id = OBJECT_ID('Processing.ConsumerTransactionHolding_Debit')
		)
		DROP INDEX PK_ConsumerTransaction_DebitCardHolding ON [Processing].[ConsumerTransactionHolding_Debit]
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

	----------------------------------------------------------------------
	-- Get Transactions from Holding
	----------------------------------------------------------------------
	INSERT INTO Processing.ConsumerTransactionHolding_Debit
	 SELECT
		 ct.*
	 FROM Warehouse.Relational.ConsumerTransactionHolding ct
	 JOIN Processing.Customers c
		 ON c.CINID = ct.CINID
			 AND rw = 1
	 LEFT JOIN Processing.RowNum_Log rnl
		 ON ct.FileID = rnl.FileID
			 AND ct.RowNum = rnl.RowNum
	 WHERE rnl.FileID IS NULL -- where the fileid/rownum combo has not been seen before
		 AND ct.FileID >= @MinFileID

	SET @RowCount += @@rowcount

	----------------------------------------------------------------------
	-- Get transactions from main table
	----------------------------------------------------------------------
	INSERT INTO Processing.ConsumerTransactionHolding_Debit
	 SELECT
		 ct.*
	 FROM Warehouse.Relational.ConsumerTransaction ct
	 JOIN Processing.Customers c
		 ON c.CINID = ct.CINID
			 AND rw = 1
	 LEFT JOIN Processing.RowNum_Log rnl
		 ON ct.FileID = rnl.FileID
			 AND ct.RowNum = rnl.RowNum
	 WHERE rnl.FileID IS NULL -- where the fileid/rownum combo has not been seen before
		 AND ct.FileID >= @MinFileID

	SET @RowCount += @@rowcount

	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------
	--ALTER INDEX [PK_ConsumerTransaction_DebitCardHolding] ON [Processing].[ConsumerTransactionHolding_Debit] REBUILD WITH (DATA_COMPRESSION = PAGE)
	CREATE UNIQUE CLUSTERED INDEX [PK_ConsumerTransaction_DebitCardHolding] ON [Processing].[ConsumerTransactionHolding_Debit] (FileID, RowNum)

	RETURN @RowCount

END
