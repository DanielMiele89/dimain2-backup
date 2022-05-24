CREATE TABLE [Inbound].[BankAccountNominees] (
    [ID]                   BIGINT           IDENTITY (1, 1) NOT NULL,
    [BankAccountNomineeID] BIGINT           NOT NULL,
    [BankAccountGUID]      UNIQUEIDENTIFIER NOT NULL,
    [CustomerGUID]         UNIQUEIDENTIFIER NOT NULL,
    [StartDate]            DATETIME2 (7)    NOT NULL,
    [EndDate]              DATETIME2 (7)    NULL,
    [LoadDate]             DATETIME2 (7)    NOT NULL,
    [FileName]             NVARCHAR (320)   NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

