CREATE TABLE [InsightArchive].[MFDD_SecondTransaction] (
    [DateRow]                    BIGINT NULL,
    [Date]                       DATE   NULL,
    [Transactions]               INT    NULL,
    [AboveThresholdTransactions] INT    NULL,
    [BelowThresholdTransactions] INT    NULL,
    [Shoppers_Household]         INT    NULL,
    [Shoppers_FanID]             INT    NULL,
    [Sales]                      MONEY  NULL,
    [AboveThresholdSales]        MONEY  NULL,
    [BelowThresholdSales]        MONEY  NULL
);

