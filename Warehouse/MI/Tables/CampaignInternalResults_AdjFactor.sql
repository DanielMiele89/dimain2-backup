CREATE TABLE [MI].[CampaignInternalResults_AdjFactor] (
    [ControlGroup]      VARCHAR (100) NOT NULL,
    [SalesType]         VARCHAR (100) NOT NULL,
    [CustomerUniverse]  VARCHAR (100) NOT NULL,
    [ClientServicesRef] VARCHAR (40)  NOT NULL,
    [StartDate]         DATE          NOT NULL,
    [Level]             VARCHAR (100) NOT NULL,
    [SegmentID]         INT           NOT NULL,
    [Cell]              VARCHAR (400) NOT NULL,
    [Adj_FactorRR]      REAL          NULL,
    [Adj_FactorSPC]     REAL          NULL,
    [Adj_FactorTPC]     REAL          NULL,
    [IsCapped]          INT           NULL,
    CONSTRAINT [UNQ_CampaignResults_AdjFactor] UNIQUE NONCLUSTERED ([ControlGroup] ASC, [SalesType] ASC, [CustomerUniverse] ASC, [ClientServicesRef] ASC, [StartDate] ASC, [Level] ASC, [SegmentID] ASC, [Cell] ASC)
);


GO
CREATE CLUSTERED INDEX [IND_C]
    ON [MI].[CampaignInternalResults_AdjFactor]([ClientServicesRef] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_1]
    ON [MI].[CampaignInternalResults_AdjFactor]([StartDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_2]
    ON [MI].[CampaignInternalResults_AdjFactor]([SegmentID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_3]
    ON [MI].[CampaignInternalResults_AdjFactor]([Cell] ASC);

