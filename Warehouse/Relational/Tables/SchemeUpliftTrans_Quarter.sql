CREATE TABLE [Relational].[SchemeUpliftTrans_Quarter] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [QuarterName] VARCHAR (50) NOT NULL,
    [StartDate]   DATE         NOT NULL,
    [EndDate]     DATE         NOT NULL,
    CONSTRAINT [PK_Relational_SchemeUpliftTrans_Quarter] PRIMARY KEY CLUSTERED ([ID] ASC)
);

