﻿


CREATE PROC [WHB].[__RBS_WarehousePartnerTrans_Load]
AS

	SET XACT_ABORT ON;
	
	DECLARE @SourceTypeID AS INT = 3
	DECLARE @RowCount BIGINT,
		@isLoaded BIT 

	EXEC WHB.TableLoadStatus_Get @SourceTypeID, @isLoaded OUTPUT

	IF @isLoaded = 1
		RETURN

	SELECT C.[ConsumerID], PT.[PartnerID], PT.[PartnerID] AS RetailerID, [OutletID], [IsOnline], [CardHolderPresentData], [TransactionAmount], [ExtremeValueFlag], [TransactionDate], [AffiliateCommissionAmount], [CommissionChargable], [CashbackEarned], O.[OfferID] AS OfferID, [ActivationDays], [AboveBase], [PaymentMethodID], ID as SourceID, @SourceTypeID AS SourceTypeID, [AddedDate], GETDATE() AS CreatedDateTime
	INTO #PartnerTransStaging
	FROM [WH_AllPublishers].[Inbound].[RBS_PartnerTrans] PT
	LEFT JOIN [WH_AllPublishers].[dbo].[Consumer] C ON C.FanID = PT.FanID AND C.SourceTypeID = @SourceTypeID
	LEFT JOIN [WH_AllPublishers].[dbo].[Offer] O ON O.SourceID = PT.IronOfferID  AND O.SourceTypeID = @SourceTypeID

	BEGIN TRAN
		INSERT INTO [WH_AllPublishers].[dbo].[Earnings] ([ConsumerID], [PartnerID], [RetailerID], [OutletID], [IsOnline], [CardHolderPresentData], [TransactionAmount], [ExtremeValueFlag], [TransactionDate], [AffiliateCommissionAmount], [CommissionChargable], [CashbackEarned], [OfferID], [ActivationDays], [AboveBase], [PaymentMethodID], [SourceID], [SourceTypeID], [SourceAddedDate], [CreatedDateTime])
		SELECT * FROM #PartnerTransStaging
		WHERE (ConsumerID IS NOT NULL
		AND OfferID IS NOT NULL)
		
		INSERT INTO dbo.WarehouseLoadAudit(ProcName,RunDateTime,RowsInserted)
		SELECT OBJECT_NAME(@@PROCID),GETDATE(),@@ROWCOUNT

		INSERT INTO [WH_AllPublishers].[dbo].[MissingEarnings] ([ConsumerID], [PartnerID], [RetailerID], [OutletID], [IsOnline], [CardHolderPresentData], [TransactionAmount], [ExtremeValueFlag], [TransactionDate], [AffiliateCommissionAmount], [CommissionChargable], [CashbackEarned], [OfferID], [ActivationDays], [AboveBase], [PaymentMethodID], [SourceID], [SourceTypeID], [SourceAddedDate], [CreatedDateTime])
		SELECT * FROM #PartnerTransStaging
		WHERE NOT (ConsumerID IS NOT NULL
		AND OfferID IS NOT NULL)

		EXEC WHB.TableLoadStatus_Set @SourceTypeID

	COMMIT TRAN
