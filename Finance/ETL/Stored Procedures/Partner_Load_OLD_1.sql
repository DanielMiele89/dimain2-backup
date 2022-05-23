CREATE PROC [ETL].[Partner_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF OBJECT_ID('#Partners_Staging') IS NOT NULL   
		DROP TABLE #Partners_Staging;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	  SELECT 
			 [ID]		AS [PartnerID]
			,[Name]
			,[Status]
			, @RunDateTime		AS CreatedDateTime
			, @RunDateTime		AS UpdatedDateTime
	  INTO #Partners_Staging
	  FROM [SLC_Report].[dbo].[Partner]

	UNION ALL

	 SELECT
		-1
		, 'NOT APPLICABLE'
		, 1
		, @RunDateTime
		, @RunDateTime

	INSERT INTO #Partners_Staging
	SELECT
		p.PartnerID
		, p.PartnerName
		, p.CurrentlyActive
		, @RunDateTime
		, @RunDateTime
	FROM Warehouse.Relational.Partner p
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Partners_Staging px
		WHERE p.PartnerID = px.PartnerID
	)

	BEGIN TRAN

		MERGE dbo.Partner AS TGT 
			USING #Partners_Staging AS SRC   
				ON TGT.[PartnerID] = SRC.[PartnerID] 
		WHEN MATCHED AND
						(	
								TGT.[Name]		<> SRC.[Name]
							OR	TGT.[Status]	<> SRC.[Status]
						)
			THEN   
				UPDATE SET     
					TGT.[Name]		= SRC.[Name],     
					TGT.[Status]	= SRC.[Status],     
					TGT.UpdatedDateTime = SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT ([PartnerID], [Name], [Status], [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.[PartnerID], SRC.[Name], SRC.[Status], SRC.[CreatedDateTime], SRC.UpdatedDateTime) 
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

