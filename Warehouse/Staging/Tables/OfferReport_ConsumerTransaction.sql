CREATE TABLE [Staging].[OfferReport_ConsumerTransaction] (
    [ConsumerCombinationID] INT           NOT NULL,
    [TranDate]              DATETIME2 (0) NOT NULL,
    [CINID]                 INT           NOT NULL,
    [Amount]                MONEY         NOT NULL,
    [IsOnline]              BIT           NOT NULL,
    [PublisherID]           INT           NOT NULL,
    [IsWarehouse]           BIT           NOT NULL,
    [IsVirgin]              BIT           NOT NULL,
    [IsVirginPCA]           BIT           NOT NULL,
    [IsVisaBarclaycard]     BIT           NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CCID]
    ON [Staging].[OfferReport_ConsumerTransaction]([ConsumerCombinationID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CCDateAmount_IncCIN]
    ON [Staging].[OfferReport_ConsumerTransaction]([PublisherID] ASC, [ConsumerCombinationID] ASC, [TranDate] ASC, [Amount] ASC)
    INCLUDE([CINID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CINID]
    ON [Staging].[OfferReport_ConsumerTransaction]([CINID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE COLUMNSTORE INDEX [CSI_All]
    ON [Staging].[OfferReport_ConsumerTransaction]([CINID], [ConsumerCombinationID], [Amount], [TranDate], [IsOnline], [IsWarehouse], [IsVirgin], [IsVisaBarclaycard])
    ON [Warehouse_Columnstores];

