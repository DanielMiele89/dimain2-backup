/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Empties, inserts and recreates index on the Staging Transaction table 
				from ConsumerTransaction_Credit, including the equivalent holding table
				for unseen transactions

				Raw Transactions for: YYYY_MM_DD-Daily.csv

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/

CREATE PROCEDURE [Processing].[ConsumerTransactionHolding_Credit_Build]
AS
BEGIN

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.ConsumerTransactionHolding_Credit;
	IF EXISTS
		(
			SELECT
				1
			FROM sys.indexes
			WHERE name = 'PK_ConsumerTransaction_CreditCardHolding'
				AND object_id = OBJECT_ID('Processing.ConsumerTransactionHolding_Credit')
		)
		DROP INDEX [PK_ConsumerTransaction_CreditCardHolding] ON Processing.ConsumerTransactionHolding_Credit

	----------------------------------------------------------------------
	-- Get Minimum file id to start pull from
	----------------------------------------------------------------------
	DECLARE @MinFileID INT
		  , @RowCount INT = 0

	SELECT
		@MinFileID = FileID
	FROM Processing.vw_MinFileID
	WHERE FileType = 'FI'

	----------------------------------------------------------------------
	-- Insert from holding
	----------------------------------------------------------------------
	INSERT INTO Processing.ConsumerTransactionHolding_Credit
	 SELECT
		 ct.*
	 FROM Warehouse.Relational.ConsumerTransaction_CreditCardHolding ct
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
	-- Insert from main table
	----------------------------------------------------------------------
	INSERT INTO Processing.ConsumerTransactionHolding_Credit
	 SELECT
		 ct.*
	 FROM Warehouse.Relational.ConsumerTransaction_CreditCard ct
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
	-- Create index
	----------------------------------------------------------------------

	CREATE UNIQUE CLUSTERED INDEX [PK_ConsumerTransaction_CreditCardHolding] ON [Processing].[ConsumerTransactionHolding_Credit] (FileID, RowNum)


	RETURN @RowCount

END
