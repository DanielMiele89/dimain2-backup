CREATE PROC [WHB].[Offer__Unknown_Load]
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

	IF (SELECT COUNT(1) FROM dbo.Offer WHERE OfferID = -1) > 0
		BEGIN
			BEGIN TRAN
				GOTO logrun
		END
		
	----------------------------------------------------------------------
	-- Build from source
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Offer') IS NOT NULL
		DROP TABLE #Offer

	SELECT TOP 0
		CAST(NULL AS INT) AS OfferID
		, OfferName
		, StartDate
		, EndDate
		, PartnerID
		, PublisherID
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	INTO #Offer
	FROM dbo.Offer

	INSERT INTO #Offer
	(
		OfferID
		, OfferName
		, StartDate
		, EndDate
		, PartnerID
		, PublisherID
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	)

	SELECT
		-1 AS OfferID
		, OfferName
		, StartDate
		, EndDate
		, PartnerID
		, PublisherID
		, -1 AS SourceTypeID
		, SourceID
		, @RunDateTime
		, @RunDateTime
		, HASHBYTES('MD5', 
			CONCAT(OfferName
				, ',', StartDate
				, ',', EndDate
				, ',', PartnerID
				, ',', PublisherID
			)
		) AS MD5
	FROM (
		SELECT
			'NOT APPLICABLE'		AS OfferName
			, '1900-01-01'			AS StartDate
			, '9999-12-31'			AS EndDate
			, -1					AS PartnerID
			, -1					AS PublisherID
			, -1					AS SourceID
	) x

	BEGIN TRAN

		SET IDENTITY_INSERT dbo.Offer ON
		
		----------------------------------------------------------------------
		-- Update Existing
		----------------------------------------------------------------------
		
		UPDATE tgt
		SET OfferName = src.OfferName
			, StartDate = src.StartDate
			, EndDate = src.EndDate
			, PartnerID = src.PartnerID
			, PublisherID = src.PublisherID
			, SourceTypeID = src.SourceTypeID
			, SourceID = src.SourceID
			, UpdatedDateTime = src.UpdatedDateTime
			, MD5 = src.MD5
		FROM dbo.Offer   AS tgt
		JOIN #Offer	  AS src
			ON tgt.OfferID = src.OfferID
		
		SET @Updated = @@ROWCOUNT
		
		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------
		
		INSERT INTO dbo.Offer
		(
			OfferID
			, OfferName
			, StartDate
			, EndDate
			, PartnerID
			, PublisherID
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		)
		SELECT
			OfferID
			, OfferName
			, StartDate
			, EndDate
			, PartnerID
			, PublisherID
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		FROM #Offer AS src
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Offer AS tgt
			WHERE tgt.OfferID = src.OfferID
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

		SET IDENTITY_INSERT dbo.Offer OFF

	COMMIT TRAN
	

END
