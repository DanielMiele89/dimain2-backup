CREATE TABLE [Rory].[OS_DebitCustomers] (
    [FanID]               INT          NOT NULL,
    [CompositeID]         BIGINT       NULL,
    [SourceUID]           VARCHAR (20) NULL,
    [IssuerCustomerID]    INT          NOT NULL,
    [ClubID]              INT          NULL,
    [IsLoyalty]           INT          NOT NULL,
    [BankAccountType]     VARCHAR (3)  NOT NULL,
    [IssuerBankAccountID] INT          NOT NULL,
    [BankAccountID]       INT          NOT NULL,
    [DebitNominee]        INT          NULL,
    [IsFrontbook]         INT          NULL,
    [IsFrontbookPackaged] INT          NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [Rory].[OS_DebitCustomers]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_IssuerBankAccountID]
    ON [Rory].[OS_DebitCustomers]([IssuerBankAccountID] ASC);

