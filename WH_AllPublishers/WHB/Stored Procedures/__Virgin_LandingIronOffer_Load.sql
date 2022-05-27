
CREATE PROC [WHB].[__Virgin_LandingIronOffer_Load]
AS
INSERT INTO [WH_AllPublishers].[Inbound].[Virgin_IronOffer]([IronOfferID], [IronOfferName], [HydraOfferID], [StartDate], [EndDate], [PartnerID], [IsAboveTheLine], [AutoAddToNewRegistrants], [IsDefaultCollateral], [IsSignedOff], [AreEligibleMembersCommitted], [AreControlMembersCommitted], [IsTriggerOffer], [Continuation], [TopCashBackRate], [AboveBase], [Clubs], [CampaignType], [SegmentName], [ClubID])
SELECT
	[IronOfferID]
	,[IronOfferName]
	,[HydraOfferID]
	,[StartDate]
	,[EndDate]
	,[PartnerID]
	,[IsAboveTheLine]
	,[AutoAddToNewRegistrants]
	,[IsDefaultCollateral]
	,[IsSignedOff]
	,[AreEligibleMembersCommitted]
	,[AreControlMembersCommitted]
	,[IsTriggerOffer]
	,[Continuation]
	,[TopCashBackRate]
	,[AboveBase]
	,[Clubs]
	,[CampaignType]
	,[SegmentName]
	,[ClubID]
FROM [WH_Virgin].[Derived].[IronOffer]
WHERE [HydraOfferID] IS NOT NULL
