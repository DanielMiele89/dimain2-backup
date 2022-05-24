CREATE TABLE [InsightArchive].[HungryHorse] (
    [IronOfferID] INT      NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NULL,
    [IsControl]   INT      NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_HungryHorse_CompositeID_StartDate_EndDate]
    ON [InsightArchive].[HungryHorse]([CompositeID] ASC, [StartDate] ASC, [EndDate] ASC);

