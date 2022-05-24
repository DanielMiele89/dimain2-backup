CREATE TABLE [Prototype].[Ijaz_iTunes] (
    [BrandID]                SMALLINT     NOT NULL,
    [BrandName]              VARCHAR (50) NOT NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (50) NOT NULL,
    [LocationCountry]        VARCHAR (3)  NOT NULL,
    [TotalTransactionAmount] MONEY        NULL,
    [TotalTransactions]      INT          NULL,
    [FirstTransactionDate]   DATE         NULL,
    [LastTransactionDate]    DATE         NULL
);

