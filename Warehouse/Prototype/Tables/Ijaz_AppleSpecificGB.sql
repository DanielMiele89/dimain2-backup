CREATE TABLE [Prototype].[Ijaz_AppleSpecificGB] (
    [BrandID]                SMALLINT     NOT NULL,
    [BrandName]              VARCHAR (50) NOT NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (50) NOT NULL,
    [TotalTransactionAmount] MONEY        NULL,
    [TotalTransactions]      INT          NULL,
    [FirstTransactionDate]   DATE         NULL,
    [LastTransactionDate]    DATE         NULL
);

