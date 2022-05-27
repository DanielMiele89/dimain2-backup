
CREATE PROCEDURE [WHB].[Customers_Load_Customer]
AS
BEGIN

		SET XACT_ABORT ON;

	/*******************************************************************************************************************************************
		1.	Declare variables
	*******************************************************************************************************************************************/

		DECLARE @MergeCounts TABLE(MergeAction VARCHAR(20))
		
		DECLARE	@Inserted INT
			,	@Updated INT
			,	@Deleted INT 

	/*******************************************************************************************************************************************
		2.	Load to [Derived].[Customer]
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			2.1.	Load entries where [FanID] is the [SourceCustomerID]
		***************************************************************************************************************************************/

			;WITH
			Inbound_Customer_FanID AS (	SELECT *
										FROM [Inbound].[Customer]
										WHERE [SourceCustomerID] = 'FanID')

			MERGE INTO [Derived].[Customer] AS TGT
			USING Inbound_Customer_FanID AS SRC
				ON TGT.[SourceSystemID] = SRC.[SourceSystemID]
				AND TGT.[PublisherID] = SRC.[PublisherID]
				AND TGT.[FanID] = SRC.[FanID]
				
			WHEN MATCHED THEN 
			UPDATE SET	TGT.[SourceSystemID]		=	SRC.[SourceSystemID]
					,	TGT.[PublisherType]			=	SRC.[PublisherType]
					,	TGT.[PublisherID]			=	SRC.[PublisherID]
					,	TGT.[FanID]					=	SRC.[FanID]
					,	TGT.[CustomerGUID]			=	SRC.[CustomerGUID]
					,	TGT.[CompositeID]			=	SRC.[CompositeID]
					,	TGT.[SourceUID]				=	SRC.[SourceUID]
					,	TGT.[CINID]					=	SRC.[CINID]
					,	TGT.[SourceCustomerID]		=	SRC.[SourceCustomerID]
					,	TGT.[AccountType]			=	SRC.[AccountType]
					,	TGT.[Title]					=	SRC.[Title]
					,	TGT.[City]					=	SRC.[City]
					,	TGT.[County]				=	SRC.[County]
					,	TGT.[Region]				=	SRC.[Region]
					,	TGT.[PostalSector]			=	SRC.[PostalSector]
					,	TGT.[PostCodeDistrict]		=	SRC.[PostCodeDistrict]
					,	TGT.[PostArea]				=	SRC.[PostArea]
					,	TGT.[CAMEOCode]				=	SRC.[CAMEOCode]
					,	TGT.[Gender]				=	SRC.[Gender]
					,	TGT.[AgeCurrent]			=	SRC.[AgeCurrent]
					,	TGT.[AgeCurrentBandText]	=	SRC.[AgeCurrentBandText]
					,	TGT.[CashbackPending]		=	SRC.[CashbackPending]
					,	TGT.[CashbackAvailable]		=	SRC.[CashbackAvailable]
					,	TGT.[CashbackLTV]			=	SRC.[CashbackLTV]
					,	TGT.[Unsubscribed]			=	SRC.[Unsubscribed]
					,	TGT.[Hardbounced]			=	SRC.[Hardbounced]
					,	TGT.[EmailTracking]			=	SRC.[EmailTracking]
					,	TGT.[MarketableByEmail]		=	SRC.[MarketableByEmail]
					,	TGT.[MarketableByPush]		=	SRC.[MarketableByPush]
					,	TGT.[CurrentlyActive]		=	SRC.[CurrentlyActive]
					,	TGT.[RegistrationDate]		=	SRC.[RegistrationDate]
					,	TGT.[DeactivatedDate]		=	SRC.[DeactivatedDate]
					,	TGT.[ModifiedDate]			=	CASE
															WHEN CHECKSUM(TGT.[SourceSystemID], TGT.[PublisherType], TGT.[PublisherID], TGT.[FanID], TGT.[CustomerGUID], TGT.[CompositeID], TGT.[SourceUID], TGT.[CINID], TGT.[SourceCustomerID], TGT.[AccountType], TGT.[Title], TGT.[City], TGT.[County], TGT.[Region], TGT.[PostalSector], TGT.[PostCodeDistrict], TGT.[PostArea], TGT.[CAMEOCode], TGT.[Gender], TGT.[AgeCurrent], TGT.[AgeCurrentBandText], TGT.[CashbackPending], TGT.[CashbackAvailable], TGT.[CashbackLTV], TGT.[Unsubscribed], TGT.[Hardbounced], TGT.[EmailTracking], TGT.[MarketableByEmail], TGT.[MarketableByPush], TGT.[CurrentlyActive], TGT.[RegistrationDate], TGT.[DeactivatedDate]) != CHECKSUM(SRC.[SourceSystemID], SRC.[PublisherType], SRC.[PublisherID], SRC.[FanID], SRC.[CustomerGUID], SRC.[CompositeID], SRC.[SourceUID], SRC.[CINID], SRC.[SourceCustomerID], SRC.[AccountType], SRC.[Title], SRC.[City], SRC.[County], SRC.[Region], SRC.[PostalSector], SRC.[PostCodeDistrict], SRC.[PostArea], SRC.[CAMEOCode], SRC.[Gender], SRC.[AgeCurrent], SRC.[AgeCurrentBandText], SRC.[CashbackPending], SRC.[CashbackAvailable], SRC.[CashbackLTV], SRC.[Unsubscribed], SRC.[Hardbounced], SRC.[EmailTracking], SRC.[MarketableByEmail], SRC.[MarketableByPush], SRC.[CurrentlyActive], SRC.[RegistrationDate], SRC.[DeactivatedDate]) THEN GETDATE()
															ELSE TGT.[ModifiedDate]
														END

			WHEN NOT MATCHED THEN INSERT ([SourceSystemID], [PublisherType], [PublisherID], [FanID], [CustomerGUID], [CompositeID], [SourceUID], [CINID], [SourceCustomerID], [AccountType], [Title], [City], [County], [Region], [PostalSector], [PostCodeDistrict], [PostArea], [CAMEOCode], [Gender], [AgeCurrent], [AgeCurrentBandText], [CashbackPending], [CashbackAvailable], [CashbackLTV], [Unsubscribed], [Hardbounced], [EmailTracking], [MarketableByEmail], [MarketableByPush], [CurrentlyActive], [RegistrationDate], [DeactivatedDate], [AddedDate], [ModifiedDate])
			VALUES ([SourceSystemID], [PublisherType], [PublisherID], [FanID], [CustomerGUID], [CompositeID], [SourceUID], [CINID], [SourceCustomerID], [AccountType], [Title], [City], [County], [Region], [PostalSector], [PostCodeDistrict], [PostArea], [CAMEOCode], [Gender], [AgeCurrent], [AgeCurrentBandText], [CashbackPending], [CashbackAvailable], [CashbackLTV], [Unsubscribed], [Hardbounced], [EmailTracking], [MarketableByEmail], [MarketableByPush], [CurrentlyActive], [RegistrationDate], [DeactivatedDate], GETDATE(), GETDATE())
			OUTPUT $action
			INTO @MergeCounts;
	
			;WITH
			MergeActions AS (	SELECT	MergeAction
									,	COUNT(*) As Total
								FROM @MergeCounts
								GROUP BY MergeAction)
			SELECT	@Inserted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'INSERT')
				,	@Updated = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'UPDATE')
				,	@Deleted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'DELETE')

			INSERT INTO [dbo].[WarehouseLoadAudit] (ProcName
												,	RunDateTime
												,	RowsInserted
												,	RowsUpdated
												,	RowsDeleted)
			SELECT	COALESCE(OBJECT_NAME(@@PROCID) + ' - FanID', 'Customers_Load_Customer' + ' - FanID')
				,	GETDATE()
				,	@Inserted
				,	@Updated
				,	@Deleted

			DELETE FROM @MergeCounts


		/***************************************************************************************************************************************
			2.2.	Load entries where [CustomerGUID] is the [SourceCustomerID]
		***************************************************************************************************************************************/

			;WITH
			Inbound_Customer_FanID AS (	SELECT *
										FROM [Inbound].[Customer]
										WHERE [SourceCustomerID] = 'CustomerGUID')

			MERGE INTO [Derived].[Customer] AS TGT
			USING Inbound_Customer_FanID AS SRC
				ON TGT.[SourceSystemID] = SRC.[SourceSystemID]
				AND TGT.[PublisherID] = SRC.[PublisherID]
				AND TGT.[CustomerGUID] = SRC.[CustomerGUID]

			WHEN MATCHED THEN 
			UPDATE SET	TGT.[SourceSystemID]		=	SRC.[SourceSystemID]
					,	TGT.[PublisherType]			=	SRC.[PublisherType]
					,	TGT.[PublisherID]			=	SRC.[PublisherID]
					,	TGT.[FanID]					=	SRC.[FanID]
					,	TGT.[CustomerGUID]			=	SRC.[CustomerGUID]
					,	TGT.[CompositeID]			=	SRC.[CompositeID]
					,	TGT.[SourceUID]				=	SRC.[SourceUID]
					,	TGT.[CINID]					=	SRC.[CINID]
					,	TGT.[SourceCustomerID]		=	SRC.[SourceCustomerID]
					,	TGT.[AccountType]			=	SRC.[AccountType]
					,	TGT.[Title]					=	SRC.[Title]
					,	TGT.[City]					=	SRC.[City]
					,	TGT.[County]				=	SRC.[County]
					,	TGT.[Region]				=	SRC.[Region]
					,	TGT.[PostalSector]			=	SRC.[PostalSector]
					,	TGT.[PostCodeDistrict]		=	SRC.[PostCodeDistrict]
					,	TGT.[PostArea]				=	SRC.[PostArea]
					,	TGT.[CAMEOCode]				=	SRC.[CAMEOCode]
					,	TGT.[Gender]				=	SRC.[Gender]
					,	TGT.[AgeCurrent]			=	SRC.[AgeCurrent]
					,	TGT.[AgeCurrentBandText]	=	SRC.[AgeCurrentBandText]
					,	TGT.[CashbackPending]		=	SRC.[CashbackPending]
					,	TGT.[CashbackAvailable]		=	SRC.[CashbackAvailable]
					,	TGT.[CashbackLTV]			=	SRC.[CashbackLTV]
					,	TGT.[Unsubscribed]			=	SRC.[Unsubscribed]
					,	TGT.[Hardbounced]			=	SRC.[Hardbounced]
					,	TGT.[EmailTracking]			=	SRC.[EmailTracking]
					,	TGT.[MarketableByEmail]		=	SRC.[MarketableByEmail]
					,	TGT.[MarketableByPush]		=	SRC.[MarketableByPush]
					,	TGT.[CurrentlyActive]		=	SRC.[CurrentlyActive]
					,	TGT.[RegistrationDate]		=	SRC.[RegistrationDate]
					,	TGT.[DeactivatedDate]		=	SRC.[DeactivatedDate]
					,	TGT.[ModifiedDate]			=	CASE
															WHEN CHECKSUM(TGT.[SourceSystemID], TGT.[PublisherType], TGT.[PublisherID], TGT.[FanID], TGT.[CustomerGUID], TGT.[CompositeID], TGT.[SourceUID], TGT.[CINID], TGT.[SourceCustomerID], TGT.[AccountType], TGT.[Title], TGT.[City], TGT.[County], TGT.[Region], TGT.[PostalSector], TGT.[PostCodeDistrict], TGT.[PostArea], TGT.[CAMEOCode], TGT.[Gender], TGT.[AgeCurrent], TGT.[AgeCurrentBandText], TGT.[CashbackPending], TGT.[CashbackAvailable], TGT.[CashbackLTV], TGT.[Unsubscribed], TGT.[Hardbounced], TGT.[EmailTracking], TGT.[MarketableByEmail], TGT.[MarketableByPush], TGT.[CurrentlyActive], TGT.[RegistrationDate], TGT.[DeactivatedDate]) != CHECKSUM(SRC.[SourceSystemID], SRC.[PublisherType], SRC.[PublisherID], SRC.[FanID], SRC.[CustomerGUID], SRC.[CompositeID], SRC.[SourceUID], SRC.[CINID], SRC.[SourceCustomerID], SRC.[AccountType], SRC.[Title], SRC.[City], SRC.[County], SRC.[Region], SRC.[PostalSector], SRC.[PostCodeDistrict], SRC.[PostArea], SRC.[CAMEOCode], SRC.[Gender], SRC.[AgeCurrent], SRC.[AgeCurrentBandText], SRC.[CashbackPending], SRC.[CashbackAvailable], SRC.[CashbackLTV], SRC.[Unsubscribed], SRC.[Hardbounced], SRC.[EmailTracking], SRC.[MarketableByEmail], SRC.[MarketableByPush], SRC.[CurrentlyActive], SRC.[RegistrationDate], SRC.[DeactivatedDate]) THEN GETDATE()
															ELSE TGT.[ModifiedDate]
														END

			WHEN NOT MATCHED THEN INSERT ([SourceSystemID], [PublisherType], [PublisherID], [FanID], [CustomerGUID], [CompositeID], [SourceUID], [CINID], [SourceCustomerID], [AccountType], [Title], [City], [County], [Region], [PostalSector], [PostCodeDistrict], [PostArea], [CAMEOCode], [Gender], [AgeCurrent], [AgeCurrentBandText], [CashbackPending], [CashbackAvailable], [CashbackLTV], [Unsubscribed], [Hardbounced], [EmailTracking], [MarketableByEmail], [MarketableByPush], [CurrentlyActive], [RegistrationDate], [DeactivatedDate], [AddedDate], [ModifiedDate])
			VALUES ([SourceSystemID], [PublisherType], [PublisherID], [FanID], [CustomerGUID], [CompositeID], [SourceUID], [CINID], [SourceCustomerID], [AccountType], [Title], [City], [County], [Region], [PostalSector], [PostCodeDistrict], [PostArea], [CAMEOCode], [Gender], [AgeCurrent], [AgeCurrentBandText], [CashbackPending], [CashbackAvailable], [CashbackLTV], [Unsubscribed], [Hardbounced], [EmailTracking], [MarketableByEmail], [MarketableByPush], [CurrentlyActive], [RegistrationDate], [DeactivatedDate], GETDATE(), GETDATE())
			OUTPUT $action
			INTO @MergeCounts;
	
			;WITH
			MergeActions AS (	SELECT	MergeAction
									,	COUNT(*) As Total
								FROM @MergeCounts
								GROUP BY MergeAction)
			SELECT	@Inserted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'INSERT')
				,	@Updated = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'UPDATE')
				,	@Deleted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'DELETE')

			INSERT INTO [dbo].[WarehouseLoadAudit] (ProcName
												,	RunDateTime
												,	RowsInserted
												,	RowsUpdated
												,	RowsDeleted)
			SELECT	COALESCE(OBJECT_NAME(@@PROCID) + ' - CustomerGUID', 'Customers_Load_Customer' + ' - CustomerGUID')
				,	GETDATE()
				,	@Inserted
				,	@Updated
				,	@Deleted

			DELETE FROM @MergeCounts


		/***************************************************************************************************************************************
			2.3.	Load entries where [SourceUID] is the [SourceCustomerID]
		***************************************************************************************************************************************/

			;WITH
			Inbound_Customer_FanID AS (	SELECT *
										FROM [Inbound].[Customer]
										WHERE [SourceCustomerID] = 'SourceUID')

			MERGE INTO [Derived].[Customer] AS TGT
			USING Inbound_Customer_FanID AS SRC
				ON TGT.[SourceSystemID] = SRC.[SourceSystemID]
				AND TGT.[PublisherID] = SRC.[PublisherID]
				AND TGT.[SourceUID] = SRC.[SourceUID]

			WHEN MATCHED THEN 
			UPDATE SET	TGT.[SourceSystemID]		=	SRC.[SourceSystemID]
					,	TGT.[PublisherType]			=	SRC.[PublisherType]
					,	TGT.[PublisherID]			=	SRC.[PublisherID]
					,	TGT.[FanID]					=	SRC.[FanID]
					,	TGT.[CustomerGUID]			=	SRC.[CustomerGUID]
					,	TGT.[CompositeID]			=	SRC.[CompositeID]
					,	TGT.[SourceUID]				=	SRC.[SourceUID]
					,	TGT.[CINID]					=	SRC.[CINID]
					,	TGT.[SourceCustomerID]		=	SRC.[SourceCustomerID]
					,	TGT.[AccountType]			=	SRC.[AccountType]
					,	TGT.[Title]					=	SRC.[Title]
					,	TGT.[City]					=	SRC.[City]
					,	TGT.[County]				=	SRC.[County]
					,	TGT.[Region]				=	SRC.[Region]
					,	TGT.[PostalSector]			=	SRC.[PostalSector]
					,	TGT.[PostCodeDistrict]		=	SRC.[PostCodeDistrict]
					,	TGT.[PostArea]				=	SRC.[PostArea]
					,	TGT.[CAMEOCode]				=	SRC.[CAMEOCode]
					,	TGT.[Gender]				=	SRC.[Gender]
					,	TGT.[AgeCurrent]			=	SRC.[AgeCurrent]
					,	TGT.[AgeCurrentBandText]	=	SRC.[AgeCurrentBandText]
					,	TGT.[CashbackPending]		=	SRC.[CashbackPending]
					,	TGT.[CashbackAvailable]		=	SRC.[CashbackAvailable]
					,	TGT.[CashbackLTV]			=	SRC.[CashbackLTV]
					,	TGT.[Unsubscribed]			=	SRC.[Unsubscribed]
					,	TGT.[Hardbounced]			=	SRC.[Hardbounced]
					,	TGT.[EmailTracking]			=	SRC.[EmailTracking]
					,	TGT.[MarketableByEmail]		=	SRC.[MarketableByEmail]
					,	TGT.[MarketableByPush]		=	SRC.[MarketableByPush]
					,	TGT.[CurrentlyActive]		=	SRC.[CurrentlyActive]
					,	TGT.[RegistrationDate]		=	SRC.[RegistrationDate]
					,	TGT.[DeactivatedDate]		=	SRC.[DeactivatedDate]
					,	TGT.[ModifiedDate]			=	CASE
															WHEN CHECKSUM(TGT.[SourceSystemID], TGT.[PublisherType], TGT.[PublisherID], TGT.[FanID], TGT.[CustomerGUID], TGT.[CompositeID], TGT.[SourceUID], TGT.[CINID], TGT.[SourceCustomerID], TGT.[AccountType], TGT.[Title], TGT.[City], TGT.[County], TGT.[Region], TGT.[PostalSector], TGT.[PostCodeDistrict], TGT.[PostArea], TGT.[CAMEOCode], TGT.[Gender], TGT.[AgeCurrent], TGT.[AgeCurrentBandText], TGT.[CashbackPending], TGT.[CashbackAvailable], TGT.[CashbackLTV], TGT.[Unsubscribed], TGT.[Hardbounced], TGT.[EmailTracking], TGT.[MarketableByEmail], TGT.[MarketableByPush], TGT.[CurrentlyActive], TGT.[RegistrationDate], TGT.[DeactivatedDate]) != CHECKSUM(SRC.[SourceSystemID], SRC.[PublisherType], SRC.[PublisherID], SRC.[FanID], SRC.[CustomerGUID], SRC.[CompositeID], SRC.[SourceUID], SRC.[CINID], SRC.[SourceCustomerID], SRC.[AccountType], SRC.[Title], SRC.[City], SRC.[County], SRC.[Region], SRC.[PostalSector], SRC.[PostCodeDistrict], SRC.[PostArea], SRC.[CAMEOCode], SRC.[Gender], SRC.[AgeCurrent], SRC.[AgeCurrentBandText], SRC.[CashbackPending], SRC.[CashbackAvailable], SRC.[CashbackLTV], SRC.[Unsubscribed], SRC.[Hardbounced], SRC.[EmailTracking], SRC.[MarketableByEmail], SRC.[MarketableByPush], SRC.[CurrentlyActive], SRC.[RegistrationDate], SRC.[DeactivatedDate]) THEN GETDATE()
															ELSE TGT.[ModifiedDate]
														END

			WHEN NOT MATCHED THEN INSERT ([SourceSystemID], [PublisherType], [PublisherID], [FanID], [CustomerGUID], [CompositeID], [SourceUID], [CINID], [SourceCustomerID], [AccountType], [Title], [City], [County], [Region], [PostalSector], [PostCodeDistrict], [PostArea], [CAMEOCode], [Gender], [AgeCurrent], [AgeCurrentBandText], [CashbackPending], [CashbackAvailable], [CashbackLTV], [Unsubscribed], [Hardbounced], [EmailTracking], [MarketableByEmail], [MarketableByPush], [CurrentlyActive], [RegistrationDate], [DeactivatedDate], [AddedDate], [ModifiedDate])
			VALUES ([SourceSystemID], [PublisherType], [PublisherID], [FanID], [CustomerGUID], [CompositeID], [SourceUID], [CINID], [SourceCustomerID], [AccountType], [Title], [City], [County], [Region], [PostalSector], [PostCodeDistrict], [PostArea], [CAMEOCode], [Gender], [AgeCurrent], [AgeCurrentBandText], [CashbackPending], [CashbackAvailable], [CashbackLTV], [Unsubscribed], [Hardbounced], [EmailTracking], [MarketableByEmail], [MarketableByPush], [CurrentlyActive], [RegistrationDate], [DeactivatedDate], GETDATE(), GETDATE())
			OUTPUT $action
			INTO @MergeCounts;
	
			;WITH
			MergeActions AS (	SELECT	MergeAction
									,	COUNT(*) As Total
								FROM @MergeCounts
								GROUP BY MergeAction)
			SELECT	@Inserted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'INSERT')
				,	@Updated = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'UPDATE')
				,	@Deleted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'DELETE')

			INSERT INTO [dbo].[WarehouseLoadAudit] (ProcName
												,	RunDateTime
												,	RowsInserted
												,	RowsUpdated
												,	RowsDeleted)
			SELECT	COALESCE(OBJECT_NAME(@@PROCID) + ' - SourceUID', 'Customers_Load_Customer' + ' - SourceUID')
				,	GETDATE()
				,	@Inserted
				,	@Updated
				,	@Deleted

			DELETE FROM @MergeCounts

END