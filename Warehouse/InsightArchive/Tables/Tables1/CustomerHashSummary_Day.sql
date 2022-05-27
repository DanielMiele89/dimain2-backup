CREATE TABLE [InsightArchive].[CustomerHashSummary_Day] (
    [trandate]        DATE  NOT NULL,
    [TranCount]       INT   NOT NULL,
    [Spend]           MONEY NOT NULL,
    [UniqueCustomers] INT   NOT NULL,
    PRIMARY KEY CLUSTERED ([trandate] ASC)
);

