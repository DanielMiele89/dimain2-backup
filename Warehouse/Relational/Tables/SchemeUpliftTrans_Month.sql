CREATE TABLE [Relational].[SchemeUpliftTrans_Month] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [MonthDesc] VARCHAR (50) NOT NULL,
    [StartDate] DATE         NOT NULL,
    [EndDate]   DATE         NOT NULL,
    [QuarterID] INT          NOT NULL,
    CONSTRAINT [PK_Relational_SchemeUpliftTrans_Month] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_Relational_SUTMonth_SUTQuarter] FOREIGN KEY ([QuarterID]) REFERENCES [Relational].[SchemeUpliftTrans_Quarter] ([ID])
);

