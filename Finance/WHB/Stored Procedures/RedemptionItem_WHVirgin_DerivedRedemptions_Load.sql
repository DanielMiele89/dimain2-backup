CREATE PROC WHB.RedemptionItem_WHVirgin_DerivedRedemptions_Load
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
	IF OBJECT_ID('tempdb..#RedemptionItem') IS NOT NULL   
		DROP TABLE #RedemptionItem;
	
	SELECT TOP 0
		RedemptionType
		, RedemptionDescription
		, RedemptionPartnerID
		, CashbackRequired
		, TradeUpValue
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	INTO #RedemptionItem
	FROM dbo.RedemptionItem

	INSERT INTO #RedemptionItem
	(
		RedemptionType
		, RedemptionDescription
		, RedemptionPartnerID
		, CashbackRequired
		, TradeUpValue
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	)
	SELECT
		RedemptionType
		, RedemptionDescription
		, RedemptionPartnerID
		, CashbackRequired
		, TradeUpValue
		, @SourceTypeID
		, SourceID
		, @RunDateTime		AS CreatedDateTime
		, @RunDateTime		AS UpdatedDateTime
		, HASHBYTES('MD5', 
						CONCAT(RedemptionType
							, ',', RedemptionDescription
							, ',', RedemptionPartnerID
							, ',', CashbackRequired
							, ',', TradeUpValue
						)
					) AS MD5
	FROM
	(		
		SELECT DISTINCT 
			COALESCE(rtm.DestinationRedemptionType, redemptiontype) AS RedemptionType
			, NULL AS RedemptionDescription
			, -1 AS redemptionPartnerID
			, NULL AS CashbackRequired
			, NULL AS TradeUpValue
			, RedemptionType AS SourceID
		FROM WH_Virgin.Derived.Redemptions r
		LEFT JOIN WHB.RedemptionTypeMapping rtm
			ON r.RedemptionType = rtm.SourceRedemptionType
	) x

	BEGIN TRAN

		DECLARE @Inserted INT = 0
			, @Updated INT = 0
			, @Deleted INT = 0
		
		----------------------------------------------------------------------
		-- Update Existing
		----------------------------------------------------------------------
		
		UPDATE tgt
		SET RedemptionType = src.RedemptionType
			, RedemptionDescription = src.RedemptionDescription
			, RedemptionPartnerID = src.RedemptionPartnerID
			, CashbackRequired = src.CashbackRequired
			, TradeUpValue = src.TradeUpValue
			, UpdatedDateTime = src.UpdatedDateTime
			, MD5 = src.MD5
		FROM dbo.RedemptionItem   AS tgt
		JOIN #RedemptionItem	  AS src
			ON tgt.SourceID = src.SourceID
			AND tgt.SourceTypeID = src.SourceTypeID
			AND tgt.md5 <> src.md5
		
		SET @Updated = @@ROWCOUNT
		
		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------
		
		INSERT INTO dbo.RedemptionItem
		(
			RedemptionType
			, RedemptionDescription
			, RedemptionPartnerID
			, CashbackRequired
			, TradeUpValue
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		)
		SELECT
			RedemptionType
			, RedemptionDescription
			, RedemptionPartnerID
			, CashbackRequired
			, TradeUpValue
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		FROM #RedemptionItem  AS src
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.RedemptionItem  AS tgt
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


