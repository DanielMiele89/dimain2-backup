/*
--=====================================================================================================
 Card Transaction Processing (loop) 
 First stage rating of [CTLoad_InitialStage] 
 Moves rated rows from [CTLoad_InitialStage_] to ConsumerTransactionHolding

 Second stage rating of [CTLoad_InitialStage]
 Moves rated rows from [CTLoad_InitialStage] to ConsumerTransactionHolding

 Moves unrated rows to CTLoad_MIDIHolding for manual processing
 Clears [CTLoad_InitialStage] for the next run

 Takes about 10 minutes to run

Notes:
There was a FK constraint on ConsumerCombination but it was expensive to process and IMHO unnecessary, since
this column is populated programmatically. If it causes problems, here's the script for restoring the constraint:
ALTER TABLE [MIDI].[ConsumerTransactionHolding]  WITH NOCHECK ADD  CONSTRAINT [FK_midi_ConsumerTransactionHolding_Combination] FOREIGN KEY([ConsumerCombinationID])
REFERENCES [Trans].[ConsumerCombination] ([ConsumerCombinationID])
GO

ALTER TABLE [MIDI].[ConsumerTransactionHolding] CHECK CONSTRAINT [FK_midi_ConsumerTransactionHolding_Combination]
GO

--=====================================================================================================
*/
CREATE PROCEDURE [MIDI].[GenericTransProcessing_MIDIHolding_20220427]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT

SELECT @RowsAffected = COUNT(*) FROM [MIDI].[CTLoad_MIDIHolding] mh
IF @RowsAffected = 0 BEGIN
	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - No rows to process'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	RETURN
END
ELSE
	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Starting first part'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	
/*******************************************************************************************************************************************
	1.	Collect previously-unseen MCCs from the new data
*******************************************************************************************************************************************/

	INSERT INTO [Warehouse].[Relational].[MCCList] (MCC, MCCGroup, MCCCategory, MCCDesc, SectorID)
	SELECT	DISTINCT 
			COALESCE(MCC, '')
		,	''
		,	''
		,	''
		,	1
	FROM [MIDI].[CTLoad_MIDIHolding] mh
	WHERE NOT EXISTS (	SELECT 1
						FROM [Warehouse].[Relational].[MCCList] mcc
						WHERE mcc.MCC = mh.MCC)

-- 0 / 00:00:02
	
/*******************************************************************************************************************************************
	2.	Collect previously-unseen CINs from the new data
*******************************************************************************************************************************************/

	INSERT INTO [Derived].[CINList] (CIN)
	SELECT	DISTINCT
			cu.SourceUID
	FROM [MIDI].[CTLoad_MIDIHolding] mh
	INNER JOIN [WHB].[Inbound_Cards] ca
		ON mh.CardID = ca.CardGUID
	INNER JOIN [Derived].[Customer] cu
		ON ca.PrimaryCustomerGUID = cu.CustomerGUID
	WHERE NOT EXISTS (	SELECT 1
						FROM [Derived].[CINList] cl
						WHERE cu.SourceUID = cl.CIN)

	--SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Collect previously-unseen CINs [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	
-- (1056 rows affected) / 00:02:58
	
/*******************************************************************************************************************************************
	3.	Update various columns
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		3.1.	Assign MMCIDs
	***********************************************************************************************************************/
	
		UPDATE mh
		SET	mh.MCCID = m.MCCID
		FROM [MIDI].[CTLoad_MIDIHolding] mh
		INNER JOIN [Warehouse].[Relational].[MCCList] m
			ON mh.MCC = m.MCC
		WHERE mh.MCCID IS NULL

	/***********************************************************************************************************************
		3.2.	Assign CIN & BankID
	***********************************************************************************************************************/
	
		UPDATE mh
		SET	mh.CIN = cu.SourceUID
		,	mh.BankID = ca.BankID
		,	mh.PaymentTypeID = 2
		FROM [MIDI].[CTLoad_MIDIHolding] mh
		INNER JOIN [WHB].[Inbound_Cards] ca
			ON mh.CardID = ca.CardGUID
		INNER JOIN [Derived].[Customer] cu
			ON ca.PrimaryCustomerGUID = cu.CustomerGUID
		WHERE mh.CIN IS NULL

	/***********************************************************************************************************************
		3.3.	Assign CINID
	***********************************************************************************************************************/

		UPDATE mh
		SET	mh.CINID = cl.CINID
		FROM [MIDI].[CTLoad_MIDIHolding] mh
		INNER JOIN [Derived].[CINList] cl
			ON mh.CIN = cl.CIN
		WHERE mh.CINID IS NULL

	/***********************************************************************************************************************
		3.4.	Assign InputModeID
	***********************************************************************************************************************/

		UPDATE mh
		SET	mh.InputModeID = cim.InputModeID
		FROM [MIDI].[CTLoad_MIDIHolding] mh
		INNER JOIN [Warehouse].[Relational].[CardInputMode] cim
			ON mh.CardInputMode = cim.CardInputMode
		WHERE mh.InputModeID IS NULL

		-- (7,426,003 rows affected) / 00:01:58
		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Update various columns [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	
/*******************************************************************************************************************************************
	4.	Assign CCs
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		4.1.	Non High Variance
	***********************************************************************************************************************/

		UPDATE	mh
		SET	mh.ConsumerCombinationID = cc.ConsumerCombinationID
		FROM [MIDI].[CTLoad_MIDIHolding] mh
		INNER JOIN [Trans].[ConsumerCombination] cc
			ON mh.MID = cc.MID
			AND mh.MerchantCountry = cc.LocationCountry
			AND mh.MCCID = cc.MCCID
			AND (mh.MerchantAcquirerBin = cc.OriginatorID OR mh.MerchantAcquirerBin IS NULL)
			AND cc.PaymentGatewayStatusID != 1	--	not default Paypal
			AND (mh.MerchantName = cc.Narrative AND cc.IsHighVariance = 0)
		WHERE mh.ConsumerCombinationID IS NULL
		
		UPDATE	mh
		SET	mh.ConsumerCombinationID = cc.ConsumerCombinationID
		FROM [MIDI].[CTLoad_MIDIHolding] mh
		INNER JOIN [Trans].[ConsumerCombination] cc
			ON mh.MID = cc.MID
			AND mh.MerchantCountry = cc.LocationCountry
			AND mh.MCCID = cc.MCCID
			AND (mh.MerchantAcquirerBin = cc.OriginatorID OR mh.MerchantAcquirerBin IS NULL)
			AND cc.PaymentGatewayStatusID != 1	--	not default Paypal
			AND (SUBSTRING(mh.MerchantName, 5, 999) = cc.Narrative AND cc.IsHighVariance = 0)
		WHERE mh.ConsumerCombinationID IS NULL
		
		UPDATE	mh
		SET	mh.ConsumerCombinationID = cc.ConsumerCombinationID
		FROM [MIDI].[CTLoad_MIDIHolding] mh
		INNER JOIN [Trans].[ConsumerCombination] cc
			ON mh.MID = cc.MID
			AND mh.MerchantCountry = cc.LocationCountry
			AND mh.MCCID = cc.MCCID
			AND (mh.MerchantAcquirerBin = cc.OriginatorID OR mh.MerchantAcquirerBin IS NULL)
			AND cc.PaymentGatewayStatusID != 1	--	not default Paypal
			AND (SUBSTRING(mh.MerchantName, 4, 999) = cc.Narrative AND cc.IsHighVariance = 0)
		WHERE mh.ConsumerCombinationID IS NULL

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Non-Paypal Combinations (low variance - 1) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	

	/***********************************************************************************************************************
		4.2.	High Variance
	***********************************************************************************************************************/

		UPDATE	mh
		SET	mh.ConsumerCombinationID = cc.ConsumerCombinationID
		FROM [MIDI].[CTLoad_MIDIHolding] mh
		INNER JOIN [Trans].[ConsumerCombination] cc
			ON mh.MID = cc.MID
			AND mh.MerchantCountry = cc.LocationCountry
			AND mh.MCCID = cc.MCCID
			AND (mh.MerchantAcquirerBin = cc.OriginatorID OR mh.MerchantAcquirerBin IS NULL)
			AND cc.PaymentGatewayStatusID != 1	--	not default Paypal
			AND (mh.MerchantName LIKE cc.Narrative AND cc.IsHighVariance = 1)
		WHERE mh.ConsumerCombinationID IS NULL

		-- (212,684 rows affected) / 00:01:04

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Non-Paypal Combinations (high variance) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	

	/***********************************************************************************************************************
		4.3.	If there a new PayPal combinations coming through that don't meet a set threshold of transactions then
				create and assign them a generic PayPal CC
	***********************************************************************************************************************/
	
		/*******************************************************************************
			4.3.1.	Fetch PayPal MIDs with less then 5 transactions
		*******************************************************************************/

			IF OBJECT_ID('tempdb..#PaypalMIDNew') IS NOT NULL DROP TABLE #PaypalMIDNew
			CREATE TABLE #PaypalMIDNew (MID VARCHAR(50) PRIMARY KEY
									,	TranCount INT NOT NULL)
			INSERT INTO #PaypalMIDNew (	MID
									,	TranCount)
			SELECT	MID
				,	TranCount = COUNT(*)
			FROM [MIDI].[CTLoad_MIDIHolding]
			WHERE MerchantName LIKE 'PAYPAL%'
			AND ConsumerCombinationID IS NULL
			GROUP BY MID
			HAVING COUNT(*) <= 0

			-- (298 rows affected) / 00:00:01
	
		/*******************************************************************************
			4.3.2.	Create CCs for the MIDs found in the previous set
					with a generic MID & Narrative
		*******************************************************************************/
		
			INSERT INTO [Trans].[ConsumerCombination] (	BrandID
													,	MID
													,	Narrative
													,	LocationCountry
													,	MCCID
													,	OriginatorID
													,	IsHighVariance
													,	IsUKSpend
													,	PaymentGatewayStatusID)
			SELECT	943 AS BrandID
				,	'%' AS MID
				,	'PAYPAL%' AS Narrative
				,	MerchantCountry AS LocationCountry
				,	MCCID
				,	mh.MerchantAcquirerBin
				,	1 AS IsHighVariance
				,	CASE
						WHEN mh.MerchantCountry = 'GB' THEN 1
						ELSE 0
					END AS IsUKSpend
				,	1 AS PaymentGatewayStatusID
			FROM [MIDI].[CTLoad_MIDIHolding] mh
			WHERE mh.ConsumerCombinationID IS NULL
			AND mh.MerchantName LIKE 'PAYPAL%'
			AND mh.MCCID IS NOT NULL
			AND EXISTS (SELECT 1
						FROM #PaypalMIDNew pn
						WHERE mh.MID = pn.MID)
			AND NOT EXISTS (SELECT 1 
							FROM [Trans].[ConsumerCombination] cc
							WHERE cc.PaymentGatewayStatusID = 1
							AND mh.MerchantCountry = cc.LocationCountry
							AND mh.MCCID = cc.MCCID)
			
			-- (0 rows affected) / 00:00:01

			SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - New Paypal Combinations [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	
		/*******************************************************************************
			4.3.3.	Assign the newly created CCs back to the transactions
		*******************************************************************************/
		
			UPDATE mh
			SET mh.ConsumerCombinationID = cc.ConsumerCombinationID
			,	mh.RequiresSecondaryID = 1
			FROM [MIDI].[CTLoad_MIDIHolding] mh
			CROSS APPLY (	SELECT	TOP 1
									ConsumerCombinationID
							FROM [Trans].[ConsumerCombination] cc
							WHERE cc.PaymentGatewayStatusID = 1
							AND mh.MerchantCountry = cc.LocationCountry
							AND mh.MCCID = cc.MCCID) cc
			WHERE mh.MerchantName LIKE 'PAYPAL%'
			AND mh.ConsumerCombinationID IS NULL
			AND EXISTS (SELECT 1
						FROM #PaypalMIDNew pn
						WHERE mh.MID = pn.MID)

			-- (95,440 rows affected) / 00:00:01

			SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Paypal Combinations'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	
/*******************************************************************************************************************************************
	5.	If a generic PayPal ID has had to be assigned to a transaction then store it here
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		5.1.	Insert new secondary combinations
	***********************************************************************************************************************/

		INSERT INTO [MIDI].[PaymentGatewaySecondaryDetail] (ConsumerCombinationID
														,	MID
														,	Narrative)
		SELECT	ConsumerCombinationID
			,	MID
			,	MerchantName
		FROM [MIDI].[CTLoad_MIDIHolding] mh
		WHERE mh.RequiresSecondaryID = 1 
		AND NOT EXISTS (SELECT 1
						FROM [MIDI].[PaymentGatewaySecondaryDetail]pgsd
						WHERE mh.ConsumerCombinationID = pgsd.ConsumerCombinationID
						AND mh.MID = pgsd.MID
						AND mh.MerchantName = pgsd.Narrative)


		-- (2,411 rows affected) / 00:01:06
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match secondary combinations (1)'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		5.2.	Update the transactions with the new secondary combinations
	***********************************************************************************************************************/

		UPDATE mh
		SET	mh.SecondaryCombinationID = pgsd.PaymentGatewayID
		FROM [MIDI].[CTLoad_MIDIHolding] mh
		INNER JOIN [MIDI].[PaymentGatewaySecondaryDetail]pgsd
			ON mh.ConsumerCombinationID = pgsd.ConsumerCombinationID
			AND mh.MID = pgsd.MID
			AND mh.MerchantName = pgsd.Narrative
		WHERE mh.RequiresSecondaryID = 1
		AND mh.SecondaryCombinationID IS NULL

		-- (95,440 rows affected) / 00:00:02

		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match secondary combinations (2)'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

/*******************************************************************************************************************************************
	6.	Assign LocationIDs
*******************************************************************************************************************************************/

	
	/***********************************************************************************************************************
		6.1.	Assign LocationIDs where possible
	***********************************************************************************************************************/

	--	UPDATE mh
	--	SET LocationID = x.LocationID
	--	FROM [MIDI].[CTLoad_MIDIHolding] mh
	--	CROSS APPLY (	SELECT LocationID = MIN(loc.LocationID)
	--					FROM [Warehouse].[Relational].[Location] loc
	--					WHERE mh.ConsumerCombinationID = loc.ConsumerCombinationID
	--					AND loc.IsNonLocational = 1) x
	--	WHERE mh.LocationID IS NULL

	---- (251,723 rows affected) / 00:00:05

	--SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match locations (non-locational)'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	
	/***********************************************************************************************************************
		6.2.	Assign 0 LocationID if none available
	***********************************************************************************************************************/

		UPDATE mh
		SET	mh.LocationID = 0
		FROM [MIDI].[CTLoad_MIDIHolding] mh
		WHERE mh.LocationID IS NULL


/*******************************************************************************************************************************************
	7.	Log Stats for the processed file
*******************************************************************************************************************************************/

	INSERT INTO [MIDI].[CardTransaction_QA] (	FileID
											,	FileCount
											,	MatchedCount
											,	UnmatchedCount
											,	NoCINCount
											,	PositiveCount)
	SELECT	FileID
		,	COUNT(1) AS FileCount
		,	SUM(CASE WHEN ConsumerCombinationID IS NULL THEN 0 ELSE 1 END) AS MatchedCount
		,	SUM(CASE WHEN ConsumerCombinationID IS NULL THEN 1 ELSE 0 END) AS UnmatchedCount
		,	SUM(CASE WHEN CINID IS NOT NULL THEN 0 ELSE 1 END) AS NoCINCount
		,	SUM(CASE WHEN IsRefund = 0 THEN 1 ELSE 0 END) AS PositiveCount
	FROM [MIDI].[CTLoad_MIDIHolding]
	GROUP BY FileID

	
/*******************************************************************************************************************************************
	8.	Load transaction with an assigned CINID & ConsumerCombinationID to permanent holding table
*******************************************************************************************************************************************/

	INSERT INTO [MIDI].[ConsumerTransactionHolding] (	FileID
													,	RowNum
													,	ConsumerCombinationID
													,	SecondaryCombinationID
													,	BankID
													,	LocationID
													,	CardholderPresentData
													,	TranDate
													,	CINID
													,	Amount
													,	IsRefund
													,	IsOnline
													,	InputModeID
													,	PaymentTypeID)
	SELECT	mh.FileID
		,	mh.RowNum
		,	mh.ConsumerCombinationID
		,	mh.SecondaryCombinationID
		,	mh.BankID
		,	mh.LocationID
		,	mh.CardholderPresentData
		,	mh.TranDate
		,	mh.CINID
		,	mh.Amount
		,	mh.IsRefund
		,	mh.IsOnline
		,	mh.InputModeID
		,	mh.PaymentTypeID	
	FROM [MIDI].[CTLoad_MIDIHolding] mh
	WHERE CINID IS NOT NULL
	AND ConsumerCombinationID IS NOT NULL
	AND NOT EXISTS (SELECT 1
					FROM [MIDI].[ConsumerTransactionHolding] cth
					WHERE mh.FileID = cth.FileID
					AND mh.RowNum = cth.RowNum)
	ORDER BY FileID, RowNum

	
/*******************************************************************************************************************************************
	9.	Delete loaded transactions with an assigned CINID & ConsumerCombinationID
*******************************************************************************************************************************************/

	DELETE mh
	FROM [MIDI].[CTLoad_MIDIHolding] mh
	WHERE EXISTS (	SELECT 1
					FROM [MIDI].[ConsumerTransactionHolding] cth
					WHERE mh.FileID = cth.FileID
					AND mh.RowNum = cth.RowNum)

	-- (7,167,273 rows affected) / 00:02:18 
	SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - capture matched transactions to holding [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	;WITH RowToUpdate AS (	SELECT TOP(1) *
							FROM [MIDI].[GenericTrans_FilesProcessed] fp
							WHERE EXISTS (	SELECT 1
											FROM [MIDI].[CTLoad_MIDIHolding] mh
											WHERE fp.FileID = mh.FileID)
							ORDER BY FileID DESC)
	UPDATE RowToUpdate
	SET	RowsProcessed = ISNULL(RowsProcessed,0) + ISNULL(@RowsAffected,0)
	,	ProcessedDate = GETDATE()
						
	SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - End of second part'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

RETURN 0 


