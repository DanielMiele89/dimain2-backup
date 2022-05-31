CREATE TABLE [ChangeLog].[RunLog] (
    [ID]             INT      IDENTITY (1, 1) NOT NULL,
    [CompletionTime] DATETIME NOT NULL,
    CONSTRAINT [PK_RunLog] PRIMARY KEY CLUSTERED ([ID] ASC)
);

