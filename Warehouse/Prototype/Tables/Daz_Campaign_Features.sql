CREATE TABLE [Prototype].[Daz_Campaign_Features] (
    [IronOfferID]                              INT         NULL,
    [FanID]                                    INT         NULL,
    [StartDate]                                DATE        NULL,
    [EndDate]                                  DATE        NULL,
    [GroupName]                                VARCHAR (1) NULL,
    [CINID]                                    INT         NULL,
    [BelowThresholdRate]                       FLOAT (53)  NULL,
    [MinimumBasketSize]                        FLOAT (53)  NULL,
    [AboveThresholdRate]                       FLOAT (53)  NULL,
    [Campaign_Sales]                           MONEY       NULL,
    [Campaign_Transactions]                    INT         NULL,
    [Campaign_AboveThreshold_Sales]            MONEY       NULL,
    [Campaign_AboveThreshold_Transactions]     INT         NULL,
    [Incentivised_Sales]                       MONEY       NULL,
    [Incentivised_Transactions]                INT         NULL,
    [Incentivised_AboveThreshold_Sales]        MONEY       NULL,
    [Incentivised_AboveThreshold_Transactions] INT         NULL,
    [Incentivised_Cashback]                    MONEY       NULL,
    [Incentivised_Investment]                  MONEY       NULL,
    [Incentivised_AboveThreshold_Cashback]     MONEY       NULL,
    [Incentivised_AboveThreshold_Investment]   MONEY       NULL,
    [MarketableByEmail]                        INT         NULL,
    [ServedOffer]                              INT         NULL,
    [OfferSlot]                                INT         NULL,
    [EmailInteractions]                        INT         NULL,
    [CampaignOpens]                            INT         NULL,
    [WebLogins]                                INT         NULL,
    [WebLoginDays]                             INT         NULL,
    [CampaignID]                               INT         NULL
);


GO
CREATE CLUSTERED INDEX [cix_FanID]
    ON [Prototype].[Daz_Campaign_Features]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [nix_FanID__IronOfferID_CampaignID]
    ON [Prototype].[Daz_Campaign_Features]([FanID] ASC)
    INCLUDE([IronOfferID], [CampaignID], [GroupName]);

