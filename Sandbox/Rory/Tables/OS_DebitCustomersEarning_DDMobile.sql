CREATE TABLE [Rory].[OS_DebitCustomersEarning_DDMobile] (
    [BankAccountID] INT   NOT NULL,
    [ClubCash]      MONEY NULL
);


GO
CREATE CLUSTERED INDEX [CIX_All]
    ON [Rory].[OS_DebitCustomersEarning_DDMobile]([BankAccountID] ASC, [ClubCash] ASC);

