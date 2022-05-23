
CREATE PROCEDURE ETL.[DirectDebitOriginator_Load_OLD]
(
	@RunID BIGINT = NULL,
	@RowCnt INT = -1 OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF OBJECT_ID('#DirectDebitOriginator_Staging') IS NOT NULL   
		DROP TABLE #DirectDebitOriginator_Staging;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	SELECT	do.ID AS DirectDebitOriginatorID
			, do.Oin
			, do.Name as SupplierName
			, c1.Name as Category1
			, CASE
				WHEN a.Oin is not null 
					THEN 'Water'
				ELSE c2.Name
			END as Category2
			, do.StartDate
			, do.EndDate
			, @RunDateTime		AS CreatedDateTime
			, @RunDateTime		AS UpdatedDateTime
	INTO #DirectDebitOriginator_Staging
	FROM SLC_Report.dbo.DirectDebitOriginator as do
	LEFT JOIN SLC_Report.dbo.DirectDebitCategory1 as c1
		ON do.Category1ID = c1.ID
	LEFT JOIN SLC_Report.dbo.DirectDebitCategory2 as c2
		ON do.Category2ID = c2.ID
	LEFT JOIN
	(	SELECT DISTINCT OIN
		FROM Warehouse.Relational.DirectDebit_OINs
		WHERE InternalCategory2 = 'Utilities' 
				AND RBSCategory2 = 'Local Authority and Water'
	) AS a
		ON do.OIN = a.oin

	BEGIN TRAN

		MERGE dbo.DirectDebitOriginator AS TGT 
			USING #DirectDebitOriginator_Staging AS SRC   
				ON TGT.DirectDebitOriginatorID = SRC.DirectDebitOriginatorID 
		WHEN MATCHED AND
						(	
								TGT.Oin	<> SRC.Oin
							OR	TGT.SupplierName <> SRC.SupplierName
							OR	TGT.Category1 <> SRC.Category1
							OR	TGT.Category2 <> SRC.Category2
							OR	TGT.StartDate <> SRC.StartDate
							OR	COALESCE(TGT.EndDate, '1900-01-01') <> COALESCE(SRC.EndDate, '1900-01-01')
						)
			THEN   
				UPDATE SET     
					TGT.Oin	= SRC.Oin,     
					TGT.SupplierName		= SRC.SupplierName,     
					TGT.Category1			= SRC.Category1,     
					TGT.Category2			= SRC.Category2,     
					TGT.StartDate			= SRC.StartDate,     
					TGT.EndDate				= SRC.EndDate,     
					TGT.[UpdatedDateTime]	= SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT (DirectDebitOriginatorID, OIN, SupplierName, Category1, Category2, StartDate, EndDate, CreatedDateTime, UpdatedDateTime)   
			VALUES (SRC.DirectDebitOriginatorID, SRC.OIN, SRC.SupplierName, SRC.Category1, SRC.Category2, SRC.StartDate, SRC.EndDate, SRC.CreatedDateTime, SRC.UpdatedDateTime) 
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