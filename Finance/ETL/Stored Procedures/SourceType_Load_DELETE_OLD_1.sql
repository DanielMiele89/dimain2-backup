CREATE PROC [ETL].[SourceType_Load_DELETE_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	DECLARE @StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
		, @RunDateTime DATETIME2 = GETDATE()
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));


	BEGIN TRAN
	
		MERGE [dbo].[SourceType] AS TGT
		USING	(
					VALUES	(1,'PartnerTrans',NULL,1),
							(2,'AdditionalCashbackAward',NULL,2),
							(3,'AdditionalCashbackAdjustment',NULL,2)	
				) AS SRC(SourceTypeID,SourceName,SourceDescription,SourceSystemID)
		ON TGT.SourceTypeID = SRC.SourceTypeID
		WHEN MATCHED AND 
					EXISTS (SELECT tgt.* EXCEPT SELECT src.*)
		THEN UPDATE SET 
					TGT.SourceName = SRC.SourceName,
					TGT.SourceDescription = SRC.SourceDescription,
					TGT.SourceSystemID = SRC.SourceSystemID
		WHEN NOT MATCHED THEN
			INSERT (SourceTypeID,SourceName,SourceDescription,SourceSystemID)
			VALUES (SRC.SourceTypeID,SRC.SourceName,SRC.SourceDescription,SRC.SourceSystemID)
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


