CREATE TABLE [MI].[LineTranDateTest] (
    [TranDate]  DATE  NOT NULL,
    [Spend]     MONEY NOT NULL,
    [SpendWeek] MONEY NOT NULL,
    CONSTRAINT [PK_MI_LineTranDateTest] PRIMARY KEY CLUSTERED ([TranDate] ASC)
);

