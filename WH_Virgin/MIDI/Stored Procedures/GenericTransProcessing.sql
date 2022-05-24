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
CREATE PROCEDURE [MIDI].[GenericTransProcessing]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT

SELECT @RowsAffected = COUNT(*) FROM [MIDI].[CTLoad_InitialStage] cis
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
			MCC
		,	''
		,	''
		,	''
		,	1
	FROM [MIDI].[CTLoad_InitialStage] cis
	WHERE NOT EXISTS (	SELECT 1
						FROM [Warehouse].[Relational].[MCCList] mcc
						WHERE mcc.MCC = cis.MCC)

-- 0 / 00:00:02
	
/*******************************************************************************************************************************************
	2.	Collect previously-unseen CINs from the new data
*******************************************************************************************************************************************/

	INSERT INTO [Derived].[CINList] (CIN)
	SELECT	DISTINCT
			fa.SourceUID
	FROM [MIDI].[CTLoad_InitialStage] cis
	INNER JOIN [WHB].[Inbound_Cards] ca
		ON cis.CardID = ca.CardID
	INNER JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[Fan] fa
		ON ca.PrimaryCustomerID = fa.ID
	WHERE NOT EXISTS (	SELECT 1
						FROM [Derived].[CINList] cl
						WHERE fa.SourceUID = cl.CIN)

	--SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Collect previously-unseen CINs [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	
-- (1056 rows affected) / 00:02:58
	
/*******************************************************************************************************************************************
	3.	Update various columns
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		3.1.	Assign MMCID
	***********************************************************************************************************************/
	
		UPDATE cis
		SET	cis.MCCID = m.MCCID
		FROM [MIDI].[CTLoad_InitialStage] cis
		INNER JOIN [Warehouse].[Relational].[MCCList] m
			ON cis.MCC = m.MCC
		
		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Assign MMCID [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		3.2.	Assign CIN & BankID
	***********************************************************************************************************************/
	
		UPDATE cis
		SET	cis.CIN = fa.SourceUID
		,	cis.BankID = ca.BankID
		,	cis.PaymentTypeID = 2
		FROM [MIDI].[CTLoad_InitialStage] cis
		INNER JOIN [WHB].[Inbound_Cards] ca
			ON cis.CardID = ca.CardID
		INNER JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[Fan] fa
			ON ca.PrimaryCustomerID = fa.ID
		
		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Assign CIN & BankID [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		3.3.	Assign CINID
	***********************************************************************************************************************/

		UPDATE cis
		SET	cis.CINID = cl.CINID
		FROM [MIDI].[CTLoad_InitialStage] cis
		INNER JOIN [Derived].[CINList] cl
			ON cis.CIN = cl.CIN
		
		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Assign CINID [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		3.4.	Assign InputModeID
	***********************************************************************************************************************/

		UPDATE cis
		SET	cis.InputModeID = cim.InputModeID
		FROM [MIDI].[CTLoad_InitialStage] cis
		INNER JOIN [Warehouse].[Relational].[CardInputMode] cim
			ON cis.CardInputMode = cim.CardInputMode
		
		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Assign InputModeID [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		3.5.	Assign Generic MID for Visa Claim Resolutions
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#VCR') IS NOT NULL DROP TABLE #VCR
		SELECT *
		INTO #VCR
		FROM [MIDI].[CTLoad_InitialStage] ct
		WHERE MID LIKE 'VCR%[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]%'

		UPDATE vcr
		SET vcr.MID = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(MID, '0', ''), '1', ''), '2', ''), '3', ''), '4', ''), '5', ''), '6', ''), '7', ''), '8', ''), '9', '')
		FROM #VCR vcr

		CREATE CLUSTERED INDEX CIX_MID ON #VCR (FileID, RowNum, MID)

		UPDATE ct
		SET ct.MID = LTRIM(RTRIM(vcr.MID)) + '%'
		FROM #VCR vcr
		INNER JOIN [MIDI].[CTLoad_InitialStage] ct
			ON vcr.FileID = ct.FileID
			AND vcr.RowNum = ct.RowNum

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Assign Generic MID for VCR [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	
/*******************************************************************************************************************************************
	4.	Assign CCs
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		4.1.	Non High Variance
	***********************************************************************************************************************/

		UPDATE	cis
		SET	cis.ConsumerCombinationID = cc.ConsumerCombinationID
		FROM [MIDI].[CTLoad_InitialStage] cis
		INNER JOIN [Trans].[ConsumerCombination] cc
			ON cis.MID = cc.MID
			AND cis.MerchantCountry = cc.LocationCountry
			AND cis.MCCID = cc.MCCID
			AND cc.PaymentGatewayStatusID != 1	--	not default Paypal
			AND (cis.MerchantName = cc.Narrative AND cc.IsHighVariance = 0)

		SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Set Non-Paypal Combinations (low variance - 1) [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	

	/***********************************************************************************************************************
		4.2.	High Variance
	***********************************************************************************************************************/

		UPDATE	cis
		SET	cis.ConsumerCombinationID = cc.ConsumerCombinationID
		FROM [MIDI].[CTLoad_InitialStage] cis
		INNER JOIN [Trans].[ConsumerCombination] cc
			ON cis.MID = cc.MID
			AND cis.MerchantCountry = cc.LocationCountry
			AND cis.MCCID = cc.MCCID
			AND cc.PaymentGatewayStatusID != 1	--	not default Paypal
			AND (cis.MerchantName LIKE cc.Narrative AND cc.IsHighVariance = 1)
		WHERE cis.ConsumerCombinationID IS NULL

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
			FROM [MIDI].[CTLoad_InitialStage]
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
													,	IsHighVariance
													,	IsUKSpend
													,	PaymentGatewayStatusID)
			SELECT	943 AS BrandID
				,	'%' AS MID
				,	'PAYPAL%' AS Narrative
				,	MerchantCountry AS LocationCountry
				,	MCCID
				,	1 AS IsHighVariance
				,	CASE
						WHEN cis.MerchantCountry = 'GB' THEN 1
						ELSE 0
					END AS IsUKSpend
				,	1 AS PaymentGatewayStatusID
			FROM [MIDI].[CTLoad_InitialStage] cis
			WHERE cis.ConsumerCombinationID IS NULL
			AND cis.MerchantName LIKE 'PAYPAL%'
			AND cis.MCCID IS NOT NULL
			AND EXISTS (SELECT 1
						FROM #PaypalMIDNew pn
						WHERE cis.MID = pn.MID)
			AND NOT EXISTS (SELECT 1 
							FROM [Trans].[ConsumerCombination] cc
							WHERE cc.PaymentGatewayStatusID = 1
							AND cis.MerchantCountry = cc.LocationCountry
							AND cis.MCCID = cc.MCCID)
			
			-- (0 rows affected) / 00:00:01

			SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - New Paypal Combinations [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	
		/*******************************************************************************
			4.3.3.	Assign the newly created CCs back to the transactions
		*******************************************************************************/
		
			UPDATE cis
			SET cis.ConsumerCombinationID = cc.ConsumerCombinationID
			,	cis.RequiresSecondaryID = 1
			FROM [MIDI].[CTLoad_InitialStage] cis
			CROSS APPLY (	SELECT	TOP 1
									ConsumerCombinationID
							FROM [Trans].[ConsumerCombination] cc
							WHERE cc.PaymentGatewayStatusID = 1
							AND cis.MerchantCountry = cc.LocationCountry
							AND cis.MCCID = cc.MCCID) cc
			WHERE cis.MerchantName LIKE 'PAYPAL%'
			AND cis.ConsumerCombinationID IS NULL
			AND EXISTS (SELECT 1
						FROM #PaypalMIDNew pn
						WHERE cis.MID = pn.MID)

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
		FROM [MIDI].[CTLoad_InitialStage] cis
		WHERE cis.RequiresSecondaryID = 1 
		AND NOT EXISTS (SELECT 1
						FROM [MIDI].[PaymentGatewaySecondaryDetail]  pgsd
						WHERE cis.ConsumerCombinationID = pgsd.ConsumerCombinationID
						AND cis.MID = pgsd.MID
						AND cis.MerchantName = pgsd.Narrative)


		-- (2,411 rows affected) / 00:01:06
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match secondary combinations (1)'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	/***********************************************************************************************************************
		5.2.	Update the transactions with the new secondary combinations
	***********************************************************************************************************************/

		UPDATE cis
		SET	cis.SecondaryCombinationID = pgsd.PaymentGatewayID
		FROM [MIDI].[CTLoad_InitialStage] cis
		INNER JOIN [MIDI].[PaymentGatewaySecondaryDetail]  pgsd
			ON cis.ConsumerCombinationID = pgsd.ConsumerCombinationID
			AND cis.MID = pgsd.MID
			AND cis.MerchantName = pgsd.Narrative
		WHERE cis.RequiresSecondaryID = 1
		AND cis.SecondaryCombinationID IS NULL

		-- (95,440 rows affected) / 00:00:02

		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match secondary combinations (2)'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

/*******************************************************************************************************************************************
	6.	Assign LocationIDs
*******************************************************************************************************************************************/

	
	/***********************************************************************************************************************
		6.1.	Assign LocationIDs where possible
	***********************************************************************************************************************/

	--	UPDATE cis
	--	SET LocationID = x.LocationID
	--	FROM [MIDI].[CTLoad_InitialStage] cis
	--	CROSS APPLY (	SELECT LocationID = MIN(loc.LocationID)
	--					FROM [Warehouse].[Relational].[Location] loc
	--					WHERE cis.ConsumerCombinationID = loc.ConsumerCombinationID
	--					AND loc.IsNonLocational = 1) x
	--	WHERE cis.LocationID IS NULL

	---- (251,723 rows affected) / 00:00:05

	--SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - match locations (non-locational)'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	
	/***********************************************************************************************************************
		6.2.	Assign 0 LocationID if none available
	***********************************************************************************************************************/

		UPDATE cis
		SET	cis.LocationID = 0
		FROM [MIDI].[CTLoad_InitialStage] cis
		WHERE cis.LocationID IS NULL


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
	FROM [MIDI].[CTLoad_InitialStage]
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
	SELECT	cis.FileID
		,	cis.RowNum
		,	cis.ConsumerCombinationID
		,	cis.SecondaryCombinationID
		,	cis.BankID
		,	cis.LocationID
		,	cis.CardholderPresentData
		,	CONVERT(DATETIME, cis.TranDate) + CONVERT(DATETIME, cis.TranTime)
		,	cis.CINID
		,	cis.Amount
		,	cis.IsRefund
		,	cis.IsOnline
		,	cis.InputModeID
		,	cis.PaymentTypeID	
	FROM [MIDI].[CTLoad_InitialStage] cis
	WHERE CINID IS NOT NULL
	AND ConsumerCombinationID IS NOT NULL
	AND NOT EXISTS (SELECT 1
					FROM [MIDI].[ConsumerTransactionHolding] cth
					WHERE cis.FileID = cth.FileID
					AND cis.RowNum = cth.RowNum)
	ORDER BY FileID, RowNum

	-- (7,167,273 rows affected) / 00:02:18 
	SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - capture matched transactions to holding [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

	;WITH RowToUpdate AS (	SELECT TOP(1) *
							FROM [MIDI].[GenericTrans_FilesProcessed] fp
							WHERE EXISTS (	SELECT 1
											FROM [MIDI].[CTLoad_InitialStage] cis
											WHERE fp.FileID = cis.FileID)
							ORDER BY FileID DESC)
	UPDATE RowToUpdate
	SET	RowsProcessed = ISNULL(RowsProcessed,0) + ISNULL(@RowsAffected,0)
	,	ProcessedDate = GETDATE() 

	
/*******************************************************************************************************************************************
	9.	Where there is no assigned CINID or ConsumerCombinationID, load to permanent MIDI holding table
*******************************************************************************************************************************************/
	
	INSERT INTO [MIDI].[CTLoad_MIDIHolding]
	SELECT	cis.[FileID]
		,	cis.[RowNum]
		,	cis.[FileName]
		,	cis.[LoadDate]
		,	cis.[CardID]
		,	cis.[BankID]
		,	cis.[CIN]
		,	cis.[CINID]
		,	cis.[MID]
		,	cis.[MerchantCountry]
		,	cis.[LocationID]
		,	cis.[LocationAddress]
		,	cis.[MerchantName]
		,	cis.[CardholderPresentData]
		,	cis.[MCC]
		,	cis.[MCCID]
		,	CONVERT(DATETIME, cis.[TranDate]) + CONVERT(DATETIME, cis.[TranTime])
		,	cis.[Amount]
		,	cis.[CurrencyCode]
		,	cis.[CardInputMode]
		,	cis.[InputModeID]
		,	cis.[PaymentTypeID]
		,	cis.[CashbackAmount]
		,	cis.[IsOnline]
		,	cis.[IsRefund]
		,	cis.[ConsumerCombinationID]
		,	cis.[RequiresSecondaryID]
		,	cis.[SecondaryCombinationID]
	FROM [MIDI].[CTLoad_InitialStage] cis
	WHERE CINID IS NULL
	OR ConsumerCombinationID IS NULL

	-- (7,167,273 rows affected) / 00:02:18 

	SET @RowsAffected = @@ROWCOUNT; SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - capture matched transactions to MIDI holding [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
		

/*******************************************************************************************************************************************
	10.	Clear down Staging table & mark file as processed
*******************************************************************************************************************************************/
	
	/***********************************************************************************************************************
		10.1.	Store ID of File processed
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#FileProcessed') IS NOT NULL DROP TABLE #FileProcessed
		SELECT	DISTINCT
				FileID
		INTO #FileProcessed
		FROM [MIDI].[CTLoad_InitialStage]
	
	/***********************************************************************************************************************
		10.2.	Clear down Staging table
	***********************************************************************************************************************/

		TRUNCATE TABLE [MIDI].[CTLoad_InitialStage]
	
	/***********************************************************************************************************************
		10.3.	Mark the file as processsed
	***********************************************************************************************************************/

		UPDATE f
		SET f.FileProcessed = 1
		FROM [WHB].[Inbound_Files] f
		WHERE EXISTS (	SELECT 1
						FROM #FileProcessed fp
						WHERE f.ID = fp.FileID)
						
		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - End of first part'; EXEC [Monitor].[ProcessLogger] 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

RETURN 0 


