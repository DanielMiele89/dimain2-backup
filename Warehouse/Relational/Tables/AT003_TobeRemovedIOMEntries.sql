CREATE TABLE [Relational].[AT003_TobeRemovedIOMEntries] (
    [ID]               INT      NOT NULL,
    [IronOfferID]      INT      NOT NULL,
    [CompositeID]      BIGINT   NOT NULL,
    [StartDate]        DATETIME NULL,
    [EndDate]          DATETIME NULL,
    [AnalyticsTableID] INT      NULL,
    [ImportDate]       DATETIME NOT NULL,
    [IsControl]        BIT      NOT NULL
);

