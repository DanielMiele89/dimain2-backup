CREATE TABLE [ChangeLog].[DataChangeHistory_Tinyint] (
    [TableColumnsID] INT      NOT NULL,
    [FanID]          INT      NOT NULL,
    [Date]           DATETIME NOT NULL,
    [Value]          TINYINT  NULL,
    CONSTRAINT [PK_DataChangeHistory_Tinyint] PRIMARY KEY CLUSTERED ([TableColumnsID] ASC, [FanID] ASC, [Date] ASC) WITH (FILLFACTOR = 70, DATA_COMPRESSION = PAGE)
);

