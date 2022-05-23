
CREATE PROCEDURE [WHB].[PaymentCard_SLC_dboPaymentCard_Load]
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
		, @CheckpointValue INT

	SET @StoredProcedureName = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	EXEC WHB.Get_SourceTypeID 
		@StoredProcedureName
		, @SourceTypeID OUTPUT
		, @SourceSystemID OUTPUT
		, @SourceTable OUTPUT

	IF @RunID IS NULL
		SET @RunID = NEXT VALUE FOR WHB.RunID

	DECLARE @CheckpointTable VARCHAR(30) = 'SLC.PaymentCard'
	EXEC WHB.Get_TableCheckpoint @CheckpointTable, 1, 'INT', @CheckpointValue OUTPUT

	IF @CheckpointValue IS NULL
		SET @CheckpointValue = 0

	----------------------------------------------------------------------
	-- Build Customer Table
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Customer_Stage') IS NOT NULL
		DROP TABLE #Customer_Stage

	SELECT
		CustomerID
		, SourceID
		, c.PublisherID
	INTO #Customer_Stage
	FROM dbo.Customer c
	JOIN dbo.SourceType st
		ON c.SourceTypeID = st.SourceTypeID
		AND st.SourceSystemID = @SourceSystemID

	CREATE CLUSTERED INDEX CIX ON #Customer_Stage (SourceID)


	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL
		DROP TABLE #Customer

	SELECT
		CustomerID
		, SourceID
		, PublisherID
		, CompositeID
	INTO #Customer
	FROM #Customer_Stage cs
	JOIN DIMAIN_TR.SLC_REPL.dbo.Fan f
		ON cs.SourceID = f.ID

	----------------------------------------------------------------------
	-- Build Source Table
	----------------------------------------------------------------------
	
	IF OBJECT_ID('tempdb..#PaymentCard') IS NOT NULL
		DROP TABLE #PaymentCard

	SELECT
		pc.Date 			AS StartDate
		, pc.CardTypeID		AS SourcePaymentCardTypeID
		, ISNULL(
			x.CardType
			, 'Unknown'
		) AS PaymentCardType
		, @SourceTypeID 	AS SourceTypeID
		, CAST(pc.ID AS VARCHAR(36)) 			AS SourceID
		, @RunDateTime 		AS CreatedDateTime
		, pc.ID				AS CheckpointID
	INTO #PaymentCard
	FROM DIMAIN_TR.SLC_Repl.dbo.PaymentCard pc
	LEFT JOIN DIMAIN_TR.SLC_REPL.dbo.PaymentCardProductType pt
		ON pt.PaymentCardID = pc.ID
	LEFT JOIN SLC_Report..cbp_credit_producttype cpt
		ON cpt.ID = pt.producttypeid
	OUTER APPLY (
		SELECT *
		FROM
		(
			VALUES 
				(1, ISNULL(cpt.Name, 'Unknown Credit'))
				, (2, 'Debit')
		) x(CardTypeID, CardType)
		WHERE pc.CardTypeID = x.CardTypeID
	) x
	WHERE pc.ID > @CheckpointValue
		AND EXISTS (
			SELECT 1
			FROM #Customer c
			JOIN SLC_REPL..Pan p
				ON c.CompositeID = p.CompositeID
			WHERE pc.ID = p.PaymentCardID	
		)

	CREATE CLUSTERED INDEX CIX ON #PaymentCard (SourceTypeID, SourceID)

	----------------------------------------------------------------------
	-- Load Card table
	----------------------------------------------------------------------
	BEGIN TRAN

		DECLARE @Inserted BIGINT = 0
			, @Updated INT = 0
			, @Deleted INT = 0

		INSERT INTO dbo.PaymentCard
		(
			StartDate
			, SourcePaymentCardTypeID
			, PaymentCardType
			, SourceTypeID
			, SourceID
			, CreatedDateTime
		) 
		SELECT
			StartDate
			, SourcePaymentCardTypeID
			, PaymentCardType
			, SourceTypeID
			, SourceID
			, CreatedDateTime
		FROM #PaymentCard pc
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.PaymentCard pcx
			WHERE pc.SourceTypeID = pcx.SourceTypeID
				AND pc.SourceID = pcx.SourceID
		)

		SET @Inserted = @@ROWCOUNT
		
		DECLARE @NewCheckpointValue INT = (SELECT MAX(CheckpointID) FROM #PaymentCard)

		EXEC WHB.Update_TableCheckpoint @CheckpointTable, @NewCheckpointValue

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

	COMMIT

END


