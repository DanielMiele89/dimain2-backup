CREATE PROC [ETL].[Supplier_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(50) = OBJECT_NAME(@@PROCID);

	IF OBJECT_ID('#Suppliers_Staging') IS NOT NULL   
		DROP TABLE #Suppliers_Staging;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	  SELECT 
			 [ID]				AS [SupplierID]
			,[Description]
			,[Status]
			, @RunDateTime		AS CreatedDateTime
			, @RunDateTime		AS UpdatedDateTime
	  INTO #Suppliers_Staging
	  FROM [SLC_Report].[dbo].[RedeemSupplier]


	BEGIN TRAN

		MERGE dbo.Supplier AS TGT 
			USING #Suppliers_Staging AS SRC   
				ON TGT.[SupplierID] = SRC.[SupplierID] 
		WHEN MATCHED AND EXISTS
					(SELECT tgt.* EXCEPT SELECT src.*)
			THEN   
				UPDATE SET     
					TGT.[Description]	= SRC.[Description],     
					TGT.[Status]		= SRC.[Status],     
					TGT.[UpdatedDateTime]	= SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT ([SupplierID], [Description], [Status], [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.[SupplierID], SRC.[Description], SRC.[Status], SRC.[CreatedDateTime], SRC.UpdatedDateTime) 
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
