CREATE TABLE [MI].[CampaignExternalResultsLTE_Workings] (
    [Effect]                   VARCHAR (40)   NULL,
    [ControlGroup]             VARCHAR (100)  NOT NULL,
    [SalesType]                VARCHAR (100)  NOT NULL,
    [CustomerUniverse]         VARCHAR (100)  NOT NULL,
    [ClientServicesRef]        VARCHAR (40)   NOT NULL,
    [StartDate]                DATE           NOT NULL,
    [Level]                    VARCHAR (100)  NOT NULL,
    [SegmentID]                INT            NOT NULL,
    [Cell]                     VARCHAR (400)  NOT NULL,
    [Cardholders_M]            BIGINT         NULL,
    [Spenders_M]               BIGINT         NULL,
    [Sales_M]                  MONEY          NULL,
    [Transactions_M]           BIGINT         NULL,
    [Commission_M]             MONEY          NULL,
    [Cashback_M]               MONEY          NULL,
    [RewardOverride_M]         MONEY          NULL,
    [StdDev_SPS_M]             REAL           NULL,
    [StdDev_SPC_M]             REAL           NULL,
    [Cardholders_C]            BIGINT         NULL,
    [Spenders_C]               BIGINT         NULL,
    [Sales_C]                  MONEY          NULL,
    [Transactions_C]           BIGINT         NULL,
    [Commission_C]             MONEY          NULL,
    [Cashback_C]               MONEY          NULL,
    [RewardOverride_C]         MONEY          NULL,
    [StdDev_SPS_C]             REAL           NULL,
    [StdDev_SPC_C]             REAL           NULL,
    [Adj_FactorRR]             REAL           NULL,
    [Adj_FactorSPC]            REAL           NULL,
    [Adj_FactorTPC]            REAL           NULL,
    [SPC_Mail]                 REAL           NULL,
    [SPC_Control]              REAL           NULL,
    [SPC_Diff]                 REAL           NULL,
    [IncrementalSales]         REAL           NULL,
    [ControlCommissionRate]    DECIMAL (5, 4) NULL,
    [MailedCommissionRate]     DECIMAL (5, 4) NULL,
    [ControlOfferRate]         DECIMAL (5, 4) NULL,
    [MailedOfferRate]          DECIMAL (5, 4) NULL,
    [ExtraCommissionGenerated] REAL           NULL,
    [ExtraOverrideGenerated]   REAL           NULL,
    [RR_Mail]                  REAL           NULL,
    [RR_Control]               REAL           NULL,
    [RR_Diff]                  REAL           NULL,
    [IncrementalSpenders]      REAL           NULL,
    [TPC_Mail]                 REAL           NULL,
    [TPC_Control]              REAL           NULL,
    [TPC_Diff]                 REAL           NULL,
    [IncrementalTransactions]  REAL           NULL,
    [SPS_Mail]                 REAL           NULL,
    [SPS_Control]              REAL           NULL,
    [SPS_Diff]                 REAL           NULL,
    [SPC_PooledStdDev]         REAL           NULL,
    [SPC_DegreesOfFreedom]     INT            NULL,
    [SPC_Tscore]               REAL           NULL,
    [SPC_Pvalue]               REAL           NULL,
    [SPC_Uplift_LowerBond95]   REAL           NULL,
    [SPC_Uplift]               REAL           NULL,
    [SPC_Uplift_UpperBond95]   REAL           NULL,
    [SPC_Uplift_Significance]  VARCHAR (40)   NULL,
    [RR_Pooled]                REAL           NULL,
    [RR_PooledStdDev]          REAL           NULL,
    [RR_DegreesOfFreedom]      INT            NULL,
    [RR_Tscore]                REAL           NULL,
    [RR_Pvalue]                REAL           NULL,
    [RR_Uplift_LowerBond95]    REAL           NULL,
    [RR_Uplift]                REAL           NULL,
    [RR_Uplift_UpperBond95]    REAL           NULL,
    [RR_Uplift_Significance]   VARCHAR (40)   NULL,
    [SPS_PooledStdDev]         REAL           NULL,
    [SPS_DegreesOfFreedom]     INT            NULL,
    [SPS_Tscore]               REAL           NULL,
    [SPS_Pvalue]               REAL           NULL,
    [SPS_Uplift_LowerBond95]   REAL           NULL,
    [SPS_Uplift]               REAL           NULL,
    [SPS_Uplift_UpperBond95]   REAL           NULL,
    [SPS_Uplift_Significance]  VARCHAR (40)   NULL,
    CONSTRAINT [UNQ_CampaignResultsOutOfProgrammeLTE_Workings] UNIQUE NONCLUSTERED ([Effect] ASC, [ControlGroup] ASC, [SalesType] ASC, [CustomerUniverse] ASC, [ClientServicesRef] ASC, [StartDate] ASC, [Level] ASC, [SegmentID] ASC, [Cell] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IND_3]
    ON [MI].[CampaignExternalResultsLTE_Workings]([Cell] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_2]
    ON [MI].[CampaignExternalResultsLTE_Workings]([SegmentID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_1]
    ON [MI].[CampaignExternalResultsLTE_Workings]([StartDate] ASC);


GO
CREATE CLUSTERED INDEX [IND_C]
    ON [MI].[CampaignExternalResultsLTE_Workings]([ClientServicesRef] ASC);

