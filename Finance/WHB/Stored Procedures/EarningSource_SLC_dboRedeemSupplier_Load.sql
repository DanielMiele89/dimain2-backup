
CREATE PROC [WHB].[EarningSource_SLC_dboRedeemSupplier_Load]
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
		, @SourceTypeID INT
		, @SourceSystemID INT
		, @SourceTable VARCHAR(100)

	SET @StoredProcedureName = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	EXEC WHB.Get_SourceTypeID 
		@StoredProcedureName
		, @SourceTypeID OUTPUT
		, @SourceSystemID OUTPUT
		, @SourceTable OUTPUT

	IF @RunID IS NULL
		SET @RunID = NEXT VALUE FOR WHB.RunID
	
	----------------------------------------------------------------------
	-- Build base table from source
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#EarningSource') IS NOT NULL
		DROP TABLE #EarningSource

	SELECT TOP 0
		SourceName
		, PartnerID
		, isBankFunded
		, AdditionalInfo1
		, AdditionalInfo2
		, SourceTypeID
		, SourceID
		, CreatedDateTime
		, DisplayName
		, FundingType
	INTO #EarningSource
	FROM dbo.EarningSource

	INSERT INTO #EarningSource
	(
		SourceName
		, PartnerID
		, isBankFunded
		, AdditionalInfo1
		, AdditionalInfo2
		, SourceTypeID
		, SourceID
		, CreatedDateTime	
		, DisplayName
		, FundingType
	)
	SELECT
		SourceName
		, PartnerID
		, isBankFunded
		, AdditionalInfo1
		, AdditionalInfo2
		, @SourceTypeID
		, SourceID
		, @RunDateTime AS CreatedDateTime
		, DisplayName
		, FundingType
	FROM
	(
		SELECT 
			ID AS SourceID
			, -1 AS PartnerID
			, 0 AS isBankFunded
			, rs.description AS SourceName
			, NULL AS AdditionalInfo1
			, NULL AS AdditionalInfo2
			, rs.description + ' - Earn Back' AS DisplayName
			, 'Other' AS FundingType
		FROM DIMAIN_TR.SLC_REPL.dbo.RedeemSupplier rs
	) x

	BEGIN TRAN
		DECLARE @Inserted INT = 0
			, @Updated INT = 0
			, @Deleted INT = 0

		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------
		
		INSERT INTO dbo.EarningSource
		(
			SourceName
			, PartnerID
			, isBankFunded
			, AdditionalInfo1
			, AdditionalInfo2
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, DisplayName
			, FundingType
		)
		SELECT
			SourceName
			, PartnerID
			, isBankFunded
			, AdditionalInfo1
			, AdditionalInfo2
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, DisplayName
			, FundingType
		FROM #EarningSource  AS src
		WHERE NOT EXISTS (
			SELECT 1 
			FROM dbo.EarningSource tgt
			WHERE src.SourceID = tgt.SourceID
				AND src.SourceTypeID = tgt.SourceTypeID
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
