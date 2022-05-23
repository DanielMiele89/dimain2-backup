CREATE PROC [ETL].[AdditionalCashbackAdjustmentCategory_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF OBJECT_ID('tempdb..#AdditionalCashbackAdjustmentCategory') IS NOT NULL   
		DROP TABLE #AdditionalCashbackAdjustmentCategory;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	  SELECT 
			 AdditionalCashbackAdjustmentCategoryID
			, Category
			, @RunDateTime		AS CreatedDateTime
			, @RunDateTime		AS UpdatedDateTime
	  INTO #AdditionalCashbackAdjustmentCategory
	  FROM Warehouse.Relational.AdditionalCashbackAdjustmentCategory

	UNION ALL
	
	 SELECT
		-1
		, 'NOT APPLICABLE'
		, @RunDateTime
		, @RunDateTime

	BEGIN TRAN

		MERGE dbo.AdditionalCashbackAdjustmentCategory AS TGT 
			USING #AdditionalCashbackAdjustmentCategory AS SRC   
				ON TGT.AdditionalCashbackAdjustmentCategoryID = SRC.AdditionalCashbackAdjustmentCategoryID 
		WHEN MATCHED AND
						(	
								TGT.Category		<> SRC.Category
						)
			THEN   
				UPDATE SET     
					TGT.Category = SRC.Category,
					TGT.UpdatedDateTime = SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT (AdditionalCashbackAdjustmentCategoryID, Category, [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.AdditionalCashbackAdjustmentCategoryID, SRC.Category, SRC.[CreatedDateTime], SRC.UpdatedDateTime) 
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
