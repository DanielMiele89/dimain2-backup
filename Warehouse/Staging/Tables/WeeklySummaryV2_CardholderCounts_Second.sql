CREATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_Second] (
    [RetailerID]          INT           NOT NULL,
    [PublisherID]         INT           NULL,
    [OfferTypeForReports] VARCHAR (100) NULL,
    [PeriodType]          VARCHAR (50)  NOT NULL,
    [StartDate]           DATE          NULL,
    [EndDate]             DATE          NULL,
    [Grouping]            VARCHAR (50)  NOT NULL,
    [Cardholders]         INT           NULL
);

