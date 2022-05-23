CREATE TABLE [dbo].[BankAccountTypeEligibility] (
    [ID]                     INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [IssuerID]               INT          NOT NULL,
    [BankAccountType]        VARCHAR (3)  NULL,
    [CustomerSegment]        VARCHAR (8)  NULL,
    [DirectDebitEligible]    BIT          NOT NULL,
    [POSEligible]            BIT          NOT NULL,
    [IronOfferID]            INT          NULL,
    [Priority]               TINYINT      NULL,
    [AutoActivateCBPAccount] BIT          NULL,
    [LoyaltyFlag]            VARCHAR (3)  NULL,
    [BankAccountName]        VARCHAR (30) NULL,
    CONSTRAINT [PK_BankAccountTypeEligibility] PRIMARY KEY NONCLUSTERED ([ID] ASC)
);


GO
CREATE CLUSTERED INDEX [icx_BankAccountTypeEligibility_IssuerID_BankAccountType]
    ON [dbo].[BankAccountTypeEligibility]([IssuerID] ASC, [BankAccountType] ASC);

