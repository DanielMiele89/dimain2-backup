CREATE TABLE [kevinc].[StagingExposedGroupMetrics] (
    [ReportingOfferID] INT   NOT NULL,
    [Amount]           MONEY NULL,
    [TransactionCount] INT   NULL,
    [DistinctSpenders] INT   NULL,
    [CardHolders]      INT   NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [kevinc].[StagingExposedGroupMetrics]([ReportingOfferID] ASC);

