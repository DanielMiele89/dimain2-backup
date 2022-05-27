CREATE TABLE [Report].[OfferReport_ConsumerTransaction] (
    [DataSource]            VARCHAR (50)  NULL,
    [RetailerID]            INT           NULL,
    [PartnerID]             INT           NULL,
    [MID]                   VARCHAR (50)  NULL,
    [ConsumerCombinationID] INT           NOT NULL,
    [CINID]                 INT           NOT NULL,
    [Amount]                MONEY         NOT NULL,
    [IsOnline]              BIT           NOT NULL,
    [TranDate]              DATETIME2 (0) NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CCID]
    ON [Report].[OfferReport_ConsumerTransaction]([ConsumerCombinationID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CINID]
    ON [Report].[OfferReport_ConsumerTransaction]([CINID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CCDateAmount_IncCIN]
    ON [Report].[OfferReport_ConsumerTransaction]([ConsumerCombinationID] ASC, [TranDate] ASC, [Amount] ASC)
    INCLUDE([CINID]);


GO
CREATE COLUMNSTORE INDEX [CSI_All]
    ON [Report].[OfferReport_ConsumerTransaction]([CINID], [ConsumerCombinationID], [Amount], [TranDate], [IsOnline]);

