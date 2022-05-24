CREATE TABLE [MI].[CBPTotalDebitCardUsage] (
    [ID]                    INT   IDENTITY (1, 1) NOT NULL,
    [GeneratedDate]         DATE  NOT NULL,
    [MonthDate]             DATE  NOT NULL,
    [ActiveCustomerCount]   INT   NOT NULL,
    [SpendingCustomerCount] INT   NOT NULL,
    [Spend]                 MONEY NOT NULL,
    [ActiveCustomerTotal]   INT   NOT NULL,
    [SpendingCustomerTotal] INT   NOT NULL,
    CONSTRAINT [MI_CBPTotalDebitCardUsage] PRIMARY KEY CLUSTERED ([ID] ASC)
);

