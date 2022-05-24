CREATE TABLE [Prototype].[Daz_Campaign_List] (
    [IronOfferID]        INT           NULL,
    [IronOfferName]      VARCHAR (100) NULL,
    [StartDate]          DATE          NULL,
    [EndDate]            DATE          NULL,
    [PartnerID]          INT           NULL,
    [BelowThresholdRate] INT           NULL,
    [MinimumBasketSize]  INT           NULL,
    [AboveThresholdRate] INT           NULL,
    [ProcessingTime]     DATETIME      NULL,
    [CampaignID]         INT           NULL
);


GO
CREATE NONCLUSTERED INDEX [nix_IronOfferID_CampaignID]
    ON [Prototype].[Daz_Campaign_List]([IronOfferID] ASC)
    INCLUDE([CampaignID]);


GO
CREATE CLUSTERED INDEX [cix_IronOfferID]
    ON [Prototype].[Daz_Campaign_List]([IronOfferID] ASC);

