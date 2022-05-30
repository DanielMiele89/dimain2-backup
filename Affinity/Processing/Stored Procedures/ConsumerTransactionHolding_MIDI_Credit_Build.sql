
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Empties, inserts and recreates index on the Staging MIDI Transaction table 
				from CreditCardLoad_MIDIHolding for unseen transactions

				Raw Transactions for: YYYY_MM_DD-Quarantine.csv

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[ConsumerTransactionHolding_MIDI_Credit_Build]
AS
BEGIN

	DECLARE @RowCount INT -- Logging row count

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.ConsumerTransactionHolding_MIDI_Credit;
	IF EXISTS
		(
			SELECT
				1
			FROM sys.indexes
			WHERE name = 'PK_ConsumerTransaction_MIDI_CreditCardHolding'
				AND object_id = OBJECT_ID('Processing.ConsumerTransactionHolding_MIDI_Credit')
		)
		DROP INDEX [PK_ConsumerTransaction_MIDI_CreditCardHolding] ON Processing.ConsumerTransactionHolding_MIDI_Credit 

	----------------------------------------------------------------------
	-- Insert
	----------------------------------------------------------------------
	INSERT INTO Processing.ConsumerTransactionHolding_MIDI_Credit
	 SELECT
		 mh.FileID
	   , mh.RowNum
	   , mh.CINID
	   , TranDate
	   , MID
	   , MCCID
	   , Narrative
	   , mh.LocationCountry
	   , mh.OriginatorReference
	   , Amount
	   , mh.CardholderPresentMC
	   , mh.PaymentTypeID
	   , mh.LocationID
	 FROM Warehouse.[Staging].[CreditCardLoad_MIDIHolding] mh
	 JOIN Processing.Customers c
		ON c.CINID = mh.CINID
		AND c.rw = 1
	 LEFT JOIN Processing.RowNum_Log rnl
		 ON mh.RowNum = rnl.RowNum
			 AND mh.FileID = rnl.FileID
	 WHERE rnl.FileID IS NULL

	 SELECT @RowCount = @@rowcount

	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------
	CREATE UNIQUE CLUSTERED INDEX [PK_ConsumerTransaction_MIDI_CreditCardHolding] ON Processing.ConsumerTransactionHolding_MIDI_Credit (FileID, RowNum)

	RETURN @@rowcount

END
