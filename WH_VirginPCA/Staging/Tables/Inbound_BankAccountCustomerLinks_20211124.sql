CREATE TABLE [Staging].[Inbound_BankAccountCustomerLinks_20211124] (
    [ID]                        BIGINT           IDENTITY (1, 1) NOT NULL,
    [BankAccountCustomerLinkID] BIGINT           NOT NULL,
    [BankAccountGUID]           UNIQUEIDENTIFIER NOT NULL,
    [CustomerGUID]              UNIQUEIDENTIFIER NOT NULL,
    [AccountRelationship]       NCHAR (2)        NOT NULL,
    [StartDate]                 DATETIME2 (7)    NOT NULL,
    [EndDate]                   DATETIME2 (7)    NULL,
    [LoadDate]                  DATETIME2 (7)    NOT NULL,
    [FileName]                  NVARCHAR (320)   NOT NULL
);

