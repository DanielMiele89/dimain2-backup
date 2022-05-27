﻿



CREATE PROC [WHB].[__nFI_WarehousePartnerTrans_Load]
AS

	SET XACT_ABORT ON;
	
	DECLARE @SourceTypeID AS INT = 6
	DECLARE @RowCount BIGINT,
		@isLoaded BIT 

	EXEC WHB.TableLoadStatus_Get @SourceTypeID, @isLoaded OUTPUT

	IF @isLoaded = 1
		RETURN

	SELECT C.[ConsumerID], PT.[PartnerID], PT.[PartnerID] AS RetailerID, [OutletID], [TransactionAmount], [TransactionDate], [CommissionChargable], [CashbackEarned], O.[OfferID] AS OfferID, [MatchID] as SourceID, @SourceTypeID AS SourceTypeID, [AddedDate], GETDATE() AS CreatedDateTime
	INTO #TransactionStaging
	FROM [WH_AllPublishers].[Inbound].[nFI_PartnerTrans] PT
	LEFT JOIN [WH_AllPublishers].[dbo].[Consumer] C ON C.FanID = PT.FanID AND C.SourceTypeID = @SourceTypeID
	LEFT JOIN [WH_AllPublishers].[dbo].[Offer] O ON O.SourceID = PT.IronOfferID  AND O.SourceTypeID = @SourceTypeID

	BEGIN TRAN
		INSERT INTO [WH_AllPublishers].[dbo].[Earnings] ([ConsumerID], [PartnerID], [RetailerID], [OutletID], [IsOnline], [CardHolderPresentData], [TransactionAmount], [ExtremeValueFlag], [TransactionDate], [AffiliateCommissionAmount], [CommissionChargable], [CashbackEarned], [OfferID], [ActivationDays], [AboveBase], [PaymentMethodID], [SourceID], [SourceTypeID], [SourceAddedDate], [CreatedDateTime])
		SELECT * FROM #TransactionStaging
		WHERE (ConsumerID IS NOT NULL
		AND OfferID IS NOT NULL)
		
		INSERT INTO dbo.WarehouseLoadAudit(ProcName,RunDateTime,RowsInserted)
		SELECT OBJECT_NAME(@@PROCID),GETDATE(),@@ROWCOUNT

		INSERT INTO [WH_AllPublishers].[dbo].[MissingEarnings] ([ConsumerID], [PartnerID], [RetailerID], [OutletID], [IsOnline], [CardHolderPresentData], [TransactionAmount], [ExtremeValueFlag], [TransactionDate], [AffiliateCommissionAmount], [CommissionChargable], [CashbackEarned], [OfferID], [ActivationDays], [AboveBase], [PaymentMethodID], [SourceID], [SourceTypeID], [SourceAddedDate], [CreatedDateTime])
		SELECT * FROM #TransactionStaging
		WHERE NOT (ConsumerID IS NOT NULL
		AND OfferID IS NOT NULL)


	--SELECT @RowCount = @@ROWCOUNT;

		INSERT INTO WH_AllPublishers.WHB.SourceCheckpoint ([SourceTypeID], [CheckpointValue], [InsertedDateTime], [Archived])
		SELECT @SourceTypeID, COALESCE(MAX(ID),(SELECT MAX(CheckpointValue) FROM WH_AllPublishers.WHB.SourceCheckpoint WHERE SourceTypeID = @SourceTypeID))  , GETDATE(), 0  
		FROM [WH_AllPublishers].[Inbound].[nFi_PartnerTrans] 

		EXEC WHB.TableLoadStatus_Set @SourceTypeID
	COMMIT TRAN
