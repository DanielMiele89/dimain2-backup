CREATE PROC [ETL].[Publisher_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF OBJECT_ID('#Publishers_Staging') IS NOT NULL   
		DROP TABLE #Publishers_Staging;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));

	SELECT 
		  ID		AS PublisherID
		, [Name]
		, [Status]
		, @RunDateTime		AS CreatedDateTime
		, @RunDateTime		AS UpdatedDateTime
	INTO #Publishers_Staging
	FROM SLC_Report.dbo.Club

	UNION ALL

	SELECT 
		*
	FROM (
		VALUES
			(-1, 'NOT APPLICABLE', 1, @RunDateTime, @RunDateTime)
	) x(a,b,c,d,e)

	BEGIN TRAN

		MERGE dbo.Publisher AS TGT 
			USING #Publishers_Staging AS SRC   
				ON TGT.PublisherID = SRC.PublisherID 
		WHEN MATCHED AND
						(	
								TGT.[Name]		<> SRC.[Name]
							OR	TGT.[Status]	<> SRC.[Status]
						)
			THEN   
				UPDATE SET     
						TGT.[Name]			= SRC.[Name],     
						TGT.[Status]		= SRC.[Status],     
						TGT.[UpdatedDateTime]	= SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT (PublisherID, [Name], [Status], [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.PublisherID, SRC.[Name], SRC.[Status], SRC.[CreatedDateTime], SRC.UpdatedDateTime) 
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
 


