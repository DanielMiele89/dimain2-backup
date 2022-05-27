CREATE PROCEDURE [Staging].[PublisherOfferTracker_ExportToRewardBI]
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	SELECT	pot.PrimaryPartnerID
		,	oi.IronOfferID
		,	pot.OfferCode
		,	pot.StartDate
		,	pot.EndDate
		,	pot.TargetAudience
		,	pot.Definition
		,	pot.CashbackOffer
		,	pot.SpendStretch
		,	pot.SegmentID
		,	pot.IsOnline
		,	ontp.PublisherID_RewardBI
	FROM [Staging].[PublisherOfferTracker_Transformed] pot
	LEFT JOIN [Staging].[PublisherOfferTracker_OfferNameToPublisher] ontp
		ON LEFT(pot.OfferCode, 3) = ontp.OfferCodePrefix3
	LEFT JOIN [Derived].[OfferIDs] oi
		ON pot.OfferCode = oi.OfferCode
	--	AND (pot.PrimaryPartnerID = oi.PartnerID OR pot.PartnerID = oi.PartnerID)
		AND ontp.PublisherID = oi.PublisherID
		AND ontp.PublisherID_RewardBI = oi.PublisherID_RewardBI
		AND oi.OfferIDTypeID = 1

END
