CREATE TABLE [InsightArchive].[AviosRepartition_20170105] (
    [IronOfferMemberID] INT      NOT NULL,
    [IronOfferID]       INT      NOT NULL,
    [CompositeID]       BIGINT   NOT NULL,
    [StartDate]         DATETIME NULL,
    [EndDate]           DATETIME NULL,
    [AnalyticsTableID]  INT      NULL,
    [ImportDate]        DATETIME NOT NULL,
    [IsControl]         BIT      NOT NULL
);

