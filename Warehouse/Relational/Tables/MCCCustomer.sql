CREATE TABLE [Relational].[MCCCustomer] (
    [MCC]           VARCHAR (4) NOT NULL,
    [CustomerCount] INT         NULL,
    CONSTRAINT [PK_MCCCustomer] PRIMARY KEY CLUSTERED ([MCC] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_MCCCustomer_CustomerCount]
    ON [Relational].[MCCCustomer]([CustomerCount] ASC);

