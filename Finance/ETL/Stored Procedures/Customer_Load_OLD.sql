CREATE PROC [ETL].[Customer_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN
	SET XACT_ABORT ON;
	DECLARE @StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
		, @RunDateTime DATETIME2 = GETDATE()
	
	----------------------------------------------------------------------
	-- Get Customers
	----------------------------------------------------------------------
	IF OBJECT_ID('#Customers_Staging') IS NOT NULL   
		DROP TABLE #Customers_Staging;
	
	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));
	
	  SELECT 
			 [ID]					AS [CustomerID]
			,[ClubID]				AS [PublisherID]
			,[Status]				AS [CustomerStatusID]
			,[ClubCashPending]		AS [CashBackPending]
			,[ClubCashAvailable]	AS [CashBackAvailable]
			,[AgreedTCsDate]		AS ActivatedDate
			, @RunDateTime			AS CreatedDateTime
			, @RunDateTime			AS UpdatedDateTime
	  INTO #Customers_Staging
	  FROM  [SLC_Report].[dbo].[Fan]
	  WHERE ClubID in (132, 138)
	  --WHERE RegistrationDate >= COALESCE(@LoadFromDate,RegistrationDate)

	  CREATE CLUSTERED INDEX CIX ON #Customers_Staging(CustomerID)
	  CREATE NONCLUSTERED INDEX NIX ON #Customers_Staging([CustomerStatusID]) INCLUDE (CustomerID, ActivatedDate)

	  /**********************************************************************
	  Get Deactivated Dates
	  ***********************************************************************/

	  IF OBJECT_ID('tempdb..#DeactivatedCustomers') IS NOT NULL 
	  	DROP TABLE #DeactivatedCustomers

	  SELECT
		CustomerID
		, ActivatedDate
	  INTO #DeactivatedCustomers
	  FROM #Customers_Staging
	  WHERE CustomerStatusID = 0

	  CREATE CLUSTERED INDEX CIX ON #DeactivatedCustomers (CustomerID)

	  ----------------------------------------------------------------------
	  -- Get Comments for Customers
	  ----------------------------------------------------------------------
	  IF OBJECT_ID('tempdb..#Comments') IS NOT NULL 
	  	DROP TABLE #Comments
	  SELECT
		ddc.CustomerID
		, c.Date AS DeactivatedDate
		, dc.LikePriority
		--, c.Comment
	  INTO #Comments 
	  FROM SLC_REPL..Comments c
	  JOIN #DeactivatedCustomers ddc
		ON c.FanID = ddc.CustomerID
		AND c.Date >= ddc.ActivatedDate
	  JOIN Finance.ETL.DeactivatedComment dc
		ON c.Comment LIKE dc.LikeString

	   CREATE CLUSTERED INDEX CIX ON #Comments (CustomerID)
	   CREATE NONCLUSTERED INDEX NIX ON #Comments (LikePriority) INCLUDE (CustomerID, DeactivatedDate)
	  ----------------------------------------------------------------------
	  -- Set Deactivated Dates
	  ----------------------------------------------------------------------
	  IF OBJECT_ID('tempdb..#DeactivatedDates') IS NOT NULL 
	  	DROP TABLE #DeactivatedDates

	  DECLARE @Today DATE = GETDATE()

	  ;WITH CommentRanking
	  AS
	  (
		  SELECT
			CustomerID
			, LikePriority
			, MAX(DeactivatedDate) DeactivatedDate
		  FROM #Comments
		  GROUP BY CustomerID
			, LikePriority
	  )
	  SELECT
		*
		, DATEDIFF(DAY, DeactivatedDate, @Today) DeactivatedDays
	  INTO #DeactivatedDates
	  FROM (
		  SELECT
			dc.CustomerID
			, COALESCE(DeactivatedDate, dc.ActivatedDate) AS DeactivatedDate
		  FROM #DeactivatedCustomers dc
		  LEFT JOIN
		  (
			SELECT 
				CustomerID
				, DeactivatedDate
				, ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY LikePriority) rw
			FROM CommentRanking
		  ) x 
			ON dc.CustomerID = x.CustomerID
			AND x.rw = 1
	) x

		
	  ----------------------------------------------------------------------
	  -- Create Final Customer Table to check
	  ----------------------------------------------------------------------
	  IF OBJECT_ID('tempdb..#Customers') IS NOT NULL 
	  	DROP TABLE #Customers

	  SELECT 
		cs.*
		, dc.DeactivatedDate
		, COALESCE(db.DeactivatedBandID, -1) AS DeactivatedBandID
	  INTO #Customers
	  FROM #Customers_Staging cs
	  LEFT JOIN #DeactivatedDates dc
		ON cs.CustomerID = dc.CustomerID
      LEFT JOIN dbo.DeactivatedBand db
		ON dc.DeactivatedDays BETWEEN db.DeactivatedBandMin and db.DeactivatedBandMax

	  CREATE CLUSTERED INDEX CIX ON #Customers (CustomerID)
	 
	BEGIN TRAN
	
		MERGE dbo.Customer AS TGT 
			USING #Customers AS SRC   
				ON TGT.[CustomerID] = SRC.[CustomerID] 
		WHEN MATCHED AND
						(	
								TGT.[PublisherID]		<> SRC.[PublisherID]
							OR	TGT.[CustomerStatusID]	<> SRC.[CustomerStatusID]
							OR	TGT.[CashBackPending]	<> SRC.[CashBackPending]
							OR	TGT.[CashBackAvailable]	<> SRC.[CashBackAvailable]
							OR	TGT.ActivatedDate	<> SRC.ActivatedDate
							OR	ISNULL(TGT.DeactivatedDate, '1900-01-01')	<> ISNULL(SRC.DeactivatedDate, '1900-01-01')
							OR	TGT.DeactivatedBandID	<> SRC.DeactivatedBandID
							
						)
			THEN   
				UPDATE SET     
					TGT.[PublisherID]		= SRC.[PublisherID],     
					TGT.[CustomerStatusID]	= SRC.[CustomerStatusID],
					TGT.[CashBackPending]	= SRC.[CashBackPending],
					TGT.[CashBackAvailable]	= SRC.[CashBackAvailable],     
					TGT.ActivatedDate	= SRC.ActivatedDate,     
					TGT.DeactivatedDate = SRC.DeactivatedDate,
					TGT.DeactivatedBandID = SRC.DeactivatedBandID,     
					TGT.[UpdatedDateTime] = SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT (CustomerID, [PublisherID], [CustomerStatusID], [CashBackPending], [CashBackAvailable], ActivatedDate, DeactivatedDate, DeactivatedBandID, [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.CustomerID, SRC.[PublisherID], SRC.[CustomerStatusID], SRC.[CashBackPending], SRC.[CashBackAvailable], SRC.ActivatedDate, SRC.DeactivatedDate, SRC.DeactivatedBandID, SRC.[CreatedDateTime], SRC.UpdatedDateTime) 
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

