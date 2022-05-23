
CREATE PROC [ETL].[AdditionalCashbackAwardType_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF OBJECT_ID('tempdb..#AdditionalCashbackAwardType') IS NOT NULL   
		DROP TABLE #AdditionalCashbackAwardType;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	  SELECT 
			 AdditionalCashbackAwardTypeID
			, Title
			, TransactionTypeID AS TransactionTypeID
			, ItemID
			, Description AS TypeDescription
			, PartnerCommissionRuleID
			, @RunDateTime		AS CreatedDateTime
			, @RunDateTime		AS UpdatedDateTime
	  INTO #AdditionalCashbackAwardType
	  FROM Warehouse.Relational.AdditionalCashbackAwardType

	UNION ALL

	 SELECT
		-1
		, 'NOT APPLICABLE'
		, -1
		, -1
		, 'NOT APPLICABLE'
		, NULL
		, @RunDateTime
		, @RunDateTime

	BEGIN TRAN

		MERGE dbo.AdditionalCashbackAwardType AS TGT 
			USING #AdditionalCashbackAwardType AS SRC   
				ON TGT.AdditionalCashbackAwardTypeID = SRC.AdditionalCashbackAwardTypeID 
		WHEN MATCHED AND
						(	
								TGT.Title		<> SRC.Title
								OR TGT.TransactionTypeID <> SRC.TransactionTypeID
								OR TGT.ItemID <> SRC.ItemID
								OR TGT.TypeDescription <> SRC.TypeDescription
								OR TGT.PartnerCommissionRuleID <> SRC.PartnerCommissionRuleID
						)
			THEN   
				UPDATE SET     
					TGT.Title = SRC.Title,
					TGT.TransactionTypeID = SRC.TransactionTypeID,
					TGT.ItemID = SRC.ItemID,
					TGT.TypeDescription = SRC.TypeDescription,
					TGT.PartnerCommissionRuleID = SRC.PartnerCommissionRuleID,
					TGT.UpdatedDateTime = SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT (AdditionalCashbackAwardTypeID, Title, TransactionTypeID, ItemID, TypeDescription, PartnerCommissionRuleID, [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.AdditionalCashbackAwardTypeID, SRC.Title, SRC.TransactionTypeID, SRC.ItemID, SRC.TypeDescription, SRC.PartnerCommissionRuleID, SRC.[CreatedDateTime], SRC.UpdatedDateTime) 
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
