
CREATE PROCEDURE [ETL].[Transactions_AdditionalCashbackAdjustment_Load_OLD]
AS
BEGIN

	 SET XACT_ABORT ON

	----------------------------------------------------------------------
	-- Checkpoint Variables
	----------------------------------------------------------------------

	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2 = GETDATE()
		, @SourceTypeID INT = 3

	EXEC ETL.SourceType_CheckID @SourceTypeID, 'AdditionalCashbackAdjustment'


	----------------------------------------------------------------------
	-- Build ACAdjustment Table
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#ACAdj') IS NOT NULL 
		DROP TABLE #ACAdj

	SELECT
		aca.*
		, act.AdditionalCashbackAdjustmentCategoryID
		, tt.Multiplier
	INTO #ACAdj
	FROM Warehouse.Relational.AdditionalCashbackAdjustment_incTranID aca -- Insert excludes Burn As You Earn, as these have an ItemID of 0 in the Warehouse.Relational.AdditionalCashbackAdjustmentType table
	INNER JOIN Warehouse.Relational.AdditionalCashbackAdjustmentType act
		ON aca.AdditionalCashbackAdjustmentTypeID = act.AdditionalCashbackAdjustmentTypeID
	INNER JOIN SLC_REPL..TransactionType tt
		ON act.TypeID = tt.ID

	CREATE CLUSTERED INDEX CIX ON #ACAdj (TranID)

	----------------------------------------------------------------------
	-- LOAD Staging Table
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#AdditionalCashbackAdjustment') IS NOT NULL
		DROP TABLE #AdditionalCashbackAdjustment

	CREATE TABLE #AdditionalCashbackAdjustment
	(
		FanID INT NOT NULL,
		IronOfferID INT NOT NULL,
		PartnerID INT NOT NULL,
		ClubID INT NOT NULL,
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
		CreatedDateTime DATETIME2 NOT NULL,
		ItemID INT NULL,
		TypeID INT NULL,
		ActivationDays INT

	)
	
	INSERT INTO #AdditionalCashbackAdjustment
	(
		FanID
		, IronOfferID
		, PartnerID
		, ClubID
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
	)
	Select	--top 1
		tr.FanID
		, -1 AS IronOfferID
		, -1 AS PartnerID
		, 132 AS ClubID
		, NULL AS Spend
		, tr.ClubCash * aca.Multiplier AS Earnings
		, tr.Date AS TranDate
		, tr.TypeID AS TransactionTypeID
		, -1 AS AdditionalCashbackAwardTypeID
		, aca.AdditionalCashbackAdjustmentTypeID
		, aca.AdditionalCashbackAdjustmentCategoryID
		, -1 AS PaymentMethodID
		, DirectDebitOriginatorID
		, tr.ProcessDate AS SourceAddedDate
		, tr.ID AS SourceID
		, @SourceTypeID AS SourceTypeID
		, 1 AS SourceSystemID
		, @RunDateTime AS CreatedDateTime
		, tr.ActivationDays
	FROM SLC_Repl.[dbo].[Trans] tr
	INNER JOIN #ACAdj aca
		ON tr.ID = aca.TranID
	WHERE NOT EXISTS (
		SELECT 1
		FROM dbo.Transactions t
		WHERE t.SourceID = aca.TranID
			AND t.SourceSystemID = 1
			AND t.AdditionalCashbackAwardTypeID = -1
	)
	
	/**********************************************************************
	LOAD INTO Main Table and update checkpoint
	***********************************************************************/
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
			, EarningSourceID
			, ActivationDays
			, EligibleDate
		)
		SELECT
			te.FanID
			, te.IronOfferID
			, te.PartnerID
			, te.ClubID
			, te.Spend
			, te.Earnings
			, te.TranDate
			, te.TransactionTypeID
			, te.AdditionalCashbackAwardTypeID
			, te.AdditionalCashbackAdjustmentTypeID
			, te.AdditionalCashbackAdjustmentCategoryID
			, te.PaymentMethodID
			, te.DirectDebitOriginatorID
			, te.SourceAddedDate
			, te.SourceID
			, te.SourceTypeID
			, te.SourceSystemID
			, te.CreatedDateTime
			, cs.EarningSourceID
			, te.ActivationDays
			, DATEADD(DAY, te.ActivationDays, te.TranDate) AS EligibleDate
		FROM #AdditionalCashbackAdjustment te
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

	COMMIT TRAN

END



