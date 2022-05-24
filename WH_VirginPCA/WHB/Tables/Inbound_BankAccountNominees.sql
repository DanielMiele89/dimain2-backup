CREATE TABLE [WHB].[Inbound_BankAccountNominees] (
    [BankAccountNomineeID] BIGINT           NOT NULL,
    [BankAccountGUID]      UNIQUEIDENTIFIER NOT NULL,
    [CustomerGUID]         UNIQUEIDENTIFIER NOT NULL,
    [StartDate]            DATETIME2 (7)    NOT NULL,
    [EndDate]              DATETIME2 (7)    NULL,
    [LoadDate]             DATETIME2 (7)    NOT NULL,
    [FileName]             NVARCHAR (320)   NOT NULL,
    PRIMARY KEY CLUSTERED ([BankAccountNomineeID] ASC)
);

