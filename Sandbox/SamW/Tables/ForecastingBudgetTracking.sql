CREATE TABLE [SamW].[ForecastingBudgetTracking] (
    [PublisherID]    INT           NULL,
    [BrandID]        INT           NULL,
    [RetailerName]   VARCHAR (500) NULL,
    [PublisherName]  VARCHAR (500) NULL,
    [Segment]        VARCHAR (500) NULL,
    [Above]          VARCHAR (500) NULL,
    [SpendStretch]   VARCHAR (500) NULL,
    [Below]          VARCHAR (500) NULL,
    [Bounty]         VARCHAR (500) NULL,
    [OfferType]      VARCHAR (500) NULL,
    [Spend]          VARCHAR (500) NULL,
    [Transactions]   VARCHAR (500) NULL,
    [Customers]      VARCHAR (500) NULL,
    [Investment]     VARCHAR (500) NULL,
    [CycleStartDate] DATETIME      NULL,
    [CycleEndDate]   DATETIME      NULL,
    [HalfCycleStart] DATETIME      NULL,
    [HalfCycleEnd]   DATETIME      NULL,
    [ForecastID]     NVARCHAR (50) NULL
);

