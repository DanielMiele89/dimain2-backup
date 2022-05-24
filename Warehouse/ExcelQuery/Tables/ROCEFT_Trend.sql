CREATE TABLE [ExcelQuery].[ROCEFT_Trend] (
    [ID]                  INT   NOT NULL,
    [CycleStart]          DATE  NOT NULL,
    [CycleEnd]            DATE  NOT NULL,
    [Seasonality_CycleID] INT   NOT NULL,
    [BrandID]             INT   NOT NULL,
    [TotalSales]          MONEY NULL,
    [InStoreSales]        MONEY NULL,
    [OnlineSales]         MONEY NULL,
    [TotalTransactions]   INT   NULL,
    [InStoreTransactions] INT   NULL,
    [OnlineTransactions]  INT   NULL,
    [MinID]               INT   NOT NULL,
    [MaxID]               INT   NOT NULL,
    PRIMARY KEY CLUSTERED ([BrandID] ASC, [ID] ASC)
);

