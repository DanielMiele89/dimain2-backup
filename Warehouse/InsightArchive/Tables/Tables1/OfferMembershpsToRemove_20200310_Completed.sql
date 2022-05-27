CREATE TABLE [InsightArchive].[OfferMembershpsToRemove_20200310_Completed] (
    [IronOfferID] INT      NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NULL,
    [ImportDate]  DATETIME NOT NULL,
    [IsControl]   BIT      NOT NULL
);

