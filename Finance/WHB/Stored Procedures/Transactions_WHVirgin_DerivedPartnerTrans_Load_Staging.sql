CREATE PROCEDURE [WHB].[Transactions_WHVirgin_DerivedPartnerTrans_Load_Staging]
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
		, @CheckpointFileID INT
		, @CheckpointRowNum INT

	SET @StoredProcedureName = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	EXEC WHB.Get_SourceTypeID 
		@StoredProcedureName
		, @SourceTypeID OUTPUT
		, @SourceSystemID OUTPUT
		, @SourceTable OUTPUT

	IF @RunID IS NULL
		SET @RunID = NEXT VALUE FOR WHB.RunID

	DECLARE @CheckpointTable VARCHAR(30) = 'WH_Virgin.' + @SourceTable
	EXEC WHB.Get_TableCheckpoint @CheckpointTable, 1, 'VARCHAR(100)', @CheckpointValue OUTPUT

	IF @CheckpointValue IS NULL
	BEGIN
		SET @CheckpointFileID = 0
		SET @CheckpointRowNum = 0
	END
	ELSE
	BEGIN
		SET @CheckpointFileID = SUBSTRING(@CheckpointValue, 0, CHARINDEX(',', @CheckpointValue))
		SET @CheckpointRowNum = SUBSTRING(@CheckpointValue, CHARINDEX(',', @CheckpointValue)+1, 99999)
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
		AND st.SourceTable = 'dbo.Partner'
	JOIN dbo.SourceSystem ss
		ON st.SourceSystemID = ss.SourceSystemID
		AND ss.SourceSystemName = 'Finance'

	CREATE CLUSTERED INDEX CIX ON #EarningSource (SourceID)

	----------------------------------------------------------------------
	-- Load Staging Table
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#PartnerTrans') IS NOT NULL
		DROP TABLE #PartnerTrans

	select
		o.HydraOfferID 			AS SourceOfferID
		, p.PartnerID			AS PartnerID
		, p.TransactionAmount 	AS Spend
		, p.CashbackEarned 		AS Earning
		, p.TransactionDate 	AS TranDate
		, p.TransactionDate 	AS TranDateTime
		, p.PaymentMethodID		AS PaymentMethodID
		, p.ActivationDays		AS ActivationDays
		, CONCAT(RIGHT(CONCAT('00000000', p.FileID), 8)
					, ','
					, RIGHT(CONCAT('00000000', p.RowNum), 8)
				) 				AS SourceID
		, c.SourceUID 			AS SourceCustomerID
		, p.AddedDate 			AS SourceAddedDateTime
		, CONCAT(RIGHT(CONCAT('00000000', p.FileID), 8)
					, ','
					, RIGHT(CONCAT('00000000', p.RowNum), 8)
				) 				AS CheckpointID
		, 'GBP' 				AS CurrencyCode
		, @SourceTypeID 		AS SourceTypeID
		, @RunDateTime 			AS CreatedDateTime
	INTO #PartnerTrans
	FROM WH_Virgin.Derived.PartnerTrans p
	JOIN WH_Virgin.Derived.Customer c
		ON p.FanID = c.FanID
	JOIN WH_Virgin.Derived.IronOffer o
		ON p.IronOfferID = o.IronOfferID
	WHERE FileID > @CheckpointFileID 
		OR (FileID = @CheckpointFileID AND RowNum > @CheckpointRowNum)
	ORDER BY FileID, RowNum
	
	CREATE CLUSTERED INDEX CIX ON #PartnerTrans(SourceID)
	CREATE NONCLUSTERED INDEX NIX ON #PartnerTrans(CheckpointID)

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
			, o.OfferID AS OfferID
			, es.EarningSourceID
			, c.PublisherID
			, -1 AS PaymentCardID
			, te.Spend AS Spend
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
		FROM #PartnerTrans te
		LEFT JOIN #EarningSource es
			ON te.PartnerID = es.SourceID
		LEFT JOIN #Customer c
			ON te.SourceCustomerID = c.SourceID
		LEFT JOIN #Offer o
			ON te.SourceOfferID = o.SourceID
		WHERE NOT EXISTS (
			SELECT 1
			FROM dbo.Transactions tx
			WHERE te.SourceID = tx.SourceID
				AND te.SourceTypeID = tx.SourceTypeID
		)

		SET @Inserted = @@ROWCOUNT
		
		DECLARE @NewCheckpointValue VARCHAR(100) = (SELECT MAX(CheckpointID) FROM #PartnerTrans)

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
