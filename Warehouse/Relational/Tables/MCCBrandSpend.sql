CREATE TABLE [Relational].[MCCBrandSpend] (
    [MCC]         VARCHAR (4) NOT NULL,
    [BrandID]     SMALLINT    NOT NULL,
    [TotalAmount] MONEY       NULL,
    [TransCount]  INT         NULL,
    CONSTRAINT [PK_MCCBrandSpend] PRIMARY KEY CLUSTERED ([MCC] ASC, [BrandID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_MCCBrandSpend_AmountTransCount]
    ON [Relational].[MCCBrandSpend]([TotalAmount] ASC, [TransCount] ASC);

