CREATE TABLE [dbo].[CurrencyCode] (
    [CurrencyCode] CHAR (3)      NOT NULL,
    [CurrencyName] VARCHAR (100) NOT NULL,
    [CurrencySign] VARCHAR (1)   NOT NULL,
    CONSTRAINT [PK_CurrencyCode] PRIMARY KEY CLUSTERED ([CurrencyCode] ASC) WITH (FILLFACTOR = 90)
);

