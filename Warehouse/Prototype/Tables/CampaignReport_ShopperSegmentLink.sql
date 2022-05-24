CREATE TABLE [Prototype].[CampaignReport_ShopperSegmentLink] (
    [ID]            INT IDENTITY (1, 1) NOT NULL,
    [OfferID]       INT NOT NULL,
    [LinkedOfferID] INT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

