CREATE TABLE [Derived].[Customer_FirstEarnDate] (
    [ID]             INT              IDENTITY (1, 1) NOT NULL,
    [FanID]          BIGINT           NULL,
    [CardID]         UNIQUEIDENTIFIER NULL,
    [TranDate]       DATETIME2 (0)    NULL,
    [LoadDate]       DATETIME2 (0)    NULL,
    [PartnerID]      INT              NULL,
    [PartnerName]    VARCHAR (50)     NULL,
    [CashbackAmount] MONEY            NULL
);

