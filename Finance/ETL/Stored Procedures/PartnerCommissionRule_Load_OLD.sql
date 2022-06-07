CREATE PROC [ETL].[PartnerCommissionRule_Load_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN

	 SET XACT_ABORT ON
  	DECLARE @RunDateTime DATETIME2 = GETDATE(),
			@StoredProcName VARCHAR(50) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID);

	DECLARE @MergeCounts TABLE(ChangeType VARCHAR(20));
	
	IF OBJECT_ID('#PartnerCommissionRule_Staging') IS NOT NULL   
		DROP TABLE #PartnerCommissionRule_Staging;
	
	
	  SELECT 
			  [ID]				AS [CommissionRuleID]
			, [PartnerID]
			, [TypeID]
			, [CommissionRate]
			, [Status]
			, [Priority]
			, [CreationDate]
			, [CreationStaffID]
			, [DeletionDate]
			, [DeletionStaffID]
			, [MaximumUsesPerFan]
			, [StartDate]
			, [EndDate]
			, [RequiredNumberOfPriorTransactions]
			, [RequiredMinimumBasketSize]
			, [RequiredMaximumBasketSize]
			, [RequiredChannel]
			, [RequiredBinRange]
			, [RequiredClubID]
			, [RequiredMinimumHourOfDay]
			, [RequiredMaximumHourOfDay]
			, [RequiredMerchantID]
			, [RequiredIronOfferID]
			, [RequiredRetailOutletID]
			, [RequiredCardholderPresence]
			, @RunDateTime		AS CreatedDateTime
			, @RunDateTime		AS UpdatedDateTime
	  INTO #PartnerCommissionRule_Staging
	  FROM [SLC_Report].[dbo].[PartnerCommissionRule]
	  --WHERE CreationDate >= COALESCE(@LoadFromDate,CreationDate)

	BEGIN TRAN
		MERGE dbo.PartnerCommissionRule AS TGT 
			USING #PartnerCommissionRule_Staging AS SRC   
				ON TGT.[CommissionRuleID] = SRC.[CommissionRuleID] 
		WHEN MATCHED AND
						(	
								TGT.[PartnerID]							<> SRC.[PublisherID]
							OR	TGT.[TypeID]							<> SRC.[TypeID]
							OR	TGT.[CommissionRate]					<> SRC.[CommissionRate]
							OR	TGT.[Status]							<> SRC.[Status]
							OR	TGT.[Priority]							<> SRC.[Priority]
							OR	TGT.[CreationDate]						<> SRC.[CreationDate]
							OR	TGT.[CreationStaffID]					<> SRC.[CreationStaffID]
							OR	TGT.[DeletionDate]						<> SRC.[DeletionDate]
							OR	TGT.[DeletionStaffID]					<> SRC.[DeletionStaffID]
							OR	TGT.[MaximumUsesPerFan]					<> SRC.[MaximumUsesPerFan]
							OR	TGT.[StartDate]							<> SRC.[StartDate]
							OR	TGT.[EndDate]							<> SRC.[EndDate]
							OR	TGT.[RequiredNumberOfPriorTransactions]	<> SRC.[RequiredNumberOfPriorTransactions]
							OR	TGT.[RequiredMinimumBasketSize]			<> SRC.[RequiredMinimumBasketSize]
							OR	TGT.[RequiredMaximumBasketSize]			<> SRC.[RequiredMaximumBasketSize]
							OR	TGT.[RequiredChannel]					<> SRC.[RequiredChannel]
							OR	TGT.[RequiredBinRange]					<> SRC.[RequiredBinRange]
							OR	TGT.[RequiredClubID]					<> SRC.[RequiredClubID]
							OR	TGT.[RequiredMinimumHourOfDay]			<> SRC.[RequiredMinimumHourOfDay]
							OR	TGT.[RequiredMaximumHourOfDay]			<> SRC.[RequiredMaximumHourOfDay]
							OR	TGT.[RequiredMerchantID]				<> SRC.[RequiredMerchantID]
							OR	TGT.[RequiredIronOfferID]				<> SRC.[RequiredIronOfferID]
							OR	TGT.[RequiredRetailOutletID]			<> SRC.[RequiredRetailOutletID]
							OR	TGT.[RequiredCardholderPresence]		<> SRC.[RequiredCardholderPresence]
							--OR	TGT.[CommissionAmount]					<> SRC.[CommissionAmount]
							--OR	TGT.[CommissionLimit]					<> SRC.[CommissionLimit]
						)
			THEN   
				UPDATE SET     
					TGT.[PartnerID]							= SRC.[PartnerID],
					TGT.[TypeID]							= SRC.[TypeID],
					TGT.[CommissionRate]					= SRC.[CommissionRate],
					TGT.[Status]							= SRC.[Status],
					TGT.[Priority]							= SRC.[Priority],
					TGT.[CreationDate]						= SRC.[CreationDate],
					TGT.[CreationStaffID]					= SRC.[CreationStaffID],
					TGT.[DeletionDate]						= SRC.[DeletionDate],
					TGT.[DeletionStaffID]					= SRC.[DeletionStaffID],
					TGT.[MaximumUsesPerFan]					= SRC.[MaximumUsesPerFan],
					TGT.[StartDate]							= SRC.[StartDate],
					TGT.[EndDate]							= SRC.[EndDate],
					TGT.[RequiredNumberOfPriorTransactions]	= SRC.[RequiredNumberOfPriorTransactions],
					TGT.[RequiredMinimumBasketSize]			= SRC.[RequiredMinimumBasketSize],
					TGT.[RequiredMaximumBasketSize]			= SRC.[RequiredMaximumBasketSize],
					TGT.[RequiredChannel]					= SRC.[RequiredChannel],
					TGT.[RequiredBinRange]					= SRC.[RequiredBinRange],
					TGT.[RequiredClubID]					= SRC.[RequiredClubID],
					TGT.[RequiredMinimumHourOfDay]			= SRC.[RequiredMinimumHourOfDay],
					TGT.[RequiredMaximumHourOfDay]			= SRC.[RequiredMaximumHourOfDay],
					TGT.[RequiredMerchantID]				= SRC.[RequiredMerchantID],
					TGT.[RequiredIronOfferID]				= SRC.[RequiredIronOfferID],
					TGT.[RequiredRetailOutletID]			= SRC.[RequiredRetailOutletID],
					TGT.[RequiredCardholderPresence]		= SRC.[RequiredCardholderPresence],
					--TGT.[CommissionAmount]					= SRC.[CommissionAmount],
					--TGT.[CommissionLimit]					= SRC.[CommissionLimit],    
					TGT.[UpdatedDateTime]						= SRC.[UpdatedDateTime]
		WHEN NOT MATCHED THEN    
			INSERT ([CommissionRuleID], [PartnerID], [TypeID], [CommissionRate], [Status], [Priority], [CreationDate], [CreationStaffID], [DeletionDate], [DeletionStaffID], [MaximumUsesPerFan], [StartDate], [EndDate], [RequiredNumberOfPriorTransactions], [RequiredMinimumBasketSize], [RequiredMaximumBasketSize], [RequiredChannel], [RequiredBinRange], [RequiredClubID], [RequiredMinimumHourOfDay], [RequiredMaximumHourOfDay], [RequiredMerchantID], [RequiredIronOfferID], [RequiredRetailOutletID], [RequiredCardholderPresence], [CommissionAmount], [CommissionLimit], [CreatedDateTime], UpdatedDateTime)   
			VALUES (SRC.[CommissionRuleID], SRC.[PartnerID], SRC.[TypeID], SRC.[CommissionRate], SRC.[Status], SRC.[Priority], SRC.[CreationDate], SRC.[CreationStaffID], SRC.[DeletionDate], SRC.[DeletionStaffID], SRC.[MaximumUsesPerFan], SRC.[StartDate], SRC.[EndDate], SRC.[RequiredNumberOfPriorTransactions], SRC.[RequiredMinimumBasketSize], SRC.[RequiredMaximumBasketSize], SRC.[RequiredChannel], SRC.[RequiredBinRange], SRC.[RequiredClubID], SRC.[RequiredMinimumHourOfDay], SRC.[RequiredMaximumHourOfDay], SRC.[RequiredMerchantID], SRC.[RequiredIronOfferID], SRC.[RequiredRetailOutletID], SRC.[RequiredCardholderPresence], SRC.[CommissionAmount], SRC.[CommissionLimit], SRC.[CreatedDateTime], SRC.UpdatedDateTime) 
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
