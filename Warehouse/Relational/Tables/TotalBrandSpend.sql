CREATE TABLE [Relational].[TotalBrandSpend] (
    [brandid]       SMALLINT NOT NULL,
    [Amount]        MONEY    NULL,
    [CustomerCount] INT      NULL,
    [TransCount]    INT      NULL,
    CONSTRAINT [PK_Relational_TotalBrandSpend] PRIMARY KEY CLUSTERED ([brandid] ASC)
);

