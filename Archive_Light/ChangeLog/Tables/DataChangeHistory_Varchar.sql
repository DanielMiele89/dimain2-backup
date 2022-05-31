CREATE TABLE [ChangeLog].[DataChangeHistory_Varchar] (
    [TableColumnsID] INT          NOT NULL,
    [FanID]          INT          NOT NULL,
    [Date]           DATETIME     NOT NULL,
    [Value]          VARCHAR (20) NULL,
    CONSTRAINT [PK_DataChangeHistory_Varchar] PRIMARY KEY CLUSTERED ([TableColumnsID] ASC, [FanID] ASC, [Date] DESC) WITH (FILLFACTOR = 80)
);

