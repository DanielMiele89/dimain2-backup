CREATE TABLE [Relational].[SchemeUpliftTrans_Week] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [WeekDesc]  VARCHAR (50) NOT NULL,
    [StartDate] DATE         NOT NULL,
    [EndDate]   DATE         NOT NULL,
    [MonthID]   INT          NOT NULL,
    CONSTRAINT [PK_SchemeUpliftTrans_Week] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_Relational_SchemeUpliftTrans_Week_MonthID] FOREIGN KEY ([MonthID]) REFERENCES [Relational].[SchemeUpliftTrans_Month] ([ID])
);

