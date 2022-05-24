CREATE TABLE [InsightArchive].[OffersAvailableByWeek] (
    [OffersByWeekID]   INT     IDENTITY (1, 1) NOT NULL,
    [SchemeTranWeekID] INT     NOT NULL,
    [OfferCount]       TINYINT NOT NULL,
    PRIMARY KEY CLUSTERED ([OffersByWeekID] ASC)
);

