CREATE TABLE [Staging].[FirstCustomerEarned_DD] (
    [FanID]           INT         NOT NULL,
    [BankAccountID]   INT         NOT NULL,
    [FirstEarnDate]   DATE        NOT NULL,
    [FirstEarnAmount] SMALLMONEY  NOT NULL,
    [AccountType]     VARCHAR (4) NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC, [BankAccountID] ASC)
);

