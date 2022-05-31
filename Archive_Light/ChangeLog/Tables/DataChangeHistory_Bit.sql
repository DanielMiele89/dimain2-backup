CREATE TABLE [ChangeLog].[DataChangeHistory_Bit] (
    [TableColumnsID] INT      NOT NULL,
    [FanID]          INT      NOT NULL,
    [Date]           DATETIME NOT NULL,
    [Value]          BIT      NULL,
    CONSTRAINT [PK_DataChangeHistory_Bit] PRIMARY KEY CLUSTERED ([TableColumnsID] ASC, [FanID] ASC, [Date] DESC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = ROW)
);

