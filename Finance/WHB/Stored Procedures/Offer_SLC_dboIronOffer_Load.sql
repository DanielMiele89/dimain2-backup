CREATE PROC [WHB].[Offer_SLC_dboIronOffer_Load]
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
	-- Get source data
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Offer') IS NOT NULL
		DROP TABLE #Offer

	SELECT TOP 0
		OfferName
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
		OfferName
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
		OfferName
		, StartDate
		, EndDate
		, PartnerID
		, PublisherID
		, @SourceTypeID
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
			io.[name]			AS OfferName
			, startdate			AS StartDate
			, io.EndDate		AS EndDate
			, io.PartnerID		AS PartnerID
			, ioc.ClubID		AS PublisherID
			, io.id				AS SourceID
		FROM SLC_Report..IronOffer io
		JOIN (
			SELECT IronOfferID, MIN(ClubID)	AS ClubID
			FROM slc_report.dbo.IronOfferClub
			WHERE ClubID in (132, 138)
			GROUP BY IronOfferID
		) ioc
			ON io.id = ioc.IronOfferID
	) x

	BEGIN TRAN
		
		DECLARE @Inserted INT = 0
			, @Updated INT = 0
			, @Deleted INT = 0
		
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
			ON tgt.SourceID = src.SourceID
			AND tgt.SourceTypeID = src.SourceTypeID
			AND tgt.md5 <> src.md5
		
		SET @Updated = @@ROWCOUNT
		
		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------
		
		INSERT INTO dbo.Offer
		(
			OfferName
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
			OfferName
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
