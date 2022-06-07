CREATE PROC [ETL].[PartnerAlternate_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN

	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL   
		DROP TABLE #PartnerAlternate;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	  SELECT 
			[PartnerID] AS AlternatePartnerID
			, [AlternatePartnerID] AS PartnerID
			, @RunDateTime		AS CreatedDateTime
			, @RunDateTime		AS UpdatedDateTime
	  INTO #PartnerAlternate
	  FROM Warehouse.APW.PartnerAlternate

	BEGIN TRAN

		MERGE dbo.PartnerAlternate AS TGT 
			USING #PartnerAlternate AS SRC   
				ON TGT.AlternatePartnerID = SRC.AlternatePartnerID 
		WHEN MATCHED AND
						(	
								TGT.PartnerID		<> SRC.PartnerID
						)
			THEN   
				UPDATE SET     
					TGT.PartnerID		= SRC.PartnerID,     
					TGT.UpdatedDateTime = SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT (AlternatePartnerID, PartnerID, [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.AlternatePartnerID, SRC.PartnerID, SRC.[CreatedDateTime], SRC.UpdatedDateTime) 
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

