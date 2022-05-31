CREATE TABLE [kevinc].[StagingControlGroupMetrics] (
    [ControlGroupID]   INT           NOT NULL,
    [ReportingOfferID] INT           NOT NULL,
    [StartDate]        DATETIME2 (7) NOT NULL,
    [EndDate]          DATETIME2 (7) NOT NULL,
    [PartnerID]        INT           NOT NULL,
    [Amount]           MONEY         NULL,
    [TransactionCount] INT           NULL,
    [DistinctSpenders] INT           NULL,
    [CardHolders]      INT           NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [kevinc].[StagingControlGroupMetrics]([ReportingOfferID] ASC);

