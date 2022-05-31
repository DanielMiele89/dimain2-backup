CREATE TABLE [ChangeLog].[DataChangeHistory_Nvarchar] (
    [TableColumnsID] INT            NOT NULL,
    [FanID]          INT            NOT NULL,
    [Date]           DATETIME       NOT NULL,
    [Value]          NVARCHAR (100) NULL,
    CONSTRAINT [PK_DataChangeHistory_Nvarchar] PRIMARY KEY CLUSTERED ([TableColumnsID] ASC, [FanID] ASC, [Date] DESC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = ROW)
);

