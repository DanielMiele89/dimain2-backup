CREATE TABLE [Prototype].[OINI_MyRewardsBankAccounts] (
    [BankAccountID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_BankAccountID]
    ON [Prototype].[OINI_MyRewardsBankAccounts]([BankAccountID] ASC);

