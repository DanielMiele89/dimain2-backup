CREATE PROC [WHB].[Redemptions_WHVirgin_DerivedRedemptions_Load]
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
		AND st.SourceSystemID = @SourceSystemID

	CREATE CLUSTERED INDEX CIX ON #RedemptionItem (SourceID)

	----------------------------------------------------------------------
	-- Load Staging table
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL 
		DROP TABLE #Redemptions

	SELECT TOP 0
		CustomerID
		, PublisherID
		, RedemptionItemID
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
		CustomerID
		, PublisherID
		, RedemptionItemID
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
		, RedemptionValue
		, RedemptionWorth
		, RedemptionDate
		, RedemptionDateTime
		, isCancelled
		, NULL AS CancelledDate
		, @SourceTypeID
		, x.SourceID
		, @RunDateTime AS CreatedDateTime
		, @RunDateTime AS UpdatedDateTime
		, NULL AS CancelledSourceID
	FROM
	(
		SELECT
			r.ID AS SourceID
			, r.RedemptionAmount AS RedemptionValue
			, r.RedemptionAmount AS RedemptionWorth
			, c.SourceUID AS SourceCustomerID
			, r.RedemptionDate AS RedemptionDate
			, r.RedemptionDate AS RedemptionDateTime
			, r.RedemptionType AS SourceRedemptionItemID
			, r.Cancelled as isCancelled
		FROM WH_Virgin.Derived.Redemptions r
		JOIN WH_Virgin.Derived.Customer c
			ON r.FanID = c.FanID
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Redemptions rx
			WHERE r.ID = rx.SourceID
				AND rx.SourceTypeID = @SourceTypeID
		)
	) x
	LEFT JOIN #Customer c
		ON x.SourceCustomerID = c.SourceID
	LEFT JOIN #RedemptionItem ri
		ON x.SourceRedemptionItemID = ri.SourceID

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
			CustomerID
			, PublisherID
			, RedemptionItemID
			, -1 AS PaymentCardID
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
		FROM #Redemptions

		SET @Inserted = @@ROWCOUNT
		
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
