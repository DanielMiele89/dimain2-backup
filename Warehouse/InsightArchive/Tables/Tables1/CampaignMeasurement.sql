﻿CREATE TABLE [InsightArchive].[CampaignMeasurement] (
    [IronOfferID]                              INT         NOT NULL,
    [FanID]                                    INT         NOT NULL,
    [StartDate]                                DATE        NULL,
    [EndDate]                                  DATE        NULL,
    [GroupName]                                VARCHAR (1) NOT NULL,
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
    [ServedOffer]                              INT         NOT NULL,
    [OfferSlot]                                INT         NULL,
    [EmailInteractions]                        INT         NULL,
    [CampaignOpens]                            INT         NULL,
    [WebLogins]                                INT         NULL,
    [WebLoginDays]                             INT         NULL
);

