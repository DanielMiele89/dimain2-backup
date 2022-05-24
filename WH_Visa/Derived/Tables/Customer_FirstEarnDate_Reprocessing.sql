CREATE TABLE [Derived].[Customer_FirstEarnDate_Reprocessing] (
    [FanID]          INT              NOT NULL,
    [CardID]         UNIQUEIDENTIFIER NULL,
    [TranDate]       DATETIME         NULL,
    [LoadDate]       DATETIME2 (7)    NULL,
    [PartnerID]      INT              NOT NULL,
    [PartnerName]    NVARCHAR (100)   NOT NULL,
    [CashbackAmount] MONEY            NULL
);

