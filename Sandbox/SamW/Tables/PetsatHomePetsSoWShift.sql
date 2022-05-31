CREATE TABLE [SamW].[PetsatHomePetsSoWShift] (
    [Group]        VARCHAR (26) NOT NULL,
    [BrandName]    VARCHAR (50) NOT NULL,
    [Period]       VARCHAR (8)  NULL,
    [CreditDebit]  TINYINT      NOT NULL,
    [IsOnline]     BIT          NOT NULL,
    [TranDate]     DATE         NOT NULL,
    [Sales]        MONEY        NULL,
    [Transactions] INT          NULL,
    [Customers]    INT          NULL
);

