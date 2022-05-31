CREATE TABLE [ChangeLog].[DataChangeHistory_Int] (
    [TableColumnsID] INT      NOT NULL,
    [FanID]          INT      NOT NULL,
    [Date]           DATETIME NOT NULL,
    [Value]          INT      NULL,
    CONSTRAINT [PK_DataChangeHistory_Int] PRIMARY KEY CLUSTERED ([TableColumnsID] ASC, [FanID] ASC, [Date] DESC) WITH (FILLFACTOR = 80)
);

