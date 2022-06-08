CREATE TABLE [dbo].[SnapshotData] (
    [SnapshotDataID]    UNIQUEIDENTIFIER NOT NULL,
    [CreatedDate]       DATETIME         NOT NULL,
    [ParamsHash]        INT              NULL,
    [QueryParams]       NTEXT            NULL,
    [EffectiveParams]   NTEXT            NULL,
    [Description]       NVARCHAR (512)   NULL,
    [DependsOnUser]     BIT              NULL,
    [PermanentRefcount] INT              NOT NULL,
    [TransientRefcount] INT              NOT NULL,
    [ExpirationDate]    DATETIME         NOT NULL,
    [PageCount]         INT              NULL,
    [HasDocMap]         BIT              NULL,
    [Machine]           NVARCHAR (512)   NOT NULL,
    [PaginationMode]    SMALLINT         NULL,
    [ProcessingFlags]   INT              NULL,
    [IsCached]          BIT              DEFAULT ((0)) NULL
);





GO
EXECUTE sp_tableoption @TableNamePattern = N'[dbo].[SnapshotData]', @OptionName = N'text in row', @OptionValue = N'256';


GO
CREATE CLUSTERED INDEX [IX_SnapshotData]
    ON [dbo].[SnapshotData]([SnapshotDataID] ASC, [ParamsHash] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SnapshotCleaning]
    ON [dbo].[SnapshotData]([PermanentRefcount] ASC, [TransientRefcount] ASC)
    INCLUDE([Machine]);


GO
CREATE NONCLUSTERED INDEX [IS_SnapshotExpiration]
    ON [dbo].[SnapshotData]([PermanentRefcount] ASC, [ExpirationDate] ASC);


GO
GRANT UPDATE
    ON OBJECT::[dbo].[SnapshotData] TO [RSExecRole]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[SnapshotData] TO [RSExecRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON OBJECT::[dbo].[SnapshotData] TO [RSExecRole]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[SnapshotData] TO [RSExecRole]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[dbo].[SnapshotData] TO [RSExecRole]
    AS [dbo];

