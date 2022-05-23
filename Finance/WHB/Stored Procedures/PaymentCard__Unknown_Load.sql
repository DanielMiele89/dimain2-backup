CREATE PROC [WHB].[PaymentCard__Unknown_Load]
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

	DECLARE @Inserted INT = 0
		, @Updated INT = 0
		, @Deleted INT = 0
	
	SET @StoredProcedureName = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
	
	IF @RunID IS NULL
		SET @RunID = NEXT VALUE FOR WHB.RunID

	IF (SELECT COUNT(1) FROM dbo.PaymentCard WHERE PaymentCardID = -1) > 0
		BEGIN
			BEGIN TRAN
				GOTO logrun
		END

	----------------------------------------------------------------------
	-- Build from source
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#PaymentCard') IS NOT NULL
		DROP TABLE #PaymentCard

	SELECT TOP 0
		CAST(NULL AS INT) AS PaymentCardID
		, StartDate
		, SourcePaymentCardTypeID
		, PaymentCardType
		, SourceTypeID
		, SourceID
		, CreatedDateTime
	INTO #PaymentCard
	FROM dbo.PaymentCard

	INSERT INTO #PaymentCard
	(
		PaymentCardID
		, StartDate
		, SourcePaymentCardTypeID
		, PaymentCardType
		, SourceTypeID
		, SourceID
		, CreatedDateTime
	)
	SELECT
		-1					AS PaymentCardID
		, '1900-01-01'		AS StartDate
		, -1 				AS SourcePaymentCardTypeID
		, 'NOT APPLICABLE' 	AS PaymentCardType
		, -1				AS SourceTypeID
		, -1				AS SourceID
		, @RunDateTime		AS CreatedDateTime

	

	BEGIN TRAN

		SET IDENTITY_INSERT dbo.PaymentCard ON
		
		----------------------------------------------------------------------
		-- Insert New
		----------------------------------------------------------------------
		
		INSERT INTO dbo.PaymentCard
		(
			PaymentCardID
			, StartDate
			, SourcePaymentCardTypeID
			, PaymentCardType
			, SourceTypeID
			, SourceID
			, CreatedDateTime
		)
		SELECT
			PaymentCardID
			, StartDate
			, SourcePaymentCardTypeID
			, PaymentCardType
			, SourceTypeID
			, SourceID
			, CreatedDateTime
		FROM #PaymentCard AS src

		SET @Inserted = @@ROWCOUNT
		
		----------------------------------------------------------------------
		-- Log
		----------------------------------------------------------------------
		
		logrun:

		INSERT INTO WHB.Build_Log (RunID, StartDateTime, EndDateTime, StoredProcName, InsertedRows, UpdatedRows, DeletedRows)
		SELECT
			@RunID
			,@RunDateTime
			,GETDATE()
			,@StoredProcedureName
			,InsertedRows = @Inserted
			,UpdatedRows = @Updated
			,DeletedRows = @Deleted

		SET IDENTITY_INSERT dbo.PaymentCard OFF

	COMMIT TRAN
	

END
