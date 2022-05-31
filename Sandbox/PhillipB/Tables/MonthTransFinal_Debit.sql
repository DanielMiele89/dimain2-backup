CREATE TABLE [PhillipB].[MonthTransFinal_Debit] (
    [FanID]        INT        NULL,
    [Month]        DATE       NULL,
    [Transactions] FLOAT (53) NULL,
    [RowNumber]    INT        NOT NULL,
    PRIMARY KEY CLUSTERED ([RowNumber] ASC) WITH (FILLFACTOR = 90)
);

