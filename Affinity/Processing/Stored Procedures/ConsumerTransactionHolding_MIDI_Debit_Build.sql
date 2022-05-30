
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Empties, inserts and recreates index on the Staging MIDI Transaction table 
				from CTLoad_MIDIHolding for unseen transactions

				Raw Transactions for: YYYY_MM_DD-Quarantine.csv

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[ConsumerTransactionHolding_MIDI_Debit_Build]
AS
BEGIN

	DECLARE @RowCount INT -- Logging row count

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	TRUNCATE TABLE Processing.ConsumerTransactionHolding_MIDI_Debit;
	IF EXISTS
		(
			SELECT
				1
			FROM sys.indexes
			WHERE name = 'PK_ConsumerTransaction_MIDI_DebitCardHolding'
				AND object_id = OBJECT_ID('Processing.ConsumerTransactionHolding_MIDI_Debit')
		)
		DROP INDEX [PK_ConsumerTransaction_MIDI_DebitCardHolding] ON Processing.ConsumerTransactionHolding_MIDI_Debit


	----------------------------------------------------------------------
	-- Insert
	----------------------------------------------------------------------
	INSERT INTO Processing.ConsumerTransactionHolding_MIDI_Debit

	 SELECT
		 mh.FileID
	   , mh.RowNum
	   , mh.CINID
	   , TranDate
	   , MID
	   , MCCID
	   , Narrative
	   , mh.LocationCountry
	   , mh.OriginatorID
	   , Amount
	   , mh.CardholderPresentData
	   , mh.PaymentTypeID
	   , mh.LocationAddress
	   , mh.LocationID
	 FROM Warehouse.[Staging].[CTLoad_MIDIHolding] mh
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
	CREATE UNIQUE CLUSTERED INDEX PK_ConsumerTransaction_MIDI_DebitCardHolding ON Processing.ConsumerTransactionHolding_MIDI_Debit (FileID, RowNum)

	RETURN @RowCount

END
