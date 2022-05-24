CREATE TABLE [InsightArchive].[DDForecastStaging_SecondTranTotals] (
    [ID]                                  INT        IDENTITY (1, 1) NOT NULL,
    [ForecastID]                          INT        NOT NULL,
    [ForecastDate]                        DATETIME   NOT NULL,
    [Date]                                DATE       NOT NULL,
    [Weighted_Transactions]               FLOAT (53) NULL,
    [Weighted_AboveThresholdTransactions] FLOAT (53) NULL,
    [Weighted_BelowThresholdTransactions] FLOAT (53) NULL,
    [Weighted_Shoppers_Household]         FLOAT (53) NULL,
    [Weighted_Sales]                      MONEY      NULL,
    [Weighted_AboveThresholdSales]        MONEY      NULL,
    [Weighted_BelowThresholdSales]        MONEY      NULL,
    [Weighted_AboveThreshold_Investment]  MONEY      NULL,
    [Weighted_AboveThreshold_Cashback]    MONEY      NULL,
    [Weighted_AboveThreshold_Override]    MONEY      NULL,
    [Weighted_BelowThreshold_Investment]  MONEY      NULL,
    [Weighted_BelowThreshold_Cashback]    MONEY      NULL,
    [Weighted_BelowThreshold_Override]    MONEY      NULL,
    [Weighted_Total_Investment]           MONEY      NULL,
    [Weighted_Total_Cashback]             MONEY      NULL,
    [Weighted_Total_Override]             MONEY      NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIX_DDForecastStaging_SecondTranTotals]
    ON [InsightArchive].[DDForecastStaging_SecondTranTotals]([ForecastID] ASC);

