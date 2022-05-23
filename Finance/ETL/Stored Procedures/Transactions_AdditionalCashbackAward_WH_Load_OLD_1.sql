CREATE PROCEDURE [ETL].[Transactions_AdditionalCashbackAward_WH_Load_OLD]
AS
BEGIN

	 SET XACT_ABORT ON

	----------------------------------------------------------------------
	-- Checkpoint Variables
	----------------------------------------------------------------------
	DECLARE @CheckpointTypeID INT = 7
		, @StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
	DECLARE @CheckpointValue INT = ETL.getTableCheckpoint(@CheckpointTypeID, @StoredProcName, 1, 0)

	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2 = GETDATE()
		, @SourceTypeID INT = 2

	EXEC ETL.SourceType_CheckID @SourceTypeID, 'AdditionalCashbackAward'

	----------------------------------------------------------------------
	-- AdditionalCashbackAward Staging for indexing purposes
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#AdditionalCashbackAward') IS NOT NULL 
		DROP TABLE #AdditionalCashbackAward
	SELECT
		*
	INTO #AdditionalCashbackAward
	FROM Warehouse.Relational.AdditionalCashbackAward aca
	WHERE aca.AdditionalCashbackAwardID > @CheckpointValue
		AND FileID > 0

	CREATE CLUSTERED INDEX CIX ON #AdditionalCashbackAward (FileID, RowNum)

	----------------------------------------------------------------------
	-- Build staging table
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#CashbackAward_Stage') IS NOT NULL
		DROP TABLE #CashbackAward_Stage

	SELECT
		aca.FanID
		, -1 AS IronOfferID
		, -1 AS PartnerID
		, 132 AS PublisherID
		, aca.Amount AS Spend
		, aca.CashbackEarned as Earnings
		, aca.TranDate as TranDate
		, t.TypeID AS TransactionTypeID
		, -1 AS AdditionalCashbackAdjustmentTypeID
		, -1 AS AdditionalCashbackAdjustmentCategoryID
		, aca.PaymentMethodID
		, t.DirectDebitOriginatorID
		, t.ProcessDate AS SourceAddedDate
		, t.ID AS SourceID
		, @SourceTypeID AS SourceTypeID
		, 1 AS SourceSystemID
		, @RunDateTime AS CreatedDateTime
		, t.ActivationDays
		, aca.AdditionalCashbackAwardID AS CheckpointID
		, t.ItemID
	INTO #CashbackAward_Stage
	FROM #AdditionalCashbackAward aca
	JOIN SLC_Report..Trans t
		ON aca.FileID = t.VectorMajorID
		AND aca.RowNum = t.VectorMinorID

	CREATE CLUSTERED INDEX CIX ON #CashbackAward_Stage (TransactionTypeID, ItemID)

	IF OBJECT_ID('tempdb..#CashbackAward') IS NOT NULL 
		DROP TABLE #CashbackAward

	SELECT
		t.*
		, act.AdditionalCashbackAwardTypeID
	INTO #CashbackAward
	FROM #CashbackAward_Stage t
	JOIN Warehouse.Relational.AdditionalCashbackAwardType act
		ON t.TransactionTypeID = act.TransactionTypeID 
		AND t.ItemID = act.ItemID
	WHERE NOT EXISTS (
		SELECT 1
		FROM dbo.Transactions tr
		WHERE tr.SourceSystemID = 1
			AND tr.SourceID = t.SourceID
	)

	----------------------------------------------------------------------
	-- Load Transaction table
	----------------------------------------------------------------------
	BEGIN TRAN

		INSERT INTO dbo.Transactions
		(
			FanID
			, IronOfferID
			, PartnerID
			, PublisherID
			, Spend
			, Earnings
			, TranDate
			, TransactionTypeID
			, AdditionalCashbackAwardTypeID
			, AdditionalCashbackAdjustmentTypeID
			, AdditionalCashbackAdjustmentCategoryID
			, PaymentMethodID
			, DirectDebitOriginatorID
			, EarningSourceID
			, SourceAddedDate
			, SourceID
			, SourceTypeID
			, SourceSystemID
			, CreatedDateTime
			, ActivationDays
			, EligibleDate
		) 
		SELECT
			te.FanID
			, te.IronOfferID
			, te.PartnerID
			, te.PublisherID
			, te.Spend
			, te.Earnings
			, te.TranDate
			, te.TransactionTypeID
			, te.AdditionalCashbackAwardTypeID
			, te.AdditionalCashbackAdjustmentTypeID
			, te.AdditionalCashbackAdjustmentCategoryID
			, te.PaymentMethodID
			, te.DirectDebitOriginatorID
			, cs.EarningSourceID
			, te.SourceAddedDate
			, te.SourceID
			, te.SourceTypeID
			, te.SourceSystemID
			, te.CreatedDateTime
			, te.ActivationDays
			, DATEADD(DAY, te.ActivationDays, te.TranDate) AS EligibleDate
		FROM #CashbackAward te
		LEFT JOIN dbo.PartnerAlternate pa
			ON te.PartnerID = pa.AlternatePartnerID
		LEFT JOIN dbo.DirectDebitOriginator do
			ON te.DirectDebitOriginatorID = do.DirectDebitOriginatorID
		LEFT JOIN dbo.EarningSource cs 
			ON COALESCE(pa.PartnerID, te.PartnerID) = cs.PartnerID
			AND te.AdditionalCashbackAdjustmentTypeID = cs.AdditionalCashbackAdjustmentTypeID
			AND te.AdditionalCashbackAwardTypeID = cs.AdditionalCashbackAwardTypeID
			AND te.AdditionalCashbackAdjustmentCategoryID = cs.AdditionalCashbackAdjustmentCategoryID
			AND COALESCE(do.Category2, '') = cs.DDCategory

		INSERT INTO ETL.TableCheckpoint (
			CheckpointTypeID,
			CheckpointValue1
		)
		SELECT 
			@CheckpointTypeID
			, MAX(CheckpointID)
		FROM #CashbackAward

	COMMIT

END



