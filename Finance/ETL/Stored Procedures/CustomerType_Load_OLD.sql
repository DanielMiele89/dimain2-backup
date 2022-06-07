CREATE PROC [ETL].[CustomerType_Load_OLD]
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
	
		MERGE [dbo].[CustomerStatus] AS TGT
		USING	(
					VALUES	(0,'Inactive',NULL),
							(1,'Active',NULL)		
				) AS SRC (CustomerStatusID,Name,Description)
		ON TGT.CustomerStatusID = SRC.CustomerStatusID
		WHEN MATCHED AND EXISTS (SELECT tgt.* EXCEPT SELECT src.*)
						--(	
						--	TGT.Name <> SRC.Name
						--	OR (TGT.Description <> SRC.Description OR (ISNULL(TGT.Description, '') <> ISNULL(SRC.Description, '')))
						--)
		THEN UPDATE SET 
					TGT.Name = SRC.Name,
					TGT.Description = SRC.Description
		WHEN NOT MATCHED THEN
			INSERT (CustomerStatusID,Name,Description)
			VALUES (SRC.CustomerStatusID,SRC.Name,SRC.Description)
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


