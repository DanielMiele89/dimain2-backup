CREATE PROC [WHB].[__Virgin_LandingPartnerTrans_Load]
AS

	DECLARE @CheckpointValue INT,
			@RowCount BIGINT;

	SELECT @CheckpointValue=MAX(CheckpointValue)
	FROM WH_AllPublishers.WHB.SourceCheckpoint
	WHERE SourceTypeID = 9  

	INSERT INTO [WH_AllPublishers].[Inbound].[Virgin_PartnerTrans] ([ID], [FileID], [RowNum], [FanID], [PartnerID], [OutletID], [IsOnline], [CardHolderPresentData], [TransactionAmount], [ExtremeValueFlag], [TransactionDate], [TransactionWeekStarting], [TransactionMonth], [TransactionYear], [TransactionWeekStartingCampaign], [AddedDate], [AddedWeekStarting], [AddedMonth], [AddedYear], [AffiliateCommissionAmount], [CommissionChargable], [CashbackEarned], [IronOfferID], [ActivationDays], [AboveBase], [PaymentMethodID])
	SELECT
		 [ID]
		 ,[FileID]
		 ,[RowNum]
		 ,[FanID]
		 ,[PartnerID]
		 ,[OutletID]
		 ,[IsOnline]
		 ,[CardHolderPresentData]
		 ,[TransactionAmount]
		 ,[ExtremeValueFlag]
		 ,[TransactionDate]
		 ,[TransactionWeekStarting]
		 ,[TransactionMonth]
		 ,[TransactionYear]
		 ,[TransactionWeekStartingCampaign]
		 ,[AddedDate]
		 ,[AddedWeekStarting]
		 ,[AddedMonth]
		 ,[AddedYear]
		 ,[AffiliateCommissionAmount]
		 ,[CommissionChargable]
		 ,[CashbackEarned]
		 ,[IronOfferID]
		 ,[ActivationDays]
		 ,[AboveBase]
		 ,[PaymentMethodID]	
	  FROM [WH_Virgin].[Derived].[PartnerTrans] PT
	  WHERE PT.ID > COALESCE(@CheckpointValue,0);
