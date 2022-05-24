CREATE TABLE [MI].[SSAS_FactSpendEarn] (
    [MatchID]             INT     NOT NULL,
    [Spend]               MONEY   NOT NULL,
    [Earnings]            MONEY   NOT NULL,
    [PublisherID]         TINYINT NOT NULL,
    [CustomerID]          INT     NOT NULL,
    [RetailerPublisherID] INT     NOT NULL,
    [OutletID]            INT     NOT NULL,
    [TranDate]            DATE    NULL,
    [AddedDate]           DATE    NULL,
    CONSTRAINT [PK_MI_SSAS_FactSpendEarn] PRIMARY KEY CLUSTERED ([MatchID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE),
    CONSTRAINT [FK_MI_SSAS_FactSpendEarn_DimRetailerPublisher] FOREIGN KEY ([RetailerPublisherID]) REFERENCES [MI].[SSAS_DimRetailerPublisher] ([RetailerPublisherID])
);

