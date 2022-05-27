
CREATE PROCEDURE [WHB].[PartnersOffers_Load_Offer]
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
		2.	Load to [Derived].[Offer]
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			2.1.	Load entries where [IronOfferID] is the [SourceOfferID]
		***************************************************************************************************************************************/
	
			;WITH
			Inbound_Offer_IronOfferID AS (	SELECT *
											FROM [Inbound].[Offer]
											WHERE [SourceOfferID] = 'IronOfferID')

			MERGE INTO [Derived].[Offer] AS TGT
			USING Inbound_Offer_IronOfferID AS SRC
				ON TGT.[SourceSystemID] = SRC.[SourceSystemID]
				AND TGT.[PartnerID] = SRC.[PartnerID]
				AND TGT.[IronOfferID] = SRC.[IronOfferID]

			WHEN MATCHED THEN 
			UPDATE SET	TGT.[SourceSystemID]		=	SRC.[SourceSystemID]
					,	TGT.[PublisherType]			=	SRC.[PublisherType]
					,	TGT.[PublisherID]			=	SRC.[PublisherID]
					,	TGT.[RetailerID]			=	SRC.[RetailerID]
					,	TGT.[PartnerID]				=	SRC.[PartnerID]
					,	TGT.[IronOfferID]			=	SRC.[IronOfferID]
					,	TGT.[OfferGUID]				=	SRC.[OfferGUID]
					,	TGT.[OfferCode]				=	SRC.[OfferCode]
					,	TGT.[CODOfferID]			=	SRC.[CODOfferID]
					,	TGT.[SourceOfferID]			=	SRC.[SourceOfferID]
					,	TGT.[StartDate]				=	SRC.[StartDate]
					,	TGT.[EndDate]				=	SRC.[EndDate]
					,	TGT.[CampaignCode]			=	SRC.[CampaignCode]
					,	TGT.[OfferName] 			=	SRC.[OfferName] 
					,	TGT.[OfferDescription]		=	SRC.[OfferDescription]
					,	TGT.[EarningChannel]		=	SRC.[EarningChannel]
					,	TGT.[EarningCount]			=	SRC.[EarningCount]
					,	TGT.[EarningType]			=	SRC.[EarningType]
					,	TGT.[EarningLimit]			=	SRC.[EarningLimit]
					,	TGT.[TopCashBackRate]		=	SRC.[TopCashBackRate]
					,	TGT.[BaseCashBackRate]		=	SRC.[BaseCashBackRate]
					,	TGT.[SpendStretchAmount_1]	=	SRC.[SpendStretchAmount_1]
					,	TGT.[SpendStretchRate_1]	=	SRC.[SpendStretchRate_1]
					,	TGT.[SpendStretchAmount_2]	=	SRC.[SpendStretchAmount_2]
					,	TGT.[SpendStretchRate_2]	=	SRC.[SpendStretchRate_2]
					,	TGT.[IsSignedOff]			=	SRC.[IsSignedOff]
					,	TGT.[ModifiedDate]			=	CASE
															WHEN CHECKSUM(TGT.[SourceSystemID], TGT.[PublisherType], TGT.[PublisherID], TGT.[RetailerID], TGT.[PartnerID], TGT.[IronOfferID], TGT.[OfferGUID], TGT.[OfferCode], TGT.[CODOfferID], TGT.[SourceOfferID], TGT.[StartDate], TGT.[EndDate], TGT.[CampaignCode], TGT.[OfferName] , TGT.[OfferDescription], TGT.[SegmentID], TGT.[SegmentName], TGT.[EarningChannel], TGT.[EarningCount], TGT.[EarningType], TGT.[EarningLimit], TGT.[TopCashBackRate], TGT.[BaseCashBackRate], TGT.[SpendStretchAmount_1], TGT.[SpendStretchRate_1], TGT.[SpendStretchAmount_2], TGT.[SpendStretchRate_2], TGT.[IsSignedOff]) != CHECKSUM(SRC.[SourceSystemID], SRC.[PublisherType], SRC.[PublisherID], SRC.[RetailerID], SRC.[PartnerID], SRC.[IronOfferID], SRC.[OfferGUID], SRC.[OfferCode], SRC.[CODOfferID], SRC.[SourceOfferID], SRC.[StartDate], SRC.[EndDate], SRC.[CampaignCode], SRC.[OfferName] , SRC.[OfferDescription], SRC.[SegmentID], SRC.[SegmentName], SRC.[EarningChannel], SRC.[EarningCount], SRC.[EarningType], SRC.[EarningLimit], SRC.[TopCashBackRate], SRC.[BaseCashBackRate], SRC.[SpendStretchAmount_1], SRC.[SpendStretchRate_1], SRC.[SpendStretchAmount_2], SRC.[SpendStretchRate_2], SRC.[IsSignedOff]) THEN GETDATE()
															ELSE TGT.[ModifiedDate]
														END

			WHEN NOT MATCHED THEN INSERT ([SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID], [SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName] , [OfferDescription], [SegmentID], [SegmentName], [EarningChannel], [EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1], [SpendStretchAmount_2], [SpendStretchRate_2], [SegmentCode], [SuperSegmentID], [SuperSegmentName], [OfferTypeID] , [OfferTypeDescription] ,[OfferTypeForReports], [IsSignedOff], [AddedDate], [ModifiedDate])
			VALUES ([SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID], [SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName] , [OfferDescription], [SegmentID], [SegmentName], [EarningChannel], [EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1], [SpendStretchAmount_2], [SpendStretchRate_2], [SegmentCode], [SuperSegmentID], [SuperSegmentName], [OfferTypeID] , [OfferTypeDescription] ,[OfferTypeForReports], [IsSignedOff], GETDATE(), GETDATE())
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
			SELECT	COALESCE(OBJECT_NAME(@@PROCID) + ' - IronOfferID', 'PartnersOffers_Load_Offer' + ' - IronOfferID')
				,	GETDATE()
				,	@Inserted
				,	@Updated
				,	@Deleted

			DELETE FROM @MergeCounts

		/***************************************************************************************************************************************
			2.2.	Load entries where [OfferGUID] is the [SourceOfferID]
		***************************************************************************************************************************************/
	
			;WITH
			Inbound_Offer_IronOfferID AS (	SELECT *
											FROM [Inbound].[Offer]
											WHERE [SourceOfferID] = 'OfferGUID')

			MERGE INTO [Derived].[Offer] AS TGT
			USING Inbound_Offer_IronOfferID AS SRC
				ON TGT.[SourceSystemID] = SRC.[SourceSystemID]
				AND TGT.[PartnerID] = SRC.[PartnerID]
				AND TGT.[OfferGUID] = SRC.[OfferGUID]

			WHEN MATCHED THEN 
			UPDATE SET	TGT.[SourceSystemID]		=	SRC.[SourceSystemID]
					,	TGT.[PublisherType]			=	SRC.[PublisherType]
					,	TGT.[PublisherID]			=	SRC.[PublisherID]
					,	TGT.[RetailerID]			=	SRC.[RetailerID]
					,	TGT.[PartnerID]				=	SRC.[PartnerID]
					,	TGT.[IronOfferID]			=	SRC.[IronOfferID]
					,	TGT.[OfferGUID]				=	SRC.[OfferGUID]
					,	TGT.[OfferCode]				=	SRC.[OfferCode]
					,	TGT.[CODOfferID]			=	SRC.[CODOfferID]
					,	TGT.[SourceOfferID]			=	SRC.[SourceOfferID]
					,	TGT.[StartDate]				=	SRC.[StartDate]
					,	TGT.[EndDate]				=	SRC.[EndDate]
					,	TGT.[CampaignCode]			=	SRC.[CampaignCode]
					,	TGT.[OfferName] 			=	SRC.[OfferName] 
					,	TGT.[OfferDescription]		=	SRC.[OfferDescription]
					,	TGT.[EarningChannel]		=	SRC.[EarningChannel]
					,	TGT.[EarningCount]			=	SRC.[EarningCount]
					,	TGT.[EarningType]			=	SRC.[EarningType]
					,	TGT.[EarningLimit]			=	SRC.[EarningLimit]
					,	TGT.[TopCashBackRate]		=	SRC.[TopCashBackRate]
					,	TGT.[BaseCashBackRate]		=	SRC.[BaseCashBackRate]
					,	TGT.[SpendStretchAmount_1]	=	SRC.[SpendStretchAmount_1]
					,	TGT.[SpendStretchRate_1]	=	SRC.[SpendStretchRate_1]
					,	TGT.[SpendStretchAmount_2]	=	SRC.[SpendStretchAmount_2]
					,	TGT.[SpendStretchRate_2]	=	SRC.[SpendStretchRate_2]
					,	TGT.[IsSignedOff]			=	SRC.[IsSignedOff]
					,	TGT.[ModifiedDate]			=	CASE
															WHEN CHECKSUM(TGT.[SourceSystemID], TGT.[PublisherType], TGT.[PublisherID], TGT.[RetailerID], TGT.[PartnerID], TGT.[IronOfferID], TGT.[OfferGUID], TGT.[OfferCode], TGT.[CODOfferID], TGT.[SourceOfferID], TGT.[StartDate], TGT.[EndDate], TGT.[CampaignCode], TGT.[OfferName] , TGT.[OfferDescription], TGT.[SegmentID], TGT.[SegmentName], TGT.[EarningChannel], TGT.[EarningCount], TGT.[EarningType], TGT.[EarningLimit], TGT.[TopCashBackRate], TGT.[BaseCashBackRate], TGT.[SpendStretchAmount_1], TGT.[SpendStretchRate_1], TGT.[SpendStretchAmount_2], TGT.[SpendStretchRate_2], TGT.[IsSignedOff]) != CHECKSUM(SRC.[SourceSystemID], SRC.[PublisherType], SRC.[PublisherID], SRC.[RetailerID], SRC.[PartnerID], SRC.[IronOfferID], SRC.[OfferGUID], SRC.[OfferCode], SRC.[CODOfferID], SRC.[SourceOfferID], SRC.[StartDate], SRC.[EndDate], SRC.[CampaignCode], SRC.[OfferName] , SRC.[OfferDescription], SRC.[SegmentID], SRC.[SegmentName], SRC.[EarningChannel], SRC.[EarningCount], SRC.[EarningType], SRC.[EarningLimit], SRC.[TopCashBackRate], SRC.[BaseCashBackRate], SRC.[SpendStretchAmount_1], SRC.[SpendStretchRate_1], SRC.[SpendStretchAmount_2], SRC.[SpendStretchRate_2], SRC.[IsSignedOff]) THEN GETDATE()
															ELSE TGT.[ModifiedDate]
														END

			WHEN NOT MATCHED THEN INSERT ([SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID], [SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName] , [OfferDescription], [SegmentID], [SegmentName], [EarningChannel], [EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1], [SpendStretchAmount_2], [SpendStretchRate_2], [SegmentCode], [SuperSegmentID], [SuperSegmentName], [OfferTypeID] , [OfferTypeDescription] ,[OfferTypeForReports], [IsSignedOff], [AddedDate], [ModifiedDate])
			VALUES ([SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID], [SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName] , [OfferDescription], [SegmentID], [SegmentName], [EarningChannel], [EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1], [SpendStretchAmount_2], [SpendStretchRate_2], [SegmentCode], [SuperSegmentID], [SuperSegmentName], [OfferTypeID] , [OfferTypeDescription] ,[OfferTypeForReports], [IsSignedOff], GETDATE(), GETDATE())
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
			SELECT	COALESCE(OBJECT_NAME(@@PROCID) + ' - OfferGUID', 'PartnersOffers_Load_Offer' + ' - OfferGUID')
				,	GETDATE()
				,	@Inserted
				,	@Updated
				,	@Deleted

			DELETE FROM @MergeCounts

		/***************************************************************************************************************************************
			2.3.	Load entries where [OfferCode] is the [SourceOfferID]
		***************************************************************************************************************************************/
	
			;WITH
			Inbound_Offer_IronOfferID AS (	SELECT *
											FROM [Inbound].[Offer]
											WHERE [SourceOfferID] = 'OfferCode')

			MERGE INTO [Derived].[Offer] AS TGT
			USING Inbound_Offer_IronOfferID AS SRC
				ON TGT.[SourceSystemID] = SRC.[SourceSystemID]
				AND TGT.[PartnerID] = SRC.[PartnerID]
				AND TGT.[OfferCode] = SRC.[OfferCode]

			WHEN MATCHED THEN 
			UPDATE SET	TGT.[SourceSystemID]		=	SRC.[SourceSystemID]
					,	TGT.[PublisherType]			=	SRC.[PublisherType]
					,	TGT.[PublisherID]			=	SRC.[PublisherID]
					,	TGT.[RetailerID]			=	SRC.[RetailerID]
					,	TGT.[PartnerID]				=	SRC.[PartnerID]
					,	TGT.[IronOfferID]			=	SRC.[IronOfferID]
					,	TGT.[OfferGUID]				=	SRC.[OfferGUID]
					,	TGT.[OfferCode]				=	SRC.[OfferCode]
					,	TGT.[CODOfferID]			=	SRC.[CODOfferID]
					,	TGT.[SourceOfferID]			=	SRC.[SourceOfferID]
					,	TGT.[StartDate]				=	SRC.[StartDate]
					,	TGT.[EndDate]				=	SRC.[EndDate]
					,	TGT.[CampaignCode]			=	SRC.[CampaignCode]
					,	TGT.[OfferName] 			=	SRC.[OfferName] 
					,	TGT.[OfferDescription]		=	SRC.[OfferDescription]
					,	TGT.[EarningChannel]		=	SRC.[EarningChannel]
					,	TGT.[EarningCount]			=	SRC.[EarningCount]
					,	TGT.[EarningType]			=	SRC.[EarningType]
					,	TGT.[EarningLimit]			=	SRC.[EarningLimit]
					,	TGT.[TopCashBackRate]		=	SRC.[TopCashBackRate]
					,	TGT.[BaseCashBackRate]		=	SRC.[BaseCashBackRate]
					,	TGT.[SpendStretchAmount_1]	=	SRC.[SpendStretchAmount_1]
					,	TGT.[SpendStretchRate_1]	=	SRC.[SpendStretchRate_1]
					,	TGT.[SpendStretchAmount_2]	=	SRC.[SpendStretchAmount_2]
					,	TGT.[SpendStretchRate_2]	=	SRC.[SpendStretchRate_2]
					,	TGT.[IsSignedOff]			=	SRC.[IsSignedOff]
					,	TGT.[ModifiedDate]			=	CASE
															WHEN CHECKSUM(TGT.[SourceSystemID], TGT.[PublisherType], TGT.[PublisherID], TGT.[RetailerID], TGT.[PartnerID], TGT.[IronOfferID], TGT.[OfferGUID], TGT.[OfferCode], TGT.[CODOfferID], TGT.[SourceOfferID], TGT.[StartDate], TGT.[EndDate], TGT.[CampaignCode], TGT.[OfferName] , TGT.[OfferDescription], TGT.[SegmentID], TGT.[SegmentName], TGT.[EarningChannel], TGT.[EarningCount], TGT.[EarningType], TGT.[EarningLimit], TGT.[TopCashBackRate], TGT.[BaseCashBackRate], TGT.[SpendStretchAmount_1], TGT.[SpendStretchRate_1], TGT.[SpendStretchAmount_2], TGT.[SpendStretchRate_2], TGT.[IsSignedOff]) != CHECKSUM(SRC.[SourceSystemID], SRC.[PublisherType], SRC.[PublisherID], SRC.[RetailerID], SRC.[PartnerID], SRC.[IronOfferID], SRC.[OfferGUID], SRC.[OfferCode], SRC.[CODOfferID], SRC.[SourceOfferID], SRC.[StartDate], SRC.[EndDate], SRC.[CampaignCode], SRC.[OfferName] , SRC.[OfferDescription], SRC.[SegmentID], SRC.[SegmentName], SRC.[EarningChannel], SRC.[EarningCount], SRC.[EarningType], SRC.[EarningLimit], SRC.[TopCashBackRate], SRC.[BaseCashBackRate], SRC.[SpendStretchAmount_1], SRC.[SpendStretchRate_1], SRC.[SpendStretchAmount_2], SRC.[SpendStretchRate_2], SRC.[IsSignedOff]) THEN GETDATE()
															ELSE TGT.[ModifiedDate]
														END

			WHEN NOT MATCHED THEN INSERT ([SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID], [SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName] , [OfferDescription], [SegmentID], [SegmentName], [EarningChannel], [EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1], [SpendStretchAmount_2], [SpendStretchRate_2], [SegmentCode], [SuperSegmentID], [SuperSegmentName], [OfferTypeID] , [OfferTypeDescription] ,[OfferTypeForReports], [IsSignedOff], [AddedDate], [ModifiedDate])
			VALUES ([SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID], [SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName] , [OfferDescription], [SegmentID], [SegmentName], [EarningChannel], [EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1], [SpendStretchAmount_2], [SpendStretchRate_2], [SegmentCode], [SuperSegmentID], [SuperSegmentName], [OfferTypeID] , [OfferTypeDescription] ,[OfferTypeForReports], [IsSignedOff], GETDATE(), GETDATE())
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
			SELECT	COALESCE(OBJECT_NAME(@@PROCID) + ' - OfferCode', 'PartnersOffers_Load_Offer' + ' - OfferCode')
				,	GETDATE()
				,	@Inserted
				,	@Updated
				,	@Deleted

			DELETE FROM @MergeCounts

		/***************************************************************************************************************************************
			2.4.	Load entries where [CODOfferID] is the [SourceOfferID]
		***************************************************************************************************************************************/
	
			;WITH
			Inbound_Offer_IronOfferID AS (	SELECT *
											FROM [Inbound].[Offer]
											WHERE [SourceOfferID] = 'CODOfferID')

			MERGE INTO [Derived].[Offer] AS TGT
			USING Inbound_Offer_IronOfferID AS SRC
				ON TGT.[SourceSystemID] = SRC.[SourceSystemID]
				AND TGT.[PartnerID] = SRC.[PartnerID]
				AND TGT.[CODOfferID] = SRC.[CODOfferID]

			WHEN MATCHED THEN 
			UPDATE SET	TGT.[SourceSystemID]		=	SRC.[SourceSystemID]
					,	TGT.[PublisherType]			=	SRC.[PublisherType]
					,	TGT.[PublisherID]			=	SRC.[PublisherID]
					,	TGT.[RetailerID]			=	SRC.[RetailerID]
					,	TGT.[PartnerID]				=	SRC.[PartnerID]
					,	TGT.[IronOfferID]			=	SRC.[IronOfferID]
					,	TGT.[OfferGUID]				=	SRC.[OfferGUID]
					,	TGT.[OfferCode]				=	SRC.[OfferCode]
					,	TGT.[CODOfferID]			=	SRC.[CODOfferID]
					,	TGT.[SourceOfferID]			=	SRC.[SourceOfferID]
					,	TGT.[StartDate]				=	SRC.[StartDate]
					,	TGT.[EndDate]				=	SRC.[EndDate]
					,	TGT.[CampaignCode]			=	SRC.[CampaignCode]
					,	TGT.[OfferName] 			=	SRC.[OfferName] 
					,	TGT.[OfferDescription]		=	SRC.[OfferDescription]
					,	TGT.[EarningChannel]		=	SRC.[EarningChannel]
					,	TGT.[EarningCount]			=	SRC.[EarningCount]
					,	TGT.[EarningType]			=	SRC.[EarningType]
					,	TGT.[EarningLimit]			=	SRC.[EarningLimit]
					,	TGT.[TopCashBackRate]		=	SRC.[TopCashBackRate]
					,	TGT.[BaseCashBackRate]		=	SRC.[BaseCashBackRate]
					,	TGT.[SpendStretchAmount_1]	=	SRC.[SpendStretchAmount_1]
					,	TGT.[SpendStretchRate_1]	=	SRC.[SpendStretchRate_1]
					,	TGT.[SpendStretchAmount_2]	=	SRC.[SpendStretchAmount_2]
					,	TGT.[SpendStretchRate_2]	=	SRC.[SpendStretchRate_2]
					,	TGT.[IsSignedOff]			=	SRC.[IsSignedOff]
					,	TGT.[ModifiedDate]			=	CASE
															WHEN CHECKSUM(TGT.[SourceSystemID], TGT.[PublisherType], TGT.[PublisherID], TGT.[RetailerID], TGT.[PartnerID], TGT.[IronOfferID], TGT.[OfferGUID], TGT.[OfferCode], TGT.[CODOfferID], TGT.[SourceOfferID], TGT.[StartDate], TGT.[EndDate], TGT.[CampaignCode], TGT.[OfferName] , TGT.[OfferDescription], TGT.[SegmentID], TGT.[SegmentName], TGT.[EarningChannel], TGT.[EarningCount], TGT.[EarningType], TGT.[EarningLimit], TGT.[TopCashBackRate], TGT.[BaseCashBackRate], TGT.[SpendStretchAmount_1], TGT.[SpendStretchRate_1], TGT.[SpendStretchAmount_2], TGT.[SpendStretchRate_2], TGT.[IsSignedOff]) != CHECKSUM(SRC.[SourceSystemID], SRC.[PublisherType], SRC.[PublisherID], SRC.[RetailerID], SRC.[PartnerID], SRC.[IronOfferID], SRC.[OfferGUID], SRC.[OfferCode], SRC.[CODOfferID], SRC.[SourceOfferID], SRC.[StartDate], SRC.[EndDate], SRC.[CampaignCode], SRC.[OfferName] , SRC.[OfferDescription], SRC.[SegmentID], SRC.[SegmentName], SRC.[EarningChannel], SRC.[EarningCount], SRC.[EarningType], SRC.[EarningLimit], SRC.[TopCashBackRate], SRC.[BaseCashBackRate], SRC.[SpendStretchAmount_1], SRC.[SpendStretchRate_1], SRC.[SpendStretchAmount_2], SRC.[SpendStretchRate_2], SRC.[IsSignedOff]) THEN GETDATE()
															ELSE TGT.[ModifiedDate]
														END

			WHEN NOT MATCHED THEN INSERT ([SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID], [SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName] , [OfferDescription], [SegmentID], [SegmentName], [EarningChannel], [EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1], [SpendStretchAmount_2], [SpendStretchRate_2], [SegmentCode], [SuperSegmentID], [SuperSegmentName], [OfferTypeID] , [OfferTypeDescription] ,[OfferTypeForReports], [IsSignedOff], [AddedDate], [ModifiedDate])
			VALUES ([SourceSystemID], [PublisherType], [PublisherID], [RetailerID], [PartnerID], [IronOfferID], [OfferGUID], [OfferCode], [CODOfferID], [SourceOfferID], [StartDate], [EndDate], [CampaignCode], [OfferName] , [OfferDescription], [SegmentID], [SegmentName], [EarningChannel], [EarningCount], [EarningType], [EarningLimit], [TopCashBackRate], [BaseCashBackRate], [SpendStretchAmount_1], [SpendStretchRate_1], [SpendStretchAmount_2], [SpendStretchRate_2], [SegmentCode], [SuperSegmentID], [SuperSegmentName], [OfferTypeID] , [OfferTypeDescription] ,[OfferTypeForReports], [IsSignedOff], GETDATE(), GETDATE())
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
			SELECT	COALESCE(OBJECT_NAME(@@PROCID) + ' - OfferCode', 'PartnersOffers_Load_Offer' + ' - CODOfferID')
				,	GETDATE()
				,	@Inserted
				,	@Updated
				,	@Deleted

			DELETE FROM @MergeCounts

END