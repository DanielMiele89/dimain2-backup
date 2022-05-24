CREATE TABLE [WHB].[Inbound_BankAccountCustomerLinks] (
    [BankAccountCustomerLinkID] BIGINT           NOT NULL,
    [BankAccountGUID]           UNIQUEIDENTIFIER NOT NULL,
    [CustomerGUID]              UNIQUEIDENTIFIER NOT NULL,
    [AccountRelationship]       NCHAR (2)        NOT NULL,
    [StartDate]                 DATETIME2 (7)    NOT NULL,
    [EndDate]                   DATETIME2 (7)    NULL,
    [LoadDate]                  DATETIME2 (7)    NOT NULL,
    [FileName]                  NVARCHAR (320)   NOT NULL,
    PRIMARY KEY CLUSTERED ([BankAccountCustomerLinkID] ASC)
);

