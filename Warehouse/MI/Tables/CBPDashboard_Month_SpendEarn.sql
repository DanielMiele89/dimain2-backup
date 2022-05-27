CREATE TABLE [MI].[CBPDashboard_Month_SpendEarn] (
    [SpendThisMonthRBS]              MONEY NOT NULL,
    [EarnedThisMonthRBS]             MONEY NOT NULL,
    [SpendersThisMonthRBS]           INT   NOT NULL,
    [TransactionsThisMonthRBS]       INT   NOT NULL,
    [SpendYearRBS]                   MONEY NOT NULL,
    [EarnedYearRBS]                  MONEY NOT NULL,
    [SpendersYearRBS]                INT   NOT NULL,
    [TransactionsYearRBS]            INT   NOT NULL,
    [SpendThisMonthCoalition]        MONEY NOT NULL,
    [EarnedThisMonthCoalition]       MONEY NOT NULL,
    [SpendersThisMonthCoalition]     INT   NOT NULL,
    [TransactionsThisMonthCoalition] INT   NOT NULL,
    [SpendYearCoalition]             MONEY NOT NULL,
    [EarnedYearCoalition]            MONEY NOT NULL,
    [SpendersYearCoalition]          INT   NOT NULL,
    [TransactionsYearCoalition]      INT   NOT NULL,
    [CoalitionCustomersMonthAverage] INT   NOT NULL,
    [CoalitionCustomersYear]         INT   NOT NULL
);

