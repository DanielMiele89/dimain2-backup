CREATE TABLE [Reporting].[SpendEarn_004] (
    [partnerName]        VARCHAR (100)   NOT NULL,
    [customersSpending]  INT             NULL,
    [totalTransactions]  INT             NULL,
    [customersEarning]   INT             NULL,
    [totalSpend]         DECIMAL (38, 2) NULL,
    [totalEarnings]      DECIMAL (38, 2) NULL,
    [transactionMonth]   INT             NULL,
    [transactionYear]    INT             NULL,
    [first_of_the_month] DATETIME        NULL
);

