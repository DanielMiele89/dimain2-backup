CREATE TABLE [dbo].[ExecutionCache] (
    [ExecutionCacheID]   UNIQUEIDENTIFIER NOT NULL,
    [ReportID]           UNIQUEIDENTIFIER NOT NULL,
    [ExpirationFlags]    INT              NOT NULL,
    [AbsoluteExpiration] DATETIME         NULL,
    [RelativeExpiration] INT              NULL,
    [SnapshotDataID]     UNIQUEIDENTIFIER NOT NULL,
    [LastUsedTime]       DATETIME         DEFAULT (getdate()) NOT NULL,
    [ParamsHash]         INT              DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExecutionCache] PRIMARY KEY NONCLUSTERED ([ExecutionCacheID] ASC)
);




GO
CREATE UNIQUE CLUSTERED INDEX [IX_ExecutionCache]
    ON [dbo].[ExecutionCache]([AbsoluteExpiration] DESC, [ReportID] ASC, [SnapshotDataID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SnapshotDataID]
    ON [dbo].[ExecutionCache]([SnapshotDataID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CacheLookup]
    ON [dbo].[ExecutionCache]([ReportID] ASC, [ParamsHash] ASC, [AbsoluteExpiration] DESC)
    INCLUDE([SnapshotDataID]);


GO
CREATE NONCLUSTERED INDEX [IX_ExecutionCacheLastUsed]
    ON [dbo].[ExecutionCache]([ReportID] ASC, [AbsoluteExpiration] ASC, [LastUsedTime] ASC, [ExecutionCacheID] ASC);


GO
GRANT UPDATE
    ON OBJECT::[dbo].[ExecutionCache] TO [RSExecRole]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[ExecutionCache] TO [RSExecRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON OBJECT::[dbo].[ExecutionCache] TO [RSExecRole]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[ExecutionCache] TO [RSExecRole]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[dbo].[ExecutionCache] TO [RSExecRole]
    AS [dbo];

