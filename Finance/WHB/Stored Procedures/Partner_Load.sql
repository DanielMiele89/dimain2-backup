CREATE PROC WHB.Partner_Load
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

	SET @StoredProcedureName = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF @RunID IS NULL
		SET @RunID = NEXT VALUE FOR WHB.RunID

	----------------------------------------------------------------------
	-- Build base tables from source
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Partner') IS NOT NULL   
		DROP TABLE #Partner;
	
	SELECT TOP 0
		PartnerID
		, RetailerID
		, PartnerName
		, RetailerName
		, PartnerStatus
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	INTO #Partner
	FROM dbo.Partner

	INSERT INTO #Partner
	(
		PartnerID
		, RetailerID
		, PartnerName
		, RetailerName
		, PartnerStatus
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	)
	SELECT
		PartnerID
		, RetailerID
		, PartnerName
		, RetailerName
		, PartnerStatus
		, @RunDateTime		AS CreatedDateTime
		, @RunDateTime		AS UpdatedDateTime
		, HASHBYTES('MD5',
			CONCAT(RetailerID
				, ',', PartnerName
				, ',', RetailerName
				, ',', PartnerStatus
			)
		) AS MD5
	FROM
	(
		SELECT 
			PartnerID
			, RetailerID
			, PartnerName
			, RetailerName
			, Status AS PartnerStatus
		FROM WH_AllPublishers.Derived.Partner

		UNION ALL

		SELECT
			-1
			, -1
			, 'NOT APPLICABLE'
			, 'NOT APPLICABLE'
			, 0
	) x

	BEGIN TRAN

		DECLARE @Inserted INT = 0
			, @Updated INT = 0
			, @Deleted INT = 0
		
		----------------------------------------------------------------------
		-- Update Existing
		----------------------------------------------------------------------
		
		UPDATE tgt
		SET RetailerID = src.RetailerID
			, PartnerName = src.PartnerName
			, PartnerStatus = src.PartnerStatus
			, UpdatedDateTime = src.UpdatedDateTime
			, MD5 = src.MD5
		FROM dbo.Partner   AS tgt
		JOIN #Partner	  AS src
			ON tgt.PartnerID = src.PartnerID
			AND tgt.md5 <> src.md5
		
		SET @Updated = @@ROWCOUNT
		
		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------
		
		INSERT INTO dbo.Partner
		(
			PartnerID
			, RetailerID
			, PartnerName
			, RetailerName
			, PartnerStatus
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		)
		SELECT
			PartnerID
			, RetailerID
			, PartnerName
			, RetailerName
			, PartnerStatus
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		FROM #Partner  AS src
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Partner  AS tgt
			WHERE tgt.PartnerID = src.PartnerID
		
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


