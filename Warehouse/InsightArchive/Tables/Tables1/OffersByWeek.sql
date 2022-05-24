CREATE TABLE [InsightArchive].[OffersByWeek] (
    [OffersByWeekID]   INT     IDENTITY (1, 1) NOT NULL,
    [SchemeTranWeekID] INT     NOT NULL,
    [OfferCount]       TINYINT NOT NULL,
    [CustomerCount]    INT     NOT NULL,
    [ActiveCustomers]  INT     NULL,
    PRIMARY KEY CLUSTERED ([OffersByWeekID] ASC)
);

