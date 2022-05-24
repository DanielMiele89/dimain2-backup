CREATE TABLE [APW].[ControlAdjusted_Archive] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [CINID]       INT      NOT NULL,
    [MonthDate]   DATE     NOT NULL,
    [ArchiveDate] DATETIME CONSTRAINT [DF_APW_ControlAdjusted_Archive_ArchiveDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_APW_ControlAdjusted_Archive] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_MonthDate]
    ON [APW].[ControlAdjusted_Archive]([MonthDate] ASC)
    INCLUDE([CINID]) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

