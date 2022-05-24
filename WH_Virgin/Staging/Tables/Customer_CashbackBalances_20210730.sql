CREATE TABLE [Staging].[Customer_CashbackBalances_20210730] (
    [ID]                BIGINT IDENTITY (1, 1) NOT NULL,
    [FanID]             INT    NOT NULL,
    [CashbackPending]   MONEY  NOT NULL,
    [CashbackAvailable] MONEY  NOT NULL,
    [CashbackLTV]       MONEY  NOT NULL,
    [Date]              DATE   NOT NULL
);

