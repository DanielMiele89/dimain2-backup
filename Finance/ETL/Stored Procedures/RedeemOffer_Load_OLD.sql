CREATE PROC [ETL].[RedeemOffer_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF OBJECT_ID('tempdb..#RedeemOffer_Staging') IS NOT NULL   
		DROP TABLE #RedeemOffer_Staging;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	  SELECT 
			 [ID]					AS RedeemOfferID
			, r.FulfillmentTypeId	AS FulfillmentTypeID
			, ri.RedeemType			AS RedemptionType
			, r.Description			AS RedeemDescription
			, r.SupplierID
			, COALESCE(p.PartnerID, -1) AS PartnerID
			, tuv.TradeUp_Value		AS TradeUpValue
			, @RunDateTime		AS CreatedDateTime
			, @RunDateTime		AS UpdatedDateTime
	  INTO #RedeemOffer_Staging
	  FROM SLC_Report..Redeem r
	  LEFT JOIN Warehouse.Relational.RedemptionItem ri
		ON r.ID = ri.RedeemID
	  LEFT JOIN Warehouse.Relational.RedemptionItem_TradeUpValue tuv
		ON ri.RedeemID = tuv.RedeemID
	  LEFT JOIN dbo.Partner p
		ON tuv.PartnerID = p.PartnerID


	 UNION ALL

	 SELECT 
		-1
		, -1
		, 'N/A'
		, 'NOT APPLICABLE'
		, -1
		, -1
		, 0
		, @RunDateTime
		, @RunDateTime


	----------------------------------------------------------------------
	-- Clean up names with HTML strings
	----------------------------------------------------------------------
	UPDATE rs
	SET RedeemDescription = ETL.ConvertToTextChars(RedeemDescription)
	FROM #RedeemOffer_Staging rs

		
	BEGIN TRAN

		MERGE dbo.RedeemOffer AS TGT 
			USING #RedeemOffer_Staging AS SRC   
				ON TGT.[RedeemOfferID] = SRC.[RedeemOfferID] 
		WHEN MATCHED AND
						(	
								TGT.FulfillmentTypeID	<> SRC.FulfillmentTypeID
							OR	TGT.RedemptionType		<> SRC.RedemptionType
							OR	TGT.[SupplierID]		<> SRC.[SupplierID]
							OR	TGT.PartnerID		<> SRC.PartnerID
							OR	TGT.TradeUpValue		<> SRC.TradeUpValue
							OR TGT.RedeemDescription <> SRC.RedeemDescription
						)
			THEN   
				UPDATE SET     
					TGT.FulfillmentTypeID	= SRC.FulfillmentTypeID,     
					TGT.RedemptionType		= SRC.RedemptionType,     
					TGT.[SupplierID]		= SRC.[SupplierID],     
					TGT.PartnerID		= SRC.PartnerID,     
					TGT.TradeUpValue		= SRC.TradeUpValue,     
					TGT.RedeemDescription		= SRC.RedeemDescription,     
					TGT.[UpdatedDateTime]	= SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT ([RedeemOfferID], FulfillmentTypeID,RedemptionType,  [SupplierID], PartnerID,TradeUpValue, RedeemDescription, [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.[RedeemOfferID], SRC.FulfillmentTypeID, SRC.RedemptionType, SRC.[SupplierID], SRC.PartnerID, SRC.TradeUpValue, SRC.RedeemDescription, SRC.[CreatedDateTime], SRC.UpdatedDateTime) 
		OUTPUT $Action INTO @MergeCounts;
		SET @RowCnt = @@ROWCOUNT

		;WITH MergeChangeAggregations AS (
			SELECT ChangeType, COUNT(*) AS CountPerChangeType
			FROM @MergeCounts
			GROUP BY ChangeType
		)
		INSERT INTO dbo.Audit_MergeLogging
		SELECT
				@RunID
				,@RunDateTime
				,@StoredProcName
				,InsertedRows = ISNULL((SELECT CountPerChangeType FROM MergeChangeAggregations WHERE ChangeType = 'INSERT'),0)
				,UpdatedRows = ISNULL((SELECT CountPerChangeType FROM MergeChangeAggregations WHERE ChangeType = 'UPDATE'),0)
				,DeletedRows = ISNULL((SELECT CountPerChangeType FROM MergeChangeAggregations WHERE ChangeType = 'DELETE'),0)

	COMMIT TRAN


  END
