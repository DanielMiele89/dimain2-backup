CREATE TABLE [Relational].[BrandCustomer] (
    [BrandID]       SMALLINT NOT NULL,
    [CustomerCount] INT      NULL,
    CONSTRAINT [PK_BrandCustomer] PRIMARY KEY CLUSTERED ([BrandID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_BrandCustomer_CustomerCount]
    ON [Relational].[BrandCustomer]([CustomerCount] ASC);

