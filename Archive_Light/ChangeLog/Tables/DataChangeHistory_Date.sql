CREATE TABLE [ChangeLog].[DataChangeHistory_Date] (
    [TableColumnsID] INT      NOT NULL,
    [FanID]          INT      NOT NULL,
    [Date]           DATETIME NOT NULL,
    [Value]          DATE     NULL,
    CONSTRAINT [PK_DataChangeHistory_Date] PRIMARY KEY CLUSTERED ([TableColumnsID] ASC, [FanID] ASC, [Date] DESC) WITH (FILLFACTOR = 80)
);

