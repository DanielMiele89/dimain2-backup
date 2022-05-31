CREATE TABLE [SamW].[ForecastingBudgetTracking_Import_V2] (
    [PublisherID]    INT             NULL,
    [BrandID]        INT             NULL,
    [RetailerName]   VARCHAR (500)   NULL,
    [PublisherName]  VARCHAR (500)   NULL,
    [Segment]        VARCHAR (500)   NULL,
    [Above]          VARCHAR (500)   NULL,
    [SpendStretch]   VARCHAR (500)   NULL,
    [Below]          VARCHAR (500)   NULL,
    [Bounty]         VARCHAR (500)   NULL,
    [OfferType]      VARCHAR (500)   NULL,
    [Spend]          DECIMAL (10, 2) NULL,
    [Transactions]   INT             NULL,
    [Customers]      INT             NULL,
    [Investment]     DECIMAL (10, 2) NULL,
    [CycleStartDate] DATE            NULL,
    [CycleEndDate]   DATE            NULL,
    [HalfCycleStart] DATE            NULL,
    [HalfCycleEnd]   DATE            NULL,
    [ForecastID]     VARCHAR (500)   NULL
);

