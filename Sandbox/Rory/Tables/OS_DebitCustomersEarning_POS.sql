CREATE TABLE [Rory].[OS_DebitCustomersEarning_POS] (
    [BankAccountID] INT   NULL,
    [ClubCash]      MONEY NULL
);


GO
CREATE CLUSTERED INDEX [CIX_All]
    ON [Rory].[OS_DebitCustomersEarning_POS]([BankAccountID] ASC, [ClubCash] ASC);

