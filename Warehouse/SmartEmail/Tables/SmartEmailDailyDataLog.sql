CREATE TABLE [SmartEmail].[SmartEmailDailyDataLog] (
    [ID]             INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CompletionDate] DATETIME NOT NULL,
    CONSTRAINT [PK_SmartEmailDailyDataLog] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);


GO
GRANT SELECT
    ON OBJECT::[SmartEmail].[SmartEmailDailyDataLog] TO [sfduser]
    AS [dbo];

