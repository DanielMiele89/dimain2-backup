CREATE TABLE [MI].[SchemeStats_Weekly_TranDate] (
    [ID]               INT   IDENTITY (1, 1) NOT NULL,
    [StartDate]        DATE  NOT NULL,
    [EndDate]          DATE  NOT NULL,
    [Spend]            MONEY NOT NULL,
    [Earnings]         MONEY NOT NULL,
    [TransactionCount] INT   NOT NULL,
    [CustomerCount]    INT   NOT NULL,
    CONSTRAINT [PK_MI_SchemeStats_Weekly_TranDate] PRIMARY KEY CLUSTERED ([ID] ASC)
);

