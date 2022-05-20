CREATE TABLE [dbo].[InvoiceBankAccount] (
    [ID]                INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Name]              VARCHAR (128) NULL,
    [Address]           VARCHAR (256) NULL,
    [SortCode]          VARCHAR (12)  NULL,
    [BankAccountNumber] VARCHAR (16)  NULL,
    CONSTRAINT [PK_InvoiceBankAccount] PRIMARY KEY CLUSTERED ([ID] ASC)
);

