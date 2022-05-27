CREATE TABLE [dbo].[ALS_old] (
    [CINID]             INT          NOT NULL,
    [TranDate]          DATE         NOT NULL,
    [Amount]            MONEY        NOT NULL,
    [isonline]          BIT          NOT NULL,
    [BrandName]         VARCHAR (50) NOT NULL,
    [WEEK]              INT          NULL,
    [YEAR]              INT          NULL,
    [TransactionNumber] BIGINT       NULL
);

