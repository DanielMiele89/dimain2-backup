CREATE TABLE [Rory].[OS_Customer_CashbackBalance_2] (
    [FanID]             INT        NOT NULL,
    [ClubCashAvailable] SMALLMONEY NOT NULL,
    [ClubcashPending]   SMALLMONEY NOT NULL,
    [Date]              DATE       NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_All]
    ON [Rory].[OS_Customer_CashbackBalance_2]([FanID] ASC, [ClubCashAvailable] ASC, [ClubcashPending] ASC);

