
--EXEC   [WHB].[RBS_WarehouseOffer_Load]

CREATE PROC [WHB].[__RBS_WarehouseOffer_Load]
AS

 SET XACT_ABORT ON;

 DECLARE @MergeCounts TABLE(MergeAction VARCHAR(20))
 DECLARE @SourceType INT = 2

 MERGE INTO [WH_AllPublishers].[dbo].[Offer] AS TGT
 USING [WH_AllPublishers].[Inbound].[RBS_IronOffer] AS SRC
	ON TGT.SourceTypeID = @SourceType
	AND TGT.SourceID = CAST(SRC.[IronOfferID] AS VARCHAR(36))
	and TGT.[ClubID] = SRC.[ClubID]
WHEN MATCHED THEN 
	UPDATE SET
	 TGT.[OfferName]		= SRC.[IronOfferName]
	,TGT.[ClubID]			= SRC.[ClubID]
	,TGT.[PublisherID]		= SRC.[ClubID]
	,TGT.[StartDateTime]	= SRC.[StartDate]
	,TGT.[EndDateTime]		= SRC.[EndDate]
	,TGT.[PartnerID]		= SRC.[PartnerID]
	,TGT.[RetailerID]		= SRC.[PartnerID]
	,TGT.[CampaignType]		= SRC.[CampaignType]
	,TGT.[SegmentName]		= SRC.[SegmentName]
	,TGT.[SourceID]			= CAST(src.[IronOfferID] AS VARCHAR(36))
	,TGT.[SourceTypeID]		= @SourceType
	,TGT.[UpdatedDateTime]	= GETDATE()
WHEN NOT MATCHED THEN
	INSERT ([OfferName], [ClubID], [PublisherID], [StartDateTime], [EndDateTime], [PartnerID], [RetailerID], [CampaignType], [SegmentName], [SourceID], [SourceTypeID], [CreatedDateTime], [UpdatedDateTime])
	VALUES ([IronOfferName],  [ClubID], [ClubID], [StartDate], [EndDate], [PartnerID], [PartnerID], [CampaignType], [SegmentName], CAST(src.[IronOfferID] AS VARCHAR(36)), @SourceType, GETDATE(), GETDATE())
 OUTPUT $action INTO @MergeCounts	
	;
	
	DECLARE @Inserted INT, @Updated INT, @Deleted INT 
	;WITH MergeActions AS(
		SELECT MergeAction,COUNT(*) As Total FROM @MergeCounts
		GROUP BY MergeAction
	)
	SELECT
		@Inserted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'INSERT')
		,@Updated = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'UPDATE')
		,@Deleted = (SELECT COALESCE(Total,0) FROM MergeActions WHERE MergeActions.MergeAction = 'DELETE')

	INSERT INTO dbo.WarehouseLoadAudit(ProcName,RunDateTime,RowsInserted,RowsUpdated,RowsDeleted)
	SELECT OBJECT_NAME(@@PROCID),GETDATE(), @Inserted,@Updated,@Deleted

