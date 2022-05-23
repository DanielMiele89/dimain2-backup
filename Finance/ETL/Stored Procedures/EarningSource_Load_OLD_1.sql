CREATE PROC [ETL].[EarningSource_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	----------------------------------------------------------------------
	-- Create N/A Rows
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#NARows') IS NOT NULL 
		DROP TABLE #NARows

	SELECT
		*
	INTO #NARows
	FROM (
		VALUES
			(-1, 'NOT APPLICABLE', -1, NULL, -1, -1, -1, '', NULL, '', '', @RunDateTime, @RunDateTime)
			, (-2, 'Unallocated Reduction', -1, NULL, -1, -1, -1, 'Unallocated', NULL, '', '', @RunDateTime, @RunDateTime)
	) x (
		EarningSourceID
		, [SourceName]
		, [PartnerID]
		, [isBankFunded]
		, [AdditionalCashbackAwardTypeID]
		, [AdditionalCashbackAdjustmentTypeID]
		, [AdditionalCashbackAdjustmentCategoryID]
		, [DDCategory]
		, [MultiplePaymentMethods]
		, [Phase]
		, DisplayCategory
		, [CreatedDateTime]
		, UpdatedDateTime
	)
	----------------------------------------------------------------------
	-- Create Empty Rows if not exist
	----------------------------------------------------------------------
	SET IDENTITY_INSERT dbo.EarningSource ON
	INSERT INTO dbo.EarningSource 
	(
		EarningSourceID
		, [SourceName]
		, [PartnerID]
		, [isBankFunded]
		, [AdditionalCashbackAwardTypeID]
		, [AdditionalCashbackAdjustmentTypeID]
		, [AdditionalCashbackAdjustmentCategoryID]
		, [DDCategory]
		, [MultiplePaymentMethods]
		, [Phase]
		, DisplayCategory
		, [CreatedDateTime]
		, UpdatedDateTime
	)
	SELECT
		EarningSourceID
		, [SourceName]
		, [PartnerID]
		, [isBankFunded]
		, [AdditionalCashbackAwardTypeID]
		, [AdditionalCashbackAdjustmentTypeID]
		, [AdditionalCashbackAdjustmentCategoryID]
		, [DDCategory]
		, [MultiplePaymentMethods]
		, [Phase]
		, DisplayCategory
		, [CreatedDateTime]
		, UpdatedDateTime
	FROM #NARows x
	WHERE NOT EXISTS (
		SELECT 1
		FROM dbo.EarningSource es
		WHERE x.EarningSourceID = es.EarningSourceID
	)
	SET IDENTITY_INSERT dbo.EarningSource OFF

	/**********************************************************************
	Get source data
	***********************************************************************/
	IF OBJECT_ID('#EarningSource_Staging') IS NOT NULL   
		DROP TABLE #EarningSource_Staging;

	CREATE TABLE #EarningSource_Staging(
		[SourceName] [varchar](50) NOT NULL,
		[PartnerID] [int] NOT NULL,
		[isBankFunded] [bit] NULL,
		[AdditionalCashbackAwardTypeID] [smallint] NOT NULL,
		[AdditionalCashbackAdjustmentTypeID] [smallint] NOT NULL,
		[AdditionalCashbackAdjustmentCategoryID] [smallint] NOT NULL,
		[DDCategory] [varchar](50) NOT NULL,
		[DisplayCategory] [varchar](50) NOT NULL,
		[MultiplePaymentMethods] [bit] NULL,
		[Phase] [varchar](50) NOT NULL,
		[CreatedDateTime] [datetime2](7) NOT NULL,
		[UpdatedDateTime] [datetime2](7) NOT NULL,
	)

	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	----------------------------------------------------------------------
	-- Get data from Source tables
	----------------------------------------------------------------------

	INSERT INTO #EarningSource_Staging
	(
		[SourceName]
		, [PartnerID]
		, [isBankFunded]
		, [AdditionalCashbackAwardTypeID]
		, [AdditionalCashbackAdjustmentTypeID]
		, [AdditionalCashbackAdjustmentCategoryID]
		, [DDCategory]
		, [MultiplePaymentMethods]
		, [Phase]
		, DisplayCategory
		, [CreatedDateTime]
		, UpdatedDateTime
	)
	SELECT 
		  [SourceName]		
		, CASE [PartnerID] WHEN 0 THEN -1 ELSE PartnerID END PartnerID
		, [RBSFunded] % 2		AS isBankFunded
		, CASE [AdditionalCashbackAwardTypeID] WHEN 0 THEN -1 ELSE AdditionalCashbackAwardTypeID END AS [AdditionalCashbackAwardTypeID]
		, CASE [AdditionalCashbackAdjustmentTypeID] WHEN 0 THEN -1 ELSE AdditionalCashbackAdjustmentTypeID END AS [AdditionalCashbackAdjustmentTypeID]
		, CASE [AdditionalCashbackAdjustmentCategoryID] WHEN 0 THEN -1 ELSE AdditionalCashbackAdjustmentCategoryID END AS [AdditionalCashbackAdjustmentCategoryID]
		, c.[DDCategory]
		, [MultiplePaymentMethods]
		, [Phase]
		, COALESCE([m].[PortalCategory], [c].[DDCategory]) AS DisplayCategory
		, @RunDateTime		AS CreatedDateTime
		, @RunDateTime		AS UpdatedDateTime
	FROM [lsRewardBI].[LoyaltyPortal].[RBSMIPortal].[CashbackSource] c
	LEFT JOIN Warehouse.RBSMIPortal.DDCategoryMap m
		ON c.DDCategory = m.DDCategory
	WHERE ID <> 76 -- dont include 'Unallocated redemptions' these are now -1 ids

	----------------------------------------------------------------------
	-- Load NA Rows in the event they have been changed
	----------------------------------------------------------------------
	INSERT INTO #EarningSource_Staging
	(
		[SourceName]
		, [PartnerID]
		, [isBankFunded]
		, [AdditionalCashbackAwardTypeID]
		, [AdditionalCashbackAdjustmentTypeID]
		, [AdditionalCashbackAdjustmentCategoryID]
		, [DDCategory]
		, [MultiplePaymentMethods]
		, [Phase]
		, DisplayCategory
		, [CreatedDateTime]
		, UpdatedDateTime
	)
	SELECT 
		[SourceName]
		, [PartnerID]
		, [isBankFunded]
		, [AdditionalCashbackAwardTypeID]
		, [AdditionalCashbackAdjustmentTypeID]
		, [AdditionalCashbackAdjustmentCategoryID]
		, [DDCategory]
		, [MultiplePaymentMethods]
		, [Phase]
		, DisplayCategory
		, [CreatedDateTime]
		, UpdatedDateTime
	FROM #NARows

	----------------------------------------------------------------------
	-- Load Missing AdditionalCashbackAdjustments
	----------------------------------------------------------------------
	UNION ALL

	SELECT
		act.TypeDescription AS SourceName
		, -1 AS PartnerID
		, 0 AS isBankFunded
		, -1 AS AdditionalCashbackAwardTypeID
		, act.AdditionalCashbackAdjustmentTypeID AS AdditionalCashbackAdjustmentTypeID
		, COALESCE(act.AdditionalCashbackAdjustmentCategoryID, -1) AS AdditionalCashbackADjustmentCategoryID
		, '' AS DDCategory
		, 0
		, ''
		, '' AS DisplayCategory
		, @RunDateTime
		, @RunDateTime
	FROM dbo.AdditionalCashbackAdjustmentType act
	WHERE NOT EXISTS (
		SELECT 1 FROM dbo.EarningSource es
		WHERE act.AdditionalCashbackAdjustmentTypeID = es.AdditionalCashbackAdjustmentTypeID
	)
	AND NOT EXISTS (
		SELECT 1 FROM #EarningSource_Staging es
		WHERE act.AdditionalCashbackAdjustmentTypeID = es.AdditionalCashbackAdjustmentTypeID
	)
	
	----------------------------------------------------------------------
	-- Load Missing AdditionalCashbackAwardTypes
	----------------------------------------------------------------------
	UNION ALL
	SELECT
		Title AS SourceName
		, -1 AS PartnerID
		, 0 AS isBankFunded
		, AdditionalCashbackAwardTypeID
		, -1 AS AdditionalCashbackAdjustmentTypeID
		, -1 AS AdditionalCashbackADjustmentCategoryID
		, '' AS DDCategory
		, 0
		, ''
		, '' AS DisplayCategory
		, @RunDateTime
		, @RunDateTime
	FROM dbo.AdditionalCashbackAwardType act
	WHERE NOT EXISTS (
		SELECT 1 FROM dbo.EarningSource es
		WHERE act.AdditionalCashbackAwardTypeID = es.AdditionalCashbackAwardTypeID
	)
	AND NOT EXISTS (
		SELECT 1 FROM #EarningSource_Staging es
		WHERE act.AdditionalCashbackAwardTypeID = es.AdditionalCashbackAwardTypeID
	)

	----------------------------------------------------------------------
	-- Load Missing DirectDebitorOriginatorIDs
	----------------------------------------------------------------------
	UNION ALL
	SELECT DISTINCT
		p.Name AS SourceName
		, p.PartnerID
		, 0 AS isBankFunded
		, -1 AS AdditionalCashbackAwardTypeID
		, -1 AS AdditionlalCashbackAdjustmentTypeID
		, -1 AS AdditionalCashbackADjustmentCategoryID
		, do.Category2 AS DDCategory
		, 0 AS MultiplePaymentMethods
		, '' AS Phase
		, '' AS DisplayCategory
		, @RunDateTime AS CreatedDateTime
		, @RunDateTime AS UpdatedDateTime
	FROM dbo.DirectDebitOriginator do 
	JOIN dbo.Partner p
		ON do.SupplierName = p.Name
		AND Status = 3
	WHERE NOT EXISTS (
		SELECT 1
		FROM dbo.EarningSource es
		WHERE do.Category2 = es.DDCategory
			AND es.PartnerID = es.PartnerID
			AND es.AdditionalCashbackAwardTypeID = -1
			AND es.AdditionalCashbackAdjustmentTypeID = -1
			AND es.AdditionalCashbackAdjustmentCategoryID = -1
	)

	----------------------------------------------------------------------
	-- Cancelled Redemption row
	----------------------------------------------------------------------
	UNION ALL
	
	SELECT
		'Cancelled Redemption'
		, -1
		, 0
		, -1
		, -1
		, -1
		, 'CANCELLED'
		, 0
		, ''
		, ''
		, @RunDateTime
		, @RunDateTime


	IF OBJECT_ID('tempdb..#EarningSource') IS NOT NULL 
		DROP TABLE #EarningSource
	SELECT 
		*
		,CASE
				WHEN DDCategory = 'Unallocated'
					THEN 'Unallocated'
				WHEN PartnerID in (4433, 4447)
					THEN 'NW' 
				WHEN AdditionalCashbackAdjustmentTypeID BETWEEN 1 and 3
					THEN 'Breakage'
				WHEN AdditionalCashbackAwardTypeID > 0 
					THEN 'NW' 
				WHEN AdditionalCashbackAdjustmentTypeID > 0
					THEN 'Other'
				WHEN PartnerID > 0
					THEN 'Retail'
			END AS DefaultFundingType
	INTO #EarningSource
	FROM #EarningSource_Staging

	BEGIN TRAN

		MERGE dbo.EarningSource AS TGT 
			USING #EarningSource AS SRC   
				ON TGT.PartnerID = SRC.PartnerID 
				AND TGT.AdditionalCashbackAwardTypeID = SRC.AdditionalCashbackAwardTypeID 
				AND TGT.AdditionalCashbackAdjustmentTypeID = SRC.AdditionalCashbackAdjustmentTypeID 
				AND TGT.DDCategory = SRC.DDCategory 
				AND TGT.AdditionalCashbackAdjustmentCategoryID = SRC.AdditionalCashbackAdjustmentCategoryID 
		WHEN MATCHED AND
						(	
								TGT.[SourceName]								<> SRC.[SourceName]
							OR	TGT.[isBankFunded]								<> SRC.[isBankFunded]
							OR	TGT.[MultiplePaymentMethods]					<> SRC.[MultiplePaymentMethods]
							OR	TGT.[Phase]										<> SRC.[Phase]
							OR	TGT.DisplayCategory							<> SRC.DisplayCategory
						)
			THEN   
				UPDATE SET     
							TGT.[SourceName]							= SRC.[SourceName]
							,TGT.[isBankFunded]								= SRC.[isBankFunded]
							,TGT.[MultiplePaymentMethods]					= SRC.[MultiplePaymentMethods]
							,TGT.[Phase]									= SRC.[Phase]    
							,TGT.DisplayCategory							= SRC.DisplayCategory
							,TGT.[UpdatedDateTime]							= SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT ([SourceName], [PartnerID], [isBankFunded], [AdditionalCashbackAwardTypeID], [AdditionalCashbackAdjustmentTypeID], [AdditionalCashbackAdjustmentCategoryID], [DDCategory], [MultiplePaymentMethods], [Phase], DisplayCategory, [CreatedDateTime], UpdatedDateTime, FundingType, DisplayName)   
			VALUES (SRC.[SourceName], SRC.[PartnerID], SRC.[isBankFunded], SRC.[AdditionalCashbackAwardTypeID], SRC.[AdditionalCashbackAdjustmentTypeID], SRC.[AdditionalCashbackAdjustmentCategoryID], SRC.[DDCategory], SRC.[MultiplePaymentMethods], SRC.[Phase], DisplayCategory, SRC.[CreatedDateTime], SRC.UpdatedDateTime, SRC.DefaultFundingType, src.SourceName) 
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




