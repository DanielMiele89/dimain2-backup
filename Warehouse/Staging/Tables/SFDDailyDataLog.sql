CREATE TABLE [Staging].[SFDDailyDataLog] (
    [ID]             INT      IDENTITY (1, 1) NOT NULL,
    [CompletionDate] DATETIME NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

