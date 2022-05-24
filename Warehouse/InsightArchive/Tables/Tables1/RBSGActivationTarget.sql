CREATE TABLE [InsightArchive].[RBSGActivationTarget] (
    [YearNumber]       SMALLINT NULL,
    [MonthNumber]      TINYINT  NULL,
    [ActivationTarget] INT      NULL,
    [ID]               INT      IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

