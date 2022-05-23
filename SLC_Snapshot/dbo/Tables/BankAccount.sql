CREATE TABLE [dbo].[BankAccount] (
    [ID]                     INT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [SortCode]               VARCHAR (6)      NULL,
    [MaskedAccountNumber]    VARCHAR (8)      NULL,
    [EncryptedAccountNumber] VARBINARY (68)   NULL,
    [Date]                   DATETIME         NOT NULL,
    [Status]                 INT              NOT NULL,
    [LastStatusChangeDate]   DATETIME         NULL,
    [BankAccountUId]         UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_BankAccount] PRIMARY KEY CLUSTERED ([ID] ASC)
);

