CREATE TABLE [InsightArchive].[nFIs_SecondaryPartnerRecords_20190103] (
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NULL,
    [Date]        DATETIME NOT NULL,
    [IsControl]   BIT      NULL
);

