CREATE TABLE [WHB].[Inbound_BankAccounts] (
    [BankAccountGUID]    UNIQUEIDENTIFIER NOT NULL,
    [SortCode]           CHAR (6)         NOT NULL,
    [AccountNumber]      CHAR (8)         NOT NULL,
    [OpenedDate]         DATETIME2 (7)    NOT NULL,
    [ClosedDate]         DATETIME2 (7)    NULL,
    [BankID]             INT              NOT NULL,
    [CurrencyCode]       NVARCHAR (5)     NOT NULL,
    [NomineeLastChanged] DATETIME2 (7)    NULL,
    [BankAccountTypeID]  TINYINT          NULL,
    [LoadDate]           DATETIME2 (7)    NOT NULL,
    [FileName]           NVARCHAR (320)   NOT NULL,
    PRIMARY KEY CLUSTERED ([BankAccountGUID] ASC)
);

