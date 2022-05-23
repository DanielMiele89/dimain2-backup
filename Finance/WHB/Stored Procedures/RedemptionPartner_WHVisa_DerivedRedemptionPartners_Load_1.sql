
CREATE PROC WHB.RedemptionPartner_WHVisa_DerivedRedemptionPartners_Load
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
	-- Build base tables from source
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#RedemptionPartner') IS NOT NULL   
		DROP TABLE #RedemptionPartner;
	
	SELECT TOP 0
		RedemptionPartnerName
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	INTO #RedemptionPartner
	FROM dbo.RedemptionPartner

	INSERT INTO #RedemptionPartner
	(
		RedemptionPartnerName
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	)
	SELECT
		RedemptionPartnerName
		, @SourceTypeID
		, SourceID
		, @RunDateTime		AS CreatedDateTime
		, @RunDateTime		AS UpdatedDateTime
		, HASHBYTES('MD5', RedemptionPartnerName) AS MD5
	FROM
	(		
		SELECT 
			RedemptionPartnerGUID AS SourceID
			, PartnerName AS RedemptionPartnerName
		FROM WH_Visa.Derived.RedemptionPartners
		WHERE RedemptionPartnerGuid <> '0F35BB79-31D1-43B4-AE63-8F58D3FB6F18' -- Pay Card, this isn't really a partner, cash/card redemptions will be marked as -1
	) x

	BEGIN TRAN

		DECLARE @Inserted INT = 0
			, @Updated INT = 0
			, @Deleted INT = 0
		
		----------------------------------------------------------------------
		-- Update Existing
		----------------------------------------------------------------------
		
		UPDATE tgt
		SET RedemptionPartnerName = src.RedemptionPartnerName
			, UpdatedDateTime = src.UpdatedDateTime
			, MD5 = src.MD5
		FROM dbo.RedemptionPartner   AS tgt
		JOIN #RedemptionPartner	  AS src
			ON  tgt.SourceID = src.SourceID
			AND tgt.SourceTypeID = src.SourceTypeID
			AND tgt.md5 <> src.md5
		
		SET @Updated = @@ROWCOUNT
		
		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------
		
		INSERT INTO dbo.RedemptionPartner
		(
			RedemptionPartnerName
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		)
		SELECT
			RedemptionPartnerName
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		FROM #RedemptionPartner  AS src
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.RedemptionPartner  AS tgt
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


