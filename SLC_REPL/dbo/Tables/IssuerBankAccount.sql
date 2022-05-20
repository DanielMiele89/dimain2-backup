CREATE TABLE [dbo].[IssuerBankAccount] (
    [ID]                           INT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [IssuerCustomerID]             INT              NOT NULL,
    [BankAccountID]                INT              NOT NULL,
    [Date]                         DATETIME         NOT NULL,
    [CustomerStatus]               INT              NOT NULL,
    [LastCustomerStatusChangeDate] DATETIME         NULL,
    [IssuerBankAccountUID]         UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_IssuerBankAccount] PRIMARY KEY CLUSTERED ([ID] ASC)
);

