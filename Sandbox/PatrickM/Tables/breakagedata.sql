CREATE TABLE [PatrickM].[breakagedata] (
    [fanid]                  INT           NOT NULL,
    [transactionyear]        INT           NULL,
    [TransactionMonth]       INT           NULL,
    [IncludedMerchantBrands] INT           NOT NULL,
    [mindate]                DATE          NULL,
    [maxdate]                DATE          NULL,
    [cashbackearned]         MONEY         NULL,
    [Description]            VARCHAR (100) NULL,
    [Total]                  MONEY         NULL
);

