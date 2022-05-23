CREATE PROCEDURE [WHB].[Transactions_WHVirgin_DerivedBalanceAdjustmentsGoodwill_Load_Staging]
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
		, @CheckpointValue VARCHAR(100)

	SET @StoredProcedureName = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	EXEC WHB.Get_SourceTypeID 
		@StoredProcedureName
		, @SourceTypeID OUTPUT
		, @SourceSystemID OUTPUT
		, @SourceTable OUTPUT

	IF @RunID IS NULL
		SET @RunID = NEXT VALUE FOR WHB.RunID

	DECLARE @CheckpointTable VARCHAR(30) = 'WH_Virgin.' + @SourceTable
	EXEC WHB.Get_TableCheckpoint @CheckpointTable, 1, 'INT', @CheckpointValue OUTPUT

	IF @CheckpointValue IS NULL
	BEGIN
		SET @CheckpointValue = 0
	END

	ALTER TABLE Staging.Transactions NOCHECK CONSTRAINT ALL;

	----------------------------------------------------------------------
	-- Build Customer Table
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL
		DROP TABLE #Customer

	SELECT
		CustomerID
		, SourceID
		, c.PublisherID
	INTO #Customer
	FROM dbo.Customer c
	JOIN dbo.SourceType st
		ON c.SourceTypeID = st.SourceTypeID
		AND st.SourceSystemID = @SourceSystemID

	CREATE CLUSTERED INDEX CIX ON #Customer (SourceID)


	----------------------------------------------------------------------
	-- Build Offer Table
	----------------------------------------------------------------------
	
	IF OBJECT_ID('tempdb..#Offer') IS NOT NULL
		DROP TABLE #Offer

	SELECT
		OfferID
		, SourceID
	INTO #Offer
	FROM dbo.Offer c
	JOIN dbo.SourceType st
		ON c.SourceTypeID = st.SourceTypeID
		AND st.SourceSystemID = @SourceSystemID

	CREATE CLUSTERED INDEX CIX ON #Offer (SourceID)

	----------------------------------------------------------------------
	-- Build Earning Source Table
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#EarningSource') IS NOT NULL
		DROP TABLE #EarningSource

	SELECT
		EarningSourceID
		, SourceID
	INTO #EarningSource
	FROM dbo.EarningSource es
	JOIN dbo.SourceType st
		ON es.SourceTypeID = st.SourceTypeID
		AND st.SourceSystemID = @SourceSystemID
		AND st.SourceTable = 'Derived.GoodwillTypes'

	CREATE CLUSTERED INDEX CIX ON #EarningSource (SourceID)

	----------------------------------------------------------------------
	-- Load Staging Table
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Goodwill') IS NOT NULL
		DROP TABLE #Goodwill

	SELECT
		-1 					AS OfferID
		, NULL 				AS Spend
		, GoodwillAmount 	AS Earning
		, GoodwillDateTime 	AS TranDate
		, GoodwillDateTime 	AS TranDateTime
		, -1 				AS PaymentMethodID
		, 0 				AS ActivationDays
		, CAST(ID AS VARCHAR(36)) AS SourceID
		, c.SourceUID 		AS SourceCustomerID
		, p.AddedDate 		AS SourceAddedDateTime
		, 'GBP' 			AS CurrencyCode
		, ID 				AS CheckpointID
		, @SourceTypeID 	AS SourceTypeID
		, @RunDateTime 		AS CreatedDateTime
		, GoodwillTypeID	AS SourceEarningSourceID
	INTO #Goodwill
	FROM WH_Virgin.Derived.BalanceAdjustments_Goodwill p
	JOIN WH_Virgin.Derived.Customer c
		ON p.FanID = c.FanID
	WHERE ID > @CheckpointValue 
	ORDER BY ID
	
	CREATE CLUSTERED INDEX CIX ON #Goodwill(SourceID)
	CREATE NONCLUSTERED INDEX NIX ON #Goodwill(CheckpointID)

	----------------------------------------------------------------------
	-- Insert into main table and log checkpoints
	----------------------------------------------------------------------

	BEGIN TRAN

		DECLARE @Inserted BIGINT = 0
			, @Updated INT = 0
			, @Deleted INT = 0

		INSERT INTO Staging.Transactions
		(
			CustomerID
			, OfferID
			, EarningSourceID
			, PublisherID
			, PaymentCardID
			, Spend
			, Earning
			, CurrencyCode
			, TranDate
			, TranDateTime
			, PaymentMethodID
			, ActivationDays
			, EligibleDate
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, SourceAddedDateTime
		) 
		SELECT
			c.CustomerID
			, te.OfferID
			, es.EarningSourceID
			, c.PublisherID
			, -1 AS PaymentCardID
			, te.Spend
			, te.Earning
			, te.CurrencyCode
			, te.TranDate
			, te.TranDateTime
			, te.PaymentMethodID
			, te.ActivationDays
			, DATEADD(DAY, te.ActivationDays, te.TranDate) AS EligibleDate
			, te.SourceTypeID
			, te.SourceID
			, te.CreatedDateTime
			, te.SourceAddedDateTime
		FROM #Goodwill te
		LEFT JOIN #EarningSource es
			ON te.SourceEarningSourceID = es.SourceID
		LEFT JOIN #Customer c
			ON te.SourceCustomerID = c.SourceID
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Transactions tx
			WHERE te.SourceID = tx.SourceID
				AND te.SourceTypeID = tx.SourceTypeID
		)

		SET @Inserted = @@ROWCOUNT
		
		DECLARE @NewCheckpointValue VARCHAR(100) = (SELECT MAX(CheckpointID) FROM #Goodwill)

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
	COMMIT TRAN

END
