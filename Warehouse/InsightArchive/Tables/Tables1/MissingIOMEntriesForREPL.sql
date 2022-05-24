CREATE TABLE [InsightArchive].[MissingIOMEntriesForREPL] (
    [IronOfferID] INT      NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [StartDate]   DATETIME NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ClusteredIndex-20170831-131209]
    ON [InsightArchive].[MissingIOMEntriesForREPL]([IronOfferID] ASC, [CompositeID] ASC, [StartDate] ASC);

