CREATE TABLE [MI].[CampaignInternalResults_PureSales] (
    [ControlGroup]      VARCHAR (100) NOT NULL,
    [SalesType]         VARCHAR (100) NOT NULL,
    [CustomerUniverse]  VARCHAR (100) NOT NULL,
    [ClientServicesRef] VARCHAR (40)  NOT NULL,
    [StartDate]         DATE          NOT NULL,
    [Level]             VARCHAR (100) NOT NULL,
    [SegmentID]         INT           NOT NULL,
    [Cell]              VARCHAR (400) NOT NULL,
    [Cardholders]       BIGINT        NULL,
    [Spenders]          BIGINT        NULL,
    [Sales]             MONEY         NULL,
    [Transactions]      BIGINT        NULL,
    [Commission]        MONEY         NULL,
    [Cashback]          MONEY         NULL,
    [RewardOverride]    MONEY         NULL,
    CONSTRAINT [UNQ_CampaignResults_PureSales] UNIQUE NONCLUSTERED ([ControlGroup] ASC, [SalesType] ASC, [CustomerUniverse] ASC, [ClientServicesRef] ASC, [StartDate] ASC, [Level] ASC, [SegmentID] ASC, [Cell] ASC)
);


GO
CREATE CLUSTERED INDEX [IND_C]
    ON [MI].[CampaignInternalResults_PureSales]([ClientServicesRef] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_1]
    ON [MI].[CampaignInternalResults_PureSales]([StartDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_2]
    ON [MI].[CampaignInternalResults_PureSales]([SegmentID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_3]
    ON [MI].[CampaignInternalResults_PureSales]([Cell] ASC);

