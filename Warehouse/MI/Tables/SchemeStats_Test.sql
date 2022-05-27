CREATE TABLE [MI].[SchemeStats_Test] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [SchemeName]       VARCHAR (50) NOT NULL,
    [RunDate]          DATE         NOT NULL,
    [Spend]            MONEY        NOT NULL,
    [Earnings]         MONEY        NOT NULL,
    [TransactionCount] INT          NOT NULL,
    [CustomerCount]    INT          NOT NULL,
    CONSTRAINT [PK_MI_SchemeStats_Test] PRIMARY KEY CLUSTERED ([ID] ASC)
);

