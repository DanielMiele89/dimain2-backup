

CREATE PROC WHB.Customer_WHVisa_DerivedCustomer_Load
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
	-- Get Customer
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Customer_Staging') IS NOT NULL
		DROP TABLE #Customer_Staging
	SELECT 
		SourceUID					AS SourceID
		, 180						AS PublisherID
		, CurrentlyActive			AS isActive
		, CashBackPending
		, CashBackAvailable
		, RegistrationDate			AS ActivatedDate
		, DeactivatedDate
	INTO #Customer_Staging
	FROM WH_Visa.Derived.Customer

	CREATE CLUSTERED INDEX CIX ON #Customer_Staging(SourceID)

	----------------------------------------------------------------------
	-- Create Final Customer Table to upsert
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL   
		DROP TABLE #Customer;

	SELECT TOP 0
		PublisherID
		, isActive
		, CashBackPending
		, CashBackAvailable
		, ActivatedDate
		, DeactivatedDate
		, DeactivatedBandID
		, isCredit
		, isDebit
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	INTO #Customer
	FROM dbo.Customer

	INSERT INTO #Customer
	(
		PublisherID
		, isActive
		, CashBackPending
		, CashBackAvailable
		, ActivatedDate
		, DeactivatedDate
		, DeactivatedBandID
		, isCredit
		, isDebit
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	)
	SELECT
		PublisherID
		, isActive
		, CashBackPending
		, CashBackAvailable
		, ActivatedDate
		, DeactivatedDate
		, DeactivatedBandID
		, isCredit
		, isDebit
		, @SourceTypeID
		, SourceID
		, @RunDateTime		AS CreatedDateTime
		, @RunDateTime		AS UpdatedDateTime
		, HASHBYTES('MD5',
			CONCAT(PublisherID
				, ',', isActive
				, ',', CashBackPending
				, ',', CashBackAvailable
				, ',', ActivatedDate
				, ',', DeactivatedDate
				, ',', DeactivatedBandID
				, ',', isCredit
				, ',', isDebit
			)
		) AS MD5
	FROM
	(
		SELECT 
			cs.SourceID
			, cs.PublisherID
			, cs.isActive
			, cs.CashBackPending
			, cs.CashBackAvailable
			, cs.ActivatedDate
			, cs.DeactivatedDate
			, COALESCE(db.DeactivatedBandID, -1) AS DeactivatedBandID
			, NULL AS isCredit
			, NULL AS isDebit
		FROM #Customer_Staging cs
		CROSS APPLY (
			SELECT DATEDIFF(DAY, DeactivatedDate, @RunDateTime) DeactivatedDays
		) cd
		LEFT JOIN dbo.DeactivatedBand db
			ON cd.DeactivatedDays BETWEEN db.DeactivatedBandMin and db.DeactivatedBandMax
	) x

	CREATE CLUSTERED INDEX CIX ON #Customer (SourceID)

	BEGIN TRAN

		DECLARE @Inserted INT = 0
			, @Updated INT = 0
			, @Deleted INT = 0

		----------------------------------------------------------------------
		-- Update Existing
		----------------------------------------------------------------------

		UPDATE tgt
		SET	 
			PublisherID = src.PublisherID
			, isActive = src.isActive
			, CashBackPending = src.CashBackPending
			, CashBackAvailable = src.CashBackAvailable
			, ActivatedDate = src.ActivatedDate
			, DeactivatedDate = src.DeactivatedDate
			, DeactivatedBandID = src.DeactivatedBandID
			, isCredit = src.isCredit
			, isDebit = src.isDebit
			, UpdatedDateTime = src.UpdatedDateTime
			, MD5 = src.MD5
		FROM dbo.Customer AS tgt
		JOIN #Customer AS src
			ON tgt.SourceID = src.SourceID
			AND tgt.SourceTypeID = src.SourceTypeID
			AND tgt.MD5 <> src.MD5

		SET @Updated = @@ROWCOUNT

		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------

		INSERT INTO dbo.Customer
		(
			PublisherID
			, isActive
			, CashBackPending
			, CashBackAvailable
			, ActivatedDate
			, DeactivatedDate
			, DeactivatedBandID
			, isCredit
			, isDebit
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		)
		SELECT
			PublisherID
			, isActive
			, CashBackPending
			, CashBackAvailable
			, ActivatedDate
			, DeactivatedDate
			, DeactivatedBandID
			, isCredit
			, isDebit
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		FROM #Customer src
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Customer tgt
			WHERE tgt.SourceID = src.SourceID
			AND tgt.SourceTypeID = src.SourceTypeID
		)

		SET @Inserted = @@ROWCOUNT

		----------------------------------------------------------------------
		-- Log
		----------------------------------------------------------------------

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
