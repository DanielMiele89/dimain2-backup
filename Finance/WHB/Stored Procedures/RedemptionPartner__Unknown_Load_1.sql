
CREATE PROC [WHB].[RedemptionPartner__Unknown_Load]
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

	DECLARE @Inserted INT = 0
		, @Updated INT = 0
		, @Deleted INT = 0
	
	SET @StoredProcedureName = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
	
	IF @RunID IS NULL
		SET @RunID = NEXT VALUE FOR WHB.RunID

	IF (SELECT COUNT(1) FROM dbo.RedemptionPartner WHERE RedemptionPartnerID = -1) > 0
		BEGIN
			BEGIN TRAN 
				GOTO logrun
		END

	----------------------------------------------------------------------
	-- Build from source
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#RedemptionPartner') IS NOT NULL   
		DROP TABLE #RedemptionPartner;
	
	SELECT TOP 0
		CAST(NULL AS INT) AS RedemptionPartnerID
		, RedemptionPartnerName
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	INTO #RedemptionPartner
	FROM dbo.RedemptionPartner

	INSERT INTO #RedemptionPartner
	(
		RedemptionPartnerID
		, RedemptionPartnerName
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	)
	SELECT
		-1 AS RedemptionPartnerID
		, RedemptionPartnerName
		, -1 AS SourceTypeID
		, SourceID
		, @RunDateTime		AS CreatedDateTime
		, @RunDateTime		AS UpdatedDateTime
		, HASHBYTES('MD5', RedemptionPartnerName) AS MD5
	FROM
	(		
		SELECT 
			-1 AS SourceID
			, 'NOT APPLICABLE' AS RedemptionPartnerName
	) x

	BEGIN TRAN

		SET IDENTITY_INSERT dbo.RedemptionPartner ON
		
		----------------------------------------------------------------------
		-- Update Existing
		----------------------------------------------------------------------
		
		UPDATE tgt
		SET RedemptionPartnerName = src.RedemptionPartnerName
			, UpdatedDateTime = src.UpdatedDateTime
			, MD5 = src.MD5
		FROM dbo.RedemptionPartner   AS tgt
		JOIN #RedemptionPartner	  AS src
			ON  tgt.RedemptionPartnerID = src.RedemptionPartnerID
		
		SET @Updated = @@ROWCOUNT
		
		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------
		
		INSERT INTO dbo.RedemptionPartner
		(
			RedemptionPartnerID
			, RedemptionPartnerName
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		)
		SELECT
			RedemptionPartnerID
			, RedemptionPartnerName
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		FROM #RedemptionPartner  AS src
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.RedemptionPartner  AS tgt
			WHERE tgt.RedemptionPartnerID = src.RedemptionPartnerID
		)
		
		SET @Inserted = @@ROWCOUNT
		
		----------------------------------------------------------------------
		-- Log
		----------------------------------------------------------------------
		
		logrun:

		INSERT INTO WHB.Build_Log (RunID, StartDateTime, EndDateTime, StoredProcName, InsertedRows, UpdatedRows, DeletedRows)
		SELECT
			@RunID
			,@RunDateTime
			,GETDATE()
			,@StoredProcedureName
			,InsertedRows = @Inserted
			,UpdatedRows = @Updated
			,DeletedRows = @Deleted

		SET IDENTITY_INSERT dbo.RedemptionPartner OFF

	COMMIT TRAN

END


