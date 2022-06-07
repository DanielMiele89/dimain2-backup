CREATE PROC [ETL].[Reductions_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN

	 SET XACT_ABORT ON
	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2 = GETDATE()

	----------------------------------------------------------------------
	-- Build Breakage Lookup
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#BreakageTypes') IS NOT NULL 
		DROP TABLE #BreakageTypes

	SELECT AdditionalCashbackAdjustmentTypeID
	INTO #BreakageTypes
	FROM dbo.AdditionalCashbackAdjustmentType
	WHERE TypeDescription like '%Breakage%'

	CREATE CLUSTERED INDEX CIX ON #BreakageTypes (AdditionalCashbackAdjustmentTypeID)

	----------------------------------------------------------------------
	-- Load Staging table
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Reductions') IS NOT NULL 
		DROP TABLE #Reductions

	CREATE TABLE #Reductions
	(
		ReductionSourceSystemID TINYINT NOT NULL
		, ReductionSourceID INT NOT NULL
		, ReductionTypeID TINYINT NOT NULL
		, CustomerID INT NOT NULL
		, ReductionValue MONEY NOT NULL
		, ReductionDate DATE NOT NULL
		, CreatedDateTime DATETIME2 NOT NULL
	)

	INSERT INTO #Reductions
	(
		[ReductionSourceSystemID]
		, [ReductionSourceID]
		, [ReductionTypeID]
		, [CustomerID]
		, [ReductionValue]
		, [ReductionDate]
		, [CreatedDateTime]
	)
	SELECT 
		2 AS [ReductionSourceSystemID] -- Redemptions
		, RedemptionID  AS [ReductionSourceID]
		, CAST(1 AS TINYINT) AS [ReductionTypeID] -- Redemption
		, CustomerID
		, RedemptionValue AS [ReductionValue]
		, RedemptionDate AS [ReductionDate]
		, @RunDateTime AS CreatedDateTime
	FROM dbo.Redemptions re
	WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Reductions r
			WHERE r.ReductionSourceSystemID = 2
				AND re.RedemptionID = r.ReductionSourceID
		)

	UNION ALL

	-- Negative Breakage
	SELECT
		1 AS [ReductionSourceSystemID] -- Transactions
		, TransactionID AS [ReductionSourceID]
		, 2 AS ReductionTypeID -- Negative Breakage
		, t.FanID AS CustomerID
		, Earnings * -1 AS ReductionValue
		, TranDate AS ReductionDate
		, @RunDateTime AS CreatedDateTime
	FROM dbo.Transactions t
	WHERE EXISTS (
		SELECT 1
		FROM #BreakageTypes bt
		WHERE t.AdditionalCashbackAdjustmentTypeID = bt.AdditionalCashbackAdjustmentTypeID
	)
		AND t.Earnings < 0
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.Reductions r
			WHERE r.ReductionSourceSystemID = 1
				AND t.TransactionID = r.ReductionSourceID
		)

	--UNION ALL
	---- <0 Earnings i.e. refunds and not a breakage
	--SELECT
	--	1 AS [ReductionSourceSystemID] -- Redemptions
	--	, TransactionID AS ReductionSourceID
	--	, 3 AS ReductionTypeID -- Refunds and others
	--	, FanID AS CustomerID
	--	, Earnings * -1 AS ReductionValue
	--	, TranDate AS ReductionDate
	--	, @RunDateTime AS CreatedDateTime
	--FROM dbo.Transactions t
	--WHERE NOT EXISTS (
	--	SELECT 1
	--	FROM #BreakageTypes bt
	--	WHERE t.AdditionalCashbackAdjustmentTypeID = bt.AdditionalCashbackAdjustmentTypeID
	--)
	--	and Earnings < 0
	--	AND NOT EXISTS (
	--		SELECT 1
	--		FROM dbo.Reductions r
	--		WHERE r.ReductionSourceSystemID = 1
	--			AND t.TransactionID = r.ReductionSourceID
	--	)

	ALTER TABLE dbo.Reductions NOCHECK CONSTRAINT ALL

	INSERT INTO dbo.Reductions
	(
		[ReductionSourceSystemID]
		, [ReductionSourceID]
		, [ReductionTypeID]
		, [CustomerID]
		, [ReductionValue]
		, [ReductionDate]
		, [CreatedDateTime]
	)
	SELECT
		[ReductionSourceSystemID]
		, [ReductionSourceID]
		, [ReductionTypeID]
		, [CustomerID]
		, [ReductionValue]
		, [ReductionDate]
		, [CreatedDateTime]
	FROM #Reductions


	SET @RowCnt = @@ROWCOUNT

	ALTER TABLE dbo.Reductions WITH CHECK CHECK CONSTRAINT ALL

  END

