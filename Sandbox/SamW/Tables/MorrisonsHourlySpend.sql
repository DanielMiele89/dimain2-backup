CREATE TABLE [SamW].[MorrisonsHourlySpend] (
    [VectorID]        INT             NOT NULL,
    [CardMatcherName] NVARCHAR (50)   NOT NULL,
    [Retailer]        NVARCHAR (100)  NOT NULL,
    [dt]              INT             NOT NULL,
    [TransactionDate] DATETIME        NOT NULL,
    [HOUR]            NVARCHAR (4000) NULL,
    [Date]            NVARCHAR (4000) NULL,
    [Spend]           MONEY           NULL,
    [Transactions]    INT             NULL
);

