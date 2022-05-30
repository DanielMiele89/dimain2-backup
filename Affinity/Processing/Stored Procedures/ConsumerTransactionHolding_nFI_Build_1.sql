/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Empties, inserts and recreates index on the Staging Transaction table 
				from SLC Match for unseen transactions

				Raw Transactions for: YYYY_MM_DD-Daily.csv

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[ConsumerTransactionHolding_nFI_Build]
AS
BEGIN

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.ConsumerTransactionHolding_nFI
	IF EXISTS
		(
			SELECT
				1
			FROM sys.indexes
			WHERE name = 'PK_ConsumerTransaction_nFICardHolding'
				AND object_id = OBJECT_ID('Processing.ConsumerTransactionHolding_nFI')
		)
			DROP INDEX PK_ConsumerTransaction_nFICardHolding ON  [Processing].[ConsumerTransactionHolding_nFI]

		--ALTER INDEX [PK_ConsumerTransaction_nFICardHolding] ON [Processing].[ConsumerTransactionHolding_nFI] DISABLE

	----------------------------------------------------------------------
	-- Get minimum fileid to pull data from
		-- for nFI transactions this is actually the transactionid
	----------------------------------------------------------------------
	DECLARE @MinFileID INT
		  , @RowCount INT = 0

	SELECT
		@MinFileID = FileID
	FROM Processing.vw_MinFileID
	WHERE FileType = 'nFI'

	----------------------------------------------------------------------
	-- Insert
	----------------------------------------------------------------------
	INSERT INTO Processing.ConsumerTransactionHolding_nFI
	 SELECT
		 CASE
			 WHEN LEN(ct.MerchantID) = 8
			  THEN SUBSTRING(ct.MerchantID, PATINDEX('0%', ct.MerchantID) + 1, 99)
			 ELSE ct.MerchantID
		 END						   AS MerchantID -- to deal with leading 0's on TNS MID
	   , CASE
			 WHEN CardholderPresentData IN ('C', 'D', 'E', ' ')
			  THEN 0
			 ELSE 9
		 END						   AS CardholderPresentData -- to deal with unknown cardholderpresent flags
	   , CAST(TransactionDate AS DATE) TranDate -- to remove transaction times from TNS
	   , AddedDate
	   , p.CompositeID
	   , Amount
	   , pc.CardTypeID
	   , RO.PartnerID
	   , VectorMajorID
	   , VectorMinorID
	   , ct.ID						   AS TranID
	   , pa.BrandID
	 FROM SLC_REPL..Match ct
	 INNER JOIN SLC_REPL..Pan p
		 ON p.ID = ct.PanID
	 INNER JOIN Processing.Customers f
		 ON p.CompositeID = f.CompositeID
		 AND f.ClubID in (144, 145, 147)
	 INNER JOIN SLC_REPL..PaymentCard pc
		 ON pc.ID = p.PaymentCardID
	 INNER JOIN SLC_REPL..RetailOutlet RO
		 ON RO.ID = ct.RetailOutletID
	 INNER JOIN Warehouse.Relational.Partner pa
		 ON pa.PartnerID = RO.PartnerID
	 LEFT JOIN Processing.RowNum_Log rnl
		 ON rnl.FileID = -1
			 AND rnl.RowNum = ct.ID
	 WHERE ct.RewardStatus = 1
		 AND ct.ID > @MinFileID
		 AND rnl.FileID IS NULL

	SET @RowCount += @@rowcount

	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------
	CREATE UNIQUE CLUSTERED INDEX [PK_ConsumerTransaction_nFICardHolding] ON [Processing].[ConsumerTransactionHolding_nFI] (TranID)

	--ALTER INDEX [PK_ConsumerTransaction_nFICardHolding] ON [Processing].[ConsumerTransactionHolding_nFI] REBUILD WITH (DATA_COMPRESSION = PAGE)

	RETURN @RowCount
END
