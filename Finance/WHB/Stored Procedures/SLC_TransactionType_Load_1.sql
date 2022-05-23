CREATE PROCEDURE WHB.SLC_TransactionType_Load
		@RunID INT = NULL
AS
BEGIN
	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2(7) = GETDATE()
		, @StoredProcedureName VARCHAR(100)

	SET @StoredProcedureName = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	IF @RunID IS NULL
		SET @RunID = NEXT VALUE FOR WHB.RunID


	----------------------------------------------------------------------
	-- Build Base Table from Source
	----------------------------------------------------------------------
	
	IF OBJECT_ID('tempdb..#SLCTransactionType') IS NOT NULL
		DROP TABLE #SLCTransactionType

	SELECT TOP 0
		SLC_TransactionTypeID
		, TypeName
		, TypeDescription
		, Multiplier
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	INTO #SLCTransactionType
	FROM dbo.SLC_TransactionType

	INSERT INTO #SLCTransactionType
	(
		SLC_TransactionTypeID
		, TypeName
		, TypeDescription
		, Multiplier
		, CreatedDateTime
		, UpdatedDateTime
		, MD5
	)
	SELECT
		SLC_TransactionTypeID
		, TypeName
		, TypeDescription
		, Multiplier
		, @RunDateTime		AS CreatedDateTime
		, @RunDateTime		AS UpdatedDateTime
		, HASHBYTES('MD5',
			CONCAT(TypeName
			, ',', TypeDescription
			, ',', Multiplier
			)
		) AS MD5
	FROM
	(
		SELECT
			[ID]	 AS SLC_TransactionTypeID
			,[Name]  AS TypeName
			,[Description] AS TypeDescription
			,[Multiplier]
		FROM SLC_Report.dbo.TransactionType

		UNION ALL

		SELECT
			-1
			, 'NOT APPLICABLE'
			, 'NOT APPLICABLE'
			, 0
	) x

	BEGIN TRAN
		DECLARE @Inserted INT = 0
			, @Updated INT = 0
			, @Deleted INT = 0

		----------------------------------------------------------------------
		-- Update Existing
		----------------------------------------------------------------------
		
		UPDATE tgt
		SET TypeName = src.TypeName
			, TypeDescription = src.TypeDescription
			, Multiplier = src.Multiplier
			, UpdatedDateTime = src.UpdatedDateTime
			, MD5 = src.MD5
		FROM dbo.SLC_TransactionType   AS tgt
		JOIN #SLCTransactionType	  AS src
			ON tgt.SLC_TransactionTypeID = src.SLC_TransactionTypeID
			AND src.md5 <> tgt.md5

		SET @Updated = @@ROWCOUNT

		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------
		
		INSERT INTO dbo.SLC_TransactionType
		(
			SLC_TransactionTypeID
			, TypeName
			, TypeDescription
			, Multiplier
			, CreatedDateTime
			, UpdatedDateTime
			, MD5

		)
		SELECT
			SLC_TransactionTypeID
			, TypeName
			, TypeDescription
			, Multiplier
			, CreatedDateTime
			, UpdatedDateTime
			, MD5
		FROM #SLCTransactionType  AS src
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.SLC_TransactionType  AS tgt
			WHERE tgt.SLC_TransactionTypeID = src.SLC_TransactionTypeID

		)

		SET @Inserted = @@ROWCOUNT

		----------------------------------------------------------------------
		-- Log
		----------------------------------------------------------------------
		
		INSERT INTO WHB.Build_Log (RunID, StartDateTime, EndDateTime, StoredProcName, InsertedRows, UpdatedRows, DeletedRows)
		SELECT
			@RunID
			,@RunDateTime
			,GETDATE()
			,@StoredProcedureName
			,InsertedRows = @Inserted
			,UpdatedRows = @Updated
			,DeletedRows = @Deleted


	COMMIT TRAN

END
