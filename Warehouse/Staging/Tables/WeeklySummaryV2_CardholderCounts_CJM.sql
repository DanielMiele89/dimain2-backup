CREATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_CJM] (
    [ID]                  INT           IDENTITY (1, 1) NOT NULL,
    [RetailerID]          INT           NOT NULL,
    [PublisherID]         INT           NULL,
    [OfferTypeForReports] VARCHAR (100) NULL,
    [PeriodType]          VARCHAR (50)  NOT NULL,
    [StartDate]           DATE          NOT NULL,
    [EndDate]             DATE          NOT NULL,
    [Cardholders]         INT           NULL,
    [Grouping]            VARCHAR (50)  NOT NULL,
    [ReportDate]          DATE          NOT NULL
);

