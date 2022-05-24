CREATE TABLE [MI].[CampaignInternalResultsLTE_PureSales] (
    [Effect]            VARCHAR (40)  NULL,
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
    CONSTRAINT [UNQ_CampaignResultsLTE_PureSales] UNIQUE NONCLUSTERED ([Effect] ASC, [ControlGroup] ASC, [SalesType] ASC, [CustomerUniverse] ASC, [ClientServicesRef] ASC, [StartDate] ASC, [Level] ASC, [SegmentID] ASC, [Cell] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IND_3]
    ON [MI].[CampaignInternalResultsLTE_PureSales]([Cell] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_2]
    ON [MI].[CampaignInternalResultsLTE_PureSales]([SegmentID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_1]
    ON [MI].[CampaignInternalResultsLTE_PureSales]([StartDate] ASC);


GO
CREATE CLUSTERED INDEX [IND_C]
    ON [MI].[CampaignInternalResultsLTE_PureSales]([ClientServicesRef] ASC);

