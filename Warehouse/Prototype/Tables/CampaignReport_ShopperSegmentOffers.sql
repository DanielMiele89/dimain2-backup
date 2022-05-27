CREATE TABLE [Prototype].[CampaignReport_ShopperSegmentOffers] (
    [ID]        INT            IDENTITY (1, 1) NOT NULL,
    [OfferID]   INT            NULL,
    [Universe]  NVARCHAR (10)  NULL,
    [PartnerID] INT            NULL,
    [OfferName] NVARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

