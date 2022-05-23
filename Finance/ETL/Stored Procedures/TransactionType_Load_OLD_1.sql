CREATE PROC [ETL].[TransactionType_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(50) = OBJECT_NAME(@@PROCID);

	IF OBJECT_ID('#TransactionType_Staging') IS NOT NULL   
		DROP TABLE #TransactionType_Staging;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	  SELECT 
			 [ID]		AS TransactionTypeID
			,[Name] AS TypeName
			,[Description] AS TypeDescription
			,[Multiplier]
			, @RunDateTime		AS CreatedDateTime
			, @RunDateTime		AS UpdatedDateTime
	  INTO #TransactionType_Staging
	  FROM [SLC_Report].[dbo].[TransactionType]

	  UNION ALL

	  SELECT
		-1
		, 'NOT APPLICABLE'
		, 'NOT APPLICABLE'
		, 0
		, @RunDateTime
		, @RunDateTime

	BEGIN TRAN

		MERGE dbo.TransactionType AS TGT 
			USING #TransactionType_Staging AS SRC   
				ON TGT.[TransactionTypeID] = SRC.[TransactionTypeID] 
		WHEN MATCHED AND
						(	
								TGT.TypeName			<> SRC.TypeName
							OR	TGT.TypeDescription	<> SRC.TypeDescription
							OR	TGT.[Multiplier]	<> SRC.[Multiplier]
						)
			THEN   
				UPDATE SET     
					TGT.TypeName			= SRC.TypeName,     
					TGT.TypeDescription	= SRC.TypeDescription,    
					TGT.[Multiplier]	= SRC.[Multiplier],  
					TGT.[UpdatedDateTime]	= SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT (TransactionTypeID, TypeName, TypeDescription, [Multiplier], [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.TransactionTypeID, SRC.TypeName, SRC.TypeDescription, SRC.[Multiplier], SRC.[CreatedDateTime], src.UpdatedDateTime) 
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



