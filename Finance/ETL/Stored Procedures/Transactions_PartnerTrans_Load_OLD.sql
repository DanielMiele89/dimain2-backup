CREATE PROCEDURE [ETL].[Transactions_PartnerTrans_Load_OLD]
AS
BEGIN

	 SET XACT_ABORT ON

	----------------------------------------------------------------------
	-- Checkpoint Variables
	----------------------------------------------------------------------
	DECLARE @CheckpointTypeID INT = 5
		, @StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
	DECLARE @CheckpointValue INT = ETL.getTableCheckpoint(@CheckpointTypeID, @StoredProcName, 1, 0)

	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2 = GETDATE()
		, @SourceTypeID INT = 1

	EXEC ETL.SourceType_CheckID @SourceTypeID, 'PartnerTrans'

	----------------------------------------------------------------------
	-- Load Staging Table
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#PartnerTrans') IS NOT NULL
		DROP TABLE #PartnerTrans

	CREATE TABLE #PartnerTrans
	(
		FanID INT NOT NULL,
		IronOfferID INT NOT NULL,
		PartnerID INT NOT NULL,
		PublisherID INT NOT NULL,
		Spend SMALLMONEY,
		Earnings SMALLMONEY,
		TranDate DATE NOT NULL,
		TransactionTypeID SMALLINT NULL,
		AdditionalCashbackAwardTypeID SMALLINT NOT NULL,
		AdditionalCashbackAdjustmentTypeID SMALLINT NOT NULL,
		AdditionalCashbackAdjustmentCategoryID SMALLINT NOT NULL,
		PaymentMethodID SMALLINT NOT NULL,
		DirectDebitOriginatorID INT,
		SourceAddedDate DATE,
		SourceID INT NOT NULL,
		SourceTypeID INT NOT NULL,
		SourceSystemID INT NOT NULL,
		CreatedDateTime DATE NOT NULL,
		ActivationDays INT,
		CheckpointID INT NOT NULL
	)

	INSERT INTO #PartnerTrans
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
		, SourceAddedDate
		, SourceID
		, SourceTypeID
		, SourceSystemID
		, CreatedDateTime
		, ActivationDays
		, CheckpointID
	) 
	select
		p.FanID
		, p.IronOfferID
		, p.PartnerID
		, 132 AS PublisherID
		, p.TransactionAmount AS Spend
		, ISNULL(p.CashbackEarned,0) AS Earnings
		, p.TransactionDate AS TranDate
		, COALESCE(t.TypeID, -1) AS TransactionTypeID
		, -1 AS AdditionalCashbackAwardTypeID
		, -1 AS [AdditionalCashbackAdjustmentTypeID]
		, -1 AS [AdditionalCashbackAdjustmentCategoryID]
		, p.PaymentMethodID
		, DirectDebitOriginatorID
		, p.AddedDate AS SourceAddedDate
		, COALESCE(t.ID, p.MatchID) AS SourceID
		, @SourceTypeID AS SourceTypeID 
		, COALESCE(CAST(t.ID AS BIT), 2) AS SourceSystemID
		, @RunDateTime AS CreatedDateTime
		, COALESCE(t.ActivationDays, p.ActivationDays) AS ActivationDays
		, p.MatchID AS CheckpointID
	from Warehouse.Relational.PartnerTrans p
	LEFT JOIN SLC_Report..Trans t
		on p.MatchID = t.MatchID
	WHERE p.MatchID > @CheckpointValue
		AND (
			(
				t.TypeID <> 24
				AND t.VectorID = 40
			) 
			OR t.vectorid <> 40
			OR t.ID IS NULL
		)
	
	CREATE CLUSTERED INDEX CIX_Match ON #PartnerTrans(SourceID)

	----------------------------------------------------------------------
	-- Insert into main table and log checkpoints
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
			, SourceAddedDate
			, SourceID
			, SourceTypeID
			, SourceSystemID
			, CreatedDateTime
			, ActivationDays
			, EarningSourceID
			, EligibleDate
		) 
		SELECT
			pt.FanID
			, pt.IronOfferID
			, pt.PartnerID
			, pt.PublisherID
			, pt.Spend
			, pt.Earnings
			, pt.TranDate
			, TransactionTypeID
			, pt.AdditionalCashbackAwardTypeID
			, pt.AdditionalCashbackAdjustmentTypeID
			, pt.AdditionalCashbackAdjustmentCategoryID
			, pt.PaymentMethodID
			, pt.DirectDebitOriginatorID
			, pt.SourceAddedDate
			, SourceID
			, pt.SourceTypeID
			, pt.SourceSystemID
			, pt.CreatedDateTime
			, pt.ActivationDays
			, cs.EarningSourceID
			, DATEADD(DAY, pt.ActivationDays, pt.TranDate) AS EligibleDate
		FROM #PartnerTrans pt
		LEFT JOIN dbo.PartnerAlternate pa
			ON pt.PartnerID = pa.AlternatePartnerID
		LEFT JOIN dbo.DirectDebitOriginator do
			ON pt.DirectDebitOriginatorID = do.DirectDebitOriginatorID
		LEFT JOIN dbo.EarningSource cs 
			ON COALESCE(pa.PartnerID, pt.PartnerID) = cs.PartnerID
			AND pt.AdditionalCashbackAdjustmentTypeID = cs.AdditionalCashbackAdjustmentTypeID
			AND pt.AdditionalCashbackAwardTypeID = cs.AdditionalCashbackAwardTypeID
			AND pt.AdditionalCashbackAdjustmentCategoryID = cs.AdditionalCashbackAdjustmentCategoryID
			AND COALESCE(do.Category2, '') = cs.DDCategory

		INSERT INTO ETL.TableCheckpoint (
			CheckpointTypeID,
			CheckpointValue1
		)
		SELECT 
			@CheckpointTypeID
			, MAX(CheckpointID)
		FROM #PartnerTrans

	COMMIT TRAN

END



