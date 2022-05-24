CREATE TABLE [MI].[CampaignExternalResultsFinalWave_Segment_Incomplete] (
    [ID]                      INT            IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef]       VARCHAR (40)   NOT NULL,
    [StartDate]               DATE           NOT NULL,
    [SegmentID]               INT            NOT NULL,
    [ControlGroup]            VARCHAR (100)  NOT NULL,
    [CustomerUniverse]        VARCHAR (100)  NOT NULL,
    [Level]                   VARCHAR (100)  NOT NULL,
    [Cardholders]             BIGINT         NULL,
    [Sales]                   MONEY          NULL,
    [Transactions]            INT            NULL,
    [Spenders]                INT            NULL,
    [IncrementalSales]        REAL           NULL,
    [IncrementalMargin]       REAL           NULL,
    [IncrementalTransactions] REAL           NULL,
    [IncrementalSpenders]     REAL           NULL,
    [SPS_Diff]                REAL           NULL,
    [SalesUplift]             REAL           NULL,
    [RRUplift]                REAL           NULL,
    [ATVUplift]               REAL           NULL,
    [ATFUplift]               REAL           NULL,
    [MainDriver]              VARCHAR (3)    NULL,
    [PooledStdDevSPC]         REAL           NULL,
    [DegreesOfFreedomSPC]     INT            NULL,
    [TscoreSPC]               REAL           NULL,
    [PValueSPC]               REAL           NULL,
    [SignificantUpliftSPC]    VARCHAR (40)   NULL,
    [PooledStdDevRR]          REAL           NULL,
    [DegreesOfFreedomRR]      INT            NULL,
    [TscoreRR]                REAL           NULL,
    [PValueRR]                REAL           NULL,
    [SignificantUpliftRR]     VARCHAR (40)   NULL,
    [PooledStdDevSPS]         REAL           NULL,
    [DegreesOfFreedomSPS]     INT            NULL,
    [TscoreSPS]               REAL           NULL,
    [PValueSPS]               REAL           NULL,
    [SignificantUpliftSPS]    VARCHAR (40)   NULL,
    [QualyfingSales]          MONEY          NULL,
    [Cashback]                MONEY          NULL,
    [QualyfingCashback]       MONEY          NULL,
    [Commission]              MONEY          NULL,
    [CampaignCost]            MONEY          NULL,
    [RewardOverride]          MONEY          NULL,
    [IncrementalOverride]     MONEY          NULL,
    [Inserted]                SMALLDATETIME  NULL,
    [InsertedBy]              NVARCHAR (128) NULL,
    [ControlGroupSize]        BIGINT         NULL,
    CONSTRAINT [UNQ_CampaignResultsOutofProgrammeFinalWave_Segment_Incomplete] UNIQUE NONCLUSTERED ([ClientServicesRef] ASC, [StartDate] ASC, [SegmentID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IND_3]
    ON [MI].[CampaignExternalResultsFinalWave_Segment_Incomplete]([SegmentID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND]
    ON [MI].[CampaignExternalResultsFinalWave_Segment_Incomplete]([ClientServicesRef] ASC, [StartDate] ASC);

