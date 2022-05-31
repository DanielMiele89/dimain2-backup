CREATE TABLE [Rory].[OS_DebitCustomersEarning] (
    [FanID]               INT         NOT NULL,
    [IssuerCustomerID]    INT         NOT NULL,
    [PanID]               INT         NULL,
    [IssuerBankAccountID] INT         NULL,
    [EarnType]            VARCHAR (3) NOT NULL,
    [ClubCash]            MONEY       NULL
);


GO
CREATE CLUSTERED INDEX [CIX_IssuerBankAccountID]
    ON [Rory].[OS_DebitCustomersEarning]([IssuerBankAccountID] ASC);

