CREATE TABLE [Relational].[Customers_ReducedFrequency_Weeks] (
    [WeekBeginning]         DATE        NOT NULL,
    [EmailSendDate]         DATE        NULL,
    [ReducedFrequencyGroup] VARCHAR (1) NOT NULL,
    PRIMARY KEY CLUSTERED ([WeekBeginning] ASC)
);

