CREATE TABLE [ChangeLog].[DataChangeHistory_Smallmoney] (
    [TableColumnsID] INT        NOT NULL,
    [FanID]          INT        NOT NULL,
    [Date]           DATETIME   NOT NULL,
    [Value]          SMALLMONEY NULL,
    CONSTRAINT [PK_DataChangeHistory_Smallmoney] PRIMARY KEY CLUSTERED ([TableColumnsID] ASC, [FanID] ASC, [Date] ASC) WITH (FILLFACTOR = 80)
);

