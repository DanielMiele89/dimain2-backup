
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Loads TempProxyMIDTupleIDs that now have a ProxyMIDTupleID and
				have not been matched previously

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[MIDTupleMatching_Load] (
	@FileDate DATE -- The date that this file is to represent
)
AS
BEGIN

	DECLARE @RowCount INT -- Logging row count

	----------------------------------------------------------------------
	-- Get TempProxyMIDTupleIDs that have not been seen
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#MIDIMatchIDs') IS NOT NULL
		DROP TABLE #MIDIMatchIDs

	SELECT 
		tpm.REW_FileID AS FileID
		, tpm.REW_RowNum AS RowNum
		, tpm.TempProxyMIDTupleID
	INTO #MIDIMatchIDs
	FROM Processing.TransactionPerturbation_MIDI tpm
	LEFT JOIN Processing.MIDTupleMatching mtm
		ON mtm.TempProxyMIDTupleID = tpm.TempProxyMIDTupleID
	WHERE mtm.TempProxyMIDTupleID IS NULL

	CREATE CLUSTERED INDEX cix_tempdb_midimatchids ON #MIDIMatchIDs (FileID, RowNum)


	----------------------------------------------------------------------
	-- Get ConsumerCombination for these trans from Transaction tables
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#TransIDs') IS NOT NULL
		DROP TABLE #TransIDs
	SELECT
		ct.FileID
		, ct.RowNum
		, ConsumerCombinationID
		, mm.TempProxyMIDTupleID
	INTO #TransIDs
	FROM Warehouse.Relational.ConsumerTransaction ct
	JOIN #MIDIMatchIDs mm
		ON ct.FileID = mm.FileID
		AND ct.RowNum = mm.RowNum

	INSERT INTO #TransIDs
	SELECT
		ct.FileID
		, ct.RowNum
		, ConsumerCombinationID
		, mm.TempProxyMIDTupleID
	FROM Warehouse.Relational.ConsumerTransactionHolding ct
	JOIN #MIDIMatchIDs mm
		ON ct.FileID = mm.FileID
		AND ct.RowNum = mm.RowNum

	INSERT INTO #TransIDs
	SELECT
		ct.FileID
		, ct.RowNum
		, ConsumerCombinationID
		, mm.TempProxyMIDTupleID
	FROM Warehouse.Relational.ConsumerTransaction_CreditCard ct
	JOIN #MIDIMatchIDs mm
		ON ct.FileID = mm.FileID
		AND ct.RowNum = mm.RowNum

	INSERT INTO #TransIDs
	SELECT
		ct.FileID
		, ct.RowNum
		, ConsumerCombinationID
		, mm.TempProxyMIDTupleID
	FROM Warehouse.Relational.ConsumerTransaction_CreditCardHolding ct
	JOIN #MIDIMatchIDs mm
		ON ct.FileID = mm.FileID
		AND ct.RowNum = mm.RowNum

	CREATE CLUSTERED INDEX cix_tempdb_transids ON #TransIDs (ConsumerCombinationID, FileID, RowNum)

	----------------------------------------------------------------------
	-- Build list of Matched TempProxyMIDTupleIDs and ProxyMIDTupleIDs
		-- The ROW_NUMBER() logic is required because, for PayPal,
		-- the same TempProxyMIDTupleID, due to a legacy MIDI bug, can be
		-- assigned to multiple combinations so we just choose the latest one
		-- because the earliest one will be the most generic version
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#MatchedIDs') IS NOT NULL
		DROP TABLE #MatchedIDs

	SELECT 
		TempProxyMIDTupleID
		, ProxyMIDTupleID
		, ConsumerCombinationID
	INTO #MatchedIDs
	FROM (
		SELECT 
			TempProxyMIDTupleID
			, cc.ProxyMIDTupleID
			, cc.ConsumerCombinationID
			, ROW_NUMBER() OVER (
				PARTITION BY TempProxyMIDTupleID 
				ORDER BY cc.ConsumerCombinationID DESC
			) rw
		FROM #TransIDs z
		JOIN Processing.ConsumerCombination cc
			ON cc.ConsumerCombinationID = z.ConsumerCombinationID
	) x
	WHERE rw = 1

	----------------------------------------------------------------------
	-- Insert
	----------------------------------------------------------------------
	INSERT INTO Processing.MIDTupleMatching (TempProxyMIDTupleID, ProxyMIDTupleID, FileDate, ConsumerCombinationID)
	SELECT TempProxyMIDTupleID, ProxyMIDTupleID, @FileDate, ConsumerCombinationID
	FROM #MatchedIDs z

	RETURN @@RowCount

END
