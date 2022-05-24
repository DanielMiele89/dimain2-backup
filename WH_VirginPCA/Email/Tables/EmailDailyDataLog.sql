CREATE TABLE [Email].[EmailDailyDataLog] (
    [ID]             INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CompletionDate] DATETIME NOT NULL,
    CONSTRAINT [PK_EmailDailyDataLog] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);




GO
DENY SELECT
    ON OBJECT::[Email].[EmailDailyDataLog] TO [New_Insight]
    AS [New_DataOps];

