CREATE TABLE [ChangeLog].[DataChangeHistory_Datetime] (
    [TableColumnsID] INT      NOT NULL,
    [FanID]          INT      NOT NULL,
    [Date]           DATETIME NOT NULL,
    [Value]          DATETIME NULL,
    CONSTRAINT [PK_DataChangeHistory_Datetime] PRIMARY KEY CLUSTERED ([TableColumnsID] ASC, [FanID] ASC, [Date] DESC) WITH (FILLFACTOR = 80)
);

