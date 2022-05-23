CREATE PROC [ETL].[SourceSystem_Load_DELETE_OLD]
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
	
		MERGE [dbo].[SourceSystem] AS TGT
		USING	(
					VALUES	(1,'SLC.Match',NULL,'MatchID',NULL),
							(2,'SLC.Trans',NULL,'ID',NULL)		
				) AS SRC (SourceSystemID,SourceName,SourceDescription,SourceTypeID1Name,SourceTypeID2Name)
		ON TGT.SourceSystemID = SRC.SourceSystemID
		WHEN MATCHED AND 
					EXISTS (SELECT tgt.* EXCEPT SELECT src.*)
		THEN UPDATE SET 
					TGT.SourceName = SRC.SourceName,
					TGT.SourceDescription = SRC.SourceDescription,
					TGT.SourceTypeID1Name = SRC.SourceTypeID1Name,
					TGT.SourceTypeID2Name = SRC.SourceTypeID2Name
		WHEN NOT MATCHED THEN
			INSERT (SourceSystemID,SourceName,SourceDescription,SourceTypeID1Name,SourceTypeID2Name)
			VALUES (SRC.SourceSystemID,SRC.SourceName,SRC.SourceDescription,SRC.SourceTypeID1Name,SRC.SourceTypeID2Name)
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


