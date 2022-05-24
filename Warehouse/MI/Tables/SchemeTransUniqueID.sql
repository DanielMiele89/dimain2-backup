CREATE TABLE [MI].[SchemeTransUniqueID] (
    [SchemeTransID] INT IDENTITY (1, 1) NOT NULL,
    [MatchID]       INT NULL,
    [FileID]        INT NULL,
    [RowNum]        INT NULL,
    CONSTRAINT [PK_MI_SchemeTransUniqueID] PRIMARY KEY CLUSTERED ([SchemeTransID] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE),
    CONSTRAINT [UK_MI_SchemeTransUniqueID] UNIQUE NONCLUSTERED ([MatchID] ASC, [FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE) ON [Warehouse_Indexes]
);


GO
CREATE NONCLUSTERED INDEX [IX_MI_SchemeTransUniqueID_MatchID]
    ON [MI].[SchemeTransUniqueID]([MatchID] ASC)
    INCLUDE([SchemeTransID]) WHERE ([MatchID] IS NOT NULL) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IX_MI_SchemeTransUniqueID_FileIDRowNum]
    ON [MI].[SchemeTransUniqueID]([FileID] ASC, [RowNum] ASC)
    INCLUDE([SchemeTransID]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

