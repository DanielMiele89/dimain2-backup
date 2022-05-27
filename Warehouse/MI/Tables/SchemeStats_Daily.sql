CREATE TABLE [MI].[SchemeStats_Daily] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [DateID]           TINYINT      NOT NULL,
    [DateDesc]         VARCHAR (50) NOT NULL,
    [SchemeName]       VARCHAR (50) NOT NULL,
    [Spend]            MONEY        NOT NULL,
    [Earnings]         MONEY        NOT NULL,
    [TransactionCount] INT          NOT NULL,
    [CustomerCount]    INT          NOT NULL,
    CONSTRAINT [PK_MI_SchemeStats_Daily] PRIMARY KEY CLUSTERED ([ID] ASC)
);

