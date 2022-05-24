CREATE TABLE [Staging].[Customer_CashbackBalances] (
    [FanID]             INT        NOT NULL,
    [ClubcashPending]   SMALLMONEY NOT NULL,
    [ClubCashAvailable] SMALLMONEY NOT NULL,
    [Date]              DATE       NOT NULL,
    CONSTRAINT [PK_Customer_CashbackBalances] PRIMARY KEY CLUSTERED ([Date] ASC, [FanID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

