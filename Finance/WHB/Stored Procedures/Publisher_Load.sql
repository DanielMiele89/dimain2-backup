
CREATE PROC [WHB].[Publisher_Load]
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
	-- Build from source
	----------------------------------------------------------------------
	
	IF OBJECT_ID('tempdb..#Publisher') IS NOT NULL   
		DROP TABLE #Publisher;
	SELECT TOP 0
		PublisherID
		, PublisherName
		, PublisherStatus
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	INTO #Publisher
	FROM dbo.Publisher	

	INSERT INTO #Publisher
	(
		PublisherID
		, PublisherName
		, PublisherStatus
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	)
	SELECT
		PublisherID
		, PublisherName
		, PublisherStatus		
		, @RunDateTime		AS CreatedDateTime
		, @RunDateTime		AS UpdatedDateTime
		, HASHBYTES('MD5', 
			CONCAT(PublisherName
				, ',', PublisherStatus)
		) AS MD5
	FROM (
		SELECT 
			ID		AS PublisherID
			, [Name] AS PublisherName
			, [Status] AS PublisherStatus

		FROM SLC_Report.dbo.Club

		UNION ALL

		SELECT 
			-1 AS PublisherID
			, 'NOT APPLICABLE' AS PublisherName
			, 1 AS PublisherStatus
	) x

	BEGIN TRAN
		DECLARE @Inserted INT = 0
			, @Updated INT = 0
			, @Deleted INT = 0
		
		----------------------------------------------------------------------
		-- Update Existing
		----------------------------------------------------------------------
		
		UPDATE tgt
		SET PublisherID = src.PublisherID
			, PublisherName = src.PublisherName
			, PublisherStatus = src.PublisherStatus
			, CreatedDateTime = src.CreatedDateTime
			, UpdatedDateTime = src.UpdatedDateTime
			, MD5 = src.MD5
		FROM dbo.Publisher   AS tgt
		JOIN #Publisher	  AS src
			ON tgt.PublisherID = src.PublisherID
			AND tgt.md5 <> src.md5
		
		SET @Updated = @@ROWCOUNT
		
		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------
		
		INSERT INTO dbo.Publisher
		(
			PublisherID
			, PublisherName
			, PublisherStatus
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		
		)
		SELECT
			PublisherID
			, PublisherName
			, PublisherStatus
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		FROM #Publisher  AS src
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Publisher  AS tgt
			WHERE tgt.PublisherID = src.PublisherID
		
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
