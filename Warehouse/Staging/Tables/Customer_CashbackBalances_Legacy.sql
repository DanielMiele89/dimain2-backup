CREATE TABLE [Staging].[Customer_CashbackBalances_Legacy] (
    [FanID]             INT        NOT NULL,
    [ClubcashPending]   SMALLMONEY NOT NULL,
    [ClubCashAvailable] SMALLMONEY NOT NULL,
    [Date]              DATE       NOT NULL,
    PRIMARY KEY NONCLUSTERED ([FanID] ASC, [Date] ASC)
);


GO
CREATE CLUSTERED INDEX [ixc_CCB]
    ON [Staging].[Customer_CashbackBalances_Legacy]([FanID] ASC, [Date] ASC) WITH (FILLFACTOR = 80);

