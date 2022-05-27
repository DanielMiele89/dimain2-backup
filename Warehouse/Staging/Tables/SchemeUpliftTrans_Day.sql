CREATE TABLE [Staging].[SchemeUpliftTrans_Day] (
    [AddedDate] DATETIME NOT NULL,
    [WeekID]    INT      NOT NULL,
    CONSTRAINT [PK_SchemeUpliftTrans_Day] PRIMARY KEY CLUSTERED ([AddedDate] ASC)
);

