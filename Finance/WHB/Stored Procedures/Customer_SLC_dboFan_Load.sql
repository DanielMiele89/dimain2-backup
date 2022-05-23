

CREATE PROC WHB.Customer_SLC_dboFan_Load
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
		f.ID											AS SourceID
		, f.ClubID										AS PublisherID
		, f.Status										AS isActive
		, f.ClubCashPending								AS CashBackPending
		, f.ClubCashAvailable							AS CashBackAvailable
		, COALESCE(f.AgreedTCsDate, c.ActivatedDate)	AS ActivatedDate
		, f.ID											AS FanID
		, c.DeactivatedDate								AS DeactivatedDate
		, f.CompositeID									AS CompositeID
	INTO #Customer_Staging
	FROM  SLC_Report.dbo.Fan f
	LEFT JOIN Warehouse.Relational.Customer c
		ON f.ID = c.FanID
	WHERE (f.ClubID in (132, 138)
		AND AgreedTCsDate IS NOT NULL)
		OR c.FanID IS NOT NULL

	CREATE CLUSTERED INDEX CIX ON #Customer_Staging(SourceID)
	CREATE NONCLUSTERED INDEX NIX ON #Customer_Staging(isActive) INCLUDE (SourceID, ActivatedDate)

	
	----------------------------------------------------------------------
	-- Get Customer Card Types
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#CardTypes') IS NOT NULL
		DROP TABLE #CardTypes

	SELECT
		SourceID
		, isCredit
		, isDebit
	INTO #CardTypes
	FROM (

		SELECT
			c.SourceID
			, MAX(CASE WHEN CardTypeID = 1 THEN 1 ELSE 0 END) AS isCredit
			, MAX(CASE WHEN CardTypeID = 2 THEN 1 ELSE 0 END) AS isDebit
		FROM #Customer_Staging c
		JOIN SLC_REPL..Pan p
			ON c.CompositeID = p.CompositeID
			AND p.RemovalDate IS NULL
		JOIN SLC_REPL..PaymentCard pc
			ON p.PaymentCardID = pc.ID
		GROUP BY c.SourceID
	) x

	CREATE CLUSTERED INDEX CIX ON #CardTypes (SourceID)
	

	/**********************************************************************
	Get Deactivated Dates
	***********************************************************************/

	IF OBJECT_ID('tempdb..#DeactivatedCustomers') IS NOT NULL 
	DROP TABLE #DeactivatedCustomers

	SELECT
		SourceID
		, ActivatedDate
	INTO #DeactivatedCustomers
	FROM #Customer_Staging
	WHERE isActive = 0

	CREATE CLUSTERED INDEX CIX ON #DeactivatedCustomers (SourceID)
	----------------------------------------------------------------------
	-- Get Deactivated Date from ChangeLog
	----------------------------------------------------------------------
	DECLARE @Today DATE = GETDATE()

	IF OBJECT_ID('tempdb..#DeactivatedDate') IS NOT NULL 
	DROP TABLE #DeactivatedDates

	SELECT
		FanID AS SourceID
		, MAX(DeactivatedDate) AS DeactivatedDate
		, DATEDIFF(DAY, MAX(DeactivatedDate), @Today) DeactivatedDays
	INTO #DeactivatedDates
	FROM
	(
		SELECT 
			d.FanID
			, d.[Date] AS DeactivatedDate
		FROM Archive_Light.ChangeLog.DataChangeHistory_Int d
		WHERE  d.TableColumnsID = 12 
			AND D.Value = 0
			AND EXISTS (
				SELECT 1
				FROM #DeactivatedCustomers dc
				WHERE d.FanID = dc.SourceID
			)

		UNION ALL
		--customers who have opted out
		SELECT 
			d.FanID
			, d.[Date]
		FROM Archive_Light.ChangeLog.DataChangeHistory_Bit d
		INNER JOIN SLC_Report.dbo.Fan f on d.FanID = f.ID
		WHERE d.TableColumnsID = 25 
			AND D.Value = 1 
			AND EXISTS (
				SELECT 1
				FROM #DeactivatedCustomers dc
				WHERE d.FanID = dc.SourceID
			)
	) x
	GROUP BY x.FanID
	
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
		x.PublisherID
		, x.isActive
		, x.CashBackPending
		, x.CashBackAvailable
		, x.ActivatedDate
		, x.DeactivatedDate
		, x.DeactivatedBandID
		, x.isCredit
		, x.isDebit
		, @SourceTypeID
		, x.SourceID
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
			, dc.DeactivatedDate
			, COALESCE(db.DeactivatedBandID, -1) AS DeactivatedBandID
			, ct.isCredit
			, ct.isDebit
		FROM #Customer_Staging cs
		LEFT JOIN #DeactivatedDates dc
			ON cs.SourceID = dc.SourceID
		LEFT JOIN dbo.DeactivatedBand db
			ON dc.DeactivatedDays BETWEEN db.DeactivatedBandMin and db.DeactivatedBandMax
		LEFT JOIN #CardTypes ct
			ON cs.SourceID = ct.SourceID
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
