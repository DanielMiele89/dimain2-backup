CREATE TABLE [AWSFile].[SpendEarn_004] (
    [partnerName]        NVARCHAR (100) NULL,
    [transactionYear]    INT            NULL,
    [transactionMonth]   INT            NULL,
    [first_of_the_month] DATETIME       NULL,
    [customersSpending]  INT            NULL,
    [totalTransactions]  INT            NULL,
    [totalSpend]         MONEY          NULL,
    [customersEarning]   INT            NULL,
    [totalEarnings]      MONEY          NULL,
    [cashbackRate]       MONEY          NULL
);

