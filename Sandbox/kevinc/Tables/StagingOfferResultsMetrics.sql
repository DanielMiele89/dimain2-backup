CREATE TABLE [kevinc].[StagingOfferResultsMetrics] (
    [ReportingOfferID]              INT             NOT NULL,
    [StartDate]                     DATETIME2 (7)   NOT NULL,
    [EndDate]                       DATETIME2 (7)   NOT NULL,
    [Sales_E]                       MONEY           NULL,
    [CardHolders_E]                 INT             NULL,
    [Spenders_E]                    INT             NULL,
    [SpendPerCardHolder_E]          MONEY           NULL,
    [TransactionsPerCardHolder_E]   DECIMAL (18, 2) NULL,
    [RR_E]                          DECIMAL (18, 2) NULL,
    [AverageTransactionValue_E]     MONEY           NULL,
    [AverageTransactionFrequency_E] DECIMAL (18, 2) NULL,
    [SpendPerSpender_E]             MONEY           NULL,
    [Sales_C]                       MONEY           NULL,
    [CardHolders_C]                 INT             NULL,
    [Spenders_C]                    INT             NULL,
    [SpendPerCardHolder_C]          MONEY           NULL,
    [TransactionsPerCardHolder_C]   DECIMAL (18, 2) NULL,
    [RR_C]                          DECIMAL (18)    NULL,
    [AverageTransactionValue_C]     MONEY           NULL,
    [AverageTransactionFrequency_C] DECIMAL (18, 2) NULL,
    [SpendPerSpender_C]             MONEY           NULL,
    [Uplift]                        DECIMAL (18, 2) NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [kevinc].[StagingOfferResultsMetrics]([ReportingOfferID] ASC);

