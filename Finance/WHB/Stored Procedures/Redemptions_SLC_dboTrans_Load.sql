CREATE PROC [WHB].[Redemptions_SLC_dboTrans_Load]
		@RunID INT = NULL
AS
BEGIN
	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2(7) = GETDATE()
		, @StoredProcedureName VARCHAR(100)
		, @SourceTypeID INT
		, @SourceSystemID INT
		, @SourceTable VARCHAR(100)

	SET @StoredProcedureName = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	EXEC WHB.Get_SourceTypeID 
		@StoredProcedureName
		, @SourceTypeID OUTPUT
		, @SourceSystemID OUTPUT
		, @SourceTable OUTPUT

	IF @RunID IS NULL
		SET @RunID = NEXT VALUE FOR WHB.RunID

	----------------------------------------------------------------------
	-- Build Customer
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL
		DROP TABLE #Customer
	SELECT
		CustomerID
		, SourceID
		, PublisherID
	INTO #Customer
	FROM dbo.Customer c
	JOIN dbo.SourceType st
		ON c.SourceTypeID = st.SourceTypeID
		AND st.SourceSystemID = @SourceSystemID

	CREATE CLUSTERED INDEX CIX ON #Customer (SourceID)

	----------------------------------------------------------------------
	-- Build RedemptionItem
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#RedemptionItem') IS NOT NULL
		DROP TABLE #RedemptionItem
	SELECT
		RedemptionItemID
		, SourceID
	INTO #RedemptionItem
	FROM dbo.RedemptionItem c
	JOIN dbo.SourceType st
		ON c.SourceTypeID = st.SourceTypeID
	JOIN dbo.SourceSystem ss
		ON st.SourceSystemID = ss.SourceSystemID
		AND ss.SourceSystemName = 'Warehouse'

	CREATE CLUSTERED INDEX CIX ON #RedemptionItem (SourceID)

	----------------------------------------------------------------------
	-- Build PaymentCard to identify redemptions
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#PaymentCard') IS NOT NULL
		DROP TABLE #PaymentCard

	SELECT p.ID AS PanID
		, pc.PaymentCardID
	INTO #PaymentCard
	FROM SLC_REPL..Pan p	
	JOIN dbo.PaymentCard pc
		ON p.PaymentCardID = pc.SourceID
	JOIN dbo.SourceType st
		ON pc.SourceTypeID = st.SourceTypeID
		AND st.SourceSystemID = @SourceSystemID

	CREATE CLUSTERED INDEX CIX ON #PaymentCard (PanID)

	----------------------------------------------------------------------
	-- Load Staging table
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL 
		DROP TABLE #Redemptions

	SELECT TOP 0
		CAST(NULL AS VARCHAR(36)) AS SourceCustomerID
		, CAST(NULL AS VARCHAR(36)) AS SourceRedemptionItemID
		, CAST(NULL AS INT) AS PanID
		, RedemptionValue
		, RedemptionWorth
		, RedemptionDate
		, RedemptionDateTime
		, isCancelled
		, CancelledDate
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, CancelledSourceID
	INTO #Redemptions
	FROM dbo.Redemptions

	INSERT INTO #Redemptions
	(
		SourceCustomerID
		, SourceRedemptionItemID
		, PanID
		, RedemptionValue
		, RedemptionWorth
		, RedemptionDate
		, RedemptionDateTime
		, isCancelled
		, CancelledDate
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, CancelledSourceID
	)
	SELECT
		SourceCustomerID
		, SourceRedemptionItemID
		, PanID
		, RedemptionValue
		, RedemptionWorth
		, RedemptionDate
		, RedemptionDateTime
		, 0 AS isCancelled
		, NULL AS CancelledDate
		, @SourceTypeID
		, x.SourceID
		, @RunDateTime AS CreatedDateTime
		, @RunDateTime AS UpdatedDateTime
		, NULL AS CancelledSourceID
	FROM
	(
		SELECT
			r.TranID AS SourceID
			, r.CashbackUsed AS RedemptionValue
			, COALESCE(r.TradeUp_Value, r.CashbackUsed) AS RedemptionWorth
			, r.FanID AS SourceCustomerID
			, r.RedeemDate AS RedemptionDate
			, r.RedeemDate AS RedemptionDateTime
			, t.ItemID AS SourceRedemptionItemID
			, t.PanID
		FROM Warehouse.Relational.Redemptions r
		JOIN DIMAIN_TR.SLC_REPL.dbo.Trans t
			ON r.TranID = t.ID
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Redemptions rx
			WHERE r.TranID = rx.SourceID
				AND rx.SourceTypeID = @SourceTypeID
		)
	) x

	BEGIN TRAN
		DECLARE @Inserted INT = 0
			, @Updated INT = 0
			, @Deleted INT = 0

		INSERT INTO dbo.Redemptions
		(
			CustomerID
			, PublisherID
			, RedemptionItemID
			, PaymentCardID
			, RedemptionValue
			, RedemptionWorth
			, RedemptionDate
			, RedemptionDateTime
			, isCancelled
			, CancelledDate
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, UpdatedDateTime
			, CancelledSourceID		
		)
		SELECT
			c.CustomerID
			, c.PublisherID
			, ri.RedemptionItemID
			, COALESCE(p.PaymentCardID, -1) AS PaymentCardID
			, r.RedemptionValue
			, r.RedemptionWorth
			, r.RedemptionDate
			, r.RedemptionDateTime
			, r.isCancelled
			, r.CancelledDate
			, r.SourceTypeID
			, r.SourceID
			, r.CreatedDateTime
			, r.UpdatedDateTime
			, r.CancelledSourceID	
		FROM #Redemptions r
		LEFT JOIN #Customer c
			ON r.SourceCustomerID = c.SourceID
		LEFT JOIN #RedemptionItem ri
			ON r.SourceRedemptionItemID = ri.SourceID
		LEFT JOIN #PaymentCard p
			ON r.PanID = p.PanID

		SET @Inserted = @@ROWCOUNT

		UPDATE r
		SET isCancelled = 1
			, CancelledDate = t.Date
			, UpdatedDateTime = @RunDateTime
		FROM dbo.Redemptions r
		JOIN SLC_REPL..Trans t
			ON r.SourceID = t.ItemID
			AND r.SourceTypeID = @SourceTypeID
			AND t.TypeID = 4
		WHERE r.isCancelled = 0

		SET @Updated = @@RowCount

		INSERT INTO WHB.Build_Log (RunID, StartDateTime, EndDateTime, StoredProcName, InsertedRows, UpdatedRows, DeletedRows)
		SELECT
			@RunID
			,@RunDateTime
			,GETDATE()
			,@StoredProcedureName
			,InsertedRows = @Inserted
			,UpdatedRows = @Updated
			,DeletedRows = @Deleted

	COMMIT TRAN
END
