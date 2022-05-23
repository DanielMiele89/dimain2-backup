CREATE PROC [ETL].[EarningSource_Load_DELETE_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF OBJECT_ID('#EarningSource_Staging') IS NOT NULL   
		DROP TABLE #EarningSource_Staging;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	SELECT 
		  [ID]				AS EarningSourceID
	    , [SourceName]		
		, CASE [PartnerID] WHEN 0 THEN -1 ELSE PartnerID END PartnerID
		, [RBSFunded] % 2		AS isBankFunded
		, CASE [AdditionalCashbackAwardTypeID] WHEN 0 THEN -1 ELSE AdditionalCashbackAwardTypeID END AS [AdditionalCashbackAwardTypeID]
		, CASE [AdditionalCashbackAdjustmentTypeID] WHEN 0 THEN -1 ELSE AdditionalCashbackAdjustmentTypeID END AS [AdditionalCashbackAdjustmentTypeID]
		, CASE [AdditionalCashbackAdjustmentCategoryID] WHEN 0 THEN -1 ELSE AdditionalCashbackAdjustmentCategoryID END AS [AdditionalCashbackAdjustmentCategoryID]
		, c.[DDCategory]
		, COALESCE([m].[PortalCategory], [c].[DDCategory]) AS PortalCategory
		, [MultiplePaymentMethods]
		, [Phase]
		, @RunDateTime		AS CreatedDateTime
		, @RunDateTime		AS UpdatedDateTime
	INTO #EarningSource_Staging
	FROM [lsRewardBI].[LoyaltyPortal].[RBSMIPortal].[CashbackSource] c
	LEFT JOIN Warehouse.RBSMIPortal.DDCategoryMap m
		ON c.DDCategory = m.DDCategory

	UNION ALL

	SELECT 
		*
	FROM (
		VALUES
			(-1, 'NOT APPLICABLE', -1, NULL, -1, -1, -1, '', '', NULL, '', @RunDateTime, @RunDateTime)
	) x(a,b,c,d,e,f,g,h,i,j,k,l,m)

	UNION ALL

	SELECT
		-AdditionalCashbackAwardTypeID AS EarningSourceID
		, Title AS SourceName
		, -1 AS PartnerID
		, 0 AS isBankFunded
		, AdditionalCashbackAwardTypeID
		, -1 AS AdditionalCashbackAdjustmentTypeID
		, -1 AS AdditionalCashbackADjustmentCategoryID
		, '' AS DDCategory
		, '' AS PortalCategory
		, 0
		, ''
		, @RunDateTime
		, @RunDateTime
	FROM dbo.AdditionalCashbackAwardType
	WHERE AdditionalCashbackAwardTypeID in (12,13,14,15,16,17,18,19)

	BEGIN TRAN

		MERGE dbo.EarningSource AS TGT 
			USING #EarningSource_Staging AS SRC   
				ON TGT.EarningSourceID = SRC.EarningSourceID 
		WHEN MATCHED AND
						(	
								TGT.[SourceName]								<> SRC.[SourceName]
							OR	TGT.[PartnerID]									<> SRC.[PartnerID]
							OR	TGT.[isBankFunded]								<> SRC.[isBankFunded]
							OR	TGT.[AdditionalCashbackAwardTypeID]				<> SRC.[AdditionalCashbackAwardTypeID]
							OR	TGT.[AdditionalCashbackAdjustmentTypeID]		<> SRC.[AdditionalCashbackAdjustmentTypeID]
							OR	TGT.[AdditionalCashbackAdjustmentCategoryID]	<> SRC.[AdditionalCashbackAdjustmentCategoryID]
							OR	TGT.[DDCategory]								<> SRC.[DDCategory]
							OR	TGT.[MultiplePaymentMethods]					<> SRC.[MultiplePaymentMethods]
							OR	TGT.[Phase]										<> SRC.[Phase]
							OR	TGT.[PortalCategory]							<> SRC.[PortalCategory]
						)
			THEN   
				UPDATE SET     
							TGT.[SourceName]							= SRC.[SourceName]
							,TGT.[PartnerID]								= SRC.[PartnerID]
							,TGT.[isBankFunded]								= SRC.[isBankFunded]
							,TGT.[AdditionalCashbackAwardTypeID]			= SRC.[AdditionalCashbackAwardTypeID]
							,TGT.[AdditionalCashbackAdjustmentTypeID]		= SRC.[AdditionalCashbackAdjustmentTypeID]
							,TGT.[AdditionalCashbackAdjustmentCategoryID]	= SRC.[AdditionalCashbackAdjustmentCategoryID]
							,TGT.[DDCategory]								= SRC.[DDCategory]
							,TGT.[MultiplePaymentMethods]					= SRC.[MultiplePaymentMethods]
							,TGT.[Phase]									= SRC.[Phase]    
							,TGT.[PortalCategory]							= SRC.[PortalCategory]
							,TGT.[UpdatedDateTime]							= SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT (EarningSourceID, [SourceName], [PartnerID], [isBankFunded], [AdditionalCashbackAwardTypeID], [AdditionalCashbackAdjustmentTypeID], [AdditionalCashbackAdjustmentCategoryID], [DDCategory], [MultiplePaymentMethods], [Phase], [PortalCategory], [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.EarningSourceID, SRC.[SourceName], SRC.[PartnerID], SRC.[isBankFunded], SRC.[AdditionalCashbackAwardTypeID], SRC.[AdditionalCashbackAdjustmentTypeID], SRC.[AdditionalCashbackAdjustmentCategoryID], SRC.[DDCategory], SRC.[MultiplePaymentMethods], SRC.[Phase], [PortalCategory], SRC.[CreatedDateTime], SRC.UpdatedDateTime) 
		OUTPUT $Action INTO @MergeCounts;
		SET @RowCnt = @@ROWCOUNT;

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



