 --EXEC [WHB].[RBS_LandingPartnerTrans_Load]
CREATE PROC [WHB].[__RBS_LandingPartnerTrans_Load]
AS

	DECLARE @CheckpointValue INT,
			@RowCount BIGINT,
			@SourceTypeID INT = 3

	INSERT INTO [Inbound].[RBS_PartnerTrans](ID, [FanID], [PartnerID], [OutletID], [IsOnline], [CardHolderPresentData], [TransactionAmount], [ExtremeValueFlag], [TransactionDate], [TransactionWeekStarting], [TransactionMonth], [TransactionYear], [TransactionWeekStartingCampaign], [AddedDate], [AddedWeekStarting], [AddedMonth], [AddedYear], [AffiliateCommissionAmount], [CommissionChargable], [EligibleForCashBack], [CashbackEarned], [IronOfferID], [ActivationDays], [AboveBase], [PaymentMethodID])
	SELECT TOP 1000
			t.ID
			,pt.[FanID]
			,pt.[PartnerID]
			,pt.[OutletID]
			,pt.[IsOnline]
			,pt.[CardHolderPresentData]
			,pt.[TransactionAmount]
			,pt.[ExtremeValueFlag]
			,pt.[TransactionDate]
			,pt.[TransactionWeekStarting]
			,pt.[TransactionMonth]
			,pt.[TransactionYear]
			,pt.[TransactionWeekStartingCampaign]
			,pt.[AddedDate]
			,pt.[AddedWeekStarting]
			,pt.[AddedMonth]
			,pt.[AddedYear]
			,pt.[AffiliateCommissionAmount]
			,pt.[CommissionChargable]
			,pt.[CashbackEarned]
			,pt.[EligibleForCashBack]
			,pt.[IronOfferID]
			,pt.[ActivationDays]
			,pt.[AboveBase]
			,pt.[PaymentMethodID]
	FROM [Warehouse].[Relational].[PartnerTrans] PT
	JOIN SLC_Report..Trans t
		ON pt.MatchID = t.MatchID
	WHERE (
			(
				t.TypeID <> 24
				AND t.VectorID = 40
			) 
			OR t.vectorid <> 40
	) AND NOT EXISTS (
		SELECT 1
		FROM WH_AllPublishers.dbo.Earnings e
		WHERE e.SourceTypeID = @SourceTypeID
			AND e.SourceID = t.ID
	)

