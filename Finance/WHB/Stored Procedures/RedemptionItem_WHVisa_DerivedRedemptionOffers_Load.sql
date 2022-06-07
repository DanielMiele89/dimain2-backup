CREATE PROC [WHB].[RedemptionItem_WHVisa_DerivedRedemptionOffers_Load]
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
		SELECT
			CASE PartnerType 
				WHEN 'Retail'
					THEN 'Trade Up'
				WHEN 'Pay Card'
					THEN 'Credit'
				ELSE rp.PartnerType
			END AS RedemptionType
			, rp.PartnerName + ' - ' + 
				CASE PartnerType
					WHEN 'Charity'
						THEN 'Donation'
					WHEN 'Retail'
						THEN 'Trade Up (Min £' 
							+ LEFT(x.CashbackReqStr, CHARINDEX('.', x.CashbackReqStr)-1) 
							+ ISNULL(
								', Earn ' 
									+ LEFT(x.CashbackRateStr, CHARINDEX('.', x.CashbackRateStr)-1) 
									+ '%)'
								, ')'
							)
					WHEN 'Pay Card'
						THEN 'Credit'
				END AS RedemptionDescription
			, ro.RedemptionOfferGUID AS SourceID
			, r.RedemptionPartnerID
			, ISNULL(ro.Charity_MinimumCashback, TradeUp_CashbackRequired) AS CashbackRequired
			, NULL AS TradeUpValue
			, ro.TradeUp_MarketingPercentage AS CashbackRate
		FROM WH_VISA.Derived.RedemptionOffers ro
		JOIN WH_VISA.Derived.RedemptionPartners rp
			ON ro.RedemptionPartnerGUID = rp.RedemptionPartnerGUID
		JOIN dbo.RedemptionPartner r
			ON (
				(CAST(rp.RedemptionPartnerGUID AS VARCHAR(36))= r.SourceID 
					AND r.SourceTypeID = 30)
				OR 
				(
					rp.RedemptionPartnerGUID = '0F35BB79-31D1-43B4-AE63-8F58D3FB6F18' 
					AND r.RedemptionPartnerID = -1
				)
			)
		CROSS APPLY (
			SELECT
				CAST(ro.TradeUp_CashbackRequired AS VARCHAR(10)) AS CashbackReqStr
				, CAST(NULLIF(ro.TradeUp_MarketingPercentage, 0) AS VARCHAR(10)) AS CAshbackRateStr
		) x
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


