CREATE TABLE [Rory].[OS_DebitCustomersEarning_CurrentAccount] (
    [BankAccountID] INT   NULL,
    [ClubCash]      MONEY NULL
);


GO
CREATE CLUSTERED INDEX [CIX_All]
    ON [Rory].[OS_DebitCustomersEarning_CurrentAccount]([BankAccountID] ASC, [ClubCash] ASC);

