

CREATE PROC [WHB].[__nFI_LandingPartnerTrans_Load]
AS

SET IDENTITY_INSERT [Inbound].[nFI_PartnerTrans] ON

	DECLARE @CheckpointValue INT,
			@RowCount BIGINT;

	SELECT @CheckpointValue=MAX(CheckpointValue)
	FROM WH_AllPublishers.WHB.SourceCheckpoint
	WHERE SourceTypeID = 6  

	INSERT INTO [WH_AllPublishers].[Inbound].[nFI_PartnerTrans] ([ID]
      ,[FanID]
      ,[PartnerID]
      ,[OutletID]
      ,[TransactionAmount]
      ,[TransactionDate]
      ,[AddedDate]
      ,[CommissionChargable]
      ,[CashbackEarned]
      ,[IronOfferID]
	  ,[MatchID])
	SELECT
		 [ID]
      ,[FanID]
      ,[PartnerID]
      ,[OutletID]
      ,[TransactionAmount]
      ,[TransactionDate]
      ,[AddedDate]
      ,[CommissionChargable]
      ,[CashbackEarned]
      ,[IronOfferID]
	  ,[MatchID]
  FROM [nFI].[Relational].[PartnerTrans] PT
	  WHERE PT.ID > COALESCE(@CheckpointValue,0); --Move to Staging

SET IDENTITY_INSERT [Inbound].[nFI_PartnerTrans] off
