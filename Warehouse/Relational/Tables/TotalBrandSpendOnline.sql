CREATE TABLE [Relational].[TotalBrandSpendOnline] (
    [brandid]       SMALLINT NOT NULL,
    [Amount]        MONEY    NULL,
    [CustomerCount] INT      NULL,
    [TransCount]    INT      NULL,
    CONSTRAINT [PK_Relational_TotalBrandSpendOnline] PRIMARY KEY CLUSTERED ([brandid] ASC)
);

