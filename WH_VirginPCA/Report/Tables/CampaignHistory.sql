CREATE TABLE [Report].[CampaignHistory] (
    [IronOfferCyclesID] INT NOT NULL,
    [FanID]             INT NOT NULL,
    PRIMARY KEY CLUSTERED ([IronOfferCyclesID] ASC, [FanID] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [UC_IronOfferCyclesIDFanID] UNIQUE NONCLUSTERED ([IronOfferCyclesID] ASC, [FanID] ASC) WITH (FILLFACTOR = 80)
);

