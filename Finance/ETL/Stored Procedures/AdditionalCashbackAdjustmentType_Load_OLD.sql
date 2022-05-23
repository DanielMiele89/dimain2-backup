CREATE PROC [ETL].[AdditionalCashbackAdjustmentType_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF OBJECT_ID('tempdb..#AdditionalCashbackAdjustmentType') IS NOT NULL   
		DROP TABLE #AdditionalCashbackAdjustmentType;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	  SELECT 
			 AdditionalCashbackAdjustmentTypeID
			, TypeID AS TransactionTypeID
			, ItemID
			, Description AS TypeDescription
			, AdditionalCashbackAdjustmentCategoryID
			, @RunDateTime		AS CreatedDateTime
			, @RunDateTime		AS UpdatedDateTime
	  INTO #AdditionalCashbackAdjustmentType
	  FROM Warehouse.Relational.AdditionalCashbackAdjustmentType

	UNION ALL

	 SELECT
		-1
		, -1
		, -1
		, 'NOT APPLICABLE'
		, -1
		, @RunDateTime
		, @RunDateTime

	BEGIN TRAN

		MERGE dbo.AdditionalCashbackAdjustmentType AS TGT 
			USING #AdditionalCashbackAdjustmentType AS SRC   
				ON TGT.AdditionalCashbackAdjustmentTypeID = SRC.AdditionalCashbackAdjustmentTypeID 
		WHEN MATCHED AND EXISTS
						(SELECT tgt.* EXCEPT SELECT src.*)
			THEN   
				UPDATE SET     
					TGT.TransactionTypeID = SRC.TransactionTypeID,
					TGT.ItemID = SRC.ItemID,
					TGT.AdditionalCashbackAdjustmentCategoryID = SRC.AdditionalCashbackAdjustmentCategoryID,
					TGT.TypeDescription = SRC.TypeDescription,
					TGT.UpdatedDateTime = SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT (AdditionalCashbackAdjustmentTypeID, TransactionTypeID, ItemID, TypeDescription, AdditionalCashbackAdjustmentCategoryID, [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.AdditionalCashbackAdjustmentTypeID, SRC.TransactionTypeID, SRC.ItemID, SRC.TypeDescription, AdditionalCashbackAdjustmentCategoryID, SRC.[CreatedDateTime], SRC.UpdatedDateTime) 
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
