CREATE PROC WHB.Retailer_Load
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
	-- Build Base table from source
	----------------------------------------------------------------------
	
	IF OBJECT_ID('tempdb..#Retailer') IS NOT NULL
		DROP TABLE #Retailer

	SELECT TOP 0
		RetailerID
		, RetailerName
		, RetailerStatus
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	INTO #Retailer
	FROM dbo.Retailer

	INSERT INTO #Retailer
	(
		RetailerID
		, RetailerName
		, RetailerStatus
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	)
	SELECT
		RetailerID
		, RetailerName
		, RetailerStatus
		, @RunDateTime AS CreatedDateTime
		, @RunDateTime AS UpdatedDateTime
		, HASHBYTES('MD5',
			CONCAT(RetailerName
				, ',', RetailerStatus
			)
		) AS MD5	
	FROM (
		SELECT
			RetailerID
			, RetailerName
			, MAX(PartnerStatus) AS RetailerStatus
		FROM dbo.Partner
		GROUP BY RetailerID, RetailerName
	) x

	BEGIN TRAN

		DECLARE @Inserted INT = 0
			, @Updated INT = 0
			, @Deleted INT = 0
		
		----------------------------------------------------------------------
		-- Update Existing
		----------------------------------------------------------------------
		
		UPDATE tgt
		SET 
			RetailerName = src.RetailerName
			, RetailerStatus = src.RetailerStatus
			, UpdatedDateTime = src.UpdatedDateTime
			, MD5 = src.MD5
		FROM dbo.Retailer   AS tgt
		JOIN #Retailer	  AS src
			ON tgt.RetailerID = src.RetailerID
			AND tgt.md5 <> src.md5
		
		SET @Updated = @@ROWCOUNT
		
		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------
		
		INSERT INTO dbo.Retailer
		(
			RetailerID
			, RetailerName
			, RetailerStatus
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		
		)
		SELECT
			RetailerID
			, RetailerName
			, RetailerStatus
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		FROM #Retailer  AS src
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Retailer  AS tgt
			WHERE tgt.RetailerID = src.RetailerID
		
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

