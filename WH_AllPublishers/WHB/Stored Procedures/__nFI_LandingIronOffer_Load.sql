


CREATE PROC [WHB].[__nFI_LandingIronOffer_Load]
AS
INSERT INTO [WH_AllPublishers].[Inbound].[nFI_IronOffer]([ID]
      ,[OfferID]
      ,[IronOfferName]
      ,[StartDate]
      ,[EndDate]
      ,[PartnerID]
      ,[IsSignedOff]
      ,[ClubID]
      ,[IsAppliedToAllMembers])
SELECT
	[ID]
      ,[OfferID]
      ,[IronOfferName]
      ,[StartDate]
      ,[EndDate]
      ,[PartnerID]
      ,[IsSignedOff]
      ,[ClubID]
      ,[IsAppliedToAllMembers]
  FROM [nFI].[Relational].[IronOffer]
