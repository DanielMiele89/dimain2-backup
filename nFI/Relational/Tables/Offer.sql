CREATE TABLE [Relational].[Offer] (
    [ID]           INT      IDENTITY (1, 1) NOT NULL,
    [OfferTypeID]  TINYINT  NULL,
    [CampaignID]   INT      NULL,
    [EngagementID] SMALLINT NULL,
    [isROC]        BIT      NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

