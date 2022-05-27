CREATE TABLE [InsightArchive].[ExposedCounts] (
    [ID]               INT      IDENTITY (1, 1) NOT NULL,
    [RecordID]         INT      NOT NULL,
    [FirstTranMonthID] INT      NULL,
    [ActivatedMonthID] INT      NOT NULL,
    [ExposedCount]     INT      NOT NULL,
    [ControlCount]     INT      NULL,
    [StartID]          INT      NULL,
    [EndID]            INT      NULL,
    [WhenInserted]     DATETIME DEFAULT (getdate()) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

