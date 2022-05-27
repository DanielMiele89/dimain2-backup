CREATE PROCEDURE [Staging].[MIDI_ConsumerCombination_Update]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT, @RowsAffected INT
	
	/*******************************************************************************************************************************************
		1.	Load Transactions to Temp
	*******************************************************************************************************************************************/

		DECLARE @LastYear DATE = DATEADD(YEAR, -1, GETDATE())				
		
		TRUNCATE TABLE [WH_AllPublishers].[Staging].[MIDI_ConsumerCombination_Temp]
		INSERT INTO [WH_AllPublishers].[Staging].[MIDI_ConsumerCombination_Temp]
		SELECT	BrandID = cc.BrandID
			,	MID = cc.MID
			,	Narrative = cc.Narrative
			,	Narrative_Cleaned = cc.Narrative
			,	LocationCountry = cc.LocationCountry
			,	MCCID = cc.MCCID
			,	OriginatorID = cc.OriginatorID
			,	IsHighVariance = cc.IsHighVariance
			,	Transactions = COUNT(*)
			,	Amount = SUM(ct.Amount)
		FROM [Warehouse].[Relational].[ConsumerCombination] cc
		INNER JOIN [Warehouse].[Relational].[ConsumerTransaction] ct
			ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
		WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
		AND BrandID != 944
		AND @LastYear <= ct.TranDate
		GROUP BY	cc.BrandID
				,	cc.MID
				,	cc.Narrative
				,	cc.LocationCountry
				,	cc.MCCID
				,	cc.OriginatorID
				,	cc.IsHighVariance

		SET @RowsAffected = @@ROWCOUNT

		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - [Warehouse].[Relational].[ConsumerTransaction] - Collect rows to process [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

		INSERT INTO [WH_AllPublishers].[Staging].[MIDI_ConsumerCombination_Temp]
		SELECT	BrandID = cc.BrandID
			,	MID = cc.MID
			,	Narrative = cc.Narrative
			,	Narrative_Cleaned = cc.Narrative
			,	LocationCountry = cc.LocationCountry
			,	MCCID = cc.MCCID
			,	OriginatorID = cc.OriginatorID
			,	IsHighVariance = cc.IsHighVariance
			,	Transactions = COUNT(*)
			,	Amount = SUM(ct.Amount)
		FROM [Warehouse].[Relational].[ConsumerCombination] cc
		INNER JOIN [Warehouse].[Relational].[ConsumerTransaction_CreditCard] ct
			ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
		WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
		AND BrandID != 944
		AND @LastYear <= ct.TranDate
		GROUP BY	cc.BrandID
				,	cc.MID
				,	cc.Narrative
				,	cc.LocationCountry
				,	cc.MCCID
				,	cc.OriginatorID
				,	cc.IsHighVariance

		SET @RowsAffected = @@ROWCOUNT

		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - [Warehouse].[Relational].[ConsumerTransaction] - Collect rows to process [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

		INSERT INTO [WH_AllPublishers].[Staging].[MIDI_ConsumerCombination_Temp]
		SELECT	BrandID = cc.BrandID
			,	MID = cc.MID
			,	Narrative = cc.Narrative
			,	Narrative_Cleaned = cc.Narrative
			,	LocationCountry = cc.LocationCountry
			,	MCCID = cc.MCCID
			,	OriginatorID = NULL
			,	IsHighVariance = cc.IsHighVariance
			,	Transactions = COUNT(*)
			,	Amount = SUM(ct.Amount)
		FROM [WH_Virgin].[Trans].[ConsumerCombination] cc
		INNER JOIN [WH_Virgin].[Trans].[ConsumerTransaction] ct
			ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
		WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
		AND BrandID != 944
		AND @LastYear <= ct.TranDate
		GROUP BY	cc.BrandID
				,	cc.MID
				,	cc.Narrative
				,	cc.LocationCountry
				,	cc.MCCID
				,	cc.IsHighVariance

		SET @RowsAffected = @@ROWCOUNT

		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - [Warehouse].[Relational].[ConsumerTransaction] - Collect rows to process [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

		INSERT INTO [WH_AllPublishers].[Staging].[MIDI_ConsumerCombination_Temp]
		SELECT	BrandID = cc.BrandID
			,	MID = cc.MID
			,	Narrative = cc.Narrative
			,	Narrative_Cleaned = cc.Narrative
			,	LocationCountry = cc.LocationCountry
			,	MCCID = cc.MCCID
			,	OriginatorID = cc.OriginatorID
			,	IsHighVariance = cc.IsHighVariance
			,	Transactions = COUNT(*)
			,	Amount = SUM(ct.Amount)
		FROM [WH_VirginPCA].[Trans].[ConsumerCombination] cc
		INNER JOIN [WH_VirginPCA].[Trans].[ConsumerTransaction] ct
			ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
		WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
		AND BrandID != 944
		AND @LastYear <= ct.TranDate
		GROUP BY	cc.BrandID
				,	cc.MID
				,	cc.Narrative
				,	cc.LocationCountry
				,	cc.MCCID
				,	cc.OriginatorID
				,	cc.IsHighVariance

		SET @RowsAffected = @@ROWCOUNT

		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - [Warehouse].[Relational].[ConsumerTransaction] - Collect rows to process [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

		INSERT INTO [WH_AllPublishers].[Staging].[MIDI_ConsumerCombination_Temp]
		SELECT	BrandID = cc.BrandID
			,	MID = cc.MID
			,	Narrative = cc.Narrative
			,	Narrative_Cleaned = cc.Narrative
			,	LocationCountry = cc.LocationCountry
			,	MCCID = cc.MCCID
			,	OriginatorID = cc.OriginatorID
			,	IsHighVariance = cc.IsHighVariance
			,	Transactions = COUNT(*)
			,	Amount = SUM(ct.Amount)
		FROM [WH_Visa].[Trans].[ConsumerCombination] cc
		INNER JOIN [WH_Visa].[Trans].[ConsumerTransaction] ct
			ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
		WHERE PaymentGatewayStatusID = 0	--	exclude non-individuated paypal
		AND BrandID != 944
		AND @LastYear <= ct.TranDate
		GROUP BY	cc.BrandID
				,	cc.MID
				,	cc.Narrative
				,	cc.LocationCountry
				,	cc.MCCID
				,	cc.OriginatorID
				,	cc.IsHighVariance

		SET @RowsAffected = @@ROWCOUNT

		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - [Warehouse].[Relational].[ConsumerTransaction] - Collect rows to process [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
		
	
	/*******************************************************************************************************************************************
		2.	Load Transactions
	*******************************************************************************************************************************************/

		TRUNCATE TABLE [WH_AllPublishers].[Staging].[MIDI_ConsumerCombination];
		WITH
		MIDI_ConsumerCombination AS (	SELECT	BrandID = ct.BrandID
											,	MID = ct.MID
											,	Narrative = ct.Narrative
											,	Narrative_Cleaned = ct.Narrative_Cleaned
											,	LocationCountry = ct.LocationCountry
											,	MCCID = ct.MCCID
											,	OriginatorID = ct.OriginatorID
											,	IsHighVariance = ct.IsHighVariance
											,	Transactions = SUM(ct.Transactions)
											,	Amount = SUM(ct.Amount)
										FROM [WH_AllPublishers].[Staging].[MIDI_ConsumerCombination_Temp] ct
										GROUP BY	ct.BrandID
												,	ct.MID
												,	ct.Narrative
												,	ct.Narrative_Cleaned
												,	ct.LocationCountry
												,	ct.MCCID
												,	ct.OriginatorID
												,	ct.IsHighVariance),

		ResultsRanked AS (				SELECT	BrandID = cc.BrandID
											,	MID = cc.MID
											,	Narrative = cc.Narrative
											,	Narrative_Cleaned = cc.Narrative_Cleaned
											,	LocationCountry = cc.LocationCountry
											,	MCCID = cc.MCCID
											,	OriginatorID = cc.OriginatorID
											,	IsHighVariance = cc.IsHighVariance
											,	Transactions = cc.Transactions
											,	Amount = cc.Amount
											,	ComboRank = ROW_NUMBER() OVER (PARTITION BY cc.MID, cc.Narrative, cc.Narrative_Cleaned, cc.LocationCountry, cc.MCCID, cc.OriginatorID, cc.IsHighVariance ORDER BY cc.Amount DESC)
										FROM MIDI_ConsumerCombination cc)

		INSERT INTO [WH_AllPublishers].[Staging].[MIDI_ConsumerCombination]
		SELECT	BrandID = rr.BrandID
			,	MID = rr.MID
			,	Narrative = rr.Narrative
			,	Narrative_Cleaned = rr.Narrative_Cleaned
			,	LocationCountry = rr.LocationCountry
			,	MCCID = rr.MCCID
			,	OriginatorID = rr.OriginatorID
			,	IsHighVariance = rr.IsHighVariance
			,	Transactions = rr.Transactions
			,	Amount = rr.Amount
		FROM ResultsRanked rr
		WHERE rr.ComboRank = 1

		SET @RowsAffected = @@ROWCOUNT

		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - [Warehouse].[Relational].[ConsumerTransaction] - Collect rows to process [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	
		
	/*******************************************************************************************************************************************
		3.	Clean Narratives
	*******************************************************************************************************************************************/

		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Indexes rebuilt'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT

		UPDATE mnc
		SET	Narrative_Cleaned = ISNULL(x.Narrative_Cleaned, mnc.Narrative_Cleaned)
		FROM [WH_AllPublishers].[Staging].[MIDI_ConsumerCombination] mnc -- 90,605
		OUTER APPLY [WH_AllPublishers].[dbo].[iTVF_NarrativeCleaner](-1,mnc.Narrative_Cleaned) q1
		OUTER APPLY [WH_AllPublishers].[dbo].[iTVF_NarrativeCleaner](q1.ID,q1.Narrative_Cleaned) q2
		OUTER APPLY [WH_AllPublishers].[dbo].[iTVF_NarrativeCleaner](q2.ID,q2.Narrative_Cleaned) q3
		CROSS APPLY (SELECT	Narrative_Cleaned = COALESCE(q3.Narrative_Cleaned, q2.Narrative_Cleaned, q1.Narrative_Cleaned, mnc.Narrative_Cleaned)) x		

		SET @RowsAffected = @@ROWCOUNT

		SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Narratives cleaned [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT
	
		
	/*******************************************************************************************************************************************
		4.	Reindex tables
	*******************************************************************************************************************************************/
	
		ALTER INDEX ALL ON [WH_AllPublishers].[Staging].[MIDI_ConsumerCombination] REBUILD

RETURN 0


