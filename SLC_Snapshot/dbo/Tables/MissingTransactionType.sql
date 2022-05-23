CREATE TABLE [dbo].[MissingTransactionType] (
    [MissingTransactionTypeId] INT           NOT NULL,
    [Description]              NVARCHAR (50) NOT NULL,
    CONSTRAINT [PK_MissingTransactionType] PRIMARY KEY CLUSTERED ([MissingTransactionTypeId] ASC)
);

