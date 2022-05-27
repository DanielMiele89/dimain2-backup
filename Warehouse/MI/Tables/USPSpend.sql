CREATE TABLE [MI].[USPSpend] (
    [ID]        INT      IDENTITY (1, 1) NOT NULL,
    [StatsDate] DATE     NOT NULL,
    [TranYear]  SMALLINT NOT NULL,
    [TranSpend] MONEY    NOT NULL,
    CONSTRAINT [PK_MI_USPSpend] PRIMARY KEY CLUSTERED ([ID] ASC)
);

