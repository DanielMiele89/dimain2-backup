CREATE TABLE [Selections].[CampaignSetup_TopPartnerOffer] (
    [PartnerID]       INT            NOT NULL,
    [IronOfferID]     INT            NOT NULL,
    [IronOfferName]   NVARCHAR (200) NOT NULL,
    [TopCashBackRate] REAL           NULL,
    CONSTRAINT [PK_IronOffer] PRIMARY KEY CLUSTERED ([IronOfferID] ASC)
);

