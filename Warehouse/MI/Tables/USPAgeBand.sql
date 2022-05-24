CREATE TABLE [MI].[USPAgeBand] (
    [ID]            INT     IDENTITY (1, 1) NOT NULL,
    [StatsDate]     DATE    NOT NULL,
    [AgeBandID]     TINYINT NOT NULL,
    [CustomerCount] INT     NOT NULL,
    CONSTRAINT [PK_MI_USPAgeBand] PRIMARY KEY CLUSTERED ([ID] ASC)
);

